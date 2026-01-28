import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../domain/models/auth/user_address.dart';

class LocationSelectorScreen extends StatefulWidget {
  const LocationSelectorScreen({super.key});

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  final TextEditingController searchController = TextEditingController();

  bool _loading = false;

  // Current location info
  String? _currentLocationLabel; // e.g. "Bahawalpur, Pakistan"
  double? _currentLat;
  double? _currentLng;

  // Optional richer placemark strings
  String? _currentLine1; // e.g. "Model Town B"
  String? _currentLine2; // e.g. "Street 5"

  final List<String> _popularCities = const [
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Bahawalpur',
    'Peshawar',
    'Quetta',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _loading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city = (place.locality ?? place.subAdministrativeArea ?? '').trim();
        final country = (place.country ?? '').trim();

        // Try to extract a decent "line1"
        final subLocality = (place.subLocality ?? '').trim();
        final street = (place.street ?? '').trim();
        final line1 = subLocality.isNotEmpty ? subLocality : street;

        setState(() {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
          _currentLine1 = line1.isNotEmpty ? line1 : null;
          _currentLine2 = null;

          if (city.isNotEmpty && country.isNotEmpty) {
            _currentLocationLabel = '$city, $country';
          } else if (city.isNotEmpty) {
            _currentLocationLabel = city;
          } else if (country.isNotEmpty) {
            _currentLocationLabel = country;
          }
        });
      }
    } catch (_) {
      // silently fail – user can pick manually
    } finally {
      setState(() => _loading = false);
    }
  }

  void _selectCityOnly(String city) {
    final a = UserAddress(
      id: 'temp',
      city: city.trim(),
      line1: city.trim(), // minimal fallback
      line2: null,
      lat: null,
      lng: null,
      isDefault: false,
      label: null,
    );
    Get.back(result: a);
  }

  void _selectCurrentLocation() {
    final label = (_currentLocationLabel ?? '').trim();
    if (label.isEmpty) return;

    // Use city part before comma as "city" if possible
    final parts = label.split(',');
    final city = parts.isNotEmpty ? parts.first.trim() : label;

    final a = UserAddress(
      id: 'temp',
      city: city.isNotEmpty ? city : null,
      line1: _currentLine1 ?? label,
      line2: _currentLine2,
      lat: _currentLat,
      lng: _currentLng,
      isDefault: false,
      label: null,
    );

    Get.back(result: a);
  }

  void _selectFromSearch(String input) {
    final v = input.trim();
    if (v.isEmpty) return;

    // If user types "Lahore, Pakistan" -> city = Lahore
    final parts = v.split(',');
    final city = parts.isNotEmpty ? parts.first.trim() : v;

    final a = UserAddress(
      id: 'temp',
      city: city.isNotEmpty ? city : v,
      line1: v,
      line2: null,
      lat: null,
      lng: null,
      isDefault: false,
      label: null,
    );

    Get.back(result: a);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Location'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search city',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (val) => _selectFromSearch(val),
              ),
            ),

            const SizedBox(height: 16),

            // Current Location
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_currentLocationLabel != null)
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Use current location'),
                subtitle: Text(_currentLocationLabel!),
                onTap: _selectCurrentLocation,
              ),

            const Divider(),

            // Popular Cities
            Expanded(
              child: ListView.builder(
                itemCount: _popularCities.length,
                itemBuilder: (context, index) {
                  final city = _popularCities[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text(city),
                    onTap: () => _selectCityOnly(city),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
