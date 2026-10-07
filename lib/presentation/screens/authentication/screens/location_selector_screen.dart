import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../domain/models/auth/user_address.dart';
import '../../../../utils/colors.dart';

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
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c),
        );

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: XColors.primaryBG,
        appBar: AppBar(
          backgroundColor: XColors.primaryBG,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: XColors.primaryText),
          title: const Text(
            'Select Location',
            style: TextStyle(
              color: XColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: XColors.primaryText),
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
                cursorColor: XColors.primary,
                style: const TextStyle(color: XColors.primaryText),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search city',
                  hintStyle: TextStyle(
                    color: XColors.bodyText.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(Icons.search, color: XColors.bodyText),
                  filled: true,
                  fillColor: XColors.secondaryBG,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: border(XColors.borderColor),
                  enabledBorder: border(XColors.borderColor),
                  focusedBorder: border(XColors.primary),
                ),
                onSubmitted: (val) => _selectFromSearch(val),
              ),
            ),

            const SizedBox(height: 16),

            // Current Location
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: XColors.primary),
              )
            else if (_currentLocationLabel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: XColors.secondaryBG,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: XColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading:
                        const Icon(Icons.my_location, color: XColors.primary),
                    title: const Text(
                      'Use current location',
                      style: TextStyle(
                        color: XColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _currentLocationLabel!,
                      style: TextStyle(
                        color: XColors.bodyText.withValues(alpha: 0.7),
                      ),
                    ),
                    onTap: _selectCurrentLocation,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            const Divider(color: XColors.borderColor, height: 1),

            // Popular Cities
            Expanded(
              child: ListView.separated(
                itemCount: _popularCities.length,
                separatorBuilder: (_, __) => Divider(
                  color: XColors.borderColor.withValues(alpha: 0.5),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final city = _popularCities[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_city,
                      color: XColors.bodyText,
                    ),
                    title: Text(
                      city,
                      style: const TextStyle(color: XColors.primaryText),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: XColors.bodyText.withValues(alpha: 0.5),
                    ),
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
