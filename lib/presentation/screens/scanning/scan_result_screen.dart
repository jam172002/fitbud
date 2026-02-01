import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/scan_controller.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScanController controller = Get.find();
    final result = controller.lastResult.value!;

    final status = result['result'] ?? 'unknown';
    final message = result['message'] ?? '';

    final success = status == 'allowed';

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Result')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: success ? Colors.green : Colors.red,
              size: 96,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Check-in Successful' : 'Check-in Failed',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                controller.reset();
                Get.offAllNamed('/home');
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
