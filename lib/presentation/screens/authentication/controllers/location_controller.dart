
import 'package:get/get.dart';

import '../../../../domain/models/auth/user_address.dart';

class LocationController extends GetxController {
  final Rxn<UserAddress> currentAddress = Rxn<UserAddress>();

  /// Derived display string for UI
  String get locationLabel {
    final a = currentAddress.value;
    if (a == null) return 'Select Location';
    return a.subtitle; // or "${a.line1}, ${a.city}"
  }

  String get cityLabel {
    final a = currentAddress.value;
    return (a?.city?.trim().isNotEmpty == true) ? a!.city! : 'Pakistan';
  }

  void updateLocation(UserAddress address) {
    currentAddress.value = address;
  }
}
