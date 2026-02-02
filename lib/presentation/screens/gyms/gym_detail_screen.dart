import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../scanning/qr_scan_screen.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../domain/models/gyms/gym.dart';
import '../chats/widget/full_screen_media.dart';

class GymDetailScreen extends StatelessWidget {
  final Gym gym;
  const GymDetailScreen({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    final logo = gym.logoUrl.isNotEmpty ? gym.logoUrl : '';
    final isNetwork = logo.startsWith('http');

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: ''),

      floatingActionButton: FloatingActionButton(
        backgroundColor: XColors.primary.withValues(alpha: 0.7),
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QRScanScreen()),
          );
        },
        child: const Icon(
          LucideIcons.scan,
          color: Colors.white,
          size: 22,
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: XColors.secondaryBG,
                      backgroundImage: isNetwork
                          ? NetworkImage(logo)
                          : const AssetImage('assets/logos/gym-logo.png') as ImageProvider,
                      radius: 35,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      gym.name.isNotEmpty ? gym.name : 'Unknown Gym',
                      style: const TextStyle(
                        color: XColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.map_pin, color: Colors.blue, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          gym.address.isNotEmpty ? gym.address : (gym.city.isNotEmpty ? gym.city : 'No location'),
                          style: const TextStyle(color: XColors.bodyText, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Members + Years + Rating
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconText(icon: LucideIcons.user, text: 'Est. ${gym.members} members', iconColor: Colors.lightGreen),
                    const SizedBox(width: 8),
                    _iconText(icon: LucideIcons.calendar_days, text: '${gym.yearsOfService} years of service', iconColor: Colors.amber),
                    const SizedBox(width: 8),
                    _iconText(icon: LucideIcons.star, text: gym.rating.toStringAsFixed(1), iconColor: Colors.amber),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Timings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconText(icon: LucideIcons.sun_dim, text: gym.dayHours.isNotEmpty ? gym.dayHours : '--', iconColor: Colors.amber),
                    const SizedBox(width: 8),
                    _iconText(icon: LucideIcons.moon, text: gym.nightHours.isNotEmpty ? gym.nightHours : '--', iconColor: Colors.amber),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Gallery
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('Gallery', style: TextStyle(color: XColors.bodyText, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: gym.images.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('No images available', style: TextStyle(color: Colors.white54, fontSize: 12)),
                )
                    : SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gym.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      final url = gym.images[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenMedia(
                                path: url,
                                isVideo: false,
                                isAsset: false,
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
                              image: NetworkImage(url),
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

              // Equipments
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('Equipments', style: TextStyle(color: XColors.bodyText, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: gym.equipments.isEmpty
                    ? const Text('No equipments added', style: TextStyle(color: Colors.white54, fontSize: 12))
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: gym.equipments.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: XColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: XColors.primary.withValues(alpha: 0.3),
                          width: 0.7,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(color: XColors.bodyText, fontSize: 11)),
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
        Text(text, style: const TextStyle(color: XColors.bodyText, fontSize: 11)),
      ],
    );
  }
}
