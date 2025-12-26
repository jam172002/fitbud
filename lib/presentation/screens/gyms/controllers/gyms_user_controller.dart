import 'dart:async';
import 'package:get/get.dart';

import '../../../../domain/models/gyms/gym.dart';
import '../../../../domain/repos/gyms/gym_repo.dart';
import '../../../../domain/repos/repo_exceptions.dart';

class GymsUserController extends GetxController {
  final GymRepo repo;
  GymsUserController(this.repo);

  final gyms = <Gym>[].obs;
  final busy = false.obs;
  final error = RxnString();

  StreamSubscription<List<Gym>>? _sub;

  @override
  void onInit() {
    super.onInit();
    watch();
  }

  void watch({String city = ''}) {
    error.value = null;
    busy.value = true;

    _sub?.cancel();
    _sub = repo.watchGyms(city: city).listen(
          (list) {
        gyms.assignAll(list);
        busy.value = false;
      },
      onError: (e) {
        busy.value = false;
        error.value = _friendlyError(e);
      },
    );
  }

  Future<void> refreshOnce({String city = ''}) async {
    try {
      busy.value = true;
      error.value = null;
      // simplest refresh: re-watch
      watch(city: city);
    } finally {
      busy.value = false;
    }
  }

  String _friendlyError(dynamic e) {
    if (e is PermissionException) return 'Please sign in to view gyms.';
    if (e is NotFoundException) return 'Gym data is not available right now.';
    return 'Unable to load gyms. Please try again.';
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
