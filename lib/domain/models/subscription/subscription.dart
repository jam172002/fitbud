import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum SubscriptionStatus { active, past_due, cancelled, expired }

SubscriptionStatus subscriptionStatusFrom(String v) {
  return SubscriptionStatus.values.firstWhere((e) => e.name == v, orElse: () => SubscriptionStatus.expired);
}

class Subscription implements FirestoreModel {
  @override
  final String id;

  final String userId;
  final String planId;

  final SubscriptionStatus status;

  final String provider; // Stripe/Play/AppStore/manual
  final String providerSubId;

  final DateTime? startAt;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.status = SubscriptionStatus.active,
    this.provider = '',
    this.providerSubId = '',
    this.startAt,
    this.currentPeriodEnd,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  static Subscription fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Subscription(
      id: doc.id,
      userId: FirestoreModel.readString(d['userId']),
      planId: FirestoreModel.readString(d['planId']),
      status: subscriptionStatusFrom(FirestoreModel.readString(d['status'], fallback: 'expired')),
      provider: FirestoreModel.readString(d['provider']),
      providerSubId: FirestoreModel.readString(d['providerSubId']),
      startAt: FirestoreModel.readDate(d['startAt']),
      currentPeriodEnd: FirestoreModel.readDate(d['currentPeriodEnd']),
      cancelledAt: FirestoreModel.readDate(d['cancelledAt']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'status': status.name,
      'provider': provider,
      'providerSubId': providerSubId,
      'startAt': FirestoreModel.ts(startAt),
      'currentPeriodEnd': FirestoreModel.ts(currentPeriodEnd),
      'cancelledAt': FirestoreModel.ts(cancelledAt),
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
    };
  }
}
