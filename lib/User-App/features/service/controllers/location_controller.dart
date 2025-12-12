import 'package:get/get.dart';

class LocationController extends GetxController {
  // Observable variable
  RxString currentLocation = "Model town, Bahawalpur".obs;

  // Function to update location
  void updateLocation(String newLocation) {
    currentLocation.value = newLocation;
  }
}
