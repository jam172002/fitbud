// lib/dev/seed_scans_screen.dart
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

  static const String USER_ID = 'ob7Rz6OwKRV8uEpQbxq8IqqxeIq2';

  static const List<String> GYM_IDS = [
    'HkKbMn9C1fOpfixNiO4N',
    'J1rD3ICGenhYRirGehyo',
    'vI8dfJbGvPFIBlgqCguQ',
  ];

  Future<void> seedDummyScans() async {
    setState(() {
      running = true;
      status = 'Seeding...';
    });

    final db = FirebaseFirestore.instance;
    const daysBack = 7;
    const scansPerDayPerGym = 4;
    final now = DateTime.now();

    for (final gymId in GYM_IDS) {
      for (int d = 0; d < daysBack; d++) {
        for (int i = 0; i < scansPerDayPerGym; i++) {
          final scanTime = now.subtract(Duration(days: d)).copyWith(
            hour: 8 + i * 2,
            minute: 0,
          );

          final dayKey = DateFormat('yyyy-MM-dd').format(scanTime);
          final monthKey = DateFormat('yyyy-MM').format(scanTime);
          final hour = scanTime.hour;

          final scanRef = db.collection('scans').doc();
          final dailyRef = db.doc('gyms/$gymId/statsDaily/$dayKey');
          final monthlyRef = db.doc('gyms/$gymId/statsMonthly/$monthKey');
          final gymRef = db.doc('gyms/$gymId');

          await db.runTransaction((tx) async {
            tx.set(scanRef, {
              'userId': USER_ID,
              'gymId': gymId,
              'clientScanId': 'dummy-${scanRef.id}',
              'deviceId': 'flutter-seeder',
              'scannedAt': Timestamp.fromDate(scanTime),
              'dayKey': dayKey,
              'monthKey': monthKey,
              'hour': hour,
              'status': 'accepted',
            });

            tx.set(
              dailyRef,
              {
                'total': FieldValue.increment(1),
                'hours.$hour': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );

            tx.set(
              monthlyRef,
              {
                'total': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );

            tx.update(gymRef, {
              'totalScans': FieldValue.increment(1),
              'monthlyScans': FieldValue.increment(1),
            });
          });
        }
      }
    }

    setState(() {
      running = false;
      status = '✅ Done';
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
