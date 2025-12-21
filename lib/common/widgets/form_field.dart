import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class XFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;

  const XFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    required Color cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = ValueNotifier(false);

    return ValueListenableBuilder(
      valueListenable: isVisible,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: XColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),

            TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              readOnly: readOnly,
              onTap: onTap,
              cursorColor: XColors.primary,

              obscureText: isPassword ? !value : false,
              style: const TextStyle(fontSize: 13, color: XColors.primaryText),
              decoration: InputDecoration(
                hintText: hint,

                hintStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w100,
                  color: XColors.bodyText,
                ),
                errorStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w100,
                  fontStyle: FontStyle.italic,
                  color: XColors.warning,
                ),
                filled: true,
                fillColor: XColors.secondaryBG,

                // Remove all default padding
                isDense: true,
                contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),

                // Prefix Icon
                prefixIcon: prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          prefixIcon,
                          size: 18,
                          color: XColors.bodyText,
                        ),
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),

                // Suffix Icon (Password Toggle)
                suffixIcon: isPassword
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GestureDetector(
                          onTap: () => isVisible.value = !value,
                          child: Icon(
                            value ? LucideIcons.eye : LucideIcons.eye_closed,
                            size: 18,
                            color: XColors.primary,
                          ),
                        ),
                      )
                    : suffix,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: XColors.borderColor, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: XColors.borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: XColors.borderColor, width: 1),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: XColors.warning,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: XColors.warning,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
