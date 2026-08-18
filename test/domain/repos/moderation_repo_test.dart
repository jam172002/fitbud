import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbud/domain/models/moderation/content_report.dart';
import 'package:fitbud/domain/repos/moderation/moderation_repo.dart';
import 'package:fitbud/domain/repos/repo_exceptions.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late ModerationRepo repo;
  const me = 'me-uid';
  const other = 'other-uid';

  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: me));
    repo = ModerationRepo(db, auth);
  });

  group('reportUser / reportMessage', () {
    test('creates a report doc with a deterministic id (reporter_type_target)', () async {
      await repo.reportUser(targetUserId: other, reason: ReportReason.harassment, details: 'rude');

      final id = ContentReport.idFor(
        reporterUserId: me,
        targetType: ReportTargetType.user,
        targetKey: other,
      );
      final snap = await db.collection('reports').doc(id).get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['reporterUserId'], me);
      expect(snap.data()!['targetUserId'], other);
      expect(snap.data()!['reason'], 'harassment');
      expect(snap.data()!['status'], 'open');
    });

    test('re-reporting the same target updates the existing doc instead of duplicating (abuse control)', () async {
      await repo.reportUser(targetUserId: other, reason: ReportReason.spam);
      await repo.reportUser(targetUserId: other, reason: ReportReason.harassment, details: 'again');

      final all = await db.collection('reports').get();
      expect(all.docs.length, 1);
      expect(all.docs.first.data()['reason'], 'harassment');
      expect(all.docs.first.data()['details'], 'again');
    });

    test('rejects reporting yourself', () async {
      await expectLater(
        repo.reportUser(targetUserId: me, reason: ReportReason.other),
        throwsA(isA<ValidationException>()),
      );
    });

    test('reportMessage records the conversation/message ids and the message author as the target', () async {
      await repo.reportMessage(
        conversationId: 'conv1',
        messageId: 'msg1',
        authorUserId: other,
        reason: ReportReason.sexualContent,
      );

      final id = ContentReport.idFor(
        reporterUserId: me,
        targetType: ReportTargetType.message,
        targetKey: 'msg1',
      );
      final snap = await db.collection('reports').doc(id).get();
      expect(snap.data()!['targetType'], 'message');
      expect(snap.data()!['targetUserId'], other);
      expect(snap.data()!['targetConversationId'], 'conv1');
      expect(snap.data()!['targetMessageId'], 'msg1');
    });

    test('watchMyReports only surfaces the current user\'s own reports', () async {
      await repo.reportUser(targetUserId: other, reason: ReportReason.spam);
      // A report filed by someone else, targeting a third user.
      await db.collection('reports').doc('someone_else_report').set({
        'reporterUserId': 'stranger',
        'targetType': 'user',
        'targetUserId': 'thirdUser',
        'targetConversationId': '',
        'targetMessageId': '',
        'reason': 'spam',
        'details': '',
        'status': 'open',
      });

      final mine = await repo.watchMyReports().first;
      expect(mine.length, 1);
      expect(mine.first.reporterUserId, me);
    });
  });

  group('blocking', () {
    test('blockUser writes users/{me}/blocks/{other}', () async {
      await repo.blockUser(other);
      final snap = await db.collection('users/$me/blocks').doc(other).get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['blockedUserId'], other);
    });

    test('unblockUser removes the block doc', () async {
      await repo.blockUser(other);
      await repo.unblockUser(other);
      final snap = await db.collection('users/$me/blocks').doc(other).get();
      expect(snap.exists, isFalse);
    });

    test('rejects blocking yourself', () async {
      await expectLater(repo.blockUser(me), throwsA(isA<ValidationException>()));
    });

    test('watchMyBlockedUserIds reflects current block state', () async {
      await repo.blockUser(other);
      final ids = await repo.watchMyBlockedUserIds().first;
      expect(ids, {other});
    });

    test('didIBlock is true only after I block them, and false after I unblock', () async {
      expect(await repo.didIBlock(other), isFalse);
      await repo.blockUser(other);
      expect(await repo.didIBlock(other), isTrue);
      await repo.unblockUser(other);
      expect(await repo.didIBlock(other), isFalse);
    });

    test('isBlockedEitherWay is true if I blocked them', () async {
      await repo.blockUser(other);
      expect(await repo.isBlockedEitherWay(other), isTrue);
    });

    test('isBlockedEitherWay is true if they blocked me, even though I never blocked them', () async {
      // Simulates the other side of the relationship: `other` has a block
      // record naming `me`, seeded directly since this repo instance is
      // signed in as `me`.
      await db.collection('users/$other/blocks').doc(me).set({'blockedUserId': me});
      expect(await repo.isBlockedEitherWay(other), isTrue);
    });

    test('isBlockedEitherWay is false when neither side has blocked the other', () async {
      expect(await repo.isBlockedEitherWay(other), isFalse);
    });
  });

  test('every method requires an authenticated user', () async {
    final signedOutAuth = MockFirebaseAuth(signedIn: false);
    final signedOutRepo = ModerationRepo(db, signedOutAuth);
    await expectLater(
      signedOutRepo.reportUser(targetUserId: other, reason: ReportReason.spam),
      throwsA(isA<PermissionException>()),
    );
    await expectLater(signedOutRepo.blockUser(other), throwsA(isA<PermissionException>()));
  });
}
