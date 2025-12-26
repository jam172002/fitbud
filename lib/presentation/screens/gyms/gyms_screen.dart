import 'package:fitbud/presentation/screens/gyms/widgets/gyms_screen_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/search_with_filter.dart';
import 'controllers/gyms_user_controller.dart';
import 'gym_detail_screen.dart';

class GymsScreen extends StatelessWidget {
  const GymsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<GymsUserController>();

    return Scaffold(
      appBar: XAppBar(title: 'Our Gyms', showBackIcon: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              SearchWithFilter(horPadding: 0, showFilter: false),
              const SizedBox(height: 16),

              Expanded(
                child: Obx(() {
                  if (c.busy.value && c.gyms.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (c.error.value != null && c.gyms.isEmpty) {
                    return _ErrorState(
                      message: c.error.value!,
                      onRetry: () => c.refreshOnce(),
                    );
                  }

                  if (c.gyms.isEmpty) {
                    return _EmptyState(onRefresh: () => c.refreshOnce());
                  }

                  return RefreshIndicator(
                    onRefresh: () async => c.refreshOnce(),
                    child: ListView.builder(
                      itemCount: c.gyms.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (_, index) {
                        final gym = c.gyms[index];
                        return SingleGymCard.fromGym(
                          gym: gym,
                          onTap: () => Get.to(() => GymDetailScreen(gym: gym)),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 56, color: Colors.white38),
            const SizedBox(height: 10),
            const Text(
              'No gyms available right now.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.white38),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
