import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/gyms/gym.dart';
import '../../../domain/models/gyms/plan.dart';
import '../../../domain/models/gyms/subscription.dart';
import '../../../domain/models/gyms/payment_transaction.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class GymRepo extends RepoBase {
  final FirebaseAuth auth;
  GymRepo(super.db, this.auth);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  // ---- Gyms ----

  Stream<List<Gym>> watchGyms({String city = '', int limit = 50}) {
    var q = col(FirestorePaths.gyms)
        .where('status', isEqualTo: GymStatus.active.name);

    if (city.isNotEmpty) q = q.where('city', isEqualTo: city);

    // Do not orderBy until all docs guaranteed to have createdAt
    return q.limit(limit).snapshots().map((s) {
      final list = s.docs.map(Gym.fromDoc).toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      return list;
    });
  }


  Future<Gym> getGym(String gymId) async {
    final s = await doc('${FirestorePaths.gyms}/$gymId').get();
    if (!s.exists) throw NotFoundException('Gym not found');
    return Gym.fromDoc(s);
  }

  // ---- Plans ----

  Stream<List<Plan>> watchActivePlans() {
    return col(FirestorePaths.plans)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((q) => q.docs.map(Plan.fromDoc).toList());
  }

  // ---- Subscriptions ----

  Stream<List<Subscription>> watchMySubscriptions({int limit = 20}) {
    final uid = _uid();
    return col(FirestorePaths.subscriptions)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(Subscription.fromDoc).toList());
  }

  Stream<Subscription?> watchMyActiveSubscription() {
    final uid = _uid();
    return col(FirestorePaths.subscriptions)
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((q) => q.docs.isEmpty ? null : Subscription.fromDoc(q.docs.first));
  }

  Future<Subscription?> getMyActiveSubscriptionOnce() async {
    final uid = _uid();
    final q = await col(FirestorePaths.subscriptions)
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Subscription.fromDoc(q.docs.first);
  }

  // Payment transactions history (optional screen)
  Stream<List<PaymentTransaction>> watchMyTransactions({int limit = 50}) {
    final uid = _uid();
    return col(FirestorePaths.transactions)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(PaymentTransaction.fromDoc).toList());
  }
}
