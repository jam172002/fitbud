import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../../domain/models/auth/user_address.dart';
import '../../../../domain/repos/repo_provider.dart';

class LocationController extends GetxController {
  final Rxn<UserAddress> currentAddress = Rxn<UserAddress>();

  final _authRepo = Get.find<Repos>().authRepo;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<UserAddress>>? _addrSub;
  StreamSubscription<String?>? _selSub;

  List<UserAddress> _latestAddresses = const <UserAddress>[];
  String? _selectedAddressId;
  String? _boundUid;

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

    // Wait for auth to be ready, then bind streams
    _authSub = _auth.authStateChanges().listen((u) {
      final uid = u?.uid;

      // Signed out
      if (uid == null) {
        _unbindStreams();
        currentAddress.value = null;
        return;
      }

      // Signed in and not yet bound or changed user
      if (_boundUid != uid) {
        _bindStreams(uid);
      }
    });
  }

  void _bindStreams(String uid) {
    _unbindStreams();
    _boundUid = uid;

    // Addresses stream (safe now because user is definitely signed in)
    _addrSub = _authRepo.watchMyAddresses(limit: 50).listen((list) {
      _latestAddresses = list;
      _applySelection();
    });

    // Selected address id from settings
    _selSub = _authRepo.watchSelectedAddressId().listen((id) {
      final v = (id ?? '').trim();
      _selectedAddressId = v.isEmpty ? null : v;
      _applySelection();
    });
  }

  void _unbindStreams() {
    _addrSub?.cancel();
    _selSub?.cancel();
    _addrSub = null;
    _selSub = null;
    _latestAddresses = const <UserAddress>[];
    _selectedAddressId = null;
    _boundUid = null;
  }

  void _applySelection() {
    if (_latestAddresses.isEmpty) {
      currentAddress.value = null;
      return;
    }

    UserAddress? selected;

    // 1) Try selectedAddressId
    if (_selectedAddressId != null) {
      selected = _latestAddresses.firstWhereOrNull((a) => a.id == _selectedAddressId);
    }

    // 2) Else default
    selected ??= _latestAddresses.firstWhereOrNull((a) => a.isDefault);

    // 3) Else first
    selected ??= _latestAddresses.first;

    currentAddress.value = selected;
  }

  /// Persist selected address so it survives app restart
  Future<void> selectAndPersist(UserAddress address, {bool makeDefault = true}) async {
    currentAddress.value = address;
    _selectedAddressId = address.id;

    // Persist selection
    await _authRepo.setSelectedAddressId(address.id);

    // OPTIONAL: Also set as default in addresses collection
    if (makeDefault) {
      await _authRepo.setDefaultAddress(address.id);
    }
  }



  // Backwards compatible (if you call updateLocation anywhere else)
  Future<void> updateLocation(UserAddress address) async {
    await selectAndPersist(address);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _unbindStreams();
    super.onClose();
  }
}

extension FirstWhereOrNullExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final x in this) {
      if (test(x)) return x;
    }
    return null;
  }
}
