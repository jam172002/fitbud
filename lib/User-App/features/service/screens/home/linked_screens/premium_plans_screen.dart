import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PremiumPlanScreen extends StatelessWidget {
  const PremiumPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy list of plans
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
          'Extra Feature', // This one will be ignored (max 5)
        ],
      },
    ];

    return Scaffold(
      appBar: XAppBar(title: 'Premium Plans'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.separated(
            itemCount: plans.length,
            separatorBuilder: (_, __) => SizedBox(height: 16),
            itemBuilder: (context, index) {
              final plan = plans[index];

              return PlanCard(
                title: plan['title'] as String,
                description: plan['description'] as String,
                price: plan['price'] as int,
                duration: plan['duration'] as String,
                features: (plan['features'] as List<dynamic>)
                    .map((e) => e.toString())
                    .take(5)
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String description;
  final int price;
  final String duration;
  final List<String> features;

  const PlanCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: XColors.secondaryBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Plan info
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: XColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: XColors.bodyText.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'PKR $price',
                        style: TextStyle(
                          color: XColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'per user/$duration',
                        style: TextStyle(
                          color: XColors.primaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Right side: Features list
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: features
                        .map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.circle,
                                  color: Colors.blue,
                                  size: 12,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    feature,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: XColors.bodyText.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Purchase Button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: XColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Purchase Plan',
                  style: TextStyle(
                    color: XColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
