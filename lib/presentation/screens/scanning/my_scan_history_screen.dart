import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/models/gyms/gym_scan.dart';
import '../../../domain/repos/scans/scan_repo.dart';

class MyScanHistoryScreen extends StatelessWidget {
  const MyScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScanRepo repo = Get.find();

    return Scaffold(
      appBar: AppBar(title: const Text('My Gym Visits')),
      body: StreamBuilder<List<GymScan>>(
        stream: repo.watchMyScanHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scans = snapshot.data!;
          if (scans.isEmpty) {
            return const Center(child: Text('No visits yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final s = scans[i];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text('Gym: ${s.gymId}'),
                subtitle: Text(
                  s.scannedAt?.toLocal().toString() ?? '',
                ),
                trailing: Text(
                  s.result.name,
                  style: TextStyle(
                    color: s.result == ScanResult.allowed
                        ? Colors.green
                        : Colors.red,
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
