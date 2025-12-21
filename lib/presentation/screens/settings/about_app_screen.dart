
import 'package:flutter/material.dart';

import '../../../common/appbar/common_appbar.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: XAppBar(title: 'About'));
  }
}
