import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class UserSettings implements FirestoreModel {
  @override
  final String id; // same as uid or a fixed doc id like "settings"

  final bool pushEnabled;
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool allowBuddyRequests;
  final bool allowGroupInvites;
  final String language;
  final String themeMode; // light/dark/system

  /// NEW: selected address doc id from users/{uid}/addresses/{addressId}
  final String? selectedAddressId;

  final DateTime? updatedAt;

  const UserSettings({
    required this.id,
    this.pushEnabled = true,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.allowBuddyRequests = true,
    this.allowGroupInvites = true,
    this.language = 'en',
    this.themeMode = 'system',
    this.selectedAddressId,
    this.updatedAt,
  });

  static UserSettings fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final sel = FirestoreModel.readString(d['selectedAddressId'], fallback: '').trim();

    return UserSettings(
      id: doc.id,
      pushEnabled: FirestoreModel.readBool(d['pushEnabled'], fallback: true),
      showOnlineStatus: FirestoreModel.readBool(d['showOnlineStatus'], fallback: true),
      showLastSeen: FirestoreModel.readBool(d['showLastSeen'], fallback: true),
      allowBuddyRequests: FirestoreModel.readBool(d['allowBuddyRequests'], fallback: true),
      allowGroupInvites: FirestoreModel.readBool(d['allowGroupInvites'], fallback: true),
      language: FirestoreModel.readString(d['language'], fallback: 'en'),
      themeMode: FirestoreModel.readString(d['themeMode'], fallback: 'system'),
      selectedAddressId: sel.isEmpty ? null : sel,
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
    );
  }


  @override
  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'allowBuddyRequests': allowBuddyRequests,
      'allowGroupInvites': allowGroupInvites,
      'language': language,
      'themeMode': themeMode,
      'selectedAddressId': selectedAddressId, // NEW
      'updatedAt': FirestoreModel.ts(updatedAt),
    };
  }
}
