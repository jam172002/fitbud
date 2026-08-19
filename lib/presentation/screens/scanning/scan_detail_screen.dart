import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/colors.dart';
import '../../../common/appbar/common_appbar.dart';

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> scan;
  const ScanDetailScreen({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final ts = scan['scannedAt'];
    final date = ts != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
        : '--';

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: 'Scan Details'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: XColors.secondaryBG.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: XColors.primary.withValues(alpha: 0.25),
              width: 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Date', date),
              _row('Status', scan['status']),
              _row('Day', scan['dayKey']),
              _row('Month', scan['monthKey']),
              _row('Hour', scan['hour'].toString()),
              _row('Scan ID', scan['clientScanId']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: XColors.bodyText.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: XColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
