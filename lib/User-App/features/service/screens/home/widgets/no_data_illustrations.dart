import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class NoDataIllustration extends StatelessWidget {
  final String imagePath;
  final String message;

  const NoDataIllustration({
    super.key,
    required this.imagePath,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 180),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: XColors.bodyText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
