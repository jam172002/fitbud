import 'package:fitbud/User-App/common/widgets/form_field.dart';
import 'package:fitbud/User-App/features/authentication/screens/enter_email_screen.dart';
import 'package:fitbud/User-App/features/authentication/screens/user_signup_screen.dart';
import 'package:fitbud/User-App/features/service/screens/navigation/user_navigation.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailPhoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final spacing = screenHeight < 700 ? 6.0 : 12.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                      SizedBox(height: 16),

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

                          // Check if input is a phone number (digits only)
                          final phoneRegExp = RegExp(
                            r'^\d{10,15}$',
                          ); // 10-15 digits
                          // Check if input is a valid email
                          final emailRegExp = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );

                          if (phoneRegExp.hasMatch(value)) {
                            return null; // valid phone
                          } else if (emailRegExp.hasMatch(value)) {
                            return null; // valid email
                          } else {
                            return "Enter a valid email or phone number";
                          }
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

                      SizedBox(height: 22),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Get.to(() => UserNavigation());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: XColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Log In",
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),

                      // Forget Password
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            'Forget Password?',
                            style: TextStyle(
                              color: XColors.bodyText,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.to(() => EnterEmailScreen()),
                            style:
                                TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: XColors.primary,
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                ),
                            child: Text(
                              'Reset it',
                              style: TextStyle(
                                color: XColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),
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
                    onPressed: () => Get.to(() => UserSignupScreen()),
                    style:
                        TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: XColors.primary,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
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
