import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/auth/app_user.dart';
import '../../domain/repos/repo_provider.dart';
import '../../presentation/screens/chats/chat_screen.dart';

class CreateGroupBottomSheet extends StatefulWidget {
  const CreateGroupBottomSheet({super.key});

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  final Repos repos = Get.find<Repos>();

  String? groupImage; // local preview only
  final ImagePicker _picker = ImagePicker();
  final TextEditingController groupNameController = TextEditingController();

  /// Selected buddies with required keys: userId, name, profilePic
  final List<Map<String, String>> selectedBuddies = [];

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  Future<void> pickGroupImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => groupImage = image.path);
    }
  }

  void removeGroupImage() => setState(() => groupImage = null);

  void removeBuddy(Map<String, String> buddy) {
    setState(() {
      selectedBuddies.removeWhere((b) => b['userId'] == buddy['userId']);
    });
  }

  Future<void> createGroup() async {
    final title = groupNameController.text.trim();

    if (title.isEmpty || selectedBuddies.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter group name and add at least one buddy.',
        backgroundColor: XColors.warning.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      final ids = selectedBuddies
          .map((e) => (e['userId'] ?? '').trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      // NOTE: photoUrl is not uploaded here, just create group first
      final groupId = await repos.groupRepo.createGroup(
        title: title,
        description: '',
        photoUrl: '',
        initialMemberUserIds: ids,
      );

      final conversationId = 'group_$groupId';

      Navigator.pop(context);

      // open group chat
      Get.to(() => ChatScreen(
        conversationId: conversationId,
        isGroup: true,
        groupName: title,
        // groupId is derived inside ChatScreen from conversationId
      ));

      Get.snackbar(
        'Success',
        'Group created successfully!',
        backgroundColor: XColors.primary.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create group: $e',
        backgroundColor: XColors.danger.withOpacity(0.25),
        colorText: XColors.primaryText,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> showAddBuddiesDialog() async {
    // Load real buddies from repo (AppUser list)
    List<AppUser> buddies = const [];
    try {
      buddies = await repos.buddyRepo.watchMyBuddiesUsers().first;
    } catch (_) {}

    // Convert to map list used by UI
    final allBuddies = buddies
        .map((u) => {
      'userId': u.id,
      'name': (u.displayName ?? '').trim().isNotEmpty
          ? (u.displayName ?? '').trim()
          : 'User',
      'profilePic': (u.photoUrl ?? '').trim(),
    })
        .toList();

    if (!mounted) return;

    // Temp selection by userId
    final Set<String> tempSelectedIds = selectedBuddies
        .map((e) => (e['userId'] ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: XColors.primaryBG,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SizedBox(
                height: 420,
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
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: allBuddies.length,
                        itemBuilder: (context, index) {
                          final buddy = allBuddies[index];
                          final id = buddy['userId'] ?? '';
                          final isSelected = tempSelectedIds.contains(id);

                          final pic = (buddy['profilePic'] ?? '').trim();
                          final hasPic = pic.isNotEmpty;

                          ImageProvider? provider;
                          if (hasPic) {
                            provider = pic.startsWith('http')
                                ? NetworkImage(pic)
                                : AssetImage(pic) as ImageProvider;
                          }

                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                if (isSelected) {
                                  tempSelectedIds.remove(id);
                                } else {
                                  tempSelectedIds.add(id);
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
                                      backgroundImage: provider,
                                      child: provider == null
                                          ? Icon(
                                        LucideIcons.user_round,
                                        color: XColors.primary.withOpacity(0.5),
                                        size: 24,
                                      )
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      buddy['name'] ?? 'User',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: XColors.primaryText, fontSize: 12),
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
                                      child: const Icon(Icons.check, color: Colors.white, size: 16),
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
                            final confirmed = allBuddies
                                .where((b) => tempSelectedIds.contains(b['userId'] ?? ''))
                                .toList();

                            setState(() {
                              selectedBuddies
                                ..clear()
                                ..addAll(confirmed);
                            });

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: XColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(color: Colors.white),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: XColors.primaryText),
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
                      backgroundImage: groupImage != null ? FileImage(File(groupImage!)) : null,
                      child: groupImage == null
                          ? Icon(LucideIcons.camera, color: XColors.primary, size: 28)
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
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      final pic = (buddy['profilePic'] ?? '').trim();

                      ImageProvider? provider;
                      if (pic.isNotEmpty) {
                        provider = pic.startsWith('http')
                            ? NetworkImage(pic)
                            : AssetImage(pic) as ImageProvider;
                      }

                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: XColors.secondaryBG,
                                  backgroundImage: provider,
                                  child: provider == null
                                      ? Icon(
                                    LucideIcons.user_round,
                                    color: XColors.primary.withOpacity(0.5),
                                    size: 20,
                                  )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    buddy['name'] ?? 'User',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: XColors.primaryText, fontSize: 10),
                                    textAlign: TextAlign.center,
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
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Add Buddies
              TextButton(
                onPressed: showAddBuddiesDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.user_plus, color: XColors.primary, size: 18),
                    const SizedBox(width: 4),
                    Text('Add Buddies', style: TextStyle(color: XColors.primary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Create Group
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Group', style: TextStyle(fontSize: 13, color: Colors.white)),
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
