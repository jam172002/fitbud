import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fitbud/utils/colors.dart';
import '../../../../../common/appbar/common_appbar.dart';
import '../../../../../common/widgets/gym_name_input_dialog.dart';
import '../../../../../common/widgets/simple_dialog.dart';

import '../../../../../domain/repos/repo_provider.dart';
import '../../../navigation/user_navigation.dart';
import '../../controllers/auth_controller.dart';

import 'ps_about_page.dart';
import 'ps_activities_page.dart';
import 'ps_gym_page.dart';
import 'ps_image_selection_page.dart';

class ProfileDataGatheringScreen extends StatefulWidget {
  const ProfileDataGatheringScreen({super.key});

  @override
  State<ProfileDataGatheringScreen> createState() =>
      _ProfileDataGatheringScreenState();
}

class _ProfileDataGatheringScreenState extends State<ProfileDataGatheringScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int totalPages = 4;

  // Controller (registered in main.dart)
  final AuthController authC = Get.find<AuthController>();

  // Page 0: Image
  Uint8List? _imageBytes;

  // Page 1: Activities (from Firebase)
  late final Stream<List<String>> _activities$;
  final Set<String> _selectedActivities = {};
  String? _favouriteActivity;

  // Page 2: Gyms (from Firebase)
  late final Stream<List<String>> _gyms$;
  bool? _hasGym;
  String? _selectedGym;
  String? _customGymName;

  // Page 3: About yourself
  final TextEditingController _aboutController = TextEditingController();
  final Repos repos = Get.find<Repos>();

  bool _submitting = false;



  @override
  void initState() {
    super.initState();

    // Prefill from existing profile if any (keeps UX consistent)
    final me = authC.me.value;
    if (me != null) {
      _selectedActivities.addAll(me.activities ?? const []);
      final fav = me.favouriteActivity;
      _favouriteActivity = (fav != null && fav.trim().isNotEmpty) ? fav : null;

      _hasGym = me.hasGym;
      final gName = me.gymName;
      _selectedGym = (gName != null && gName.trim().isNotEmpty) ? gName : null;

      _aboutController.text = (me.about ?? '');
      // Note: We do not prefill image picker with network URL. Image selection is local.
    }

    _activities$ = repos.activityRepo
        .watchActiveActivities()
        .map((list) => list.map((a) => a.name).toList());

    _gyms$ = repos.gymRepo
        .watchGyms()
        .map((list) => list.map((g) => g.name).toList());

  }

  @override
  void dispose() {
    _pageController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  // ---------------------
  // Validation
  // ---------------------
  bool _isPageValid(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return _imageBytes != null;

      case 1:
        return _selectedActivities.length >= 3 && _favouriteActivity != null;

      case 2:
        if (_hasGym == null) return false;

        if (_hasGym == true) {
          if (_selectedGym == null) return false;
          final sel = _selectedGym!.trim();
          if (sel.isEmpty) return false;
          if (sel == '-- select --') return false;

          if (sel == 'not found in list') {
            final custom = (_customGymName ?? '').trim();
            return custom.isNotEmpty;
          }
          return true;
        }
        return true;

      case 3:
        return _aboutController.text.trim().isNotEmpty;

      default:
        return false;
    }
  }

  Future<void> _showSimpleMessage(
      String message, {
        IconData icon = Icons.info,
        Color iconColor = XColors.primary,
      }) async {
    await Get.dialog(
      SimpleDialogWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        buttonText: 'Ok',
      ),
      barrierDismissible: false,
    );
  }

  // ---------------------
  // Image picker
  // ---------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    String? chosen;
    if (kIsWeb) {
      chosen = 'gallery';
    } else {
      chosen = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: XColors.secondaryBG,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: XColors.bodyText),
                  title: Text('Take a photo', style: TextStyle(color: XColors.bodyText)),
                  onTap: () => Navigator.of(ctx).pop('camera'),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: XColors.bodyText),
                  title: Text('Choose from gallery', style: TextStyle(color: XColors.bodyText)),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }

    if (chosen == null) return;

    try {
      final source = chosen == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (_) {
      await _showSimpleMessage(
        'Unable to pick image. Please try again.',
        icon: Icons.error,
        iconColor: XColors.danger,
      );
    }
  }

  void _removeSelectedImage() => setState(() => _imageBytes = null);

  Future<String?> _openGymInputDialog() async {
    final result = await Get.dialog<String?>(
      GymNameInputDialog(),
      barrierDismissible: false,
    );
    return result;
  }

  // ---------------------
  // Submit to Firebase
  // ---------------------
  Future<void> _submitProfileSetup() async {
    if (_submitting) return;

    // Validate all pages before submit
    for (int i = 0; i < totalPages; i++) {
      if (!_isPageValid(i)) {
        await _showSimpleMessage(
          'Please complete all steps before finishing.',
          icon: Icons.info,
          iconColor: XColors.primary,
        );
        return;
      }
    }

    if (_imageBytes == null) {
      await _showSimpleMessage('Please select a profile image.', icon: Icons.photo);
      return;
    }

    setState(() => _submitting = true);

    try {
      final gymNameToSave = (_selectedGym == 'not found in list')
          ? (_customGymName?.trim() ?? '')
          : (_selectedGym?.trim() ?? '');

      final res = await authC.completeProfileSetup(
        imageBytes: _imageBytes!,
        activities: _selectedActivities.toList(),
        favouriteActivity: _favouriteActivity!,
        hasGym: _hasGym ?? false,
        gymName: gymNameToSave,
        about: _aboutController.text.trim(),
      );

      if (!res.ok) {
        await _showSimpleMessage(
          res.message,
          icon: Icons.error,
          iconColor: XColors.danger,
        );
        return;
      }

      // success -> go to home
      Get.offAll(() => UserNavigation());
    } catch (e) {
      await _showSimpleMessage(
        'Failed to complete profile: $e',
        icon: Icons.error,
        iconColor: XColors.danger,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------------------
  // Navigation
  // ---------------------
  Future<void> _nextPage() async {
    if (!_isPageValid(_currentPage)) {
      switch (_currentPage) {
        case 0:
          await _showSimpleMessage(
            'Please select an image for your profile.',
            icon: Icons.photo,
          );
          return;

        case 1:
          if (_selectedActivities.length < 3) {
            await _showSimpleMessage(
              'Please select at least 3 activities you are interested in.',
              icon: Icons.checklist,
            );
            return;
          }
          if (_favouriteActivity == null) {
            await _showSimpleMessage(
              'Please select your favourite activity.',
              icon: Icons.star,
            );
            return;
          }
          return;

        case 2:
          if (_hasGym == null) {
            await _showSimpleMessage(
              'Please tell us whether you have joined a gym.',
              icon: Icons.fitness_center,
            );
            return;
          }
          if (_hasGym == true) {
            if (_selectedGym == null) {
              await _showSimpleMessage(
                'Please select your gym or add it via "not found in list".',
                icon: Icons.location_city,
              );
              return;
            }
            final sel = _selectedGym!.trim();
            if (sel.isEmpty || sel == '-- select --') {
              await _showSimpleMessage(
                'Please select your gym or add it via "not found in list".',
                icon: Icons.location_city,
              );
              return;
            }
            if (sel == 'not found in list' && (_customGymName ?? '').trim().isEmpty) {
              await _showSimpleMessage(
                'Please enter your gym name.',
                icon: Icons.location_city,
              );
              return;
            }
          }
          return;

        case 3:
          if (_aboutController.text.trim().isEmpty) {
            await _showSimpleMessage(
              'Please write something about yourself.',
              icon: Icons.edit,
            );
            return;
          }
          return;
      }
    }

    // Finish
    if (_currentPage >= totalPages - 1) {
      await _submitProfileSetup();
      return;
    }

    setState(() => _currentPage += 1);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _prevPage() {
    if (_currentPage <= 0) return;
    setState(() => _currentPage -= 1);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // ---------------------
  // UI
  // ---------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: XAppBar(title: 'Profile Setup', showBackIcon: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(totalPages, (index) {
                final isActive = index <= _currentPage;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? XColors.primary
                          : XColors.bodyText.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                ProfileSetupImageSelectionPage(
                  imageBytes: _imageBytes,
                  onPickImage: _pickImage,
                  onRemoveImage: _removeSelectedImage,
                ),

                StreamBuilder<List<String>>(
                  stream: _activities$,
                  builder: (context, snap) {
                    final all = snap.data ?? const <String>[];
                    return ProfileSetupActivitiesPage(
                      allActivities: all,
                      selectedActivities: _selectedActivities,
                      favouriteActivity: _favouriteActivity,
                      onActivitySelected: (act, remove) {
                        setState(() {
                          if (remove) {
                            _selectedActivities.remove(act);
                            if (_favouriteActivity == act) _favouriteActivity = null;
                          } else {
                            _selectedActivities.add(act);
                          }
                        });
                      },
                      onFavouriteSelected: (val) => setState(() => _favouriteActivity = val),
                    );
                  },
                ),

                StreamBuilder<List<String>>(
                  stream: _gyms$,
                  builder: (context, snap) {
                    final gymsFromDb = snap.data ?? const <String>[];

                    final gyms = <String>[
                      '-- select --',
                      ...gymsFromDb,
                      'not found in list',
                    ];

                    return ProfileSetupGymPage(
                      hasGym: _hasGym,
                      selectedGym: _selectedGym,
                      customGymName: _customGymName,
                      gyms: gyms,
                      onHasGymChanged: (val) {
                        setState(() {
                          _hasGym = val;
                          if (val == false) {
                            _selectedGym = null;
                            _customGymName = null;
                          }
                        });
                      },
                      onGymChanged: (val) async {
                        if (val == 'not found in list') {
                          final result = await _openGymInputDialog();
                          if (result != null && result.trim().isNotEmpty) {
                            setState(() {
                              _selectedGym = 'not found in list';
                              _customGymName = result.trim();
                            });
                          }
                        } else if (val == '-- select --') {
                          setState(() {
                            _selectedGym = '-- select --';
                            _customGymName = null;
                          });
                        } else {
                          setState(() {
                            _selectedGym = val;
                            _customGymName = null;
                          });
                        }
                      },
                    );
                  },
                ),

                ProfileSetupAboutPage(controller: _aboutController),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: XColors.secondaryBG,
                            side: BorderSide(color: XColors.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _submitting ? null : _prevPage,
                          child: Text('Back', style: TextStyle(color: XColors.bodyText)),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 12),

                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: XColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submitting ? null : _nextPage,
                        child: Text(
                          _submitting
                              ? "Saving..."
                              : (_currentPage == totalPages - 1 ? "Finish" : "Next"),
                          style: const TextStyle(
                            fontSize: 14,
                            color: XColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Low-emphasis skip button
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                    await authC.updateMeFields({'isProfileComplete': false});
                    Get.offAll(() => UserNavigation());
                  },
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 13,
                      color: XColors.bodyText.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
