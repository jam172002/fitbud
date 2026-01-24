import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../presentation/screens/scanning/controllers/checkin_outbox_controller.dart';
import '../../../utils/qr_parser.dart';

// ✅ ADDED import
import 'checkin_status_sheet.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with WidgetsBindingObserver {
  late final MobileScannerController cameraController;
  final CheckinOutboxController outbox = Get.find<CheckinOutboxController>();

  bool _locked = false;
  bool _cameraRunning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates, // ✅ reduces repeated callbacks
      facing: CameraFacing.back,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ Avoid camera errors when app goes background/foreground
    if (!mounted) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    if (!_cameraRunning) {
      _cameraRunning = true;
      try {
        await cameraController.start();
      } catch (_) {
        // ignore; camera may already be running or unavailable briefly
      }
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraRunning) {
      _cameraRunning = false;
      try {
        await cameraController.stop();
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> _onBarcode(Barcode barcode) async {
    if (_locked) return;

    final raw = barcode.rawValue?.trim();
    if (raw == null || raw.isEmpty) {
      Get.snackbar(
        'Scan Failed',
        'Unable to read QR code. Try again!',
        backgroundColor: XColors.secondaryBG,
        colorText: XColors.primaryText,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final gymId = extractGymId(raw);
    if (gymId == null || gymId.isEmpty) {
      Get.snackbar(
        'Invalid QR',
        'This QR code is not a valid gym code.',
        backgroundColor: XColors.secondaryBG,
        colorText: XColors.primaryText,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ✅ Lock to prevent multiple detections
    _locked = true;

    // ✅ Stop camera once (don’t restart automatically)
    await _stopCamera();

    // ✅ Queue & send (offline-safe)
    // IMPORTANT: does NOT remove your old method; it just returns clientId
    final clientId = await outbox.enqueueAndSendWithId(gymId: gymId);

    Get.snackbar(
      'Check-in captured',
      'It will confirm automatically. (Cooldown: 120 minutes)',
      backgroundColor: XColors.secondaryBG,
      colorText: XColors.primaryText,
      snackPosition: SnackPosition.BOTTOM,
    );

    // ✅ ADDED: Show status UI so user knows if it is confirmed or not
    Get.bottomSheet(
      CheckinStatusSheet(
        clientCheckinId: clientId,
        gymId: gymId,
      ),
      isScrollControlled: true,
    );

    // Keep locked until user manually scans again
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

            SizedBox(
              height: 300,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) async {
                      if (capture.barcodes.isEmpty) return;
                      await _onBarcode(capture.barcodes.first);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    _locked = false;
                    await _startCamera();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _locked ? 'Scan Again' : 'Scan',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
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
