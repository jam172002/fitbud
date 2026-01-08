import 'dart:async';
import 'package:get/get.dart';

import '../../../../domain/models/auth/user_address.dart';
import '../../../../domain/repos/repo_provider.dart';

class LocationController extends GetxController {
  final Rxn<UserAddress> currentAddress = Rxn<UserAddress>();

  // Dependencies
  final _authRepo = Get.find<Repos>().authRepo;

  StreamSubscription? _addrSub;
  StreamSubscription? _selSub;

  List<UserAddress> _latestAddresses = const <UserAddress>[];
  String? _selectedAddressId;

  /// Derived display string for UI
  String get locationLabel {
    final a = currentAddress.value;
    if (a == null) return 'Select Location';
    return a.subtitle;
  }

  String get cityLabel {
    final a = currentAddress.value;
    return (a?.city?.trim().isNotEmpty == true) ? a!.city! : 'Pakistan';
  }

  @override
  void onInit() {
    super.onInit();

    // 1) Listen addresses list
    _addrSub = _authRepo.watchMyAddresses(limit: 50).listen((list) {
      _latestAddresses = list;
      _applySelection();
    });

    // 2) Listen selectedAddressId from settings
    _selSub = _authRepo.watchSelectedAddressId().listen((id) {
      _selectedAddressId = (id?.trim().isNotEmpty == true) ? id!.trim() : null;
      _applySelection();
    });
  }

  void _applySelection() {
    if (_latestAddresses.isEmpty) {
      currentAddress.value = null;
      return;
    }

    UserAddress? selected;

    // A) pick by selectedAddressId
    if (_selectedAddressId != null) {
      selected = _latestAddresses.firstWhereOrNull((a) => a.id == _selectedAddressId);
    }

    // B) else pick default
    selected ??= _latestAddresses.firstWhereOrNull((a) => a.isDefault);

    // C) else pick first
    selected ??= _latestAddresses.first;

    currentAddress.value = selected;
  }

  /// Call this when user selects/confirm an address from bottom sheet
  Future<void> selectAndPersist(UserAddress address) async {
    currentAddress.value = address; // immediate UI update
    _selectedAddressId = address.id;

    await _authRepo.setSelectedAddressId(address.id);
  }

  /// Keep for backward compatibility (if other screens call updateLocation)
  /// Now it also persists selection.
  Future<void> updateLocation(UserAddress address) async {
    await selectAndPersist(address);
  }

  @override
  void onClose() {
    _addrSub?.cancel();
    _selSub?.cancel();
    super.onClose();
  }
}

// Helper extension (if not already in your project)
extension FirstWhereOrNullExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final x in this) {
      if (test(x)) return x;
    }
    return null;
  }
}
