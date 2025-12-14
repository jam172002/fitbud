import 'package:fitbud/User-App/common/widgets/form_field.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/User-App/features/authentication/screens/user_login_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    // If user is NOT logged in, we cannot set password here for Firebase email reset flow.
    if (user == null) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message:
          "You are not logged in. Please reset your password using the link sent to your email, then login again.",
          buttonText: "Go to Login",
          onOk: () => Get.offAll(() => const UserLoginScreen()),
        ),
        barrierDismissible: false,
      );
      return;
    }

    setState(() => _busy = true);

    try {
      await user.updatePassword(passwordController.text);

      Get.dialog(
        SimpleDialogWidget(
          message: "Password updated successfully",
          icon: LucideIcons.circle_check,
          iconColor: Colors.green,
          buttonText: "Continue",
          onOk: () => Get.offAll(() => const UserLoginScreen()),
        ),
        barrierDismissible: false,
      );
    } on FirebaseAuthException catch (e) {
      // Common case: requires recent login
      if (e.code == 'requires-recent-login') {
        Get.dialog(
          SimpleDialogWidget(
            icon: LucideIcons.shield_alert,
            iconColor: XColors.warning,
            message:
            "For security reasons, please login again and then change your password from Settings/Profile.",
            buttonText: "Go to Login",
            onOk: () => Get.offAll(() => const UserLoginScreen()),
          ),
          barrierDismissible: false,
        );
      } else {
        Get.dialog(
          SimpleDialogWidget(
            icon: LucideIcons.shield_alert,
            iconColor: XColors.warning,
            message: e.message ?? "Failed to update password. Please try again.",
          ),
        );
      }
    } catch (e) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: "Unexpected error: $e",
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: XColors.primaryBG,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            LucideIcons.chevron_left,
            color: XColors.primaryText,
            size: 25,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          padding: EdgeInsets.zero,
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: XColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your new password must be different from\npreviously used passwords.',
                  style: TextStyle(fontSize: 12, color: XColors.bodyText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Password Field
                XFormField(
                  controller: passwordController,
                  label: "Password",
                  hint: "Enter your new password",
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a password";
                    }
                    final pattern =
                        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$';
                    if (!RegExp(pattern).hasMatch(value)) {
                      return "Password must be at least 8 characters,\ninclude uppercase, lowercase, number & special character";
                    }
                    return null;
                  },
                  cursorColor: XColors.primary,
                ),
                const SizedBox(height: 10),

                // Confirm Password Field
                XFormField(
                  controller: confirmPasswordController,
                  label: "Confirm Password",
                  hint: "Confirm your password",
                  isPassword: true,
                  prefixIcon: LucideIcons.rectangle_ellipsis,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your password";
                    }
                    if (value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                  cursorColor: XColors.primary,
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: XColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _busy ? "Updating..." : "Create Password",
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
