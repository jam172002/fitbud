import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../common/appbar/common_appbar.dart';
import '../chats/widget/full_screen_media.dart';

class GymDetailScreen extends StatelessWidget {
  const GymDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> equipments = [
      'Dumbbells',
      'Barbell',
      'Pull-Up Bar',
      'Bench Press',
      'Leg Press',
      'Lat Pulldown',
      'Treadmill',
      'Cable Machine',
      'Kettlebells',
      'Smith Machine',
      'Rowing Machine',
      'Chest Fly Machine',
      'Deadlift Platform',
      'Dip Station',
      'Shoulder Press',
      'Squat Rack',
      'Preacher Curl',
      'Pec Deck',
      'Ab Roller',
      'Seated Row Machine',
    ];

    final List<String> gymImages = [
      "assets/images/gym1.jpg",
      "assets/images/gym2.jpg",
      "assets/images/gym3.jpg",
      "assets/images/gym4.jpg",
      "assets/images/gym5.jpg",
      "assets/images/gym6.jpg",
    ];

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: ''),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              //? Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: XColors.secondaryBG,
                      backgroundImage: const AssetImage(
                        'assets/logos/gym-logo.png',
                      ),
                      radius: 35,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Iron Fitness',
                      style: TextStyle(
                        color: XColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.map_pin, color: Colors.blue, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Model Town A, Bahawalpur',
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    // const SizedBox(height: 16),
                    // Divider(color: XColors.borderColor, height: 0.2),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              //? Members + Years + Rating
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconText(
                      icon: LucideIcons.user,
                      text: 'Est. 140 members',
                      iconColor: Colors.lightGreen,
                    ),
                    SizedBox(width: 8),
                    _iconText(
                      icon: LucideIcons.calendar_days,
                      text: '04 years of service',
                      iconColor: Colors.amber,
                    ),
                    SizedBox(width: 8),
                    _iconText(
                      icon: LucideIcons.star,
                      text: '4.5',
                      iconColor: Colors.amber,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              //? Gym Timings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconText(
                      icon: LucideIcons.sun_dim,
                      text: '06:00 AM to 09:30 AM',
                      iconColor: Colors.amber,
                    ),
                    SizedBox(width: 8),
                    _iconText(
                      icon: LucideIcons.moon,
                      text: '04:00 PM to 08:00 PM',
                      iconColor: Colors.amber,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              //? GALLERY (Moved ABOVE Equipments)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Gallery',
                  style: TextStyle(
                    color: XColors.bodyText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gymImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      final path = gymImages[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenMedia(
                                path: path,
                                isVideo: false,
                                isAsset: true,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          decoration: BoxDecoration(
                            color: XColors.secondaryBG,
                            borderRadius: BorderRadius.circular(14),
                            image: DecorationImage(
                              image: AssetImage(path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              //? EQUIPMENTS SECTION
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Equipments',
                  style: TextStyle(
                    color: XColors.bodyText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: equipments.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: XColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: XColors.primary.withValues(alpha: 0.3),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        e,
                        style: const TextStyle(
                          color: XColors.bodyText,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconText({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: XColors.bodyText, fontSize: 11),
        ),
      ],
    );
  }
}
