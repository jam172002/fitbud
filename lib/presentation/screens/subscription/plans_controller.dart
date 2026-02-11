import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/plans/plan.dart';
import '../../../utils/enums.dart';
import 'directpay_webview_screen.dart';

class PremiumPlanController extends GetxController {
  PremiumPlanController({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // ---- UI expects these names ----
  final RxList<Plan> plans = <Plan>[].obs;
  final RxBool loading = true.obs;
  final RxString error = ''.obs;

  // ---- Selection/UI state ----
  final RxInt selectedIndex = (-1).obs;

  // Keep Rx private; expose public getters as NON-Rx (so your PlanCard code works)
  final Rx<PlanStatus> _status = PlanStatus.none.obs;
  final Rxn<PaymentMethod> _paymentMethod = Rxn<PaymentMethod>();
  final RxString _orderId = ''.obs;

  PlanStatus get status => _status.value;
  PaymentMethod? get paymentMethod => _paymentMethod.value;
  String get orderId => _orderId.value;

  // ---- User state ----
  final Rxn<AppUser> me = Rxn<AppUser>();

  StreamSubscription? _plansSub;
  StreamSubscription? _meSub;

  // ---------------- DirectPay constants ----------------
  static const String _kSuccessPrefix =
      "https://fitbud-46f70.web.app/payments/success";
  static const String _kFailedPrefix =
      "https://fitbud-46f70.web.app/payments/failed";

  static const String _fnCreatePaymentUrl = "directPayCreatePaymentUrl";
  static const String _fnFinalize = "directPayFinalizeFromRedirect";

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  @override
  void onInit() {
    super.onInit();
    _listenPlans();
    _listenMe();
  }

  // UI expects this
  Future<void> refreshPlans() async {
    _listenPlans();
  }

  // UI expects this
  bool isSelected(int index) => selectedIndex.value == index;

  // UI expects this
  bool isDisabled(int index) {
    final u = me.value;
    final alreadyPremium = u?.hasPremiumAccess == true;
    if (alreadyPremium) return true;

    if (index >= 0 && index < plans.length) {
      if (!plans[index].isActive) return true;
    }
    return false;
  }

  /// UI expects this signature.
  /// UPDATED:
  /// - JazzCash/EasyPaisa now use DirectPay PWA WebView flow.
  /// - Card keeps your existing direct activation flow.
  Future<void> setPending({
    required int index,
    required PaymentMethod method,
    required String order,
  }) async {
    if (isDisabled(index)) return;
    if (index < 0 || index >= plans.length) return;

    if (method == PaymentMethod.card) {
      await setActive(index);
      return;
    }

    await startDirectPayPwa(
      index: index,
      chosenMethod: method, // jazzcash/easypaisa
      orderId: order,
    );
  }

  // UI expects this
  Future<void> setActive(int index) async {
    if (isDisabled(index)) return;
    if (index < 0 || index >= plans.length) return;

    selectedIndex.value = index;
    _status.value = PlanStatus.active;
    _paymentMethod.value = PaymentMethod.card;
    _orderId.value = 'FB-${DateTime.now().millisecondsSinceEpoch}';

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final p = plans[index];
    final now = DateTime.now();
    final endAt = now.add(Duration(days: p.durationDays));

    final subRef = _db
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .doc(_orderId.value);

    await subRef.set({
      'status': 'active',
      'provider': 'card',
      'orderId': _orderId.value,
      'planId': p.id,
      'planName': p.name,
      'price': p.price,
      'currency': p.currency,
      'durationDays': p.durationDays,
      'startAt': Timestamp.fromDate(now),
      'endAt': Timestamp.fromDate(endAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'isPremium': true,
      'premiumUntil': Timestamp.fromDate(endAt),
      'activePlanId': p.id,
      'activeSubscriptionId': _orderId.value,
      'premiumUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- DIRECTPAY FLOW ----------------

  Future<void> startDirectPayPwa({
    required int index,
    required PaymentMethod chosenMethod, // jazzcash or easypaisa
    required String orderId,
  }) async {
    if (index < 0 || index >= plans.length) return;
    if (isDisabled(index)) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final p = plans[index];

    // 1) Local controller state
    selectedIndex.value = index;
    _status.value = PlanStatus.pending;
    _paymentMethod.value = chosenMethod;
    _orderId.value = orderId;

    // 2) Write pending (client-side, optional because function also merges it)
    final subRef = _db
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .doc(orderId);

    await subRef.set({
      'status': 'pending',
      'provider': 'directpay_pwa',
      'selectedMethod': chosenMethod.name,
      'orderId': orderId,
      'planId': p.id,
      'planName': p.name,
      'price': p.price,
      'currency': p.currency,
      'durationDays': p.durationDays,
      'startAt': FieldValue.serverTimestamp(),
      'endAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'activePlanId': p.id,
      'activeSubscriptionId': orderId,
      'isPremium': false,
      'premiumUntil': null,
      'premiumUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3) Call Cloud Function to get paymentUrl
    final create = _functions.httpsCallable(_fnCreatePaymentUrl);
    final finalize = _functions.httpsCallable(_fnFinalize);

    final resp = await create.call({
      "orderId": orderId,
      "planId": p.id,
    });
    debugPrint("DirectPay response: ${resp.data}");
    final data = resp.data;
    if (data is! Map || data["paymentUrl"] == null) {
      await cancelPending(orderId: orderId);
      return;
    }

    final paymentUrl = data["paymentUrl"].toString().trim();
    if (paymentUrl.isEmpty) {
      await cancelPending(orderId: orderId);
      return;
    }

    // 4) Open WebView
    final result = await Get.to(
          () => DirectPayWebViewScreen(
        initialUrl: paymentUrl,
        successPrefix: _kSuccessPrefix,
        failedPrefix: _kFailedPrefix,
      ),
    );

    // User closed/back
    if (result == null) {
      await cancelPending(orderId: orderId);
      return;
    }

    final bool success = (result is Map) && (result["success"] == true);
    final String finalOrderId =
    (result is Map ? (result["orderId"] ?? "") : "").toString().trim();

    if (finalOrderId.isEmpty) {
      await cancelPending(orderId: orderId);
      return;
    }

    // 5) Finalize server-side
    await finalize.call({
      "orderId": finalOrderId,
      "success": success,
    });
  }

  Future<void> cancelPending({required String orderId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final subRef =
    _db.collection('users').doc(uid).collection('subscriptions').doc(orderId);

    await subRef.set({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'isPremium': false,
      'premiumUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- LISTENERS ----------------

  void _listenPlans() {
    loading.value = true;
    error.value = '';

    _plansSub?.cancel();
    _plansSub = _db
        .collection('plans')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      plans.value = snap.docs.map((d) => Plan.fromDoc(d)).toList();
      loading.value = false;
      _syncSelectionWithUser();
    }, onError: (e) {
      loading.value = false;
      error.value = e.toString();
    });
  }

  void _listenMe() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _meSub?.cancel();
    _meSub = _db.collection('users').doc(uid).snapshots().listen((snap) {
      if (!snap.exists) {
        me.value = null;
        return;
      }
      me.value = AppUser.fromDoc(snap);
      _syncSelectionWithUser();
    });
  }

  void _syncSelectionWithUser() {
    final u = me.value;
    if (u == null) return;

    final planId = u.activePlanId;
    if (planId != null && planId.isNotEmpty) {
      final idx = plans.indexWhere((p) => p.id == planId);
      if (idx != -1) selectedIndex.value = idx;
    }

    if (u.hasPremiumAccess == true) {
      _status.value = PlanStatus.active;
      _paymentMethod.value = null;
      _orderId.value = u.activeSubscriptionId ?? '';
      return;
    }

    final subId = u.activeSubscriptionId;
    if ((subId ?? '').isNotEmpty) {
      _status.value = PlanStatus.pending;
      _orderId.value = subId!;
    } else {
      _status.value = PlanStatus.none;
      _orderId.value = '';
      _paymentMethod.value = null;
    }
  }

  @override
  void onClose() {
    _plansSub?.cancel();
    _meSub?.cancel();
    super.onClose();
  }
}