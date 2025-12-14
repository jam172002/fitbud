import 'package:get/get.dart';
import '../../../../domain/repos/repo_provider.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Provide Repos once globally (or do it in your main binding)
    if (!Get.isRegistered<Repos>()) {
      Get.put(Repos(), permanent: true);
    }

    // AuthController
    Get.put(AuthController(Get.find<Repos>()), permanent: true);
  }
}
