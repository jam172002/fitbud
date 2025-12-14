import 'package:fitbud/Onboarding/screens/onboarding-screen/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF000000),
        fontFamily: 'Outfit',
      ),
      home: XOnBoarding(),
    );
  }
}
