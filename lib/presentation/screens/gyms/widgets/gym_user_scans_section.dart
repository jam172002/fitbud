// lib/presentation/screens/gyms/widgets/gym_user_scans_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../utils/colors.dart';

class GymUserScansSection extends StatelessWidget {
  final String gymId;

  const GymUserScansSection({
    super.key,
    required this.gymId,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const SizedBox.shrink();
    }

    final query = FirebaseFirestore.instance
        .collection('scans')
        .where('userId', isEqualTo: uid)
        .where('gymId', isEqualTo: gymId)
        .orderBy('scannedAt', descending: true)
        .limit(10);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final d = snapshot.data!.docs[index].data();

                final ts = d['scannedAt'] as Timestamp?;
                final date = ts != null
                    ? DateFormat('dd MMM yyyy, hh:mm a')
                    .format(ts.toDate())
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
