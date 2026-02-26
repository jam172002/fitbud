import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class HomeProductBanner extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String imagePath;

  const HomeProductBanner({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.imagePath,
  });

  bool get _isNetworkImage =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: XHelperFunctions.screenWidth(),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [XColors.secondaryBG, XColors.secondaryBG.withOpacity(0.7)],
        ),
        image: DecorationImage(
          image: const AssetImage("assets/images/smoke4.png"),
          fit: BoxFit.cover,
          opacity: 0.3,
          colorFilter: ColorFilter.mode(
            XColors.primaryBG.withOpacity(0.15),
            BlendMode.multiply,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: XColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: XColors.bodyText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: XColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ✅ Constrained image so Row won’t overflow
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 110,
              height: 110,
              child: _isNetworkImage
                  ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) {
                  return const Center(child: Icon(Icons.broken_image));
                },
              )
                  : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return const Center(child: Icon(Icons.broken_image));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}