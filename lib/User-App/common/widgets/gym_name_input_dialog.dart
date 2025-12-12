import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GymNameInputDialog extends StatefulWidget {
  const GymNameInputDialog({super.key});

  @override
  State<GymNameInputDialog> createState() => _GymNameInputDialogState();
}

class _GymNameInputDialogState extends State<GymNameInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      Navigator.of(context).pop(_controller.text.trim());
    } else {
      Get.snackbar(
        'Error',
        'Please enter gym name',
        backgroundColor: XColors.danger,
        colorText: XColors.primaryText,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: XColors.secondaryBG, // dark background
      title: Text(
        'Enter your gym name',
        style: TextStyle(color: XColors.primaryText, fontSize: 16),
      ),
      content: SizedBox(
        height: 60, // compact height
        child: TextField(
          controller: _controller,
          style: TextStyle(color: XColors.primaryText),
          decoration: InputDecoration(
            hintText: 'Gym name',
            hintStyle: TextStyle(
              color: XColors.bodyText.withOpacity(0.6),
              fontSize: 12,
            ),
            filled: true,
            fillColor: XColors.bodyText.withValues(
              alpha: 0.1,
            ), // slightly lighter bg inside input
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: XColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: XColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: XColors.bodyText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: XColors.primary,
            foregroundColor: XColors.primaryText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: _submit,
          child: const Text('Submit'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
