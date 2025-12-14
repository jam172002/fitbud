import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PermissionScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String allowButtonText;
  final VoidCallback onAllow;

  final String denyButtonText;
  final VoidCallback? onDeny;
  final Widget? illustration;
  final bool showDenyButton;

  /// If true, this screen will request location permission itself.
  /// If false, it behaves exactly like before (calls onAllow immediately).
  final bool requestLocationPermission;

  const PermissionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.allowButtonText,
    required this.onAllow,
    this.denyButtonText = 'No, May be other time',
    this.onDeny,
    this.illustration,
    this.showDenyButton = false,
    this.requestLocationPermission = false,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _handleAllow() async {
    if (!widget.requestLocationPermission) {
      widget.onAllow();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // 1) Service enabled?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = "Location services are disabled. Please enable GPS and try again.";
        });
        return;
      }

      // 2) Permission status
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _error = "Location permission denied. Please allow access to continue.";
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error =
          "Location permission is permanently denied. Please enable it from App Settings.";
        });
        return;
      }

      // 3) Granted
      widget.onAllow();
    } catch (e) {
      setState(() {
        _error = "Failed to request permission: $e";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section (unchanged UI)
            Expanded(
              flex: 4,
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: widget.illustration ??
                      Container(
                        width: screenWidth * 0.3,
                        height: screenWidth * 0.3,
                        decoration: BoxDecoration(
                          color: XColors.primaryBG,
                          border: Border.all(
                            color: XColors.borderColor.withOpacity(0.2),
                            width: 3,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                ),
              ),
            ),

            // Bottom content
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.bold,
                        color: XColors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.008),

                    // Subtitle
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: screenHeight * 0.015,
                        color: XColors.bodyText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Error (new; minimal)
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          color: XColors.warning,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],

                    // Allow button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _handleAllow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: XColors.primary,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _busy ? "Please wait..." : widget.allowButtonText,
                          style: TextStyle(
                            fontSize: screenHeight * 0.018,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // If permanently denied, show "Open Settings" (new, only when needed)
                    if (_error != null &&
                        _error!.toLowerCase().contains('app settings'))
                      TextButton(
                        onPressed: _openSettings,
                        child: Text(
                          "Open App Settings",
                          style: TextStyle(
                            color: XColors.primary,
                            fontSize: screenHeight * 0.016,
                          ),
                        ),
                      ),

                    // Optional deny button (unchanged behavior)
                    if (widget.showDenyButton && widget.onDeny != null)
                      TextButton(
                        onPressed: widget.onDeny,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: XColors.bodyText,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                        child: Text(
                          widget.denyButtonText,
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: screenHeight * 0.016,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
