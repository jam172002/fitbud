import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimpleDialogWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final String buttonText;
  final VoidCallback? onOk;

  const SimpleDialogWidget({
    super.key,
    required this.message,
    this.icon = Icons.check_circle,
    this.iconColor = Colors.blue,
    this.buttonText = "Ok",
    this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: XColors.secondaryBG,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                Icon(icon, color: iconColor, size: 48),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: XColors.bodyText,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 1,
            child: Divider(color: XColors.borderColor, height: 0.7),
          ),

          InkWell(
            onTap: () {
              Get.back();
              if (onOk != null) onOk!();
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                buttonText,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
