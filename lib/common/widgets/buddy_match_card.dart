import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class BuddyMatchCard extends StatelessWidget {
  final String name;
  final String location;
  final String interest;
  final String sport;
  final String avatar;
  final bool isInvited;
  final VoidCallback onInvite;

  const BuddyMatchCard({
    super.key,
    required this.name,
    required this.location,
    required this.interest,
    required this.sport,
    required this.avatar,
    this.isInvited = false,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Get to the buddy detail profile screen.
      },
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            //? Avatar
            CircleAvatar(backgroundImage: AssetImage(avatar), radius: 40),
            const SizedBox(width: 8),
            //? Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //? name
                  Text(
                    name,
                    style: const TextStyle(
                      color: XColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  //? location
                  Row(
                    children: [
                      Icon(LucideIcons.map_pin, color: Colors.blue, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          color: XColors.bodyText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  //? Interests
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: XColors.primary.withValues(alpha: 0.8),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: XColors.bodyText,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.pink.shade700,
                        ),
                        child: Text(
                          sport,
                          style: const TextStyle(
                            color: XColors.bodyText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //? Invite Button
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: onInvite,
                child: Icon(
                  isInvited
                      ? LucideIcons.circle_check
                      : LucideIcons.circle_plus,
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
