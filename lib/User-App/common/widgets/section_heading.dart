import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class XHeading extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onActionTap;
  final bool showActionButton;
  final double sidePadding;

  const XHeading({
    super.key,
    required this.title,
    required this.actionText,
    required this.onActionTap,
    this.showActionButton = true,
    required this.sidePadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: XColors.primaryText,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),

          /// Show action button only if true
          showActionButton
              ? TextButton(
                  onPressed: onActionTap,
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    minimumSize: WidgetStateProperty.all(Size.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(color: XColors.primary, fontSize: 12),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
