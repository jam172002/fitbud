import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: XAppBar(title: 'About'));
  }
}
