import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/models/chat/conversation.dart';
import '../../../domain/models/chat/conversation_participant.dart';
import '../../../domain/models/chat/message.dart';
import '../../../domain/models/chat/user_conversation_index.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class ChatRepo extends RepoBase {
  final FirebaseAuth auth;
  ChatRepo(super.db, this.auth);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  // ✅ UPDATED: must return cleaned id reliably
  String _cleanId(String v) {
    final id = v.trim();
    if (id.isEmpty) return '';
    // prevent "/abc" or "abc/" from producing bad paths
    return id.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  // -----------------------------
  // Helpers
  // -----------------------------
/*  String _sortedPairKey(String a, String b) {
    final s = [a, b]..sort();
    return '${s[0]}_${s[1]}';
  }*/

  String _directConversationId(String a, String b) {
    final s = [a, b]..sort();
    return 'direct_${s[0]}_${s[1]}';
  }

  String _preview({required MessageType type, required String text}) {
    switch (type) {
      case MessageType.text:
        final t = text.trim();
        if (t.isEmpty) return '';
        return t.length > 60 ? '${t.substring(0, 60)}…' : t;
      case MessageType.image:
        return 'Photo';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Audio';
      case MessageType.file:
        return 'File';
      case MessageType.location:
        return 'Location';
      case MessageType.system:
        return 'System';
    }
  }

  // -----------------------------
  // Inbox
  // -----------------------------
  Stream<List<(UserConversationIndex idx, Conversation? conv)>> watchMyInbox({int limit = 50}) {
    final uid = _uid();

    // NOTE: FirestorePaths.userConversations(uid) is now alias to userInbox(uid)
    return col(FirestorePaths.userConversations(uid))
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((idxSnap) async {
      final idxItems = idxSnap.docs.map(UserConversationIndex.fromDoc).toList();
      if (idxItems.isEmpty) return <(UserConversationIndex, Conversation?)>[];

      final ids = idxItems
          .map((e) => _cleanId(e.conversationId))
          .where((e) => e.isNotEmpty)
          .toList();

      if (ids.isEmpty) return <(UserConversationIndex, Conversation?)>[];

      final convMap = <String, Conversation>{};

      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
        final snap = await db
            .collection(FirestorePaths.conversations)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final d in snap.docs) {
          convMap[d.id] = Conversation.fromDoc(d);
        }
      }

      return idxItems.map((idx) => (idx, convMap[_cleanId(idx.conversationId)])).toList();
    });
  }

  // -----------------------------
  // Participants
  // -----------------------------
  Stream<List<ConversationParticipant>> watchParticipants(String conversationId) {
    final id = _cleanId(conversationId);
    if (id.isEmpty) return const Stream.empty();

    return col(FirestorePaths.conversationParticipants(id))
        .snapshots()
        .map((q) => q.docs.map((d) => ConversationParticipant.fromDoc(d, conversationId: id)).toList());
  }

  Future<List<String>> _participantIdsOnce(String conversationId) async {
    final id = _cleanId(conversationId);
    if (id.isEmpty) return <String>[];
    final snap = await col(FirestorePaths.conversationParticipants(id)).get();
    return snap.docs.map((d) => d.id).toList();
  }

  // -----------------------------
  // Direct: get or create
  // -----------------------------
  Future<String> getOrCreateDirectConversation({required String otherUserId}) async {
    final uid = _uid();
    final other = _cleanId(otherUserId);

    if (other.isEmpty) throw RepoException('Other user id is empty', 'invalid_user');
    if (other == uid) throw RepoException('Cannot chat with yourself', 'self_chat_not_allowed');

    final convId = _directConversationId(uid, other);
    final convRef = doc('${FirestorePaths.conversations}/$convId');

    final existing = await convRef.get();
    if (existing.exists) return convId;

    final now = FieldValue.serverTimestamp();

    await db.runTransaction((tx) async {
      final check = await tx.get(convRef);
      if (check.exists) return;

      tx.set(convRef, {
        'type': ConversationType.direct.name,
        'title': '',
        'groupId': '',
        'createdByUserId': uid,
        'createdAt': now,
        'updatedAt': now,
        'lastMessageId': '',
        'lastMessagePreview': '',
        'lastMessageAt': null,
      });

      tx.set(doc('${FirestorePaths.conversationParticipants(convId)}/$uid'), {
        'userId': uid,
        'joinedAt': now,
        'lastReadAt': now,
        'isMuted': false,
        'mutedUntil': null,
      });

      tx.set(doc('${FirestorePaths.conversationParticipants(convId)}/$other'), {
        'userId': other,
        'joinedAt': now,
        'lastReadAt': null,
        'isMuted': false,
        'mutedUntil': null,
      });

      // ✅ UPDATED: ensure updatedAt exists for ordering + show without messages
      tx.set(
        doc('${FirestorePaths.userConversations(uid)}/$convId'),
        {
          'conversationId': convId,
          'type': ConversationType.direct.name,
          'title': '',
          'lastMessageAt': null,
          'lastMessagePreview': '',
          'unreadCount': 0,
          'updatedAt': now, // ✅
          'createdAt': now, // optional but useful
        },
        SetOptions(merge: true),
      );

      tx.set(
        doc('${FirestorePaths.userConversations(other)}/$convId'),
        {
          'conversationId': convId,
          'type': ConversationType.direct.name,
          'title': '',
          'lastMessageAt': null,
          'lastMessagePreview': '',
          'unreadCount': 0,
          'updatedAt': now, // ✅
          'createdAt': now, // optional but useful
        },
        SetOptions(merge: true),
      );
    });

    return convId;
  }

  // -----------------------------
  // Group creation (older chat-only)
  // -----------------------------
  Future<String> createGroupConversation({
    required String title,
    required List<String> memberUserIds,
  }) async {
    final uid = _uid();
    final members = {...memberUserIds, uid}.toList();

    final convRef = col(FirestorePaths.conversations).doc();
    final now = FieldValue.serverTimestamp();

    await db.runTransaction((tx) async {
      tx.set(convRef, {
        'type': ConversationType.group.name,
        'title': title.trim(),
        'groupId': '',
        'createdByUserId': uid,
        'createdAt': now,
        'updatedAt': now,
        'lastMessageId': '',
        'lastMessagePreview': '',
        'lastMessageAt': null,
      });

      for (final m in members) {
        tx.set(doc('${FirestorePaths.conversationParticipants(convRef.id)}/$m'), {
          'userId': m,
          'joinedAt': now,
          'lastReadAt': m == uid ? now : null,
          'isMuted': false,
          'mutedUntil': null,
        });

        // ✅ UPDATED: ensure updatedAt exists so it appears in inbox without messages
        tx.set(
          doc('${FirestorePaths.userConversations(m)}/${convRef.id}'),
          {
            'conversationId': convRef.id,
            'type': ConversationType.group.name,
            'title': title.trim(),
            'lastMessageAt': null,
            'lastMessagePreview': '',
            'unreadCount': 0,
            'updatedAt': now, // ✅
            'createdAt': now, // optional
          },
          SetOptions(merge: true),
        );
      }
    });

    return convRef.id;
  }

  // -----------------------------
  // Messages
  // -----------------------------
  Stream<List<Message>> watchMessages(String conversationId, {int limit = 100}) {
    final id = _cleanId(conversationId);
    if (id.isEmpty) return const Stream.empty();

    return col(FirestorePaths.conversationMessages(id))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => Message.fromDoc(d, conversationId: id)).toList());
  }

  Future<String> sendMessage({
    required String conversationId,
    required MessageType type,
    String text = '',
    String mediaUrl = '',
    String thumbnailUrl = '',
    double? lat,
    double? lng,
    String replyToMessageId = '',
    String clientMessageId = '',
    DateTime? clientCreatedAt,
  }) async {
    final uid = _uid();
    final cid = _cleanId(conversationId);

    if (cid.isEmpty) throw RepoException('Conversation id is empty', 'invalid_conversation');

    final me = await doc('${FirestorePaths.conversationParticipants(cid)}/$uid').get();
    if (!me.exists) throw PermissionException('Not a participant');

    final participantIds = await _participantIdsOnce(cid);
    final msgRef = col(FirestorePaths.conversationMessages(cid)).doc();

    final now = FieldValue.serverTimestamp();
    final preview = _preview(type: type, text: text);

    await db.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderUserId': uid,
        'type': type.name,
        'text': text,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'lat': lat,
        'lng': lng,
        'replyToMessageId': replyToMessageId,
        'createdAt': now,
        'clientMessageId': clientMessageId,
        'clientCreatedAt': clientCreatedAt == null ? null : Timestamp.fromDate(clientCreatedAt),

        'isDeleted': false,
        'deliveryState': DeliveryState.sent.name,
      });

      tx.update(
        doc('${FirestorePaths.conversations}/$cid'),
        {
          'lastMessageId': msgRef.id,
          'lastMessagePreview': preview,
          'lastMessageAt': now,
          'updatedAt': now,
        },
      );

      for (final pid in participantIds) {
        // ✅ UPDATED: write updatedAt for ordering + still keep unread logic same
        tx.set(
          doc('${FirestorePaths.userConversations(pid)}/$cid'),
          {
            'conversationId': cid,
            'lastMessageAt': now,
            'lastMessagePreview': preview,
            'unreadCount': pid == uid ? 0 : FieldValue.increment(1),
            'updatedAt': now, // ✅
          },
          SetOptions(merge: true),
        );
      }
    });

    return msgRef.id;
  }

  Future<void> markConversationRead(String conversationId) async {
    final uid = _uid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;

    final now = FieldValue.serverTimestamp();
    final batch = db.batch();

    batch.set(
      doc('${FirestorePaths.conversationParticipants(cid)}/$uid'),
      {'userId': uid, 'lastReadAt': now},
      SetOptions(merge: true),
    );

    // ✅ UPDATED: also set updatedAt (keeps ordering stable after read actions)
    batch.set(
      doc('${FirestorePaths.userConversations(uid)}/$cid'),
      {'unreadCount': 0, 'updatedAt': now},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> leaveConversation(String conversationId) async {
    final uid = _uid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;

    final batch = db.batch();
    batch.delete(doc('${FirestorePaths.conversationParticipants(cid)}/$uid'));
    batch.delete(doc('${FirestorePaths.userConversations(uid)}/$cid'));
    await batch.commit();
  }

  // In ChatRepo
  Stream<DateTime?> watchMyClearedAt(String conversationId) {
    final uid = _uid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return const Stream.empty();

    return doc('${FirestorePaths.conversationParticipants(cid)}/$uid')
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() ?? {};
      final ts = data['clearedAt'];
      if (ts is Timestamp) return ts.toDate();
      return null;
    });
  }

  /// "Delete chat" (clear for me only) - works for direct and group.
  /// - Marks my participant doc with clearedAt
  /// - Deletes my inbox index doc so it disappears from Inbox
  Future<void> deleteChatForMe(String conversationId) async {
    final uid = _uid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;

    // Make sure I'm a participant (otherwise no-op)
    final meRef = doc('${FirestorePaths.conversationParticipants(cid)}/$uid');
    final meSnap = await meRef.get();
    if (!meSnap.exists) {
      throw PermissionException('Not a participant');
    }

    final batch = db.batch();
    final now = FieldValue.serverTimestamp();

    // 1) Store clearedAt on participant (so UI filters old messages)
    batch.set(
      meRef,
      {
        'userId': uid,
        'clearedAt': now,
        'lastReadAt': now, // optional but keeps unread sane
      },
      SetOptions(merge: true),
    );

    // 2) Remove it from inbox list for me
    batch.delete(doc('${FirestorePaths.userConversations(uid)}/$cid'));

    await batch.commit();
  }

  Future<void> markConversationDelivered(String conversationId) async {
    final uid = _uid();
    final cid = _cleanId(conversationId);
    if (cid.isEmpty) return;

    await doc('${FirestorePaths.conversationParticipants(cid)}/$uid').set(
      {
        'userId': uid,
        'lastDeliveredAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

}
