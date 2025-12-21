import 'package:fitbud/presentation/screens/authentication/screens/password_reset_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../../common/widgets/simple_dialog.dart';

class VerifyCodeScreen extends StatefulWidget {
  final bool isGYM;
  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.isGYM,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController otpController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> _confirmCode() async {
    if (otpController.text.length != 4) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: "Please enter the 4 digits verification code.",
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      // TODO: When you implement real OTP verification, do it here.
      // For now it is a mock OTP check.
      // Example (future): await authC.verifyResetOtp(email: widget.email, otp: otpController.text);

      Get.to(() => const PasswordResetScreen());
    } catch (e) {
      Get.dialog(
        SimpleDialogWidget(
          icon: LucideIcons.shield_alert,
          iconColor: XColors.warning,
          message: "Verification failed: $e",
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 55,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 18,
        color: XColors.bodyText,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: XColors.secondaryBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
    );

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: XColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please enter the code we just sent to this email:',
                style: TextStyle(fontSize: 12, color: XColors.bodyText),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.email,
                style: TextStyle(fontSize: 12, color: XColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              // OTP Field
              Pinput(
                length: 4,
                controller: otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: XColors.primary),
                  ),
                ),
                showCursor: true,
              ),

              const SizedBox(height: 40),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _confirmCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _busy ? "Verifying..." : "Confirm",
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
