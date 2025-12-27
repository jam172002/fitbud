import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class PaymentTransaction implements FirestoreModel {
  @override
  final String id;

  final String userId;
  final String subscriptionId;
  final double amount;
  final String currency;
  final String provider;
  final String providerTxnId;
  final String status; // succeeded/failed/refunded
  final DateTime? createdAt;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    this.amount = 0,
    this.currency = 'PKR',
    this.provider = '',
    this.providerTxnId = '',
    this.status = 'succeeded',
    this.createdAt,
  });

  static PaymentTransaction fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PaymentTransaction(
      id: doc.id,
      userId: FirestoreModel.readString(d['userId']),
      subscriptionId: FirestoreModel.readString(d['subscriptionId']),
      amount: FirestoreModel.readDouble(d['amount']),
      currency: FirestoreModel.readString(d['currency'], fallback: 'PKR'),
      provider: FirestoreModel.readString(d['provider']),
      providerTxnId: FirestoreModel.readString(d['providerTxnId']),
      status: FirestoreModel.readString(d['status'], fallback: 'succeeded'),
      createdAt: FirestoreModel.readDate(d['createdAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'provider': provider,
      'providerTxnId': providerTxnId,
      'status': status,
      'createdAt': FirestoreModel.ts(createdAt),
    };
  }
}
