import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SpecificBuddyMatchCard extends StatelessWidget {
  const SpecificBuddyMatchCard({
    super.key,
    required this.avatar,
    required this.name,
    required this.location,
    required this.gender,
    required this.age,
    this.onInvite, // ✅ nullable
    this.isInvited = false,
    required this.onCardTap,
  });

  final String avatar;
  final String name;
  final String location;
  final String gender;
  final String age;

  final VoidCallback? onInvite; // ✅ nullable => hide invite button
  final VoidCallback onCardTap;
  final bool isInvited;

  bool get _isNetwork => avatar.trim().startsWith('http');

  @override
  Widget build(BuildContext context) {
    final showInvite = onInvite != null;

    return GestureDetector(
      onTap: onCardTap,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            // ✅ Avatar (network OR asset)
            CircleAvatar(
              radius: 35,
              backgroundImage:
              _isNetwork ? NetworkImage(avatar) : AssetImage(avatar) as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 8),

            // Details (unchanged)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: XColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),

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
                            "$age years old",
                            style: const TextStyle(
                              color: XColors.bodyText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  Row(
                    children: [
                      const Icon(LucideIcons.map_pin, color: Colors.blue, size: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: XColors.bodyText,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ Invite Button (hidden when already buddy)
            if (showInvite)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isInvited ? null : onInvite,
                  child: Icon(
                    isInvited ? LucideIcons.circle_check : LucideIcons.circle_plus,
                    color: isInvited ? XColors.primary : XColors.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}