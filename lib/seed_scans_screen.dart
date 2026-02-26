import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SeedScansScreen extends StatefulWidget {
  const SeedScansScreen({super.key});

  @override
  State<SeedScansScreen> createState() => _SeedScansScreenState();
}

class _SeedScansScreenState extends State<SeedScansScreen> {
  bool running = false;
  String status = 'Idle';

  /// ✅ USERS (as provided)
  static const List<String> USER_IDS = [
    'Qb4ZsgR1iBNiMoZqT6E1nvhQ1WT2',
    'tVyIdyPyObNPEQaR13Jbp2J2Tmd2',
    'QoCYIMRPEjXxTK0o6y6FJtrdxa32',
  ];

  /// ✅ GYMS (as provided)
  static const List<String> GYM_IDS = [
    'HkKbMn9C1fOpfixNiO4N',
    'J1rD3ICGenhYRirGehyo',
    'vI8dfJbGvPFIBlgqCguQ',
  ];

  Future<void> seedDummyScans() async {
    setState(() {
      running = true;
      status = 'Seeding scans...';
    });

    final db = FirebaseFirestore.instance;

    const int daysBack = 7;
    const int scansPerDay = 2;

    final now = DateTime.now();

    for (final userId in USER_IDS) {
      for (final gymId in GYM_IDS) {
        for (int d = 0; d < daysBack; d++) {
          for (int i = 0; i < scansPerDay; i++) {
            final scanTime = now.subtract(Duration(days: d)).copyWith(
              hour: 9 + (i * 3),
              minute: 0,
            );

            final dayKey = DateFormat('yyyy-MM-dd').format(scanTime);
            final monthKey = DateFormat('yyyy-MM').format(scanTime);
            final hour = scanTime.hour;

            await db.collection('scans').add({
              'userId': userId,
              'gymId': gymId,
              'scannedAt': Timestamp.fromDate(scanTime),
              'status': 'accepted',
              'dayKey': dayKey,
              'monthKey': monthKey,
              'hour': hour,
            });
          }
        }
      }
    }

    setState(() {
      running = false;
      status = '✅ Seeding completed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Dummy Scans')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: running ? null : seedDummyScans,
              child: const Text('RUN SEEDER'),
            ),
          ],
        ),
      ),
    );
  }
}
