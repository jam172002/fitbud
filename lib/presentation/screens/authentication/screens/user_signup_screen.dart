
import 'package:fitbud/presentation/screens/authentication/screens/permission_screen.dart';
import 'package:fitbud/presentation/screens/authentication/screens/profile_setup_screens/profile_data_gathering_screen.dart';
import 'package:fitbud/presentation/screens/authentication/screens/user_login_screen.dart';
import 'package:fitbud/presentation/screens/profile/privacy_security_screen.dart';
import 'package:fitbud/presentation/screens/profile/terms_conditions_screen.dart';

import '../../../../common/widgets/form_field.dart';
import '../../../../common/widgets/gender_dropdown.dart';
import '../../../../common/widgets/simple_dialog.dart';
import '../../../../domain/models/auth/user_address.dart';
import '../controllers/auth_controller.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../../domain/repos/repo_provider.dart';
import 'location_selector_screen.dart';

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
  bool _termsAccepted = false;

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

    if (!_termsAccepted) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: "Please accept the Terms & Conditions and Privacy Policy to continue.",
        ),
      );
      return;
    }

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
          // IMPORTANT: LocationSelectorScreen returns UserAddress (NOT String)
          final addr = await Get.to<UserAddress>(() => const LocationSelectorScreen());

          if (!mounted) return;

          // If user selected an address, update state and go back to signup
          if (addr != null) {
            final label = (addr.city?.trim().isNotEmpty == true)
                ? addr.city!.trim()
                : addr.line1?.trim();

            setState(() => selectedLocation = label);

            // IMPORTANT: You are currently on PermissionScreen after the selector pops.
            // Pop PermissionScreen to return to Signup.
            Get.back();
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

                        const SizedBox(height: 10),

                        // Terms & Conditions checkbox
                        GestureDetector(
                          onTap: () {
                            setState(() => _termsAccepted = !_termsAccepted);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _termsAccepted
                                  ? XColors.primary.withOpacity(0.07)
                                  : XColors.secondaryBG.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _termsAccepted
                                    ? XColors.primary.withOpacity(0.5)
                                    : XColors.borderColor.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _termsAccepted,
                                    onChanged: (val) {
                                      setState(
                                          () => _termsAccepted = val ?? false);
                                    },
                                    activeColor: XColors.primary,
                                    checkColor: Colors.black,
                                    side: BorderSide(
                                      color: _termsAccepted
                                          ? XColors.primary
                                          : Colors.grey.shade600,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: XColors.bodyText.withOpacity(0.75),
                                        height: 1.5,
                                      ),
                                      children: [
                                        const TextSpan(text: 'I have read and agree to the '),
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.baseline,
                                          baseline: TextBaseline.alphabetic,
                                          child: GestureDetector(
                                            onTap: () => Get.to(
                                                () => const TermsConditionsScreen()),
                                            child: const Text(
                                              'Terms & Conditions',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: XColors.primary,
                                                fontWeight: FontWeight.w600,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.baseline,
                                          baseline: TextBaseline.alphabetic,
                                          child: GestureDetector(
                                            onTap: () => Get.to(
                                                () => const PrivacySecurityScreen()),
                                            child: const Text(
                                              'Privacy Policy',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: XColors.primary,
                                                fontWeight: FontWeight.w600,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
