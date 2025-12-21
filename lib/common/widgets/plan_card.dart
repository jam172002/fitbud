import 'package:fitbud/User-App/features/service/controllers/plans_controller.dart';
import 'package:fitbud/common/widgets/payment_account_number_dialog.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../bottom_sheets/payment_methods_selection_sheet.dart';
import 'order_id_dialog.dart';

class PlanCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final int price;
  final String duration;
  final List<String> features;

  const PlanCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PremiumPlanController>();

    final isSelected = controller.isSelected(index);
    final isDisabled = controller.isDisabled(index);

    /// ---------------- BUTTON HELPERS ----------------

    String getButtonText() {
      if (isSelected && controller.status == PlanStatus.pending) {
        return 'Pending';
      } else if (isSelected && controller.status == PlanStatus.active) {
        return 'Active Plan';
      }
      return 'Purchase Plan';
    }

    Color getButtonBgColor() {
      if (!isSelected) return Colors.transparent;

      return controller.status == PlanStatus.active
          ? XColors.primary
          : Colors.orange;
    }

    Color getButtonBorderColor() {
      if (!isSelected) return XColors.primary;
      return Colors.transparent;
    }

    Color getButtonTextColor() {
      if (!isSelected) return XColors.primary;
      return XColors.primaryText;
    }

    Color getPlanNameColor() {
      return isDisabled ? Colors.grey : XColors.primary;
    }

    /// ------------------------------------------------

    return Opacity(
      opacity: isDisabled ? 0.45 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: XColors.secondaryBG,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            /// -------- TOP INFO --------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: getPlanNameColor(),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: XColors.bodyText.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PKR $price',
                          style: const TextStyle(
                            color: XColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/$duration',
                          style: const TextStyle(
                            color: XColors.primaryText,
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: features
                          .map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.circle,
                                    size: 12,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: XColors.bodyText.withOpacity(
                                          0.7,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// -------- BUTTON --------
            GestureDetector(
              onTap: isDisabled
                  ? null
                  : () async {
                      final method = await showModalBottomSheet<PaymentMethod>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) =>
                            PaymentMethodBottomSheet(planIndex: index),
                      );

                      if (method == null) return;

                      if (method == PaymentMethod.card) {
                        controller.setActive(index);
                      } else {
                        Get.dialog(
                          PaymentAccountDialog(
                            paymentName: method.name,
                            onConfirm: (accountNumber) {
                              final orderId =
                                  'FB-${DateTime.now().millisecondsSinceEpoch}';

                              controller.setPending(
                                index: index,
                                method: method,
                                order: orderId,
                              );

                              Get.back();

                              Get.dialog(
                                OrderInstructionDialog(
                                  paymentName: method.name,
                                  orderId: orderId,
                                ),
                                barrierDismissible: false,
                              );
                            },
                          ),
                          barrierDismissible: false,
                        );
                      }
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: getButtonBgColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: getButtonBorderColor(), width: 1.2),
                ),
                child: Center(
                  child: Text(
                    getButtonText(),
                    style: TextStyle(
                      color: getButtonTextColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            /// -------- PENDING INFO --------
            if (isSelected && controller.status == PlanStatus.pending) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: LucideIcons.credit_card,
                label: 'Payment: ${controller.paymentMethod?.name ?? '-'}',
              ),
              _InfoRow(
                icon: LucideIcons.box,
                label: 'Order ID: ${controller.orderId}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
