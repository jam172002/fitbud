
import 'package:fitbud/presentation/screens/authentication/screens/user_signup_screen.dart';

import '../../../../common/widgets/form_field.dart';
import '../../../../common/widgets/simple_dialog.dart';
import '../../navigation/user_navigation.dart';
import '../controllers/auth_controller.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import 'enter_email_screen.dart';


class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Controller is registered in main.dart
  final AuthController authC = Get.find<AuthController>();

  @override
  void dispose() {
    emailPhoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final res = await authC.login(
      emailOrPhone: emailPhoneController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    if (res.ok) {
      Get.off(() => UserNavigation());
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final spacing = screenHeight < 700 ? 6.0 : 12.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: XColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Continue by entering your details.',
                        style: TextStyle(fontSize: 12, color: XColors.bodyText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Email / Phone
                      XFormField(
                        controller: emailPhoneController,
                        label: "Email or Phone",
                        hint: "Enter email or phone",
                        prefixIcon: LucideIcons.mail,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter email or phone";
                          }

                          final phoneRegExp = RegExp(r'^\d{10,15}$');
                          final emailRegExp =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                          if (phoneRegExp.hasMatch(value)) return null;
                          if (emailRegExp.hasMatch(value)) return null;

                          return "Enter a valid email or phone number";
                        },
                        cursorColor: XColors.primary,
                      ),
                      SizedBox(height: spacing),

                      // Password
                      XFormField(
                        controller: passwordController,
                        label: "Password",
                        hint: "Enter your password",
                        isPassword: true,
                        prefixIcon: LucideIcons.lock,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }
                          if (value.length < 6) {
                            return "Minimum 6 characters required";
                          }
                          return null;
                        },
                        cursorColor: XColors.primary,
                      ),

                      const SizedBox(height: 22),

                      // Login Button (loading aware)
                      Obx(() {
                        final busy = authC.isLoading.value;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: busy ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: XColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              busy ? "Logging in..." : "Log In",
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: spacing),

                      // Forget Password
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            'Forget Password?',
                            style: TextStyle(color: XColors.bodyText, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () => Get.to(() => const EnterEmailScreen()),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: XColors.primary,
                            ).copyWith(
                              overlayColor: WidgetStateProperty.all(Colors.transparent),
                            ),
                            child: Text(
                              'Reset it',
                              style: TextStyle(color: XColors.primary, fontSize: 13),
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

            // Bottom Signup row
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: TextStyle(color: XColors.bodyText, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => Get.to(() => const UserSignupScreen()),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: XColors.primary,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Text(
                      'Signup',
                      style: TextStyle(color: XColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
