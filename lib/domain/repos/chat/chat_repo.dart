import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/chat/conversation.dart';
import '../../../domain/models/chat/message.dart';
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

  /// List conversations where current user is a participant.
  /// Implementation: collectionGroup("participants") -> conversationIds, then fetch conversation docs.
  /// For best performance, maintain user index: users/{uid}/conversations/{conversationId}.
  Stream<List<Conversation>> watchMyConversations() {
    final uid = _uid();

    // Use user index if you implement it.
    // Here is a workable approach: collectionGroup participants + then map to conversation doc snapshots.
    final participantsQuery = db.collectionGroup('participants')
        .where('userId', isEqualTo: uid);

    return participantsQuery.snapshots().asyncMap((q) async {
      final ids = q.docs.map((d) => d.reference.parent.parent!.id).toSet();
      if (ids.isEmpty) return <Conversation>[];

      // Firestore does not allow "whereIn" with huge list; for small it is ok.
      // We'll fetch sequentially (works, but you should build a user index for scale).
      final results = <Conversation>[];
      for (final id in ids) {
        final snap = await doc('${FirestorePaths.conversations}/$id').get();
        if (snap.exists) results.add(Conversation.fromDoc(snap));
      }
      results.sort((a, b) {
        final at = a.lastMessageAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastMessageAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return results;
    });
  }

  Stream<List<Message>> watchMessages(String conversationId, {int limit = 50}) {
    return col(FirestorePaths.conversationMessages(conversationId))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => Message.fromDoc(d, conversationId: conversationId)).toList());
  }

  Future<(List<Message> items, DocumentSnapshot<Map<String, dynamic>>? lastDoc)> loadMoreMessages({
    required String conversationId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 50,
  }) async {
    final q = col(FirestorePaths.conversationMessages(conversationId))
        .orderBy('createdAt', descending: true);
    final snap = await applyPaging(q: q, startAfter: startAfter, limit: limit).get();
    final items = snap.docs.map((d) => Message.fromDoc(d, conversationId: conversationId)).toList();
    final last = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (items, last);
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
    final msgRef = col(FirestorePaths.conversationMessages(conversationId)).doc();

    await db.runTransaction((tx) async {
      // Write message
      tx.set(msgRef, {
        'senderUserId': uid,
        'type': type.name,
        'text': text,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'lat': lat,
        'lng': lng,
        'replyToMessageId': replyToMessageId,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'deliveryState': DeliveryState.sent.name,
      });

      // Update conversation "last message"
      tx.update(doc('${FirestorePaths.conversations}/$conversationId'), {
        'lastMessageId': msgRef.id,
        'lastMessagePreview': _preview(type: type, text: text),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return msgRef.id;
  }

  Future<void> markConversationRead(String conversationId) async {
    final uid = _uid();
    await doc('${FirestorePaths.conversationParticipants(conversationId)}/$uid').set({
      'userId': uid,
      'lastReadAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _preview({required MessageType type, required String text}) {
    switch (type) {
      case MessageType.text:
        return text.length > 60 ? '${text.substring(0, 60)}…' : text;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎤 Audio';
      case MessageType.file:
        return '📎 File';
      case MessageType.location:
        return '📍 Location';
      case MessageType.system:
        return 'System';
    }
  }
}
