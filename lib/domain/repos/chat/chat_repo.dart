import '../../models/chat/conversation.dart';
import '../../models/chat/conversation_participant.dart';
import '../../models/chat/message.dart';
import '../../models/chat/user_conversation_index.dart';
import '../repo_base.dart';
import '../repo_exceptions.dart';

class ChatRepo extends RepoBase {
  ChatRepo(super.db);

  String _cleanId(String v) {
    final id = v.trim();
    if (id.isEmpty) return '';
    // prevent "/abc" or "abc/" from producing bad ids
    return id.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  // -----------------------------
  // Inbox
  // -----------------------------
  /// Index rows carry everything the inbox list needs (title, last message,
  /// unread count, type); they're maintained server-side by a trigger.
  Stream<List<(UserConversationIndex idx, Conversation? conv)>> watchMyInbox({int limit = 30}) {
    final uid = requireUid();
    return streamDocs(
      'inbox',
      pk: ['user_id', 'conversation_id'],
      idKey: 'conversation_id',
      eqColumn: 'user_id',
      eqValue: uid,
      orderBy: 'updated_at',
      limit: limit,
    ).map((l) => l.map((d) => (UserConversationIndex.fromDoc(d), null as Conversation?)).toList());
  }

  // -----------------------------
  // Participants
  // -----------------------------
  Stream<List<ConversationParticipant>> watchParticipants(String conversationId) {
    final id = _cleanId(conversationId);
    if (id.isEmpty) return const Stream.empty();

    return streamDocs(
      'conversation_participants',
      pk: ['conversation_id', 'user_id'],
      idKey: 'user_id',
      eqColumn: 'conversation_id',
      eqValue: id,
    ).map((l) => l.map((d) => ConversationParticipant.fromDoc(d, conversationId: id)).toList());
  }

  Future<List<String>> _participantIdsOnce(String conversationId) async {
    final id = _cleanId(conversationId);
    if (id.isEmpty) return <String>[];
    final rows = await db
        .from('conversation_participants')
        .select('user_id')
        .eq('conversation_id', id);
    return rows.map((r) => r['user_id'] as String).toList();
  }

  // -----------------------------
  // Direct: get or create
  // -----------------------------
  Future<String> getOrCreateDirectConversation({required String otherUserId}) async {
    final uid = requireUid();
    final other = _cleanId(otherUserId);

    if (other.isEmpty) throw RepoException('invalid_user', 'Other user id is empty');
    if (other == uid) throw RepoException('self_chat_not_allowed', 'Cannot chat with yourself');

    final id = await db.rpc('get_or_create_direct_conversation', params: {'other': other});
    return '$id';
  }

  // -----------------------------
  // Group creation (chat group)
  // -----------------------------
  Future<String> createGroupConversation({
    required String title,
    required List<String> memberUserIds,
  }) async {
    final gid = await db.rpc('create_group', params: {
      'p_group_id': '',
      'p_title': title.trim(),
      'p_description': '',
      'p_photo_url': '',
      'p_members': memberUserIds,
    });
    return 'group_$gid';
  }

  // -----------------------------
  // Messages
  // -----------------------------
  Stream<List<Message>> watchMessages(String conversationId, {int limit = 50}) {
    final id = _cleanId(conversationId);
    if (id.isEmpty) return const Stream.empty();

    return streamDocs(
      'messages',
      eqColumn: 'conversation_id',
      eqValue: id,
      orderBy: 'created_at',
      limit: limit,
    ).map((l) => l.map((d) => Message.fromDoc(d, conversationId: id)).toList());
  }

  /// Inserts the message; a database trigger updates the conversation, every
  /// participant's inbox row (unread counts) and the notifications.
  Future<String> sendMessage({
    required String conversationId,
    required MessageType type,
    List<String>? participantIds, // kept for call-site compatibility; unused
    String text = '',
    String mediaUrl = '',
    String thumbnailUrl = '',
    double? lat,
    double? lng,
    String replyToMessageId = '',
    String clientMessageId = '',
    DateTime? clientCreatedAt,
  }) async {
    final uid = requireUid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) throw RepoException('invalid_conversation', 'Conversation id is empty');

    final row = await db
        .from('messages')
        .insert({
          'conversation_id': cid,
          'sender_user_id': uid,
          'type': type.name,
          'text': text,
          'media_url': mediaUrl,
          'thumbnail_url': thumbnailUrl,
          'lat': lat,
          'lng': lng,
          'reply_to_message_id': replyToMessageId,
          'client_message_id': clientMessageId,
          'client_created_at': clientCreatedAt?.toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> markConversationRead(String conversationId) async {
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;
    await db.rpc('mark_conversation_read', params: {'cid': cid});
  }

  Future<void> leaveConversation(String conversationId) async {
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;
    await db.rpc('leave_conversation', params: {'cid': cid});
  }

  Stream<DateTime?> watchMyClearedAt(String conversationId) {
    final uid = requireUid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return const Stream.empty();

    return streamDocs(
      'conversation_participants',
      pk: ['conversation_id', 'user_id'],
      idKey: 'user_id',
      eqColumn: 'conversation_id',
      eqValue: cid,
      where: (r) => r['user_id'] == uid,
    ).map((l) {
      if (l.isEmpty) return null;
      return FirestoreModelDate.read(l.first.data()['clearedAt']);
    });
  }

  /// "Delete chat" (clear for me only) - works for direct and group.
  Future<void> deleteChatForMe(String conversationId) async {
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;
    await db.rpc('delete_chat_for_me', params: {'cid': cid});
  }

  Future<void> markConversationDelivered(String conversationId) async {
    final uid = requireUid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;

    await db
        .from('conversation_participants')
        .update({'last_delivered_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', cid)
        .eq('user_id', uid);
  }
}

/// Tiny date reader so this file doesn't need the model helper import.
class FirestoreModelDate {
  static DateTime? read(dynamic v) {
    if (v is DateTime) return v.toLocal();
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    return null;
  }
}
