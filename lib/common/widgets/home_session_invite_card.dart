import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class HomeSessionInviteCard extends StatelessWidget {
  final String image;
  final String category;
  final String invitedBy;
  final String dateTime;
  final String location;
  final VoidCallback nameOnTap;

  const HomeSessionInviteCard({
    super.key,
    required this.image,
    required this.category,
    required this.invitedBy,
    required this.dateTime,
    required this.location,
    required this.nameOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    width: 200,
                    height: 100,
                    child: Image.asset(image, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 200,
                      height: 50,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          //? Session Type
                          Text(
                            category,
                            style: const TextStyle(
                              color: XColors.primaryText,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),

                          const Spacer(),
                          //? Accept button
                          GestureDetector(
                            onTap: () {},
                            child: Icon(
                              LucideIcons.circle_check,
                              color: XColors.primary,
                              size: 18,
                            ),
                          ),

                          const SizedBox(width: 16),
                          //? Reject button
                          GestureDetector(
                            onTap: () {},
                            child: Icon(
                              LucideIcons.circle_x,
                              color: XColors.danger,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invited by',
                  style: TextStyle(color: XColors.bodyText, fontSize: 10),
                ),
                GestureDetector(
                  onTap: nameOnTap,
                  child: Text(
                    invitedBy,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Date & Time',
                  style: TextStyle(color: XColors.bodyText, fontSize: 10),
                ),
                Text(
                  dateTime,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

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
    );
  }
}
