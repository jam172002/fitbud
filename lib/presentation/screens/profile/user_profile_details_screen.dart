import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitbud/utils/colors.dart';

import '../../../common/appbar/common_appbar.dart';

class UserProfileDetailsScreen extends StatefulWidget {
  const UserProfileDetailsScreen({super.key});

  @override
  State<UserProfileDetailsScreen> createState() =>
      _UserProfileDetailsScreenState();
}

class _UserProfileDetailsScreenState extends State<UserProfileDetailsScreen> {
  File? profileImage;

  String name = "Ali Haider";
  String favouriteActivity = "Badminton";
  List<String> userActivities = ["Badminton", "Gym", "Running"];

  bool goesToGym = true;
  String gymName = "360 GYM Commercial Area";

  String about =
      "Fitness enthusiast who loves staying active and meeting new workout buddies.";

  bool isEditingAbout = false;
  late TextEditingController aboutController;

  final List<String> allActivities = [
    "Cricket",
    "Football",
    "Badminton",
    "Gym",
    "Running",
    "Swimming",
    "Cycling",
    "Yoga",
    "Boxing",
  ];

  final List<String> affiliatedGyms = [
    "360 GYM Commercial Area",
    "Iron House Fitness",
    "Gold Gym DHA",
    "Fitness Hub",
  ];

  @override
  void initState() {
    super.initState();
    aboutController = TextEditingController(text: about);
  }

  @override
  void dispose() {
    aboutController.dispose();
    super.dispose();
  }

  /* ───────── IMAGE PICK ───────── */

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image != null) {
      setState(() => profileImage = File(image.path));
      Get.back();
      _success("Profile image updated");
    }
  }

  void _showImagePicker() {
    Get.bottomSheet(
      _bottomSheet([
        _sheetTile(
          "Camera",
          LucideIcons.camera,
          () => _pickImage(ImageSource.camera),
        ),
        _sheetTile(
          "Gallery",
          LucideIcons.image,
          () => _pickImage(ImageSource.gallery),
        ),
      ]),
    );
  }

  /* ───────── NAME ───────── */

  void _editName() {
    final c = TextEditingController(text: name);

    Get.dialog(
      _dialog(
        title: "Edit Name",
        child: TextField(
          controller: c,
          style: const TextStyle(color: XColors.primaryText),
        ),
        onConfirm: () {
          if (c.text.trim().isEmpty) {
            _error("Name cannot be empty");
            return;
          }
          setState(() => name = c.text.trim());
          Get.back();
          _success("Name updated");
        },
      ),
    );
  }

  /* ───────── FAVOURITE ACTIVITY ───────── */

  void _editFavourite() {
    String selected = favouriteActivity;

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
          onConfirm: () {
            setState(() => favouriteActivity = selected);
            Get.back();
            _success("Favourite activity updated");
          },
        ),
      ),
    );
  }

  /* ───────── ACTIVITIES ───────── */

  void _editActivities() {
    final temp = List<String>.from(userActivities);

    Get.dialog(
      StatefulBuilder(
        builder: (_, setLocal) => _dialog(
          title: "Your Activities",
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allActivities.map((e) {
              final selected = temp.contains(e);
              return _chip(e, selected, () {
                selected ? temp.remove(e) : temp.add(e);
                setLocal(() {});
              });
            }).toList(),
          ),
          onConfirm: () {
            if (temp.isEmpty) {
              _error("Select at least one activity");
              return;
            }
            setState(() => userActivities = temp);
            Get.back();
            _success("Activities updated");
          },
        ),
      ),
    );
  }

  /* ───────── GYM ───────── */

  void _editGym() {
    bool tempGoes = goesToGym;
    String? tempGym = gymName;
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
                DropdownButtonFormField<String>(
                  value: affiliatedGyms.contains(tempGym) ? tempGym : null,
                  dropdownColor: XColors.secondaryBG,
                  decoration: const InputDecoration(
                    labelText: "Select Gym",
                    isDense: true,
                  ),
                  items: [
                    ...affiliatedGyms.map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: const TextStyle(color: XColors.bodyText),
                        ),
                      ),
                    ),
                    const DropdownMenuItem(
                      value: "custom",
                      child: Text(
                        "Not found in list",
                        style: TextStyle(color: XColors.primary),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == "custom") {
                      _customGym((val) {
                        customGym = val;
                        setLocal(() {});
                      });
                    } else {
                      tempGym = v!;
                      customGym = null;
                      setLocal(() {});
                    }
                  },
                ),
              if (customGym != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Selected: $customGym",
                    style: const TextStyle(
                      fontSize: 11,
                      color: XColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          onConfirm: () {
            setState(() {
              goesToGym = tempGoes;
              gymName = !tempGoes
                  ? "Not going to gym"
                  : (customGym ?? tempGym!);
            });
            Get.back();
            _success("Gym updated");
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
          if (c.text.trim().isEmpty) {
            _error("Address required");
            return;
          }
          onSave(c.text.trim());
          Get.back();
        },
      ),
    );
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: 'Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImagePicker,
              child: CircleAvatar(
                radius: 46,
                backgroundImage: profileImage != null
                    ? FileImage(profileImage!)
                    : const AssetImage("assets/images/buddy.jpg")
                          as ImageProvider,
              ),
            ),
            const SizedBox(height: 12),

            _card(
              icon: LucideIcons.user,
              title: "Name",
              value: name,
              onEdit: _editName,
            ),

            _card(
              icon: LucideIcons.heart,
              title: "Favourite Activity",
              value: favouriteActivity,
              onEdit: _editFavourite,
            ),

            _card(
              icon: LucideIcons.activity,
              title: "Activities",
              custom: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: userActivities
                    .map((e) => _chip(e, true, null))
                    .toList(),
              ),
              onEdit: _editActivities,
            ),

            _card(
              icon: LucideIcons.dumbbell,
              title: "Gym",
              value: gymName,
              onEdit: _editGym,
            ),

            /// INLINE ABOUT EDIT
            _card(
              icon: LucideIcons.file_text,
              title: "About",
              custom: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isEditingAbout)
                    Text(
                      about,
                      style: TextStyle(
                        fontSize: 12,
                        color: XColors.bodyText.withOpacity(.6),
                      ),
                    )
                  else
                    TextField(
                      controller: aboutController,
                      maxLines: 4,
                      autofocus: true,
                      style: const TextStyle(
                        color: XColors.primaryText,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  if (isEditingAbout) const SizedBox(height: 8),
                  if (isEditingAbout)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (aboutController.text.trim().isEmpty) {
                              _error("About cannot be empty");
                              return;
                            }
                            setState(() {
                              about = aboutController.text.trim();
                              isEditingAbout = false;
                            });
                            _success("About updated");
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
              ),
              onEdit: () => setState(() => isEditingAbout = true),
            ),
          ],
        ),
      ),
    );
  }

  /* ───────── HELPERS ───────── */

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
                value!,
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
  }) => AlertDialog(
    backgroundColor: XColors.secondaryBG,
    title: Text(title, style: const TextStyle(color: XColors.primaryText)),
    content: child,
    actions: [
      TextButton(onPressed: Get.back, child: const Text("Cancel")),
      TextButton(onPressed: onConfirm, child: const Text("Save")),
    ],
  );

  Widget _bottomSheet(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: XColors.secondaryBG,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );

  Widget _sheetTile(String title, IconData icon, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: XColors.primary),
        title: Text(title, style: const TextStyle(color: XColors.bodyText)),
        onTap: onTap,
      );

  void _success(String msg) => Get.snackbar(
    "Success",
    msg,
    backgroundColor: XColors.primary.withOpacity(.2),
    colorText: XColors.primaryText,
  );

  void _error(String msg) => Get.snackbar(
    "Error",
    msg,
    backgroundColor: XColors.danger.withOpacity(.2),
    colorText: XColors.primaryText,
  );
}
