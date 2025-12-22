import 'dart:math';
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

  // -----------------------------
  // Helpers
  // -----------------------------
  String _sortedPairKey(String a, String b) {
    final s = [a, b]..sort();
    return '${s[0]}_${s[1]}';
  }

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
  // Inbox: stream user index then hydrate conversations
  // -----------------------------
  Stream<List<(UserConversationIndex idx, Conversation? conv)>> watchMyInbox({int limit = 50}) {
    final uid = _uid();
    return col(FirestorePaths.userConversations(uid))
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((idxSnap) async {
      final idxItems = idxSnap.docs.map(UserConversationIndex.fromDoc).toList();
      if (idxItems.isEmpty) return <(UserConversationIndex, Conversation?)>[];

      final ids = idxItems.map((e) => e.conversationId).toList();

      // whereIn max 10 -> chunk
      final convMap = <String, Conversation>{};
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
        final snap = await db.collection(FirestorePaths.conversations)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in snap.docs) {
          convMap[d.id] = Conversation.fromDoc(d);
        }
      }

      return idxItems.map((idx) => (idx, convMap[idx.conversationId])).toList();
    });
  }

  // -----------------------------
  // Participants
  // -----------------------------
  Stream<List<ConversationParticipant>> watchParticipants(String conversationId) {
    return col(FirestorePaths.conversationParticipants(conversationId))
        .snapshots()
        .map((q) => q.docs.map((d) => ConversationParticipant.fromDoc(d, conversationId: conversationId)).toList());
  }

  Future<List<String>> _participantIdsOnce(String conversationId) async {
    final snap = await col(FirestorePaths.conversationParticipants(conversationId)).get();
    return snap.docs.map((d) => d.id).toList(); // doc id is uid
  }

  // -----------------------------
  // Direct conversation: get or create (deterministic id)
  // -----------------------------
  Future<String> getOrCreateDirectConversation({required String otherUserId}) async {
    final uid = _uid();
    if (otherUserId == uid) throw RepoException('Cannot chat with yourself', 'self_chat_not_allowed');

    final convId = _directConversationId(uid, otherUserId);
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

      // participants
      tx.set(
        doc('${FirestorePaths.conversationParticipants(convId)}/$uid'),
        {
          'userId': uid,
          'joinedAt': now,
          'lastReadAt': now,
          'isMuted': false,
          'mutedUntil': null,
        },
      );

      tx.set(
        doc('${FirestorePaths.conversationParticipants(convId)}/$otherUserId'),
        {
          'userId': otherUserId,
          'joinedAt': now,
          'lastReadAt': null,
          'isMuted': false,
          'mutedUntil': null,
        },
      );

      // inbox index docs
      tx.set(
        doc('${FirestorePaths.userConversations(uid)}/$convId'),
        {
          'conversationId': convId,
          'type': ConversationType.direct.name,
          'title': '',
          'lastMessageAt': null,
          'lastMessagePreview': '',
          'unreadCount': 0,
        },
        SetOptions(merge: true),
      );

      tx.set(
        doc('${FirestorePaths.userConversations(otherUserId)}/$convId'),
        {
          'conversationId': convId,
          'type': ConversationType.direct.name,
          'title': '',
          'lastMessageAt': null,
          'lastMessagePreview': '',
          'unreadCount': 0,
        },
        SetOptions(merge: true),
      );
    });

    return convId;
  }

  // -----------------------------
  // Group creation
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

        tx.set(doc('${FirestorePaths.userConversations(m)}/${convRef.id}'), {
          'conversationId': convRef.id,
          'type': ConversationType.group.name,
          'title': title.trim(),
          'lastMessageAt': null,
          'lastMessagePreview': '',
          'unreadCount': 0,
        }, SetOptions(merge: true));
      }
    });

    return convRef.id;
  }

  // -----------------------------
  // Messages
  // -----------------------------
  Stream<List<Message>> watchMessages(String conversationId, {int limit = 100}) {
    return col(FirestorePaths.conversationMessages(conversationId))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => Message.fromDoc(d, conversationId: conversationId)).toList());
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
  }) async {
    final uid = _uid();

    // guard: must be participant
    final me = await doc('${FirestorePaths.conversationParticipants(conversationId)}/$uid').get();
    if (!me.exists) throw PermissionException('Not a participant');

    // IMPORTANT: do NOT query inside transaction
    final participantIds = await _participantIdsOnce(conversationId);

    final msgRef = col(FirestorePaths.conversationMessages(conversationId)).doc();
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
        'isDeleted': false,
        'deliveryState': DeliveryState.sent.name,
      });

      tx.update(doc('${FirestorePaths.conversations}/$conversationId'), {
        'lastMessageId': msgRef.id,
        'lastMessagePreview': preview,
        'lastMessageAt': now,
        'updatedAt': now,
      });

      for (final pid in participantIds) {
        tx.set(
          doc('${FirestorePaths.userConversations(pid)}/$conversationId'),
          {
            'conversationId': conversationId,
            'lastMessageAt': now,
            'lastMessagePreview': preview,
            // increment unread for everyone except sender; sender forced to 0
            'unreadCount': pid == uid ? 0 : FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      }
    });

    return msgRef.id;
  }

  Future<void> markConversationRead(String conversationId) async {
    final uid = _uid();
    final now = FieldValue.serverTimestamp();
    final batch = db.batch();

    batch.set(
      doc('${FirestorePaths.conversationParticipants(conversationId)}/$uid'),
      {'userId': uid, 'lastReadAt': now},
      SetOptions(merge: true),
    );

    batch.set(
      doc('${FirestorePaths.userConversations(uid)}/$conversationId'),
      {'unreadCount': 0},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> leaveConversation(String conversationId) async {
    final uid = _uid();
    final batch = db.batch();
    batch.delete(doc('${FirestorePaths.conversationParticipants(conversationId)}/$uid'));
    batch.delete(doc('${FirestorePaths.userConversations(uid)}/$conversationId'));
    await batch.commit();
  }
}
