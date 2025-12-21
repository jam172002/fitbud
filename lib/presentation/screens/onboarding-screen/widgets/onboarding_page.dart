import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });
  final String image, title, subtitle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Center(
            child: Image(
              width: XHelperFunctions.screenWidth() * 0.8,
              height: XHelperFunctions.screenHeight() * 0.6,
              image: AssetImage(image),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: XColors.primaryText,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
