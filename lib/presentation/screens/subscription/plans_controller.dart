import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/plans/plan.dart';
import '../../../firebase_instances.dart';
import '../../../utils/enums.dart';

/// Thrown by every purchase path until a real payment processor is wired
/// up server-side. See the PAYMENT_SAFETY_NOTE comments on setActive() and
/// startDirectPayPwa() for why, and what "real" looks like.
class PaymentsUnavailableException implements Exception {
  @override
  String toString() =>
      "Subscriptions aren't available for purchase yet. Please check back soon.";
}

class PremiumPlanController extends GetxController {
  PremiumPlanController({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseInstances.db,
        _auth = auth ?? FirebaseInstances.auth;

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

  // DirectPay endpoint names/URLs kept here (rather than deleted) as the
  // reference for whoever implements the real functions - see the
  // PAYMENT_SAFETY_NOTE on startDirectPayPwa().
  // Cloud Functions to implement: "directPayCreatePaymentUrl" and
  // "directPayFinalizeFromRedirect" (region: asia-south1), redirecting to
  // https://fitbud-46f70.web.app/payments/success and .../failed.

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
  //
  // PAYMENT_SAFETY_NOTE: this used to grant premium immediately with no
  // payment processor involved at all - anyone could tap "Card" and get a
  // free subscription. That's fixed by refusing outright rather than
  // pretending to charge a card. It also could no longer write
  // isPremium/activeSubscriptionId or a `subscriptions` doc directly even
  // if it wanted to - firestore.rules now makes both server-write-only,
  // since a payment being "active" must come from a verified payment
  // event, never a client's say-so.
  //
  // To actually implement Card: process the charge through a real payment
  // processor from a Cloud Function, and have that function (Admin SDK)
  // write isPremium/the subscription doc after the charge is confirmed -
  // mirroring the DirectPay finalize pattern below.
  Future<void> setActive(int index) async {
    throw PaymentsUnavailableException();
  }

  // ---------------- DIRECTPAY FLOW ----------------

  // PAYMENT_SAFETY_NOTE: `directPayCreatePaymentUrl` and
  // `directPayFinalizeFromRedirect` are called here but do not exist in
  // functions/src/ - this flow has never actually worked. Rather than let
  // the client attempt a call that's guaranteed to fail (and, before this
  // fix, silently write "pending"/premium-adjacent state to Firestore
  // beforehand regardless), it now refuses upfront with a clear message.
  //
  // To actually implement this: after getting JazzCash/EasyPaisa's real
  // DirectPay merchant credentials and API contract from the project
  // owner, implement `directPayCreatePaymentUrl` and
  // `directPayFinalizeFromRedirect` as Cloud Functions (Admin SDK) that
  // hold those credentials server-side - never in the Flutter client - and
  // write the subscription/premium fields only after the provider
  // confirms payment.
  Future<void> startDirectPayPwa({
    required int index,
    required PaymentMethod chosenMethod, // jazzcash or easypaisa
    required String orderId,
  }) async {
    throw PaymentsUnavailableException();
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