import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbud/domain/repos/account/account_repo.dart';

/// AccountRepo.requestDeletion()/getDeletionStatus() go over a real
/// cloud_functions HttpsCallable, which has no fake/mock implementation
/// available in this repo (unlike Firestore/Auth) - so those two paths are
/// exercised on the backend side instead, in
/// functions/src/__tests__/accountDeletion.test.ts, which calls the same
/// callable handler directly. `needsReauth` has no such dependency and is
/// fully covered here.
void main() {
  group('AccountRepo.needsReauth', () {
    test('true when nobody is signed in', () {
      final repo = AccountRepo(MockFirebaseAuth(signedIn: false), _NeverCalledFunctions());
      expect(repo.needsReauth(), isTrue);
    });

    test('false when the user signed in well within the max age', () {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'u1',
          email: 'u1@example.com',
          metadata: UserMetadata(
            DateTime.now().millisecondsSinceEpoch,
            DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch,
          ),
        ),
      );
      final repo = AccountRepo(auth, _NeverCalledFunctions());
      expect(repo.needsReauth(), isFalse);
    });

    test('true once the session is older than the 15-minute default max age', () {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'u1',
          email: 'u1@example.com',
          metadata: UserMetadata(
            DateTime.now().millisecondsSinceEpoch,
            DateTime.now().subtract(const Duration(minutes: 20)).millisecondsSinceEpoch,
          ),
        ),
      );
      final repo = AccountRepo(auth, _NeverCalledFunctions());
      expect(repo.needsReauth(), isTrue);
    });

    test('respects a custom maxAge', () {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'u1',
          email: 'u1@example.com',
          metadata: UserMetadata(
            DateTime.now().millisecondsSinceEpoch,
            DateTime.now().subtract(const Duration(minutes: 4)).millisecondsSinceEpoch,
          ),
        ),
      );
      final repo = AccountRepo(auth, _NeverCalledFunctions());
      expect(repo.needsReauth(maxAge: const Duration(minutes: 5)), isFalse);
      expect(repo.needsReauth(maxAge: const Duration(minutes: 3)), isTrue);
    });
  });
}

/// A FirebaseFunctions stand-in that fails the test loudly if any of these
/// tests ever accidentally invoke it - `needsReauth` is pure and must never
/// touch the network.
class _NeverCalledFunctions implements FirebaseFunctions {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    fail('needsReauth() should never call FirebaseFunctions');
  }
}
