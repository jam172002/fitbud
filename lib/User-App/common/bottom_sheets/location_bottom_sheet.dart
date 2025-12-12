import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

Future<String?> showLocationBottomSheet(BuildContext context) {
  // Track selected subtitle
  String selected = 'Model town B, Bahawalpur';

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: XColors.secondaryBG,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Choose Your Location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: XColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Saved address",
                    style: TextStyle(fontSize: 13, color: XColors.primary),
                  ),
                  const SizedBox(height: 12),

                  // Bahawalpur tile
                  _LocationTile(
                    title: "Bahawalpur",
                    subtitle: "Model town B, Bahawalpur",
                    isSelected: selected == "Model town B, Bahawalpur",
                    onTap: () =>
                        setState(() => selected = "Model town B, Bahawalpur"),
                  ),
                  const SizedBox(height: 8),

                  // Rajanpur tile
                  _LocationTile(
                    title: "Lahore",
                    subtitle: "DHA Phase II, Lahore",
                    isSelected: selected == "DHA Phase II, Lahore",
                    onTap: () =>
                        setState(() => selected = "DHA Phase II, Lahore"),
                  ),

                  const SizedBox(height: 20),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: XColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirm Selection",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _LocationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationTile({
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? XColors.primaryText.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Iconsax.location5, size: 22, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: XColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: XColors.bodyText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: const Icon(
                  Icons.check_circle,
                  color: XColors.primary,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
