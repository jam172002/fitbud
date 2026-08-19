import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbud/domain/models/notifications/app_notification.dart';
import 'package:fitbud/domain/repos/notifications/notification_repo.dart';

/// Regression coverage for the notification write/read path fix: the
/// Cloud Function (functions/src/index.ts's `writeNotification`) writes to
/// `users/{uid}/notifications` with fields {userId, type, title, body,
/// data, isRead, createdAt}. This seeds a doc in exactly that shape - not
/// whatever shape the client happens to expect - so a future drift between
/// the two would show up here instead of only in production.
void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late NotificationRepo repo;
  const uid = 'notif-uid';

  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));
    repo = NotificationRepo(db, auth);
  });

  Future<void> seedServerWrittenNotification({
    required String id,
    required String type,
    required String title,
    required String body,
  }) {
    // Mirrors functions/src/index.ts's writeNotification() exactly.
    return db.collection('users/$uid/notifications').doc(id).set({
      'userId': uid,
      'type': type,
      'title': title,
      'body': body,
      'data': <String, dynamic>{},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  test('a notification written at the server path/schema is read back correctly by the client', () async {
    await seedServerWrittenNotification(
      id: 'n1',
      type: 'buddy_request',
      title: 'New Buddy Request',
      body: 'Alex sent you a buddy request',
    );

    final list = await repo.watchMyNotifications().first;
    expect(list.length, 1);
    final n = list.first;
    expect(n.id, 'n1');
    expect(n.userId, uid);
    expect(n.type, NotificationType.buddy_request);
    expect(n.title, 'New Buddy Request');
    expect(n.body, 'Alex sent you a buddy request');
    expect(n.isRead, isFalse);
  });

  test('every NotificationType the backend can send round-trips through fromDoc correctly', () async {
    const backendTypes = [
      'buddy_request',
      'buddy_accepted',
      'session_invite',
      'message',
    ];
    for (final t in backendTypes) {
      await seedServerWrittenNotification(id: 'n_$t', type: t, title: 'T', body: 'B');
    }

    final list = await repo.watchMyNotifications().first;
    final byId = {for (final n in list) n.id: n};
    for (final t in backendTypes) {
      expect(byId['n_$t']!.type.name, t);
    }
  });

  test('watchMyNotifications only returns the signed-in user\'s own notifications', () async {
    await seedServerWrittenNotification(id: 'mine', type: 'message', title: 'Hi', body: 'B');
    await db.collection('users/someone-else/notifications').doc('theirs').set({
      'userId': 'someone-else',
      'type': 'message',
      'title': 'Not mine',
      'body': 'B',
      'data': <String, dynamic>{},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final list = await repo.watchMyNotifications().first;
    expect(list.length, 1);
    expect(list.first.id, 'mine');
  });

  test('markRead flips isRead on the exact doc the server wrote', () async {
    await seedServerWrittenNotification(id: 'n1', type: 'message', title: 'Hi', body: 'B');

    await repo.markRead('n1');

    final snap = await db.collection('users/$uid/notifications').doc('n1').get();
    expect(snap.data()!['isRead'], isTrue);
  });

  test('markAllRead flips every unread notification for the user', () async {
    await seedServerWrittenNotification(id: 'n1', type: 'message', title: 'A', body: 'B');
    await seedServerWrittenNotification(id: 'n2', type: 'buddy_request', title: 'C', body: 'D');
    await db.collection('users/$uid/notifications').doc('n1').update({'isRead': true});

    await repo.markAllRead();

    final all = await db.collection('users/$uid/notifications').get();
    expect(all.docs.every((d) => d.data()['isRead'] == true), isTrue);
  });
}
