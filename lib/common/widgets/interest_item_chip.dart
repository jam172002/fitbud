import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class InterestItem extends StatelessWidget {
  final String title;

  const InterestItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: XColors.primary.withValues(alpha: 0.6),
      ),
      child: Text(
        title,
        style: const TextStyle(color: XColors.bodyText, fontSize: 11),
      ),
    );
  }
}
