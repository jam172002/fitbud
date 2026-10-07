import '../../../domain/models/gyms/gym.dart';
import '../../models/plans/plan.dart';
import '../../models/subscription/subscription.dart';
import '../../models/subscription/payment_transaction.dart';
import '../repo_base.dart';
import '../repo_exceptions.dart';

class GymRepo extends RepoBase {
  GymRepo(super.db);

  // ---- Gyms ----

  Stream<List<Gym>> watchGyms({String city = '', int limit = 50}) {
    return streamDocs(
      'gyms',
      eqColumn: 'status',
      eqValue: GymStatus.active.name,
      limit: limit,
      where: city.isEmpty ? null : (r) => r['city'] == city,
    ).map((l) {
      final list = l.map(Gym.fromDoc).toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      return list;
    });
  }

  Future<Gym> getGym(String gymId) async {
    final row = await db.from('gyms').select().eq('id', gymId).maybeSingle();
    if (row == null) throw NotFoundException('Gym not found');
    return Gym.fromDoc(docOf(row));
  }

  // ---- Plans ----

  Stream<List<Plan>> watchActivePlans() {
    return streamDocs('plans', eqColumn: 'is_active', eqValue: true, orderBy: 'created_at', ascending: true)
        .map((l) => l.map(Plan.fromDoc).toList());
  }

  // ---- Subscriptions ----

  Stream<List<Subscription>> watchMySubscriptions({int limit = 20}) {
    final uid = requireUid();
    return streamDocs('subscriptions',
            eqColumn: 'user_id', eqValue: uid, orderBy: 'created_at', limit: limit)
        .map((l) => l.map(Subscription.fromDoc).toList());
  }

  Stream<Subscription?> watchMyActiveSubscription() {
    final uid = requireUid();
    return streamDocs(
      'subscriptions',
      eqColumn: 'user_id',
      eqValue: uid,
      orderBy: 'created_at',
      limit: 20,
      where: (r) => r['status'] == SubscriptionStatus.active.name,
    ).map((l) => l.isEmpty ? null : Subscription.fromDoc(l.first));
  }

  Future<Subscription?> getMyActiveSubscriptionOnce() async {
    final uid = requireUid();
    final rows = await db
        .from('subscriptions')
        .select()
        .eq('user_id', uid)
        .eq('status', SubscriptionStatus.active.name)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return Subscription.fromDoc(docOf(rows.first));
  }

  // Payment transactions history (optional screen)
  Stream<List<PaymentTransaction>> watchMyTransactions({int limit = 50}) {
    final uid = requireUid();
    return streamDocs('transactions',
            eqColumn: 'user_id', eqValue: uid, orderBy: 'created_at', limit: limit)
        .map((l) => l.map(PaymentTransaction.fromDoc).toList());
  }
}
