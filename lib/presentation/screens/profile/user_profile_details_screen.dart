import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fitbud/utils/colors.dart';
import '../../../common/appbar/common_appbar.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/repos/repo_provider.dart';
import '../authentication/controllers/auth_controller.dart';
import '../authentication/screens/profile_setup_screens/profile_data_gathering_screen.dart';

class UserProfileDetailsScreen extends StatefulWidget {
  const UserProfileDetailsScreen({super.key});

  @override
  State<UserProfileDetailsScreen> createState() => _UserProfileDetailsScreenState();
}

class _UserProfileDetailsScreenState extends State<UserProfileDetailsScreen> {
  final AuthController authC = Get.find<AuthController>();

  bool _saving = false;

  // local-only preview when user picks a new image
  File? _localProfileImage;

  // About inline editing (keep your current UX)
  bool isEditingAbout = false;
  late TextEditingController aboutController;

  // Activities & gyms lists from Firebase
  late final Stream<List<String>> _activities$;
  late final Stream<List<String>> _gyms$;
  final Repos repos = Get.find<Repos>();


  @override
  void initState() {
    super.initState();
    aboutController = TextEditingController();

    _activities$ = repos.activityRepo.watchActiveActivities()
        .map((list) => list.map((a) => a.name).toList());

    _gyms$ = repos.gymRepo.watchGyms()
        .map((list) => list.map((g) => g.name).toList());

  }

  @override
  void dispose() {
    aboutController.dispose();
    super.dispose();
  }

  // -------------------------
  // Firebase update helper
  // -------------------------
  Future<void> _updateMe(Map<String, dynamic> fields, {String successMsg = 'Updated'}) async {
    if (_saving) return;
    setState(() => _saving = true);

    final res = await authC.updateMeFields(fields);

    if (mounted) setState(() => _saving = false);

    if (!res.ok) {
      _error(res.message);
    } else {
      _success(successMsg);
    }
  }

  // -------------------------
  // IMAGE PICK
  // -------------------------
  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (image == null) return;

    final file = File(image.path);
    setState(() => _localProfileImage = file);

    try {
      setState(() => _saving = true);
      final url = await repos.authRepo.uploadMyProfileImage(file);
      final res = await authC.updateMeFields({'photoUrl': url});
      if (!res.ok) {
        _error(res.message);
      } else {
        _success("Profile image updated");
      }
    } catch (e) {
      _error("Failed to update image: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
      Get.back();
    }
  }

  void _showImagePicker() {
    Get.bottomSheet(
      _bottomSheet([
        _sheetTile("Camera", LucideIcons.camera, () => _pickImage(ImageSource.camera)),
        _sheetTile("Gallery", LucideIcons.image, () => _pickImage(ImageSource.gallery)),
      ]),
    );
  }

  // -------------------------
  // NAME
  // -------------------------
  void _editName(AppUser me) {
    final c = TextEditingController(text: me.displayName ?? '');
    Get.dialog(
      _dialog(
        title: "Edit Name",
        child: TextField(
          controller: c,
          style: const TextStyle(color: XColors.primaryText),
        ),
        onConfirm: () async {
          final val = c.text.trim();
          if (val.isEmpty) {
            _error("Name cannot be empty");
            return;
          }
          Get.back();
          await _updateMe({'displayName': val}, successMsg: "Name updated");
        },
      ),
    );
  }

  // -------------------------
  // FAVOURITE ACTIVITY
  // -------------------------
  void _editFavourite(AppUser me) {
    final userActivities = List<String>.from(me.activities ?? const []);
    if (userActivities.isEmpty) {
      _error("Please add activities first");
      return;
    }

    String selected = (me.favouriteActivity != null && me.favouriteActivity!.trim().isNotEmpty)
        ? me.favouriteActivity!
        : userActivities.first;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setLocal) => _dialog(
          title: "Favourite Activity",
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: userActivities.map((e) {
              final active = selected == e;
              return _chip(e, active, () => setLocal(() => selected = e));
            }).toList(),
          ),
          onConfirm: () async {
            Get.back();
            await _updateMe({'favouriteActivity': selected}, successMsg: "Favourite activity updated");
          },
        ),
      ),
    );
  }

  // -------------------------
  // ACTIVITIES (from Firebase list)
  // -------------------------
  void _editActivities(AppUser me) {
    final temp = List<String>.from(me.activities ?? const []);

    Get.dialog(
      StatefulBuilder(
        builder: (_, setLocal) => _dialog(
          title: "Your Activities",
          child: StreamBuilder<List<String>>(
            stream: _activities$,
            builder: (_, snap) {
              final all = snap.data ?? const <String>[];
              if (all.isEmpty) {
                return Text(
                  'No activities available.',
                  style: TextStyle(color: XColors.bodyText.withOpacity(.7)),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: all.map((e) {
                  final selected = temp.contains(e);
                  return _chip(e, selected, () {
                    selected ? temp.remove(e) : temp.add(e);
                    setLocal(() {});
                  });
                }).toList(),
              );
            },
          ),
          onConfirm: () async {
            if (temp.isEmpty) {
              _error("Select at least one activity");
              return;
            }

            final payload = <String, dynamic>{'activities': temp};

            // If favourite no longer exists, clear it
            final fav = me.favouriteActivity;
            if (fav != null && fav.trim().isNotEmpty && !temp.contains(fav)) {
              payload['favouriteActivity'] = '';
            }

            Get.back();
            await _updateMe(payload, successMsg: "Activities updated");
          },
        ),
      ),
    );
  }

  // -------------------------
  // GYM (from Firebase list)
  // -------------------------
  void _editGym(AppUser me) {
    bool tempGoes = me.hasGym == true;
    String? tempGym = me.gymName;
    String? customGym;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setLocal) => _dialog(
          title: "Gym",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                dense: true,
                value: tempGoes,
                activeColor: XColors.primary,
                title: const Text(
                  "Do you go to gym?",
                  style: TextStyle(color: XColors.bodyText),
                ),
                onChanged: (v) => setLocal(() => tempGoes = v),
              ),
              if (tempGoes)
                StreamBuilder<List<String>>(
                  stream: _gyms$,
                  builder: (_, snap) {
                    final gyms = snap.data ?? const <String>[];

                    return DropdownButtonFormField<String>(
                      value: gyms.contains(tempGym) ? tempGym : null,
                      dropdownColor: XColors.secondaryBG,
                      decoration: const InputDecoration(
                        labelText: "Select Gym",
                        isDense: true,
                      ),
                      items: [
                        ...gyms.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(color: XColors.bodyText),
                          ),
                        )),
                        const DropdownMenuItem(
                          value: "custom",
                          child: Text(
                            "Not found in list",
                            style: TextStyle(color: XColors.primary),
                          ),
                        ),
                      ],
                      onChanged: (v) async {
                        if (v == "custom") {
                          _customGym((val) {
                            customGym = val;
                            setLocal(() {});
                          });
                        } else {
                          tempGym = v;
                          customGym = null;
                          setLocal(() {});
                        }
                      },
                    );
                  },
                ),
              if (customGym != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Selected: $customGym",
                    style: const TextStyle(fontSize: 11, color: XColors.primary),
                  ),
                ),
            ],
          ),
          onConfirm: () async {
            final hasGym = tempGoes;
            final gymName = !hasGym ? '' : (customGym ?? (tempGym ?? '')).trim();

            if (hasGym && gymName.isEmpty) {
              _error("Please select or enter gym name");
              return;
            }

            Get.back();
            await _updateMe({'hasGym': hasGym, 'gymName': gymName}, successMsg: "Gym updated");
          },
        ),
      ),
    );
  }

  void _customGym(Function(String) onSave) {
    final c = TextEditingController();
    Get.dialog(
      _dialog(
        title: "Gym Address",
        child: TextField(
          controller: c,
          style: const TextStyle(color: XColors.primaryText),
        ),
        onConfirm: () {
          final val = c.text.trim();
          if (val.isEmpty) {
            _error("Address required");
            return;
          }
          onSave(val);
          Get.back();
        },
      ),
    );
  }

  // -------------------------
  // ABOUT (inline, same UX)
  // -------------------------
  Widget _aboutSection(AppUser me) {
    final about = (me.about ?? '').trim();

    if (!isEditingAbout) {
      // keep UI style the same
      return Text(
        about.isEmpty ? '' : about,
        style: TextStyle(
          fontSize: 12,
          color: XColors.bodyText.withOpacity(.6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: aboutController,
          maxLines: 4,
          autofocus: true,
          style: const TextStyle(
            color: XColors.primaryText,
            fontSize: 12,
          ),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final val = aboutController.text.trim();
                if (val.isEmpty) {
                  _error("About cannot be empty");
                  return;
                }
                setState(() => isEditingAbout = false);
                await _updateMe({'about': val}, successMsg: "About updated");
              },
              child: const Icon(
                LucideIcons.check,
                size: 16,
                color: XColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                aboutController.text = about;
                setState(() => isEditingAbout = false);
              },
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: XColors.bodyText.withOpacity(.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startEditAbout(AppUser me) {
    aboutController.text = (me.about ?? '');
    setState(() => isEditingAbout = true);
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: 'Profile'),
      body: Obx(() {
        final me = authC.me.value;

        // Loading
        if (authC.authUser.value != null && me == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Not logged in
        if (authC.authUser.value == null) {
          return Center(
            child: Text(
              'Please log in.',
              style: TextStyle(color: XColors.bodyText.withOpacity(.7)),
            ),
          );
        }

        // Incomplete profile: professional minimal state (no fake values)
        if (me == null || me.isProfileComplete != true) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Profile not completed yet.',
                    style: TextStyle(
                      color: XColors.bodyText.withOpacity(.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Get.to(() => const ProfileDataGatheringScreen()),
                    child: Text(
                      'Complete now',
                      style: TextStyle(color: XColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Completed profile -> keep your UI layout unchanged, but real data
        final name = me.displayName ?? '';
        final favouriteActivity = me.favouriteActivity ?? '';
        final userActivities = List<String>.from(me.activities ?? const []);
        final goesToGym = me.hasGym == true;
        final gymName = goesToGym ? (me.gymName ?? '') : 'Not going to gym';

        final imageProvider = _localProfileImage != null
            ? FileImage(_localProfileImage!)
            : (me.photoUrl != null && me.photoUrl!.isNotEmpty
            ? NetworkImage(me.photoUrl!)
            : const AssetImage("assets/images/buddy.jpg"))
        as ImageProvider;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: _saving ? null : _showImagePicker,
                child: CircleAvatar(
                  radius: 46,
                  backgroundImage: imageProvider,
                ),
              ),
              const SizedBox(height: 12),

              _card(
                icon: LucideIcons.user,
                title: "Name",
                value: name,
                onEdit: () => _editName(me),
              ),
              _card(
                icon: LucideIcons.heart,
                title: "Favourite Activity",
                value: favouriteActivity,
                onEdit: () => _editFavourite(me),
              ),
              _card(
                icon: LucideIcons.activity,
                title: "Activities",
                custom: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: userActivities.map((e) => _chip(e, true, null)).toList(),
                ),
                onEdit: () => _editActivities(me),
              ),
              _card(
                icon: LucideIcons.dumbbell,
                title: "Gym",
                value: gymName,
                onEdit: () => _editGym(me),
              ),
              _card(
                icon: LucideIcons.file_text,
                title: "About",
                custom: _aboutSection(me),
                onEdit: () => _startEditAbout(me),
              ),
            ],
          ),
        );
      }),
    );
  }

  // -------------------------
  // HELPERS (unchanged UI style)
  // -------------------------
  Widget _chip(String label, bool active, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? XColors.primary : XColors.secondaryBG,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? XColors.primary : XColors.primary.withOpacity(.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: XColors.bodyText),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    String? value,
    Widget? custom,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: XColors.secondaryBG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: XColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: XColors.primaryText,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  LucideIcons.pencil,
                  size: 14,
                  color: XColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          custom ??
              Text(
                value ?? '',
                style: const TextStyle(color: XColors.bodyText, fontSize: 13),
              ),
        ],
      ),
    );
  }

  Widget _dialog({
    required String title,
    required Widget child,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      backgroundColor: XColors.secondaryBG,
      title: Text(title, style: const TextStyle(color: XColors.primaryText)),
      content: child,
      actions: [
        TextButton(onPressed: Get.back, child: const Text("Cancel")),
        TextButton(onPressed: onConfirm, child: const Text("Save")),
      ],
    );
  }

  Widget _bottomSheet(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: XColors.secondaryBG,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _sheetTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: XColors.primary),
      title: Text(title, style: const TextStyle(color: XColors.bodyText)),
      onTap: onTap,
    );
  }

  void _success(String msg) {
    Get.snackbar(
      "Success",
      msg,
      backgroundColor: XColors.primary.withOpacity(.2),
      colorText: XColors.primaryText,
    );
  }

  void _error(String msg) {
    Get.snackbar(
      "Error",
      msg,
      backgroundColor: XColors.danger.withOpacity(.2),
      colorText: XColors.primaryText,
    );
  }
}
