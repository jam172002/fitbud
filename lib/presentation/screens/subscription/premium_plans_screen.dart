
import 'package:fitbud/User-App/features/service/controllers/plans_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/plan_card.dart';

class PremiumPlanScreen extends StatelessWidget {
  const PremiumPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PremiumPlanController>();

    final plans = [
      {
        'title': 'Basic',
        'description': 'Enjoy app functionalities for 15 days.',
        'price': 2000,
        'duration': '15 days',
        'features': [
          'Unlimited Matches',
          'Basic Support',
          'Access to Free Content',
        ],
      },
      {
        'title': 'Standard',
        'description': 'Enjoy app functionalities for 1 month.',
        'price': 3500,
        'duration': '30 days',
        'features': [
          'Unlimited Matches',
          'Priority Support',
          'Access to Premium Content',
          'Ad-Free Experience',
        ],
      },
      {
        'title': 'Premium',
        'description': 'Enjoy app functionalities for 3 months.',
        'price': 9000,
        'duration': '90 days',
        'features': [
          'Unlimited Matches',
          '24/7 Support',
          'Access to Premium Content',
          'Ad-Free Experience',
          'Exclusive Offers',
        ],
      },
    ];

    return Scaffold(
      appBar: XAppBar(title: 'Premium Plans'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GetBuilder<PremiumPlanController>(
            builder: (_) {
              return ListView.separated(
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return PlanCard(
                    index: index,
                    title: plan['title'] as String,
                    description: plan['description'] as String,
                    price: plan['price'] as int,
                    duration: plan['duration'] as String,
                    features: List<String>.from(plan['features'] as List),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
