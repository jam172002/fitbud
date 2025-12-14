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
    required String title,
    String description = '',
    String photoUrl = '',
    List<String> initialMemberUserIds = const [],
  }) async {
    final uid = _uid();
    final groupRef = col(FirestorePaths.groups).doc();
    final groupId = groupRef.id;

    // Optional: create a conversation for this group (WhatsApp-style)
    final convRef = doc('${FirestorePaths.conversations}/group_$groupId');

    await db.runTransaction((tx) async {
      tx.set(groupRef, {
        'title': title,
        'photoUrl': photoUrl,
        'description': description,
        'createdByUserId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'memberCount': 1 + initialMemberUserIds.length,
      });

      // owner member
      tx.set(doc('${FirestorePaths.groupMembers(groupId)}/$uid'), GroupMember(
        id: uid,
        groupId: groupId,
        userId: uid,
        role: GroupRole.owner,
        joinedAt: DateTime.now(),
      ).toMap()..addAll({'joinedAt': FieldValue.serverTimestamp()}));

      // Add initial members directly (or invite instead)
      for (final m in initialMemberUserIds.toSet()) {
        if (m == uid) continue;
        tx.set(doc('${FirestorePaths.groupMembers(groupId)}/$m'), GroupMember(
          id: m,
          groupId: groupId,
          userId: m,
          role: GroupRole.member,
          joinedAt: DateTime.now(),
        ).toMap()..addAll({'joinedAt': FieldValue.serverTimestamp()}));
      }

      // Create group conversation
      tx.set(convRef, Conversation(
        id: convRef.id,
        type: ConversationType.group,
        title: title,
        groupId: groupId,
        createdByUserId: uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap()..addAll({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageId': '',
        'lastMessagePreview': '',
        'lastMessageAt': null,
      }));

      // Participants mirror group members
      final all = <String>{uid, ...initialMemberUserIds};
      for (final userId in all) {
        tx.set(
          doc('${FirestorePaths.conversationParticipants(convRef.id)}/$userId'),
          ConversationParticipant(
            id: userId,
            conversationId: convRef.id,
            userId: userId,
            joinedAt: DateTime.now(),
          ).toMap()..addAll({'joinedAt': FieldValue.serverTimestamp()}),
        );
      }
    });

    return groupId;
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
