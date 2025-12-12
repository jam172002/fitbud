import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class BuddyRequestCard extends StatelessWidget {
  final String name;
  final String gender;
  final String age;
  final String interest;
  final String location;
  final String time;
  final String avatar;
  final String status; // pending / accepted / rejected
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCardTap;

  const BuddyRequestCard({
    super.key,
    required this.name,
    required this.gender,
    required this.age,
    required this.interest,
    required this.location,
    required this.time,
    required this.avatar,
    required this.status,
    required this.onAccept,
    required this.onReject,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    // Conditional avatar size
    final double avatarRadius = status == 'pending' ? 40 : 35;

    return GestureDetector(
      onTap: onCardTap,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
              radius: avatarRadius,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Text(
                        time,
                        style: TextStyle(
                          color: XColors.bodyText.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Gender, Age, Interest
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.venus,
                            color: Colors.lightGreen,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gender,
                            style: const TextStyle(
                              color: XColors.bodyText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar_days,
                            color: Colors.amber,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            age,
                            style: const TextStyle(
                              color: XColors.bodyText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.heart,
                            color: Colors.pink,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            interest,
                            style: const TextStyle(
                              color: XColors.bodyText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.map_pin,
                        color: Colors.blueAccent,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: XColors.bodyText,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Buttons only for pending
                  if (status == 'pending')
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onAccept,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: XColors.primary,
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onReject,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: XColors.danger,
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
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
    );
  }
}
