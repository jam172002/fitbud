import 'package:fitbud/User-App/common/widgets/form_field.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class DobField extends StatefulWidget {
  final Function(DateTime dob) onDobSelected;

  const DobField({super.key, required this.onDobSelected});

  @override
  State<DobField> createState() => _DobFieldState();
}

class _DobFieldState extends State<DobField> {
  final TextEditingController _dobController = TextEditingController();
  DateTime? selectedDob;

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100, now.month, now.day);
    final lastDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? DateTime(now.year - 18),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: XColors.primary,
              onPrimary: XColors.primaryText,
              surface: XColors.secondaryBG,
              onSurface: XColors.primaryText,
            ),
            dialogBackgroundColor: XColors.secondaryBG,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDob = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
      _validateAge(picked);
    }
  }

  void _validateAge(DateTime dob) {
    final now = DateTime.now();
    final age =
        now.year -
        dob.year -
        ((now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day))
            ? 1
            : 0);

    if (age < 16) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.circle_x,
          iconColor: XColors.danger,
          message:
              "You are underage. This app is not made for users under 16 years old.",
        ),
      );
      setState(() {
        _dobController.clear();
        selectedDob = null;
      });
    } else {
      widget.onDobSelected(dob);
    }
  }

  @override
  Widget build(BuildContext context) {
    return XFormField(
      controller: _dobController,
      label: 'Date of Birth',
      hint: 'DD-MM-YYYY',
      cursorColor: XColors.primary,
      prefixIcon: LucideIcons.calendar,
      readOnly: true,
      onTap: _pickDate,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Date of birth is required";
        }
        return null;
      },
      // Use 'suffix' instead of 'suffixIcon'
      suffix: GestureDetector(
        onTap: _pickDate,
        child: Icon(LucideIcons.calendar, color: XColors.primary, size: 20),
      ),
    );
  }
}
