import 'package:get/get.dart';

import '../../../../domain/repos/scans/scan_repo.dart';
class ScanController extends GetxController {
  final ScanRepo repo;

  ScanController(this.repo);

  final isScanning = false.obs;
  final isLoading = false.obs;
  final lastResult = Rxn<Map<String, dynamic>>();

  Future<void> scanQr({
    required String qrPayload,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final res = await repo.validateAndCreateScan(
        qrPayload: qrPayload,
      );

      lastResult.value = res;
    } catch (e) {
      Get.snackbar(
        'Scan Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    lastResult.value = null;
    isScanning.value = false;
  }
}
