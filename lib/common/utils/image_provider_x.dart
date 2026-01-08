import 'package:flutter/material.dart';

class ImageProviderX {
  static ImageProvider provider(
      String? path, {
        String fallbackAsset = 'assets/images/profile.png',
      }) {
    final p = (path ?? '').trim();

    if (p.isEmpty || p == 'null') return AssetImage(fallbackAsset);

    // Network URL
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return NetworkImage(p);
    }

    // Treat everything else as asset path
    return AssetImage(p);
  }

  static bool isNetwork(String? path) {
    final p = (path ?? '').trim();
    return p.startsWith('http://') || p.startsWith('https://');
  }
}
