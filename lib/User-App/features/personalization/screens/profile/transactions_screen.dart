import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class TransactionsScreen extends StatelessWidget {
  TransactionsScreen({super.key});

  // ======= Scenario 1: No transactions =======
  final List<Map<String, dynamic>> noTransactions = const [];

  // ======= Scenario 2: With transactions =======
  final List<Map<String, dynamic>> transactions = [
    {
      'planName': 'Pro Fitness Plan',
      'planLimit': '30 Days',
      'price': 'Rs. 4,999',
      'dateTime': '12 Dec 2025 • 09:42 PM',
      'paymentMethod': PaymentMethod.jazzcash,
    },
    {
      'planName': 'Premium Plan',
      'planLimit': '90 Days',
      'price': 'Rs. 9,999',
      'dateTime': '01 Dec 2025 • 03:15 PM',
      'paymentMethod': PaymentMethod.easypaisa,
    },
    {
      'planName': 'Standard Plan',
      'planLimit': '30 Days',
      'price': 'Rs. 3,499',
      'dateTime': '20 Nov 2025 • 08:00 AM',
      'paymentMethod': PaymentMethod.card,
    },
  ];

  // Choose which data to display
  final bool showTransactions =
      true; // Set true to show transactions, false for empty

  @override
  Widget build(BuildContext context) {
    final dataToShow = showTransactions ? transactions : noTransactions;

    return Scaffold(
      appBar: const XAppBar(title: 'Transactions'),
      body: dataToShow.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/no-transactions.png",
                        width: constraints.maxWidth * 0.9,
                        height: constraints.maxWidth * 0.5,
                        fit: BoxFit.contain,
                      ),

                      Text(
                        "No Transactions Found",
                        style: TextStyle(
                          fontSize: 13,
                          color: XColors.bodyText.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: 70),
                    ],
                  ),
                );
              },
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dataToShow.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final txn = dataToShow[index];
                return _TransactionCard(
                  planName: txn['planName'],
                  planLimit: txn['planLimit'],
                  price: txn['price'],
                  dateTime: txn['dateTime'],
                  paymentMethod: txn['paymentMethod'],
                );
              },
            ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String planName;
  final String planLimit;
  final String price;
  final String dateTime;
  final PaymentMethod paymentMethod;

  const _TransactionCard({
    required this.planName,
    required this.planLimit,
    required this.price,
    required this.dateTime,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: XColors.secondaryBG,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan + Price Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Limit: $planLimit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: XColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Date + Payment Method Row
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                dateTime,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              _PaymentMethodBadge(method: paymentMethod),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  final PaymentMethod method;

  const _PaymentMethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    late String logo;
    late Color color;

    switch (method) {
      case PaymentMethod.jazzcash:
        logo = 'assets/logos/Jazzcash.png';
        color = Colors.white70;
        break;
      case PaymentMethod.easypaisa:
        logo = 'assets/logos/Easypaisa.png';
        color = Colors.tealAccent;
        break;
      case PaymentMethod.card:
        logo = 'assets/logos/card.png';
        color = Colors.blueAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(logo, fit: BoxFit.cover, height: 20),
    );
  }
}
