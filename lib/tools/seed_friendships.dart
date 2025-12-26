import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// If you are in a Flutter app, import your firebase_options if you use it:
// import 'firebase_options.dart';

/// Run this once to create friendships for testing.
///
/// Friendships doc id: "<smallerUid>_<largerUid>"
/// Fields:
/// - userAId (smaller)
/// - userBId (larger)
/// - userIds: [smaller, larger]  (IMPORTANT for arrayContains queries)
/// - createdAt: serverTimestamp
/// - isBlocked: false
/// - blockedByUserId: ""
Future<void> seedFriendships() async {
  // If you are running inside your app, Firebase is already initialized.
  // If you run as standalone, initialize Firebase:
  //
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  //
  // For most cases: call this from a debug screen after app start.

  final db = FirebaseFirestore.instance;

  const mainUid = 'rjLuAokrvqQsZgk64u07vYg1uD73';

  const otherUids = <String>[
    '1psiSmyWnFNs24laE99z43YoNQp2',
    '4hDDGw2UYcPZhQk4h2MkprDVWCJ2',
    'fKAY3piJMrV8siO5lSphQ1ttVsF3',
  ];

  final batch = db.batch();

  for (final other in otherUids) {
    if (other == mainUid) continue;

    final pair = [mainUid, other]..sort();
    final a = pair[0];
    final b = pair[1];

    final friendshipId = '${a}_$b';
    final ref = db.collection('friendships').doc(friendshipId);

    batch.set(ref, {
      'userAId': a,
      'userBId': b,
      'userIds': [a, b], // required for arrayContains
      'createdAt': FieldValue.serverTimestamp(),
      'isBlocked': false,
      'blockedByUserId': '',
    }, SetOptions(merge: true));
  }

  await batch.commit();
  // ignore: avoid_print
  print('Seeded friendships for main user: $mainUid');
}
