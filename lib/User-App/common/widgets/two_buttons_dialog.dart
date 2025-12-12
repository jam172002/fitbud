import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class XButtonsConfirmationDialog extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  final String confirmText;
  final String cancelText;

  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  final bool showCancel;

  const XButtonsConfirmationDialog({
    super.key,
    required this.message,
    this.icon = Icons.check_circle,
    this.iconColor = Colors.blue,
    this.confirmText = "Ok",
    this.cancelText = "Cancel",
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: XColors.secondaryBG,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),

          /// ICON + MESSAGE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                Icon(icon, color: iconColor, size: 44),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: XColors.bodyText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          /// DIVIDER
          Divider(
            color: XColors.borderColor.withOpacity(0.4),
            height: 1,
            thickness: 1,
          ),

          /// BUTTONS AREA
          Row(
            children: [
              /// Cancel Button
              if (showCancel)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                      if (onCancel != null) onCancel!();
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          color: XColors.bodyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),

              /// Vertical Divider between buttons
              if (showCancel)
                Container(
                  width: 1,
                  height: 45,
                  color: XColors.borderColor.withOpacity(0.3),
                ),

              /// Confirm Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    Get.back();
                    if (onConfirm != null) onConfirm!();
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
