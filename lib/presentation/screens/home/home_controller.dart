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
        _sessionRepo = SessionRepo(db ?? FirebaseFirestore.instance, auth ?? FirebaseAuth.instance);

  final FirebaseFirestore _db;
  final SessionRepo _sessionRepo;

  // me is read from AuthController — no extra Firestore listener needed.
  AppUser? get me => Get.find<AuthController>().me.value;
  bool get hasPremium => me?.hasPremiumAccess == true;

  final RxList<Product> products = <Product>[].obs;
  final RxList<SessionInvite> invites = <SessionInvite>[].obs;

  final RxBool loadingProducts = true.obs;
  final RxBool loadingInvites = true.obs;

  final RxString errProducts = ''.obs;
  final RxString errInvites = ''.obs;

  StreamSubscription? _prodSub;
  StreamSubscription? _invSub;

  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool loadingActivities = false.obs;
  final RxString errActivities = ''.obs;

  Future<void> fetchActivities() async {
    loadingActivities.value = true;
    errActivities.value = '';
    try {
      final snap = await _db
          .collection('activities')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .limit(50)
          .get();

      activities.assignAll(
        snap.docs.map((d) => Activity.fromDoc(d)).toList(),
      );
    } catch (e) {
      errActivities.value = e.toString();
    } finally {
      loadingActivities.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _listenProducts();
    _listenInvites();
    fetchActivities();
  }

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
      products.value = snap.docs.map((d) => Product.fromDoc(d)).toList();
      loadingProducts.value = false;
    }, onError: (e) {
      loadingProducts.value = false;
      errProducts.value = e.toString();
    });
  }

  void _listenInvites() {
    loadingInvites.value = true;
    errInvites.value = '';

    _invSub?.cancel();
    _invSub = _sessionRepo.watchMySessionInvites().listen((list) {
      invites.value = list;
      loadingInvites.value = false;
    }, onError: (e) {
      loadingInvites.value = false;
      errInvites.value = e.toString();
    });
  }

  @override
  void onClose() {
    _prodSub?.cancel();
    _invSub?.cancel();
    super.onClose();
  }
}
