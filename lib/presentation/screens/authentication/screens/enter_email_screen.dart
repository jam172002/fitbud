import 'package:fitbud/presentation/screens/authentication/screens/user_login_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/form_field.dart';
import '../../../../common/widgets/simple_dialog.dart';
import '../controllers/auth_controller.dart';

class EnterEmailScreen extends StatefulWidget {
  const EnterEmailScreen({super.key});

  @override
  State<EnterEmailScreen> createState() => _EnterEmailScreenState();
}

class _EnterEmailScreenState extends State<EnterEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  // Since you register AuthController in main.dart, just find it.
  final AuthController authC = Get.find<AuthController>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final res = await authC.sendPasswordResetEmail(email);

    if (!mounted) return;

    if (res.ok) {
      Get.dialog(
        SimpleDialogWidget(
          message:
          "We sent a password reset link to your email.\nPlease open your inbox and reset your password from there.",
          icon: LucideIcons.circle_check,
          iconColor: Colors.green,
          buttonText: "Back to Login",
          onOk: () {
            Get.offAll(() => const UserLoginScreen());
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: XColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter email associated with your account and\nwe\'ll send an email with instructions to reset\nyour password.',
                  style: TextStyle(fontSize: 12, color: XColors.bodyText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                XFormField(
                  controller: emailController,
                  label: "Email",
                  hint: "Enter your email",
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter email";
                    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                  cursorColor: XColors.primary,
                ),
                const SizedBox(height: 40),

                Obx(() {
                  final busy = authC.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: XColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        busy ? "Sending..." : "Send",
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
