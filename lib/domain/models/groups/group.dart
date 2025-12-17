import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class Group implements FirestoreModel {
  @override
  final String id;

  final String title;
  final String photoUrl;
  final String description;
  final String createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int memberCount;

  const Group({
    required this.id,
    this.title = '',
    this.photoUrl = '',
    this.description = '',
    this.createdByUserId = '',
    this.createdAt,
    this.updatedAt,
    this.memberCount = 0,
  });

  static Group fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Group(
      id: doc.id,
      title: FirestoreModel.readString(d['title']),
      photoUrl: FirestoreModel.readString(d['photoUrl']),
      description: FirestoreModel.readString(d['description']),
      createdByUserId: FirestoreModel.readString(d['createdByUserId']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
      memberCount: FirestoreModel.readInt(d['memberCount']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'photoUrl': photoUrl,
      'description': description,
      'createdByUserId': createdByUserId,
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
      'memberCount': memberCount,
    };
  }
}
