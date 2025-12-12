import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SingleGymCard extends StatelessWidget {
  final String name;
  final String members;
  final String years;
  final String location;
  final String image;
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
                backgroundImage: AssetImage(image),
                radius: 35,
              ),
              const SizedBox(width: 12),

              // TEXTS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
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

                    // Members + years
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.user,
                              color: Colors.lightGreen,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              members,
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
                              years,
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
