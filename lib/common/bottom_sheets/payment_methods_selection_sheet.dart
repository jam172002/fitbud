import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../presentation/screens/subscription/plans_controller.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final int planIndex;
  const PaymentMethodBottomSheet({super.key, required this.planIndex});

  @override
  State<PaymentMethodBottomSheet> createState() => _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PremiumPlanController>();

    Future<void> _startDirectPay(PaymentMethod chosenMethod) async {
      if (_busy) return;
      setState(() => _busy = true);

      final orderId = 'FB-${DateTime.now().millisecondsSinceEpoch}';

      try {
        // Close bottom sheet before starting flow
        Navigator.pop(context);

        await controller.startDirectPayPwa(
          index: widget.planIndex,
          chosenMethod: chosenMethod, // jazzcash/easypaisa
          orderId: orderId,
        );
      } catch (e) {
        // If something fails, show error and reset pending if needed
        Get.snackbar(
          "Payment Error",
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: XColors.primaryBG,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.6 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Select Payment Method',
                style: TextStyle(
                  color: XColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              _PaymentTile(
                logo: 'assets/logos/Jazzcash.png',
                title: 'JazzCash (DirectPay)',
                color: Colors.white70,
                onTap: () => _startDirectPay(PaymentMethod.jazzcash),
              ),

              _PaymentTile(
                logo: 'assets/logos/Easypaisa.png',
                title: 'Easypaisa (DirectPay)',
                color: Colors.tealAccent,
                onTap: () => _startDirectPay(PaymentMethod.easypaisa),
              ),

              _PaymentTile(
                logo: 'assets/logos/card.png',
                title: 'Card',
                color: Colors.blueAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await controller.setActive(widget.planIndex);
                },
              ),

              if (_busy) ...[
                const SizedBox(height: 8),
                Row(
                  children: const [
                    SizedBox(width: 6),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Text("Starting payment...")),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String logo;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.title,
    required this.color,
    required this.onTap,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: XColors.primaryBG,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(logo, fit: BoxFit.cover, height: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: XColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              size: 16,
              color: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}