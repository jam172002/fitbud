import 'package:fitbud/presentation/screens/gyms/widgets/gyms_screen_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/search_with_filter.dart';
import 'gym_detail_screen.dart';

class GymsScreen extends StatelessWidget {
  const GymsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gymData = [
      {
        'name': 'The Gym 360',

        'members': 'Est. 180 members',
        'years': '05 Years in service',
        'location': 'Bahawalpur Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'Iron Fitness',

        'members': 'Est. 120 members',
        'years': '03 Years in service',
        'location': 'Multan Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'Strong House Gym',
        'members': 'Est. 240 members',
        'years': '07 Years in service',
        'location': 'Lahore Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'Muscle Factory',
        'members': 'Est. 300 members',
        'years': '06 Years in service',
        'location': 'Karachi Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'FitZone Gym',
        'members': 'Est. 160 members',
        'years': '04 Years in service',
        'location': 'Islamabad Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'Beast Mode Club',
        'members': 'Est. 210 members',
        'years': '05 Years in service',
        'location': 'Rawalpindi Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'BodyPro Fitness',
        'members': 'Est. 90 members',
        'years': '02 Years in service',
        'location': 'Faisalabad Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'Titan Strength Club',
        'members': 'Est. 140 members',
        'years': '03 Years in service',
        'location': 'Sialkot Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'Ultimate Fitness Hub',
        'members': 'Est. 200 members',
        'years': '06 Years in service',
        'location': 'Quetta Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'ProActive Gym',
        'members': 'Est. 150 members',
        'years': '04 Years in service',
        'location': 'Peshawar Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'PowerHouse Fitness',
        'members': 'Est. 230 members',
        'years': '08 Years in service',
        'location': 'Hyderabad Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
      {
        'name': 'Elite Performance Gym',
        'members': 'Est. 110 members',
        'years': '03 Years in service',
        'location': 'Sargodha Pakistan',
        'image': 'assets/logos/gym-logo.png',
      },
    ];

    return Scaffold(
      appBar: XAppBar(title: 'Our Gyms', showBackIcon: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              SearchWithFilter(horPadding: 0, showFilter: false),
              const SizedBox(height: 16),

              /// LIST OF GYMS
              Expanded(
                child: ListView.builder(
                  itemCount: gymData.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final g = gymData[index];
                    return SingleGymCard(
                      name: g['name']!,

                      members: g['members']!,
                      years: g['years']!,
                      location: g['location']!,
                      image: g['image']!,
                      onTap: () {
                        Get.to(() => GymDetailScreen());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
