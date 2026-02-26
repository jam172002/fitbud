import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/colors.dart';
import '../../../common/appbar/common_appbar.dart';
import 'scan_detail_screen.dart';

class GymScanHistoryScreen extends StatelessWidget {
  final String gymId;
  const GymScanHistoryScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: 'Your Visits'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('scans')
            .where('userId', isEqualTo: uid)
            .where('gymId', isEqualTo: gymId)
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
                'No visits yet',
                style: TextStyle(color: XColors.bodyText, fontSize: 13),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final ts = d['scannedAt'] as Timestamp?;
              final date = ts != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
                  : '--';

              final status = d['status'] ?? 'unknown';

              return GestureDetector(
                onTap: () {
                  Get.to(() => ScanDetailScreen(scan: d));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: status == 'accepted'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          date,
                          style: const TextStyle(
                            color: XColors.primaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
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
