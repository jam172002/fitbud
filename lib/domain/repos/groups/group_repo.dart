import 'package:uuid/uuid.dart';

import '../../models/groups/group.dart';
import '../../models/groups/group_invite.dart';
import '../../models/groups/group_member.dart';
import '../repo_base.dart';

class GroupRepo extends RepoBase {
  GroupRepo(super.db);

  String newGroupId() => const Uuid().v4();

  Stream<List<Group>> watchMyGroupsByMembership() {
    // Groups are RLS-scoped to the user's memberships, so every row the
    // stream returns is one of "my groups".
    return streamDocs('groups', orderBy: 'updated_at')
        .map((l) => l.map(Group.fromDoc).toList());
  }

  /// Creates the group, its members, the group chat, every participant and
  /// their inbox rows in one atomic server-side call.
  Future<String> createGroup({
    String? groupId,
    required String title,
    String description = '',
    String photoUrl = '',
    List<String> initialMemberUserIds = const [],
  }) async {
    requireUid();
    final members = initialMemberUserIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final gid = await db.rpc('create_group', params: {
      'p_group_id': groupId ?? '',
      'p_title': title,
      'p_description': description,
      'p_photo_url': photoUrl,
      'p_members': members,
    });
    return '$gid';
  }

  // ----- Members -----

  Stream<List<GroupMember>> watchGroupMembers(String groupId) {
    return streamDocs(
      'group_members',
      pk: ['group_id', 'user_id'],
      idKey: 'user_id',
      eqColumn: 'group_id',
      eqValue: groupId,
    ).map((l) {
      final list = l.map((d) => GroupMember.fromDoc(d, groupId: groupId)).toList();
      list.sort((a, b) => (a.joinedAt ?? DateTime(0)).compareTo(b.joinedAt ?? DateTime(0)));
      return list;
    });
  }

  // ----- Invites -----

  Future<String> inviteToGroup({
    required String groupId,
    required String invitedUserId,
  }) async {
    final uid = requireUid();
    final row = await db
        .from('group_invites')
        .insert({
          'group_id': groupId,
          'invited_user_id': invitedUserId,
          'invited_by_user_id': uid,
          'status': GroupInviteStatus.pending.name,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Stream<List<GroupInvite>> watchMyGroupInvites() {
    final uid = requireUid();
    return streamDocs(
      'group_invites',
      eqColumn: 'invited_user_id',
      eqValue: uid,
      orderBy: 'created_at',
      where: (r) => r['status'] == GroupInviteStatus.pending.name,
    ).map((l) => l.map(GroupInvite.fromDoc).toList());
  }

  Future<void> acceptGroupInvite({
    required String groupId,
    required String inviteId,
  }) async {
    await db.rpc('accept_group_invite', params: {'invite_id': inviteId});
  }

  Future<void> declineGroupInvite({
    required String groupId,
    required String inviteId,
  }) async {
    await db.rpc('decline_group_invite', params: {'invite_id': inviteId});
  }
}
