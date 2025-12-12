import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class ProfileSetupAboutPage extends StatelessWidget {
  final TextEditingController controller;

  const ProfileSetupAboutPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us something about yourself',
            style: TextStyle(color: XColors.bodyText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 6,
            style: TextStyle(
              color: XColors.primaryText, // text color for dark theme
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'About yourself...',
              hintStyle: TextStyle(
                color: XColors.bodyText.withOpacity(0.6), // subtle hint
                fontSize: 14,
              ),
              filled: true,
              fillColor: XColors.secondaryBG, // dark background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: XColors.borderColor,
                ), // border color
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: XColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: XColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
