import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SearchWithFilter extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final String hintText;
  final IconData searchIcon;
  final IconData filterIcon;
  final double horPadding;
  final bool showFilter;

  const SearchWithFilter({
    super.key,
    this.controller,
    this.onChanged,
    this.onSearchTap,
    this.onFilterTap,
    this.hintText = 'Looking For ...',
    this.searchIcon = Iconsax.search_normal,
    this.filterIcon = Iconsax.setting_4,
    required this.horPadding,
    this.showFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final double searchHeight = height * 0.06;
    final double iconSize = width * 0.05;
    final double padding = width * 0.04;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horPadding),
      child: SizedBox(
        height: searchHeight,
        child: Row(
          children: [
            // Search Input Box
            Expanded(
              flex: showFilter ? 5 : 6,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: height * 0.012, // ADDED VERTICAL PADDING
                ),
                decoration: BoxDecoration(
                  color: XColors.secondaryBG,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: XColors.borderColor, width: 0.7),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onSearchTap,
                      child: Icon(
                        searchIcon,
                        color: XColors.primary,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: width * 0.02),

                    // Editable TextField
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        cursorColor: XColors.primary,
                        style: TextStyle(
                          color: XColors.primaryText,
                          fontSize: width * 0.032,
                        ),
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(
                            color: XColors.bodyText,
                            fontSize: width * 0.030,
                            fontWeight: FontWeight.w300,
                          ),
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (showFilter) SizedBox(width: width * 0.025),

            // Filter Button
            if (showFilter)
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: XColors.primary,
                    ),
                    child: Icon(
                      filterIcon,
                      size: iconSize,
                      color: XColors.bodyText,
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
