import 'package:fitbud/User-App/common/widgets/form_field.dart';
import 'package:fitbud/User-App/common/widgets/gender_dropdown.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/User-App/features/authentication/screens/location_selector_screen.dart';
import 'package:fitbud/User-App/features/authentication/screens/permission_screen.dart';
import 'package:fitbud/User-App/features/authentication/screens/profile_setup_screens/profile_data_gathering_screen.dart';
import 'package:fitbud/User-App/features/authentication/screens/user_login_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import 'package:fitbud/User-App/features/authentication/controllers/auth_controller.dart';

import '../../../../domain/repos/repo_provider.dart';

class UserSignupScreen extends StatefulWidget {
  const UserSignupScreen({super.key});

  @override
  State<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends State<UserSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final dobController = TextEditingController();

  String? selectedGender;
  String? selectedLocation;
  DateTime? selectedDob;

  AuthController get authC {
    // Safe fallback if you didn't register bindings in main
    if (!Get.isRegistered<Repos>()) Get.put(Repos(), permanent: true);
    return Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(Get.find<Repos>()), permanent: true);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDob == null) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: "Please select your date of birth",
        ),
      );
      return;
    }

    if (selectedGender == null) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: "Please select your gender",
        ),
      );
      return;
    }

    if (selectedLocation == null) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: "Please select your location",
        ),
      );
      return;
    }

    final res = await authC.signUpWithEmail(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      password: passwordController.text,
      dob: selectedDob!,
      gender: selectedGender!,
      location: selectedLocation!,
    );

    if (!mounted) return;

    if (res.ok) {
      Get.dialog(
        SimpleDialogWidget(
          message: "Signup successful!",
          icon: LucideIcons.circle_check,
          iconColor: Colors.green,
          buttonText: "Continue",
          onOk: () {
            Get.off(() => ProfileDataGatheringScreen());
          },
        ),
        barrierDismissible: false,
      );
    } else {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: res.message,
        ),
      );
    }
  }

  void _pickDob() async {
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
            colorScheme: const ColorScheme.dark(
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
      final age = now.year -
          picked.year -
          ((now.month < picked.month ||
              (now.month == picked.month && now.day < picked.day))
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
        return;
      }

      setState(() {
        selectedDob = picked;
        dobController.text =
        "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Future<void> _selectLocationFlow() async {
    // keep your permission screen flow exactly the same
    Get.to(
          () => PermissionScreen(
        title: 'Need Location Access',
        subtitle: 'Please give us access to your GPS Location',
        illustration: Image.asset('assets/icons/location.png'),
        allowButtonText: 'Allow',
            requestLocationPermission: true,
            showDenyButton: false,
        onDeny: () {},
        onAllow: () async {
          // navigate to location selector
          // You can return selected location from LocationSelectorScreen via Get.back(result: 'City')
          final result = await Get.to<String>(() => const LocationSelectorScreen());
          if (result != null && result.trim().isNotEmpty) {
            setState(() => selectedLocation = result.trim());
          } else {
            // fallback
            setState(() => selectedLocation = "Selected location");
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final spacing = screenHeight < 700 ? 6.0 : 8.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: XColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tell us a bit about yourself.',
                          style: TextStyle(
                            fontSize: 12,
                            color: XColors.bodyText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spacing),

                        // Name
                        XFormField(
                          controller: nameController,
                          label: 'User Name',
                          hint: 'Enter your name',
                          cursorColor: XColors.primary,

                          prefixIcon: LucideIcons.user,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Name is required";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: spacing),

                        // Email
                        XFormField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'Enter your email address',
                          cursorColor: XColors.primary,
                          prefixIcon: LucideIcons.mail,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: spacing),

                        // Phone
                        XFormField(
                          controller: phoneController,
                          label: 'Phone',
                          hint: 'Enter your phone number',
                          cursorColor: XColors.primary,
                          prefixIcon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Phone number is required";
                            }
                            if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                              return "Enter a valid phone number";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: spacing),

                        // Password
                        XFormField(
                          controller: passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          cursorColor: XColors.primary,
                          prefixIcon: LucideIcons.lock,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password is required";
                            }
                            if (!RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$',
                            ).hasMatch(value)) {
                              return "Password must contain upper, lower, number & special character";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: spacing),

                        // Date of Birth
                        XFormField(
                          controller: dobController,
                          label: 'Date of Birth',
                          hint: 'DD-MM-YYYY',
                          cursorColor: XColors.primary,
                          prefixIcon: LucideIcons.calendar,
                          readOnly: true,
                          onTap: _pickDob,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Date of birth is required";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: spacing),

                        // Gender
                        GenderDropdown(
                          onChanged: (val) {
                            setState(() => selectedGender = val);
                          },
                        ),
                        SizedBox(height: spacing),

                        // Location
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _selectLocationFlow,
                            icon: const Icon(
                              LucideIcons.locate,
                              size: 16,
                              color: XColors.primary,
                            ),
                            label: Text(
                              selectedLocation == null
                                  ? 'Select your location'
                                  : 'Location: $selectedLocation',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: XColors.primary,
                              ),
                            ),
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(EdgeInsets.zero),
                              minimumSize: MaterialStateProperty.all(Size.zero),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: MaterialStateProperty.all(Colors.transparent),
                              alignment: Alignment.centerRight,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Signup Button (loading aware)
                        Obx(() {
                          final busy = authC.isLoading.value;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: busy ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: XColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                busy ? "Creating..." : "Sign up",
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 4),

                        // Terms
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              'By signing up, You agree to our',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 10,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: XColors.primary,
                              ).copyWith(
                                overlayColor: MaterialStateProperty.all(Colors.transparent),
                              ),
                              child: Text(
                                'Terms & Conditions',
                                style: TextStyle(
                                  color: XColors.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Login link
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: XColors.bodyText, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () => Get.to(() => const UserLoginScreen()),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: XColors.primary,
                      ).copyWith(
                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(color: XColors.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
