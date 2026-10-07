import 'package:flutter_test/flutter_test.dart';
import 'package:fitbud/presentation/screens/scanning/scan_result_screen.dart';

/// Covers the spec's QR test-plan item directly against the real contract
/// mapping used by ScanResultScreen: success / duplicate / cooldown /
/// inactive-gym / invalid-code / server-error, mirroring the exact
/// `result` strings functions/src/index.ts's scanGym actually returns
/// (see functions/src/__tests__/scanGym.test.ts for the backend side).
void main() {
  group('outcomeFromResult', () {
    test('accepted -> ScanOutcome.accepted (success)', () {
      expect(outcomeFromResult('accepted'), ScanOutcome.accepted);
    });

    test('already_processed -> ScanOutcome.alreadyProcessed (duplicate)', () {
      expect(outcomeFromResult('already_processed'), ScanOutcome.alreadyProcessed);
    });

    test('cooldown -> ScanOutcome.cooldown', () {
      expect(outcomeFromResult('cooldown'), ScanOutcome.cooldown);
    });

    test('gym_inactive -> ScanOutcome.gymInactive', () {
      expect(outcomeFromResult('gym_inactive'), ScanOutcome.gymInactive);
    });

    test('an unrecognized/garbage result (invalid-code, server-error, etc.) -> ScanOutcome.unknown', () {
      expect(outcomeFromResult('some_new_backend_value'), ScanOutcome.unknown);
      expect(outcomeFromResult('error'), ScanOutcome.unknown);
    });

    test('null result (e.g. a thrown/network error never populated lastResult) -> ScanOutcome.unknown', () {
      expect(outcomeFromResult(null), ScanOutcome.unknown);
    });

    test('the old, never-actually-returned "allowed" value is NOT treated as accepted', () {
      // Regression guard for the exact bug this screen used to have: it
      // checked for 'allowed', a value the backend never sends, so every
      // real success rendered as a failure.
      expect(outcomeFromResult('allowed'), isNot(ScanOutcome.accepted));
      expect(outcomeFromResult('allowed'), ScanOutcome.unknown);
    });
  });
}
