import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class GenderDropdown extends StatefulWidget {
  final ValueChanged<String?>? onChanged;

  const GenderDropdown({super.key, this.onChanged});

  @override
  State<GenderDropdown> createState() => _GenderDropdownState();
}

class _GenderDropdownState extends State<GenderDropdown> {
  String? selectedGender = 'Male';
  final List<String> genders = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: XColors.bodyText,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selectedGender,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              LucideIcons.venus,
              color: XColors.bodyText,
              size: 16,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: XColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: XColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: XColors.borderColor),
            ),
          ),
          dropdownColor: XColors.secondaryBG,

          style: TextStyle(color: XColors.bodyText, fontSize: 13),
          icon: const Icon(
            LucideIcons.chevron_down,
            size: 15,
            color: XColors.bodyText,
          ),
          items: genders
              .map(
                (gender) => DropdownMenuItem<String>(
                  value: gender,
                  child: Text(
                    gender,
                    style: TextStyle(fontSize: 13, color: XColors.bodyText),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedGender = value;
            });
            // Call external callback if provided
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
        ),
      ],
    );
  }
}
