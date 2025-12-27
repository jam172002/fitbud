import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/product/product.dart';
import '../../../domain/models/sessions/session_invite.dart';
import '../../../domain/repos/sessions/session_repo.dart';

class HomeController extends GetxController {
  HomeController({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _sessionRepo = SessionRepo(db ?? FirebaseFirestore.instance, auth ?? FirebaseAuth.instance);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  // Repo
  final SessionRepo _sessionRepo;
  final Rxn<AppUser> me = Rxn<AppUser>();
  bool get hasPremium => me.value?.hasPremiumAccess == true;

  final RxList<Product> products = <Product>[].obs;
  final RxList<SessionInvite> invites = <SessionInvite>[].obs;

  final RxBool loadingMe = true.obs;
  final RxBool loadingProducts = true.obs;
  final RxBool loadingInvites = true.obs;

  final RxString errMe = ''.obs;
  final RxString errProducts = ''.obs;
  final RxString errInvites = ''.obs;

  StreamSubscription? _meSub;
  StreamSubscription? _prodSub;
  StreamSubscription? _invSub;

  @override
  void onInit() {
    super.onInit();
    _listenMe();
    _listenProducts();
    _listenInvites();
  }

  void _listenMe() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      loadingMe.value = false;
      errMe.value = 'User not signed in';
      return;
    }

    loadingMe.value = true;
    errMe.value = '';

    _meSub?.cancel();
    _meSub = _db.collection('users').doc(uid).snapshots().listen((snap) {
      if (!snap.exists) {
        me.value = null;
      } else {
        me.value = AppUser.fromDoc(snap);
      }
      loadingMe.value = false;
    }, onError: (e) {
      loadingMe.value = false;
      errMe.value = e.toString();
    });
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

    // Uses your existing SessionRepo logic (collectionGroup('invites'))
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
    _meSub?.cancel();
    _prodSub?.cancel();
    _invSub?.cancel();
    super.onClose();
  }
}
