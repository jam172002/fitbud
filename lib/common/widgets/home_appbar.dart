import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class CustomHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String location;
  final String country;
  final String? imagePath;
  final bool hasPremium;

  final VoidCallback? onNotificationTap;
  final VoidCallback? onScanTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onProfileTap;

  const CustomHomeAppBar({
    super.key,
    required this.name,
    required this.location,
    required this.country,
    this.imagePath,
    this.onNotificationTap,
    this.onScanTap,
    this.onLocationTap,
    this.onProfileTap,
    required this.hasPremium,
  });

  @override
  Size get preferredSize => const Size.fromHeight(95);

  bool isValidAsset(String? path) {
    if (path == null) return false;
    if (path.trim().isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // ---------------- PROFILE IMAGE / FALLBACK ----------------
            GestureDetector(
              onTap: onProfileTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isValidAsset(imagePath)
                    ? Image.asset(
                        imagePath!,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      )
                    : _defaultProfileBox(),
              ),
            ),

            const SizedBox(width: 12),

            // ---------------- NAME + LOCATION ----------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      //? Name
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      //? Tag
                      if (hasPremium)
                        Text(
                          'Pro',
                          style: TextStyle(
                            color: XColors.primary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: onLocationTap,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.map_pin,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 4),

                        // Location Text
                        Flexible(
                          child: Text(
                            "$location, $country",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),

                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // ---------------- NOTIFICATION + MESSAGE ----------------
            Row(
              children: [
                GestureDetector(
                  onTap: onNotificationTap,
                  child: const Icon(
                    LucideIcons.bell,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (hasPremium) SizedBox(width: 14),
                if (hasPremium)
                  GestureDetector(
                    onTap: onScanTap,
                    child: const Icon(
                      LucideIcons.scan,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- DEFAULT PROFILE BOX ----------------
  Widget _defaultProfileBox() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: XColors.secondaryBG.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.user, color: XColors.bodyText, size: 20),
    );
  }
}
