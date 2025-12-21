import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderInstructionDialog extends StatelessWidget {
  final String paymentName;
  final String orderId;

  const OrderInstructionDialog({
    super.key,
    required this.paymentName,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: XColors.secondaryBG,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, color: XColors.primary, size: 42),

            const SizedBox(height: 12),

            Text(
              'Complete Payment',
              style: const TextStyle(
                color: XColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Open $paymentName app and complete payment using the Order ID below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: XColors.bodyText.withOpacity(0.7),
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: XColors.primaryBG,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                orderId,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: XColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Divider(color: XColors.borderColor, height: 1),

            GestureDetector(
              onTap: () => Get.back(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    color: XColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
