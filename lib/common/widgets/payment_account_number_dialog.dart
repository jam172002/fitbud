import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentAccountDialog extends StatefulWidget {
  final String paymentName;
  final void Function(String accountNumber) onConfirm;

  const PaymentAccountDialog({
    super.key,
    required this.paymentName,
    required this.onConfirm,
  });

  @override
  State<PaymentAccountDialog> createState() => _PaymentAccountDialogState();
}

class _PaymentAccountDialogState extends State<PaymentAccountDialog> {
  final TextEditingController controller = TextEditingController();
  String? errorText;

  bool _isValidPakNumber(String input) {
    final regex = RegExp(r'^(?:\+92|0)3[0-9]{9}$');
    return regex.hasMatch(input);
  }

  void _confirm() {
    final value = controller.text.trim();

    if (!_isValidPakNumber(value)) {
      setState(() {
        errorText = 'Enter a valid Number';
      });
      return;
    }

    // Call the onConfirm callback
    widget.onConfirm(value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: XColors.secondaryBG,
      child: Stack(
        children: [
          /// Close Icon
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: XColors.danger.withValues(alpha: 0.5),
                  radius: 12,
                  child: Icon(
                    Icons.close,
                    size: 15,
                    color: XColors.bodyText.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),

          /// Main Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_android, color: XColors.primary, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Enter ${widget.paymentName} Account Number',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: XColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: XColors.primaryText,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: '03XXXXXXXXX',
                    hintStyle: TextStyle(
                      color: XColors.bodyText.withOpacity(0.5),
                    ),
                    errorText: errorText,
                    filled: true,
                    fillColor: XColors.primaryBG,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: XColors.borderColor, height: 1),
                GestureDetector(
                  onTap: _confirm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        color: XColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
