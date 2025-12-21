import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupBottomSheet extends StatefulWidget {
  const CreateGroupBottomSheet({super.key});

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  String? groupImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController groupNameController = TextEditingController();
  final List<Map<String, String>> selectedBuddies = [];

  final List<Map<String, String>> allBuddies = [
    {'name': 'Ali Haider', 'profilePic': 'assets/images/buddy.jpg'},
    {'name': 'Sara Khan', 'profilePic': ''},
    {'name': 'Haider Ali', 'profilePic': ''},
    {'name': 'Fatima', 'profilePic': 'assets/images/buddy.jpg'},
    {'name': 'John Doe', 'profilePic': ''},
  ];

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  void pickGroupImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        groupImage = image.path;
      });
    }
  }

  void removeGroupImage() {
    setState(() {
      groupImage = null;
    });
  }

  void removeBuddy(Map<String, String> buddy) {
    setState(() {
      selectedBuddies.remove(buddy);
    });
  }

  void createGroup() {
    if (groupNameController.text.isEmpty || selectedBuddies.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter group name and add at least one buddy.',
        backgroundColor: XColors.warning.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    Navigator.pop(context);
    Get.snackbar(
      'Success',
      'Group created successfully!',
      backgroundColor: XColors.primary.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void showAddBuddiesDialog() {
    List<Map<String, String>> tempSelected = List.from(selectedBuddies);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: XColors.primaryBG,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 400,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Select Buddies',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: XColors.primaryText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: allBuddies.length,
                        itemBuilder: (context, index) {
                          final buddy = allBuddies[index];
                          final isSelected = tempSelected.contains(buddy);
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                if (isSelected) {
                                  tempSelected.remove(buddy);
                                } else {
                                  tempSelected.add(buddy);
                                }
                              });
                            },
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: XColors.secondaryBG,
                                      backgroundImage:
                                          buddy['profilePic']!.isNotEmpty
                                          ? AssetImage(buddy['profilePic']!)
                                          : null,
                                      child: buddy['profilePic']!.isEmpty
                                          ? Icon(
                                              LucideIcons.user_round,
                                              color: XColors.primary
                                                  .withOpacity(0.5),
                                              size: 24,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      buddy['name']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: XColors.primaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 0,
                                    right: 20,
                                    child: CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Colors.green,
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedBuddies.clear();
                              selectedBuddies.addAll(tempSelected);
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: XColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(color: XColors.primaryText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // This ensures sheet moves above keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: XColors.primaryBG,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: XColors.secondaryBG,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Create New Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: XColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),

              // Group Image
              Stack(
                children: [
                  GestureDetector(
                    onTap: pickGroupImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: XColors.secondaryBG,
                      backgroundImage: groupImage != null
                          ? FileImage(File(groupImage!))
                          : null,
                      child: groupImage == null
                          ? Icon(
                              LucideIcons.camera,
                              color: XColors.primary,
                              size: 28,
                            )
                          : null,
                    ),
                  ),
                  if (groupImage != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: removeGroupImage,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Group Name
              TextField(
                controller: groupNameController,
                style: TextStyle(color: XColors.primaryText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: XColors.secondaryBG,
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(color: XColors.bodyText, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selected Buddies
              if (selectedBuddies.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedBuddies.length,
                    itemBuilder: (context, index) {
                      final buddy = selectedBuddies[index];
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: XColors.secondaryBG,
                                  backgroundImage:
                                      buddy['profilePic']!.isNotEmpty
                                      ? AssetImage(buddy['profilePic']!)
                                      : null,
                                  child: buddy['profilePic']!.isEmpty
                                      ? Icon(
                                          LucideIcons.user_round,
                                          color: XColors.primary.withOpacity(
                                            0.5,
                                          ),
                                          size: 20,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  buddy['name']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: XColors.primaryText,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => removeBuddy(buddy),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Add Buddies Button
              TextButton(
                onPressed: showAddBuddiesDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.user_plus,
                      color: XColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add Buddies',
                      style: TextStyle(color: XColors.primary, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Create Group Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Group',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// To show the sheet
void showCreateGroupSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateGroupBottomSheet(),
  );
}
