import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/groups/group.dart';
import '../../../domain/models/groups/group_invite.dart';
import '../../../domain/models/groups/group_member.dart';
import '../../../domain/models/chat/conversation.dart';
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

  // ----------------------------
  // Membership Mirror (My Groups)
  // ----------------------------

  /// Uses users/{uid}/groupMemberships/{groupId} for fast “my groups”.
  Stream<List<Group>> watchMyGroupsByMembership({int limit = 100}) {
    final uid = _uid();
    return col(FirestorePaths.userGroupMemberships(uid))
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((q) async {
      final ids = q.docs.map((d) => d.id).toList();
      if (ids.isEmpty) return <Group>[];

      // Firestore whereIn max is 10, so chunk
      final out = <Group>[];
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);
        final gs = await db
            .collection(FirestorePaths.groups)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        out.addAll(gs.docs.map((d) => Group.fromDoc(d)));
      }

      // Keep order similar to membership docs order (best-effort)
      final order = {for (var i = 0; i < ids.length; i++) ids[i]: i};
      out.sort((a, b) => (order[a.id] ?? 1 << 30).compareTo(order[b.id] ?? 1 << 30));
      return out;
    });
  }

  // -------------
  // Group Helpers
  // -------------

  String _convId(String groupId) => 'group_$groupId';

  Future<Group?> getGroup(String groupId) async {
    final s = await db.collection(FirestorePaths.groups).doc(groupId).get();
    if (!s.exists) return null;
    return Group.fromDoc(s);
  }

  // -------------
  // Members
  // -------------

  Stream<List<GroupMember>> watchGroupMembers(String groupId) {
    return col(FirestorePaths.groupMembers(groupId))
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((q) => q.docs.map((d) => GroupMember.fromDoc(d, groupId: groupId)).toList());
  }

  Future<GroupRole> _myRoleTx(Transaction tx, {required String groupId, required String uid}) async {
    final myRef = doc('${FirestorePaths.groupMembers(groupId)}/$uid');
    final mySnap = await tx.get(myRef);
    if (!mySnap.exists) throw PermissionException('Not a group member');
    final data = mySnap.data() as Map<String, dynamic>? ?? {};
    return groupRoleFrom((data['role'] as String?) ?? GroupRole.member.name);
  }

  /// Admin/Owner only. Adds members directly (no invite flow).
  Future<void> addMembers({
    required String groupId,
    required List<String> userIds,
  }) async {
    final uid = _uid();
    final convId = _convId(groupId);

    final groupRef = doc('${FirestorePaths.groups}/$groupId');

    await db.runTransaction((tx) async {
      // Permission check
      final myRole = await _myRoleTx(tx, groupId: groupId, uid: uid);
      if (myRole != GroupRole.owner && myRole != GroupRole.admin) {
        throw PermissionException('Only owner/admin can add members');
      }

      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) throw NotFoundException('Group not found');

      final g = groupSnap.data() as Map<String, dynamic>? ?? {};
      final title = (g['title'] as String?) ?? '';
      final photoUrl = (g['photoUrl'] as String?) ?? '';

      int added = 0;
      for (final newUid in userIds.toSet()) {
        if (newUid.isEmpty) continue;

        final memberRef = doc('${FirestorePaths.groupMembers(groupId)}/$newUid');
        final memberSnap = await tx.get(memberRef);
        if (memberSnap.exists) continue;

        // group member
        tx.set(memberRef, {
          'userId': newUid,
          'role': GroupRole.member.name,
          'joinedAt': FieldValue.serverTimestamp(),
          'isMuted': false,
          'mutedUntil': null,
        });

        // conversation participant mirror
        tx.set(
          doc('${FirestorePaths.conversationParticipants(convId)}/$newUid'),
          {
            'userId': newUid,
            'joinedAt': FieldValue.serverTimestamp(),
            'lastReadAt': null,
            'isMuted': false,
            'mutedUntil': null,
          },
          SetOptions(merge: true),
        );

        // membership mirror (fast my-groups)
        tx.set(
          doc('${FirestorePaths.userGroupMemberships(newUid)}/$groupId'),
          {
            'groupId': groupId,
            'conversationId': convId,
            'role': GroupRole.member.name,
            'title': title,
            'photoUrl': photoUrl,
            'joinedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        added++;
      }

      if (added > 0) {
        tx.update(groupRef, {
          'memberCount': FieldValue.increment(added),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Member can leave (owner cannot leave without transfer/delete).
  Future<void> leaveGroup(String groupId) async {
    final uid = _uid();
    final convId = _convId(groupId);

    final groupRef = doc('${FirestorePaths.groups}/$groupId');
    final memberRef = doc('${FirestorePaths.groupMembers(groupId)}/$uid');
    final participantRef = doc('${FirestorePaths.conversationParticipants(convId)}/$uid');
    final mirrorRef = doc('${FirestorePaths.userGroupMemberships(uid)}/$groupId');

    await db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final data = memberSnap.data() as Map<String, dynamic>? ?? {};
      final role = groupRoleFrom((data['role'] as String?) ?? GroupRole.member.name);
      if (role == GroupRole.owner) {
        throw ValidationException('Owner cannot leave. Transfer ownership or delete the group.');
      }

      tx.delete(memberRef);
      tx.delete(participantRef);
      tx.delete(mirrorRef);

      tx.update(groupRef, {
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Admin/Owner only. Removes member.
  Future<void> removeMember({
    required String groupId,
    required String memberUserId,
  }) async {
    final uid = _uid();
    final convId = _convId(groupId);

    final groupRef = doc('${FirestorePaths.groups}/$groupId');
    final targetMemberRef = doc('${FirestorePaths.groupMembers(groupId)}/$memberUserId');
    final targetParticipantRef = doc('${FirestorePaths.conversationParticipants(convId)}/$memberUserId');
    final targetMirrorRef = doc('${FirestorePaths.userGroupMemberships(memberUserId)}/$groupId');

    await db.runTransaction((tx) async {
      final myRole = await _myRoleTx(tx, groupId: groupId, uid: uid);
      if (myRole != GroupRole.owner && myRole != GroupRole.admin) {
        throw PermissionException('Only owner/admin can remove members');
      }

      final targetSnap = await tx.get(targetMemberRef);
      if (!targetSnap.exists) return;

      final tData = targetSnap.data() as Map<String, dynamic>? ?? {};
      final tRole = groupRoleFrom((tData['role'] as String?) ?? GroupRole.member.name);

      // Only owner can remove admin/owner; admin can remove members only
      if (myRole == GroupRole.admin && (tRole == GroupRole.admin || tRole == GroupRole.owner)) {
        throw PermissionException('Admin cannot remove admin/owner');
      }
      if (tRole == GroupRole.owner) {
        throw ValidationException('Owner cannot be removed. Transfer ownership or delete group.');
      }

      tx.delete(targetMemberRef);
      tx.delete(targetParticipantRef);
      tx.delete(targetMirrorRef);

      tx.update(groupRef, {
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // -------------
  // Invites
  // -------------

  /// Optional: basic protection to avoid duplicate pending invites.
  Future<String> inviteToGroup({
    required String groupId,
    required String invitedUserId,
  }) async {
    final uid = _uid();
    final invitesCol = col(FirestorePaths.groupInvites(groupId));

    // Prevent duplicate pending invites (best-effort; still can race, but acceptable)
    final existing = await invitesCol
        .where('invitedUserId', isEqualTo: invitedUserId)
        .where('status', isEqualTo: GroupInviteStatus.pending.name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = invitesCol.doc();
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
    // NOTE: requires Firestore composite index for:
    // invitedUserId ==, status ==, createdAt desc
    return db
        .collectionGroup('invites')
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
    final convId = _convId(groupId);
    final mirrorRef = doc('${FirestorePaths.userGroupMemberships(uid)}/$groupId');

    await db.runTransaction((tx) async {
      final inv = await tx.get(inviteRef);
      if (!inv.exists) throw NotFoundException('Invite not found');
      final d = inv.data() as Map<String, dynamic>? ?? {};

      if (d['invitedUserId'] != uid) throw PermissionException('Not your invite');
      if ((d['status'] as String?) != GroupInviteStatus.pending.name) return;

      final gSnap = await tx.get(groupRef);
      if (!gSnap.exists) throw NotFoundException('Group not found');
      final g = gSnap.data() as Map<String, dynamic>? ?? {};
      final title = (g['title'] as String?) ?? '';
      final photoUrl = (g['photoUrl'] as String?) ?? '';

      tx.update(inviteRef, {
        'status': GroupInviteStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // group member
      tx.set(
        memberRef,
        {
          'userId': uid,
          'role': GroupRole.member.name,
          'joinedAt': FieldValue.serverTimestamp(),
          'isMuted': false,
          'mutedUntil': null,
        },
        SetOptions(merge: true),
      );

      // group counters
      tx.update(groupRef, {
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ensure chat participant
      tx.set(
        doc('${FirestorePaths.conversationParticipants(convId)}/$uid'),
        {
          'userId': uid,
          'joinedAt': FieldValue.serverTimestamp(),
          'lastReadAt': null,
          'isMuted': false,
          'mutedUntil': null,
        },
        SetOptions(merge: true),
      );

      // Membership mirror
      tx.set(
        mirrorRef,
        {
          'groupId': groupId,
          'conversationId': convId,
          'role': GroupRole.member.name,
          'title': title,
          'photoUrl': photoUrl,
          'joinedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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
      final d = inv.data() as Map<String, dynamic>? ?? {};

      if (d['invitedUserId'] != uid) throw PermissionException('Not your invite');
      if ((d['status'] as String?) != GroupInviteStatus.pending.name) return;

      tx.update(inviteRef, {
        'status': GroupInviteStatus.declined.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelInvite({
    required String groupId,
    required String inviteId,
  }) async {
    final uid = _uid();
    final inviteRef = doc('${FirestorePaths.groupInvites(groupId)}/$inviteId');

    await db.runTransaction((tx) async {
      final inv = await tx.get(inviteRef);
      if (!inv.exists) throw NotFoundException('Invite not found');
      final d = inv.data() as Map<String, dynamic>? ?? {};

      // Only inviter can cancel pending invite (you can expand to admin/owner)
      if (d['invitedByUserId'] != uid) throw PermissionException('Not your invite');
      if ((d['status'] as String?) != GroupInviteStatus.pending.name) return;

      tx.update(inviteRef, {
        'status': GroupInviteStatus.cancelled.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // -------------
  // Group Creation
  // -------------

  Future<String> createGroup({
    required String title,
    String description = '',
    String photoUrl = '',
    List<String> initialMemberUserIds = const [],
  }) async {
    final uid = _uid();

    final groupRef = col(FirestorePaths.groups).doc();
    final groupId = groupRef.id;

    final conversationId = _convId(groupId);
    final convRef = doc('${FirestorePaths.conversations}/$conversationId');

    final all = <String>{uid, ...initialMemberUserIds}.where((e) => e.trim().isNotEmpty).toSet();

    await db.runTransaction((tx) async {
      tx.set(groupRef, {
        'title': title,
        'photoUrl': photoUrl,
        'description': description,
        'createdByUserId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'memberCount': all.length,
        'conversationId': conversationId,
      });

      // conversation
      tx.set(
        convRef,
        Conversation(
          id: conversationId,
          type: ConversationType.group,
          title: title,
          groupId: groupId,
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
      );

      for (final userId in all) {
        final role = userId == uid ? GroupRole.owner : GroupRole.member;

        // group member
        tx.set(
          doc('${FirestorePaths.groupMembers(groupId)}/$userId'),
          {
            'userId': userId,
            'role': role.name,
            'joinedAt': FieldValue.serverTimestamp(),
            'isMuted': false,
            'mutedUntil': null,
          },
        );

        // conversation participant
        tx.set(
          doc('${FirestorePaths.conversationParticipants(conversationId)}/$userId'),
          {
            'userId': userId,
            'joinedAt': FieldValue.serverTimestamp(),
            'lastReadAt': null,
            'isMuted': false,
            'mutedUntil': null,
          },
        );

        // membership mirror
        tx.set(
          doc('${FirestorePaths.userGroupMemberships(userId)}/$groupId'),
          {
            'groupId': groupId,
            'conversationId': conversationId,
            'role': role.name,
            'title': title,
            'photoUrl': photoUrl,
            'joinedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
    });

    return groupId;
  }

  // -------------------------
  // Update group basic info
  // -------------------------

  /// Owner/admin can update title/description/photoUrl.
  /// Also updates conversation title and membership mirrors (best-effort).
  Future<void> updateGroupInfo({
    required String groupId,
    String? title,
    String? description,
    String? photoUrl,
  }) async {
    final uid = _uid();
    final convId = _convId(groupId);

    final groupRef = doc('${FirestorePaths.groups}/$groupId');
    final convRef = doc('${FirestorePaths.conversations}/$convId');

    await db.runTransaction((tx) async {
      final myRole = await _myRoleTx(tx, groupId: groupId, uid: uid);
      if (myRole != GroupRole.owner && myRole != GroupRole.admin) {
        throw PermissionException('Only owner/admin can update group');
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      tx.update(groupRef, updates);

      if (title != null) {
        tx.set(convRef, {'title': title, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
    });

    // Mirror updates (non-transactional best-effort; safe to fail)
    try {
      final g = await getGroup(groupId);
      if (g == null) return;

      final members = await col(FirestorePaths.groupMembers(groupId)).get();
      for (final m in members.docs) {
        final memberUid = (m.data()['userId'] as String?) ?? m.id;
        if (memberUid.isEmpty) continue;

        await doc('${FirestorePaths.userGroupMemberships(memberUid)}/$groupId').set(
          {
            'title': g.title,
            'photoUrl': g.photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (_) {}
  }
}
