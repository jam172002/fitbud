import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSelectorScreen extends StatefulWidget {
  const LocationSelectorScreen({super.key});

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  final TextEditingController searchController = TextEditingController();

  bool _loading = false;
  String? _currentLocation;

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

      final placemarks =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea;
        final country = place.country;

        if (city != null && country != null) {
          setState(() {
            _currentLocation = '$city, $country';
          });
        }
      }
    } catch (_) {
      // silently fail – user can pick manually
    } finally {
      setState(() => _loading = false);
    }
  }

  void _selectLocation(String location) {
    Get.back(result: location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _selectLocation(val.trim());
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Current Location
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_currentLocation != null)
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Use current location'),
              subtitle: Text(_currentLocation!),
              onTap: () => _selectLocation(_currentLocation!),
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
                  onTap: () => _selectLocation(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
