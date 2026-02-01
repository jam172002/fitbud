import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/colors.dart';
import 'controllers/scan_controller.dart';
import 'scan_result_screen.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final ScanController controller = Get.find();

  bool scanned = false;

  Future<void> _handleScan(String payload) async {
    if (scanned) return;

    scanned = true;
    cameraController.stop();

    await controller.scanQr(qrPayload: payload);

    if (controller.lastResult.value != null) {
      Get.to(() => const ScanResultScreen());
    } else {
      scanned = false;
      cameraController.start();
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XColors.primaryBG,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Scan the gym QR code',
              style: TextStyle(
                color: XColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 320,
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      final code = barcode.rawValue;
                      if (code != null && code.isNotEmpty) {
                        _handleScan(code);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            Obx(() {
              if (controller.isLoading.value) {
                return const CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: () {
                  scanned = false;
                  cameraController.start();
                },
                child: const Text('Scan Again'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
