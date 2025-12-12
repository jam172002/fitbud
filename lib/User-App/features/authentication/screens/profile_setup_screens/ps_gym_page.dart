import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class ProfileSetupGymPage extends StatelessWidget {
  final bool? hasGym;
  final String? selectedGym;
  final String? customGymName; // new
  final List<String> gyms;
  final void Function(bool val) onHasGymChanged;
  final void Function(String val) onGymChanged;

  const ProfileSetupGymPage({
    super.key,
    required this.hasGym,
    required this.selectedGym,
    required this.customGymName,
    required this.gyms,
    required this.onHasGymChanged,
    required this.onGymChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you go to a gym?',
            style: TextStyle(color: XColors.bodyText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Yes'),
                selected: hasGym == true,
                onSelected: (_) => onHasGymChanged(true),
                selectedColor: XColors.primary,
                backgroundColor: XColors.secondaryBG,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: hasGym == true
                      ? XColors.primaryText
                      : XColors.bodyText,
                ),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('No'),
                selected: hasGym == false,
                showCheckmark: false,
                onSelected: (_) => onHasGymChanged(false),
                selectedColor: XColors.primary,
                backgroundColor: XColors.secondaryBG,
                labelStyle: TextStyle(
                  color: hasGym == false
                      ? XColors.primaryText
                      : XColors.bodyText,
                ),
              ),
            ],
          ),
          if (hasGym == true) ...[
            const SizedBox(height: 30),
            Text(
              'Select your gym',
              style: TextStyle(color: XColors.bodyText, fontSize: 12),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedGym ?? '-- select --', // must exist in items
              dropdownColor: XColors.secondaryBG, // dropdown menu background
              style: TextStyle(
                color: XColors.primaryText, // selected text color
                fontSize: 14,
              ),
              items: gyms.map((gym) {
                return DropdownMenuItem<String>(
                  value: gym,
                  child: Text(
                    gym,
                    style: TextStyle(
                      color: XColors.primaryText,
                    ), // menu item text
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onGymChanged(val);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: XColors.secondaryBG, // input background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: XColors.borderColor,
                  ), // border color
                ),
                enabledBorder: OutlineInputBorder(
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

            if (customGymName != null && customGymName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: XColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customGymName!,
                      style: TextStyle(
                        color: XColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
