import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../User-App/features/service/controllers/plans_controller.dart';
import '../widgets/order_id_dialog.dart';
import '../widgets/payment_account_number_dialog.dart';

class PaymentMethodBottomSheet extends StatelessWidget {
  final int planIndex; // Index of the plan for which payment is being made

  const PaymentMethodBottomSheet({super.key, required this.planIndex});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PremiumPlanController>();

    void _handlePending(PaymentMethod method) {
      final orderId = 'FB-${DateTime.now().millisecondsSinceEpoch}';
      controller.setPending(index: planIndex, method: method, order: orderId);
      Get.dialog(
        OrderInstructionDialog(paymentName: method.name, orderId: orderId),
        barrierDismissible: false,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: XColors.primaryBG,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Handle
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

          /// Title
          Text(
            'Select Payment Method',
            style: TextStyle(
              color: XColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          /// JazzCash
          _PaymentTile(
            logo: 'assets/logos/Jazzcash.png',
            title: 'JazzCash',
            color: Colors.white70,
            onTap: () {
              Navigator.pop(context);
              Get.dialog(
                PaymentAccountDialog(
                  paymentName: 'JazzCash',
                  onConfirm: (accountNumber) {
                    Get.back(); // close the dialog
                    _handlePending(PaymentMethod.jazzcash);
                  },
                ),
                barrierDismissible: false,
              );
            },
          ),

          /// Easypaisa
          _PaymentTile(
            logo: 'assets/logos/Easypaisa.png',
            title: 'Easypaisa',
            color: Colors.tealAccent,
            onTap: () {
              Navigator.pop(context);
              Get.dialog(
                PaymentAccountDialog(
                  paymentName: 'Easypaisa',
                  onConfirm: (accountNumber) {
                    Get.back(); // close the dialog
                    _handlePending(PaymentMethod.easypaisa);
                  },
                ),
                barrierDismissible: false,
              );
            },
          ),

          /// Card
          /// Card
          _PaymentTile(
            logo: 'assets/logos/card.png',
            title: 'Card',
            color: Colors.blueAccent,
            onTap: () {
              Navigator.pop(context);

              // ✅ DIRECTLY ACTIVATE PLAN
              controller.setActive(planIndex);
            },
          ),
        ],
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
