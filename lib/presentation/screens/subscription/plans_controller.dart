import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/plans/plan.dart';
import '../../../utils/enums.dart';

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

  // UI expects this signature
  Future<void> setPending({
    required int index,
    required PaymentMethod method,
    required String order,
  }) async {
    if (isDisabled(index)) return;
    if (index < 0 || index >= plans.length) return;

    selectedIndex.value = index;
    _status.value = PlanStatus.pending;
    _paymentMethod.value = method;
    _orderId.value = order;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final p = plans[index];

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .doc(order);

    await ref.set({
      'status': 'pending',
      'provider': method.name,
      'orderId': order,
      'planId': p.id,
      'planName': p.name,
      'price': p.price,
      'currency': p.currency,
      'durationDays': p.durationDays,
      'startAt': FieldValue.serverTimestamp(),
      'endAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'activePlanId': p.id,
      'activeSubscriptionId': order,
      'isPremium': false,
      'premiumUntil': null,
      'premiumUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'isPremium': true,
      'premiumUntil': Timestamp.fromDate(endAt),
      'activePlanId': p.id,
      'activeSubscriptionId': _orderId.value,
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
        //.orderBy('createdAt', descending: true)
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
