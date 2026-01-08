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

  bool isValidPath(String? path) {
    if (path == null) return false;
    if (path.trim().isEmpty) return false;
    return true;
  }

  bool _isNetworkUrl(String? path) {
    final p = (path ?? '').trim().toLowerCase();
    return p.startsWith('http://') || p.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final img = (imagePath ?? '').trim();

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
                child: isValidPath(img)
                    ? (_isNetworkUrl(img)
                    ? Image.network(
                  img,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultProfileBox(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 50,
                      width: 50,
                      child: Center(
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: XColors.primary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    );
                  },
                )
                    : Image.asset(
                  img,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultProfileBox(),
                ))
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
                      // Name (kept same behavior; ellipsis already here)
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tag
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
                  const SizedBox(height: 4),
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

                        // Location Text (kept; already Flexible + ellipsis)
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

            const SizedBox(width: 8),

            // ---------------- NOTIFICATION + MESSAGE ----------------
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onNotificationTap,
                  child: const Icon(
                    LucideIcons.bell,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (hasPremium) const SizedBox(width: 14),
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
