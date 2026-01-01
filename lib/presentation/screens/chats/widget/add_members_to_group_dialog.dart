import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fitbud/utils/colors.dart';

/// Expected buddy map keys:
/// - 'userId' (required)
/// - 'name' (required)
/// - 'avatar' (optional, can be network url or asset path or empty)
class AddMembersDialog extends StatefulWidget {
  final List<Map<String, String>> allBuddies;

  /// Can be passed as list of maps (must include userId),
  /// but you can also pass empty and rely on disabling via userId checks.
  final List<Map<String, String>> existingMembers;

  /// Returns selected buddy maps (including userId).
  final ValueChanged<List<Map<String, String>>> onConfirm;

  const AddMembersDialog({
    super.key,
    required this.allBuddies,
    required this.existingMembers,
    required this.onConfirm,
  });

  @override
  State<AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<AddMembersDialog> {
  final Set<String> _selectedIds = <String>{};
  late final Set<String> _existingIds;

  @override
  void initState() {
    super.initState();
    _existingIds = widget.existingMembers
        .map((m) => (m['userId'] ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  ImageProvider? _avatarProvider(String? avatar) {
    final a = (avatar ?? '').trim();
    if (a.isEmpty) return null;
    if (a.startsWith('http://') || a.startsWith('https://')) {
      return NetworkImage(a);
    }
    return AssetImage(a);
  }

  @override
  Widget build(BuildContext context) {
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
                'Add Members',
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
                itemCount: widget.allBuddies.length,
                itemBuilder: (context, index) {
                  final buddy = widget.allBuddies[index];
                  final userId = (buddy['userId'] ?? '').trim();
                  final name = (buddy['name'] ?? 'User').trim();
                  final avatar = (buddy['avatar'] ?? '').trim();

                  final isExisting = userId.isNotEmpty && _existingIds.contains(userId);
                  final isSelected = userId.isNotEmpty && _selectedIds.contains(userId);
                  final showChecked = isExisting || isSelected;

                  final provider = _avatarProvider(avatar);

                  return GestureDetector(
                    onTap: () {
                      if (userId.isEmpty) return;
                      if (isExisting) return;

                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(userId);
                        } else {
                          _selectedIds.add(userId);
                        }
                      });
                    },
                    child: Opacity(
                      opacity: isExisting ? 0.55 : 1,
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
                                name.isEmpty ? 'User' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: XColors.primaryText,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              if (isExisting)
                                Text(
                                  'Already in',
                                  style: TextStyle(
                                    color: XColors.bodyText.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                          if (showChecked)
                            Positioned(
                              top: 0,
                              right: 12,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: isExisting ? Colors.blueGrey : Colors.green,
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                    final selected = widget.allBuddies.where((b) {
                      final id = (b['userId'] ?? '').trim();
                      return id.isNotEmpty && _selectedIds.contains(id);
                    }).toList();

                    widget.onConfirm(selected);
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}