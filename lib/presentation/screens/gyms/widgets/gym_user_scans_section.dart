// lib/presentation/screens/gyms/widgets/gym_user_scans_section.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/supabase_instances.dart';
import '../../../../domain/repos/repo_provider.dart';
import '../../../../utils/colors.dart';

class GymUserScansSection extends StatelessWidget {
  final String gymId;

  const GymUserScansSection({
    super.key,
    required this.gymId,
  });

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseInstances.uid;

    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Get.find<Repos>().scanRepo.watchScanMaps(gymId: gymId, limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No scans yet at this gym',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Your Visits',
                style: TextStyle(
                  color: XColors.bodyText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final d = snapshot.data![index];

                final ts = d['scannedAt'] as DateTime?;
                final date = ts != null
                    ? DateFormat('dd MMM yyyy, hh:mm a')
                    .format(ts)
                    : '--';

                final status = d['status'] ?? 'unknown';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: XColors.secondaryBG,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: XColors.primary.withValues(alpha: 0.2),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: status == 'accepted'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          date,
                          style: const TextStyle(
                            color: XColors.primaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
