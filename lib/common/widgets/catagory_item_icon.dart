import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class CategoryHomeIcon extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;

  const CategoryHomeIcon({
    super.key,
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          //? icon
          Container(
            height: 60,
            width: 60,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: XColors.primaryText.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                XColors.primary.withOpacity(0.95),
                BlendMode.srcATop,
              ),
              child: Image.asset(iconPath),
            ),
          ),

          const SizedBox(height: 8),

          //? Text
          Text(
            title,
            style: const TextStyle(color: XColors.bodyText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
