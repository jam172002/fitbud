import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/plan_card.dart';
import '../../../domain/models/plans/plan.dart';
import 'plans_controller.dart';

class PremiumPlanScreen extends StatelessWidget {
  const PremiumPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PremiumPlanController>();

    return Scaffold(
      appBar: XAppBar(title: 'Premium Plans'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error.value.isNotEmpty) {
              return _ErrorState(
                message: controller.error.value,
                onRetry: controller.refreshPlans,
              );
            }

            final plans = controller.plans;
            if (plans.isEmpty) {
              return _EmptyState(onRetry: controller.refreshPlans);
            }

            return RefreshIndicator(
              onRefresh: controller.refreshPlans,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final Plan p = plans[index];
                  return PlanCard(
                    index: index,
                    title: p.name,
                    description: p.description,
                    price: p.price.round(), // PlanCard expects int in your code
                    duration: '${p.durationDays} days',
                    features: p.features,
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No active plans found.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onRetry(),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Failed to load plans'),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onRetry(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
