import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigation/user_navigation.dart';
import 'controllers/scan_controller.dart';

/// Typed view of the `scanGym` Cloud Function's response contract
/// (functions/src/index.ts). Mirrors the exact `result` string values the
/// backend returns - this used to be checked against `'allowed'`, a value
/// the function never actually returns, so a genuinely successful check-in
/// rendered as "Check-in Failed". Fixed by matching the real contract.
enum ScanOutcome { accepted, alreadyProcessed, cooldown, gymInactive, unknown }

/// Public (not `_`-prefixed) and `@visibleForTesting` solely so
/// test/presentation/scan_outcome_test.dart can verify every branch of the
/// backend contract mapping without needing to fake Firebase/GetX just to
/// pump this widget.
@visibleForTesting
ScanOutcome outcomeFromResult(String? result) {
  switch (result) {
    case 'accepted':
      return ScanOutcome.accepted;
    case 'already_processed':
      return ScanOutcome.alreadyProcessed;
    case 'cooldown':
      return ScanOutcome.cooldown;
    case 'gym_inactive':
      return ScanOutcome.gymInactive;
    default:
      return ScanOutcome.unknown;
  }
}

class _OutcomeDisplay {
  final IconData icon;
  final Color color;
  final String heading;
  const _OutcomeDisplay(this.icon, this.color, this.heading);
}

const _displays = {
  ScanOutcome.accepted: _OutcomeDisplay(Icons.check_circle, Colors.green, 'Checked In'),
  ScanOutcome.alreadyProcessed: _OutcomeDisplay(Icons.info, Colors.blue, 'Already Checked In'),
  ScanOutcome.cooldown: _OutcomeDisplay(Icons.access_time_filled, Colors.orange, 'Too Soon'),
  ScanOutcome.gymInactive: _OutcomeDisplay(Icons.cancel, Colors.red, 'Check-in Unavailable'),
  ScanOutcome.unknown: _OutcomeDisplay(Icons.help, Colors.grey, "Couldn't Confirm Check-in"),
};

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScanController controller = Get.find();
    final result = controller.lastResult.value ?? const {};

    final outcome = outcomeFromResult(result['result'] as String?);
    final display = _displays[outcome]!;
    final message = (result['message'] as String?)?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Result')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(display.icon, color: display.color, size: 96),
            const SizedBox(height: 16),
            Text(display.heading, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            if (message != null && message.isNotEmpty)
              Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                controller.reset();
                // Note: this app has no named-route table (no GetPage/
                // getPages anywhere) - `Get.offAllNamed('/home')` would
                // have thrown at runtime. Using the same
                // Get.offAll(() => Screen()) pattern login/logout use.
                Get.offAll(() => const UserNavigation());
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
