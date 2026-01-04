import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/groups/group.dart';
import '../../../domain/models/groups/group_invite.dart';
import '../../../domain/models/groups/group_member.dart';
import '../../../domain/models/chat/conversation.dart';
import '../../../domain/models/chat/conversation_participant.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class GroupRepo extends RepoBase {
  final FirebaseAuth auth;
  GroupRepo(super.db, this.auth);
  String newGroupId() => col(FirestorePaths.groups).doc().id;

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  Stream<List<Group>> watchMyGroupsByMembership() {
    // If you want fast “my groups”, keep a mirror index: users/{uid}/groups/{groupId}
    // Here we do a simple approach: query GroupMember subcollection per group is hard.
    // Recommended: maintain an index collection `groupMemberships` or `users/{uid}/groups`.
    throw ValidationException('Use membership index for My Groups list (recommended).');
  }

  Future<String> createGroup({
    String? groupId,
    required String title,
    String description = '',
    String photoUrl = '',
    List<String> initialMemberUserIds = const [],
  }) async {
    final uid = _uid();

    final groupRef = groupId == null
        ? col(FirestorePaths.groups).doc()
        : col(FirestorePaths.groups).doc(groupId);

    final gid = groupRef.id;
    final convId = 'group_$gid';
    final convRef = doc('${FirestorePaths.conversations}/$convId');

    // sanitize member list
    final memberIds = <String>{
      uid,
      ...initialMemberUserIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
    };

    await db.runTransaction((tx) async {
      // 1) Group
      tx.set(groupRef, {
        'title': title,
        'photoUrl': photoUrl,
        'description': description,
        'createdByUserId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'memberCount': memberIds.length,
      }, SetOptions(merge: true));

      // 2) Members
      for (final userId in memberIds) {
        final role = userId == uid ? GroupRole.owner : GroupRole.member;

        tx.set(
          doc('${FirestorePaths.groupMembers(gid)}/$userId'),
          GroupMember(
            id: userId,
            groupId: gid,
            userId: userId,
            role: role,
            joinedAt: DateTime.now(),
          ).toMap()
            ..addAll({'joinedAt': FieldValue.serverTimestamp()}),
          SetOptions(merge: true),
        );
      }

      // 3) Conversation (group chat)
      tx.set(
        convRef,
        Conversation(
          id: convId,
          type: ConversationType.group,
          title: title,
          groupId: gid,
          createdByUserId: uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap()
          ..addAll({
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastMessageId': '',
            'lastMessagePreview': '',
            'lastMessageAt': null,
          }),
        SetOptions(merge: true),
      );

      // 4) Participants + 5) Inbox index (CRITICAL for production)
      for (final userId in memberIds) {
        // participants
        tx.set(
          doc('${FirestorePaths.conversationParticipants(convId)}/$userId'),
          ConversationParticipant(
            id: userId,
            conversationId: convId,
            userId: userId,
            joinedAt: DateTime.now(),
          ).toMap()
            ..addAll({'joinedAt': FieldValue.serverTimestamp()}),
          SetOptions(merge: true),
        );

        // inbox index => users/{uid}/inbox/{conversationId}
        tx.set(
          doc('${FirestorePaths.userInbox(userId)}/$convId'),
          {
            'conversationId': convId,
            'type': ConversationType.group.name, // important for InboxScreen
            'title': title,
            'photoUrl': photoUrl,
            'groupId': gid,
            'lastMessageAt': null,
            'lastMessagePreview': '',
            'unreadCount': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // OPTIONAL: group memberships mirror
        tx.set(
          doc('${FirestorePaths.userGroupMemberships(userId)}/$gid'),
          {
            'groupId': gid,
            'conversationId': convId,
            'title': title,
            'photoUrl': photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    return gid;
  }

  // ----- Members -----

  Stream<List<GroupMember>> watchGroupMembers(String groupId) {
    return col(FirestorePaths.groupMembers(groupId))
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((q) => q.docs.map((d) => GroupMember.fromDoc(d, groupId: groupId)).toList());
  }

  // ----- Invites -----

  Future<String> inviteToGroup({
    required String groupId,
    required String invitedUserId,
  }) async {
    final uid = _uid();
    final ref = col(FirestorePaths.groupInvites(groupId)).doc();
    await ref.set({
      'groupId': groupId,
      'invitedUserId': invitedUserId,
      'invitedByUserId': uid,
      'status': GroupInviteStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });
    return ref.id;
  }

  Stream<List<GroupInvite>> watchMyGroupInvites() {
    final uid = _uid();
    // Collection group query across all groups requires a collectionGroup.
    return db.collectionGroup('invites')
        .where('invitedUserId', isEqualTo: uid)
        .where('status', isEqualTo: GroupInviteStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => GroupInvite.fromDoc(d)).toList());
  }

  Future<void> acceptGroupInvite({
    required String groupId,
    required String inviteId,
  }) async {
    final uid = _uid();
    final inviteRef = doc('${FirestorePaths.groupInvites(groupId)}/$inviteId');
    final memberRef = doc('${FirestorePaths.groupMembers(groupId)}/$uid');
    final groupRef = doc('${FirestorePaths.groups}/$groupId');
    final convId = 'group_$groupId';

    await db.runTransaction((tx) async {
      final inv = await tx.get(inviteRef);
      if (!inv.exists) throw NotFoundException('Invite not found');
      final d = inv.data()!;
      if (d['invitedUserId'] != uid) throw PermissionException('Not your invite');
      if ((d['status'] as String?) != GroupInviteStatus.pending.name) return;

      tx.update(inviteRef, {
        'status': GroupInviteStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      tx.set(memberRef, {
        'userId': uid,
        'role': GroupRole.member.name,
        'joinedAt': FieldValue.serverTimestamp(),
        'isMuted': false,
        'mutedUntil': null,
      }, SetOptions(merge: true));

      tx.update(groupRef, {'memberCount': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()});

      // Ensure chat participant
      tx.set(doc('${FirestorePaths.conversationParticipants(convId)}/$uid'), {
        'userId': uid,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastReadAt': null,
        'isMuted': false,
        'mutedUntil': null,
      }, SetOptions(merge: true));
    });
  }

  Future<void> declineGroupInvite({
    required String groupId,
    required String inviteId,
  }) async {
    final uid = _uid();
    final inviteRef = doc('${FirestorePaths.groupInvites(groupId)}/$inviteId');

    await db.runTransaction((tx) async {
      final inv = await tx.get(inviteRef);
      if (!inv.exists) throw NotFoundException('Invite not found');
      final d = inv.data()!;
      if (d['invitedUserId'] != uid) throw PermissionException('Not your invite');
      if ((d['status'] as String?) != GroupInviteStatus.pending.name) return;
      tx.update(inviteRef, {
        'status': GroupInviteStatus.declined.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
