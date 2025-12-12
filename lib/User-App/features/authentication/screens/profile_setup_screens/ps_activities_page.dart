import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class ProfileSetupActivitiesPage extends StatelessWidget {
  final List<String> allActivities;
  final Set<String> selectedActivities;
  final String? favouriteActivity;
  final void Function(String activity, bool remove) onActivitySelected;
  final void Function(String activity) onFavouriteSelected;

  const ProfileSetupActivitiesPage({
    super.key,
    required this.allActivities,
    required this.selectedActivities,
    required this.favouriteActivity,
    required this.onActivitySelected,
    required this.onFavouriteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your activities',
            style: TextStyle(color: XColors.bodyText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allActivities.map((act) {
              final isSelected = selectedActivities.contains(act);
              return GestureDetector(
                onTap: () => onActivitySelected(act, isSelected),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? XColors.primary : XColors.secondaryBG,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? XColors.primary : XColors.borderColor,
                    ),
                  ),
                  child: Text(
                    act,
                    style: TextStyle(
                      color: isSelected
                          ? XColors.primaryText
                          : XColors.bodyText,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          if (selectedActivities.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick your favourite activity',
                  style: TextStyle(color: XColors.bodyText, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedActivities.map((act) {
                    final isFavourite = favouriteActivity == act;
                    return GestureDetector(
                      onTap: () => onFavouriteSelected(act),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isFavourite
                              ? XColors.primary
                              : XColors.secondaryBG,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFavourite
                                ? XColors.primary
                                : XColors.borderColor,
                          ),
                        ),
                        child: Text(
                          act,
                          style: TextStyle(
                            color: isFavourite
                                ? XColors.primaryText
                                : XColors.bodyText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
