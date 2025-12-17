import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool scanned = false;

  void _handleScan(Barcode barcode) {
    final code = barcode.rawValue;

    if (!scanned) {
      if (code != null && code.isNotEmpty) {
        scanned = true;

        // Navigate to next screen on success
      } else {
        // Show snackbar on failure
        Get.snackbar(
          'Scan Failed',
          'Unable to read QR code. Try again!',
          backgroundColor: XColors.secondaryBG,
          colorText: XColors.primaryText,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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
            const SizedBox(height: 30),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Scan the gym QR Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: XColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // QR Scanner
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) {
                      for (final barcode in capture.barcodes) {
                        _handleScan(barcode);
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Scan Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    scanned = false;
                    cameraController.start();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Scan',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
