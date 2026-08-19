import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitbud/domain/models/auth/app_user.dart';
import 'package:fitbud/domain/repos/repo_provider.dart';
import 'package:fitbud/presentation/screens/chats/chat_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

void showCreateGroupSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CreateGroupSheet(),
  );
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final repos = Get.find<Repos>();

  final nameCtrl = TextEditingController();
  final Set<String> selectedIds = {};

  bool loading = true;
  bool creating = false;

  List<AppUser> buddies = [];

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadBuddies();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBuddies() async {
    try {
      final list = await repos.buddyRepo.watchMyBuddiesUsers().first;
      if (!mounted) return;
      setState(() {
        buddies = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      Get.snackbar(
        'Error',
        'Failed to load buddies: $e',
        backgroundColor: XColors.danger.withValues(alpha: .25),
        colorText: XColors.primaryText,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  String _nameOf(AppUser u) {
    final n = (u.displayName ?? '').trim();
    return n.isEmpty ? 'Buddy' : n;
  }

  ImageProvider _avatarOf(AppUser u) {
    final url = (u.photoUrl ?? '').trim();
    if (url.isNotEmpty) return NetworkImage(url);
    return const AssetImage('assets/images/buddy.jpg');
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final bytes = res.files.single.bytes;
    if (bytes == null) return;
    setState(() => _imageBytes = bytes);
  }

  void _removeImage() => setState(() => _imageBytes = null);

  Future<String> _uploadGroupPhoto(String groupId) async {
    if (_imageBytes == null) return '';
    final ref = FirebaseStorage.instance.ref().child('groups/$groupId/avatar.jpg');
    await ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<void> _createGroup() async {
    final title = nameCtrl.text.trim();
    if (title.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter group name.',
        backgroundColor: XColors.warning.withValues(alpha: .95),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (selectedIds.isEmpty) {
      Get.snackbar(
        'Error',
        'Select at least one buddy.',
        backgroundColor: XColors.warning.withValues(alpha: .95),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (creating) return;
    setState(() => creating = true);

    try {
      // 1) pre-generate groupId
      final groupId = repos.groupRepo.newGroupId();

      // 2) upload image (optional)
      final photoUrl = await _uploadGroupPhoto(groupId);

      // 3) create group + conversation + participants + user inbox index
      final gid = await repos.groupRepo.createGroup(
        groupId: groupId,
        title: title,
        photoUrl: photoUrl,
        initialMemberUserIds: selectedIds.toList(),
      );

      final convId = 'group_$gid';

      if (mounted) Navigator.pop(context);

      Get.to(() => ChatScreen(
        conversationId: convId,
        isGroup: true,
        groupName: title,
      ));

      Get.snackbar(
        'Success',
        'Group created.',
        backgroundColor: XColors.primary.withValues(alpha: .18),
        colorText: XColors.primaryText,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create group: $e',
        backgroundColor: XColors.danger.withValues(alpha: .25),
        colorText: XColors.primaryText,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) setState(() => creating = false);
    }
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
        child: loading
            ? const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: XColors.secondaryBG,
                    borderRadius: BorderRadius.circular(2),
                  ),
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

              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: XColors.secondaryBG,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : null,
                        child: _imageBytes == null
                            ? Icon(LucideIcons.camera, color: XColors.primary, size: 28)
                            : null,
                      ),
                    ),
                    if (_imageBytes != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
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

              const SizedBox(height: 14),

              Text(
                'Select Buddies',
                style: TextStyle(
                  color: XColors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: buddies.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (_, i) {
                  final u = buddies[i];
                  final selected = selectedIds.contains(u.id);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          selectedIds.remove(u.id);
                        } else {
                          selectedIds.add(u.id);
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
                              backgroundImage: _avatarOf(u),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _nameOf(u),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: XColors.primaryText, fontSize: 12),
                            ),
                          ],
                        ),
                        if (selected)
                          Positioned(
                            top: 0,
                            right: 18,
                            child: const CircleAvatar(
                              radius: 9,
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: creating ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    creating ? 'Creating...' : 'Create Group',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
