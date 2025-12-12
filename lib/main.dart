import 'package:fitbud/User-App/features/service/controllers/location_controller.dart';
import 'package:fitbud/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  Get.put(LocationController());
  runApp(const MainApp());
}
