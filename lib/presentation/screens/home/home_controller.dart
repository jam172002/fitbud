import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../domain/models/activities/activity.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/product/product.dart';
import '../../../domain/models/sessions/session_invite.dart';
import '../../../domain/repos/sessions/session_repo.dart';
import '../authentication/controllers/auth_controller.dart';

class HomeController extends GetxController {
  HomeController({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _sessionRepo = SessionRepo(
          db ?? FirebaseFirestore.instance,
          auth ?? FirebaseAuth.instance,
        );

  final FirebaseFirestore _db;
  final SessionRepo _sessionRepo;

  // cache auth controller (avoid repeated Get.find calls)
  final AuthController authC = Get.find<AuthController>();

  AppUser? get me => authC.me.value;
  bool get hasPremium => me?.hasPremiumAccess == true;

  // ---------------- Products ----------------
  final RxList<Product> products = <Product>[].obs;
  final RxBool loadingProducts = true.obs;
  final RxString errProducts = ''.obs;
  StreamSubscription? _prodSub;

  // ---------------- Invites ----------------
  final RxList<SessionInvite> invites = <SessionInvite>[].obs;
  final RxBool loadingInvites = true.obs;
  final RxString errInvites = ''.obs;
  StreamSubscription? _invSub;

  // ---------------- Activities (Categories) ----------------
  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool loadingActivities = false.obs;
  final RxString errActivities = ''.obs;

  DateTime? _activitiesLoadedAt;
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();

    _listenProducts();

    // Invites should follow auth state
    _authWorker = ever<User?>(authC.authUser, (u) {
      if (u == null) {
        _stopInvites();
        invites.clear();
        loadingInvites.value = false;
      } else {
        _listenInvites();
      }
    });

    // run once
    if (authC.authUser.value != null) {
      _listenInvites();
    } else {
      loadingInvites.value = false;
    }

    fetchActivities();
  }

  // ---------------- Activities ----------------
  Future<void> fetchActivities({bool force = false}) async {
    if (!force && activities.isNotEmpty && _activitiesLoadedAt != null) {
      final age = DateTime.now().difference(_activitiesLoadedAt!);
      if (age.inMinutes < 30) return;
    }

    loadingActivities.value = true;
    errActivities.value = '';
    try {
      final snap = await _db
          .collection('activities')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));

      activities.assignAll(
        snap.docs.map((d) => Activity.fromDoc(d)).toList(),
      );
      _activitiesLoadedAt = DateTime.now();
    } catch (e) {
      errActivities.value = e.toString();
    } finally {
      loadingActivities.value = false;
    }
  }

  // ---------------- Products ----------------
  void _listenProducts() {
    loadingProducts.value = true;
    errProducts.value = '';

    _prodSub?.cancel();
    _prodSub = _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
      products.assignAll(snap.docs.map((d) => Product.fromDoc(d)));
      loadingProducts.value = false;
    }, onError: (e) {
      loadingProducts.value = false;
      errProducts.value = e.toString();
    });
  }

  // ---------------- Invites ----------------
  void _listenInvites() {
    loadingInvites.value = true;
    errInvites.value = '';

    _invSub?.cancel();
    _invSub = _sessionRepo.watchMySessionInvites().listen((list) {
      invites.assignAll(list);
      loadingInvites.value = false;
    }, onError: (e) {
      loadingInvites.value = false;
      errInvites.value = e.toString();
    });
  }

  void _stopInvites() {
    _invSub?.cancel();
    _invSub = null;
  }

  @override
  void onClose() {
    _prodSub?.cancel();
    _stopInvites();
    _authWorker?.dispose();
    super.onClose();
  }
}