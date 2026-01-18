import 'package:flutter/material.dart';

class CategoryHomeIcon extends StatelessWidget {
  final String iconPath; // can be url OR asset
  final String title;
  final VoidCallback onTap;

  const CategoryHomeIcon({
    super.key,
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  bool get _hasPath => iconPath.trim().isNotEmpty;

  bool get _isNetwork {
    final p = iconPath.trim().toLowerCase();
    return p.startsWith('http://') || p.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 54,
            width: 54,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: _hasPath
                ? (_isNetwork
                ? Image.network(
              iconPath,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/icons/badminton.png',
                fit: BoxFit.contain,
              ),
            )
                : Image.asset(
              iconPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/icons/badminton.png',
                fit: BoxFit.contain,
              ),
            ))
                : Image.asset(
              'assets/icons/badminton.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11,
              color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
