import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/colors.dart';
import '../../../common/appbar/common_appbar.dart';
import 'gym_scan_history_screen.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: 'Scan History'),
      body: uid == null
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('scans')
            .where('userId', isEqualTo: uid)
            .orderBy('scannedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No scan history yet',
                style: TextStyle(
                  color: XColors.bodyText,
                  fontSize: 13,
                ),
              ),
            );
          }

          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byGym = {};

          for (final d in docs) {
            final gymId = d['gymId'] as String;
            byGym.putIfAbsent(gymId, () => []).add(d);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: byGym.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final gymId = byGym.keys.elementAt(index);
              final scans = byGym[gymId]!;

              final lastTs = scans.first['scannedAt'] as Timestamp?;
              final lastVisit = lastTs != null
                  ? DateFormat('dd MMM yyyy').format(lastTs.toDate())
                  : '--';

              return GestureDetector(
                onTap: () {
                  Get.to(() => GymScanHistoryScreen(gymId: gymId));
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: XColors.secondaryBG.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: XColors.primary.withValues(alpha: 0.25),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: XColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 20,
                          color: XColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gym Visits',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: XColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${scans.length} visits • Last on $lastVisit',
                              style: TextStyle(
                                fontSize: 12,
                                color: XColors.bodyText.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
