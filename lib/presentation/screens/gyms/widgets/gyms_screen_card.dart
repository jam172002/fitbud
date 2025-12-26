import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../domain/models/gyms/gym.dart';

class SingleGymCard extends StatelessWidget {
  final String name;
  final String members;
  final String years;
  final String location;
  final ImageProvider image;
  final VoidCallback onTap;

  const SingleGymCard({
    super.key,
    required this.name,
    required this.members,
    required this.years,
    required this.location,
    required this.image,
    required this.onTap,
  });

  factory SingleGymCard.fromGym({
    required Gym gym,
    required VoidCallback onTap,
  }) {
    final logo = gym.logoUrl;
    final isNetwork = logo.startsWith('http');

    return SingleGymCard(
      name: gym.name.isNotEmpty ? gym.name : 'Unknown Gym',
      members: 'Est. ${gym.members} members',
      years: '${gym.yearsOfService} years in service',
      location: gym.address.isNotEmpty ? gym.address : (gym.city.isNotEmpty ? gym.city : 'No Location'),
      image: isNetwork
          ? NetworkImage(logo)
          : const AssetImage('assets/logos/gym-logo.png'),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: XColors.secondaryBG,
                backgroundImage: image,
                radius: 35,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: XColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.user, color: Colors.lightGreen, size: 11),
                            const SizedBox(width: 4),
                            Text(members, style: const TextStyle(color: XColors.bodyText, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar_days, color: Colors.amber, size: 11),
                            const SizedBox(width: 4),
                            Text(years, style: const TextStyle(color: XColors.bodyText, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(LucideIcons.map_pin, color: Colors.blueAccent, size: 11),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(color: XColors.bodyText, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
