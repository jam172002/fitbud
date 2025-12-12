import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fitbud/utils/colors.dart';

class AddMembersDialog extends StatefulWidget {
  final List<Map<String, String>> allBuddies;
  final List<Map<String, String>> existingMembers;
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
  late List<Map<String, String>> tempSelected;

  @override
  void initState() {
    super.initState();
    tempSelected = [];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: XColors.primaryBG,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 400,
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
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.allBuddies.length,
                itemBuilder: (context, index) {
                  final buddy = widget.allBuddies[index];
                  final isSelected =
                      tempSelected.contains(buddy) ||
                      widget.existingMembers.contains(buddy);

                  return GestureDetector(
                    onTap: () {
                      if (!widget.existingMembers.contains(buddy)) {
                        setState(() {
                          if (tempSelected.contains(buddy)) {
                            tempSelected.remove(buddy);
                          } else {
                            tempSelected.add(buddy);
                          }
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: XColors.secondaryBG,
                              backgroundImage: buddy['avatar']!.isNotEmpty
                                  ? AssetImage(buddy['avatar']!)
                                  : null,
                              child: buddy['avatar']!.isEmpty
                                  ? Icon(
                                      LucideIcons.user_round,
                                      color: XColors.primary.withOpacity(0.5),
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
                          const Positioned(
                            top: 0,
                            right: 12,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
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
                    widget.onConfirm(tempSelected);
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
  }
}
