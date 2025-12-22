import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeedUsers {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Main test account you provided
  static const String mainUid = 'rjLuAokrvqQsZgk64u07vYg1uD73';

  // Your provided UIDs (demo buddies)
  static const List<String> demoUids = <String>[
    'furz8yYJR7NEFLbQYPlDzvcfRX73',
    'jTcq9BKpR8hejSP5H8xgjOL3aaD2',
    'TsqnFnuVX2ZwdLZDVqc4N7KWo8r2',
  ];

  /// Run ALL seeding (profiles + friendships + direct chats)
  static Future<void> seedAll() async {
    await seedProfilesForExistingUids();
    await seedFriendshipsForMainUser();
    await seedDirectChatsForMainUser();
  }

  /// Run this ONCE to seed profile documents for existing Auth users.
  static Future<void> seedProfilesForExistingUids() async {
    const uids = demoUids;

    const activitiesPool = <String>[
      'Badminton',
      'Gym',
      'Running',
      'Football',
      'Cricket',
      'Yoga',
      'Cycling',
      'Swimming',
      'Basketball',
      'Tennis',
    ];

    const gymsPool = <String>[
      '360 GYM Commercial Area',
      'Iron House Fitness',
      'Gold Gym DHA',
      'Fitness Hub Model Town',
      'PowerHouse Gym',
    ];

    final profiles = <Map<String, dynamic>>[
      _buildUserProfile(
        uid: uids[0],
        displayName: 'Demo User 1',
        email: 'demo1@fitbud.app',
        phone: '03001234567',
        city: 'Lahore',
        gender: 'Male',
        dob: DateTime(1999, 4, 12),
        activities: const ['Badminton', 'Gym', 'Running'],
        favouriteActivity: 'Badminton',
        hasGym: true,
        gymName: '360 GYM Commercial Area',
        about:
        'Fitness enthusiast focused on consistency. Looking for workout buddies for Badminton and Gym sessions.',
      ),
      _buildUserProfile(
        uid: uids[1],
        displayName: 'Demo User 2',
        email: 'demo2@fitbud.app',
        phone: '03007654321',
        city: 'Lahore',
        gender: 'Female',
        dob: DateTime(2001, 9, 3),
        activities: const ['Yoga', 'Cycling', 'Running'],
        favouriteActivity: 'Yoga',
        hasGym: false,
        gymName: '',
        about:
        'I enjoy Yoga and outdoor activities. Prefer morning sessions and long-term accountability partners.',
      ),
      _buildUserProfile(
        uid: uids[2],
        displayName: 'Demo User 3',
        email: 'demo3@fitbud.app',
        phone: '03111223344',
        city: 'Islamabad',
        gender: 'Male',
        dob: DateTime(1997, 1, 22),
        activities: const ['Football', 'Cricket', 'Gym', 'Running'],
        favouriteActivity: 'Football',
        hasGym: true,
        gymName: 'PowerHouse Gym',
        about:
        'Team sports + strength training. Always up for Football and progressive gym routines.',
      ),
    ];

    final batch = _db.batch();

    for (final p in profiles) {
      final uid = p['id'] as String;
      final ref = _db.collection('users').doc(uid);
      batch.set(ref, p, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// NEW: Seed friendships between mainUid and demoUids.
  ///
  /// Creates docs in: friendships/{a_b}
  /// Fields match your Friendship model + adds `userIds` to support arrayContains.
  static Future<void> seedFriendshipsForMainUser() async {
    final batch = _db.batch();

    for (final other in demoUids) {
      if (other == mainUid) continue;

      final pair = <String>[mainUid, other]..sort();
      final a = pair[0];
      final b = pair[1];

      final friendshipId = '${a}_$b';
      final ref = _db.collection('friendships').doc(friendshipId);

      batch.set(ref, {
        'userAId': a,
        'userBId': b,
        'userIds': [a, b], // IMPORTANT for arrayContains queries
        'createdAt': FieldValue.serverTimestamp(),
        'isBlocked': false,
        'blockedByUserId': '',
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// NEW (Recommended): Create direct conversation docs for mainUid ↔ demoUids
  /// so Inbox will show chats immediately without needing buddy request accept flow.
  ///
  /// Creates:
  /// - conversations/direct_{a}_{b}
  /// - conversations/{id}/participants/{uid}
  /// - users/{uid}/conversations/{conversationId} index for both users
  static Future<void> seedDirectChatsForMainUser() async {
    final batch = _db.batch();

    for (final other in demoUids) {
      if (other == mainUid) continue;

      final pair = <String>[mainUid, other]..sort();
      final a = pair[0];
      final b = pair[1];

      final convId = 'direct_${a}_$b';

      final convRef = _db.collection('conversations').doc(convId);
      final pARef = convRef.collection('participants').doc(a);
      final pBRef = convRef.collection('participants').doc(b);

      final idxARef = _db.collection('users').doc(a).collection('conversations').doc(convId);
      final idxBRef = _db.collection('users').doc(b).collection('conversations').doc(convId);

      // Conversation document
      batch.set(convRef, {
        'type': 'direct',
        'title': '',
        'groupId': '',
        'createdByUserId': mainUid,
        'directKey': '${a}_$b', // optional but good for queries
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageId': '',
        'lastMessagePreview': '',
        'lastMessageAt': null,
      }, SetOptions(merge: true));

      // Participants
      batch.set(pARef, {
        'userId': a,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'lastReadAt': a == mainUid ? FieldValue.serverTimestamp() : null,
        'isMuted': false,
        'mutedUntil': null,
      }, SetOptions(merge: true));

      batch.set(pBRef, {
        'userId': b,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'lastReadAt': null,
        'isMuted': false,
        'mutedUntil': null,
      }, SetOptions(merge: true));

      // UserConversations index docs (Inbox index)
      batch.set(idxARef, {
        'conversationId': convId,
        'type': 'direct',
        'title': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': '',
        'unreadCount': 0,
      }, SetOptions(merge: true));

      batch.set(idxBRef, {
        'conversationId': convId,
        'type': 'direct',
        'title': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': '',
        'unreadCount': 0,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Builds a Firestore-ready payload matching your AppUser fields.
  static Map<String, dynamic> _buildUserProfile({
    required String uid,
    required String displayName,
    required String email,
    required String phone,
    required String city,
    required String gender,
    required DateTime dob,
    required List<String> activities,
    required String favouriteActivity,
    required bool hasGym,
    required String gymName,
    required String about,
  }) {
    return <String, dynamic>{
      'id': uid,
      'displayName': displayName,
      'email': email,
      'phone': phone,

      'photoUrl': '',
      'activities': activities,
      'favouriteActivity': favouriteActivity,
      'hasGym': hasGym,
      'gymName': gymName,
      'about': about,
      'isProfileComplete': true,

      'city': city,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),

      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
