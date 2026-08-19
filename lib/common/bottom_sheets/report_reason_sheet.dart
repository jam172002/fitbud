import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/moderation/content_report.dart';

const _reasonLabels = {
  ReportReason.harassment: 'Harassment or bullying',
  ReportReason.threats: 'Threats or violence',
  ReportReason.spam: 'Spam or scam',
  ReportReason.sexualContent: 'Sexual content',
  ReportReason.illegalContent: 'Illegal content',
  ReportReason.impersonation: 'Impersonation',
  ReportReason.other: 'Something else',
};

class ReportSubmission {
  final ReportReason reason;
  final String details;
  const ReportSubmission(this.reason, this.details);
}

/// Bottom sheet for reporting a user or a specific message. Returns null if
/// the user cancels.
Future<ReportSubmission?> showReportReasonSheet(
  BuildContext context, {
  required String title,
}) {
  ReportReason? selected;
  final detailsController = TextEditingController();

  return showModalBottomSheet<ReportSubmission?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: XColors.secondaryBG,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: XColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your report is reviewed by the FitBud team.',
                  style: TextStyle(color: XColors.bodyText, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ..._reasonLabels.entries.map((entry) {
                  return RadioListTile<ReportReason>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: XColors.primary,
                    title: Text(
                      entry.value,
                      style: const TextStyle(color: XColors.primaryText, fontSize: 13),
                    ),
                    value: entry.key,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v),
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  style: const TextStyle(color: XColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Add details (optional)',
                    hintStyle: TextStyle(color: XColors.bodyText),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: XColors.danger),
                    onPressed: selected == null
                        ? null
                        : () => Get.back(
                              result: ReportSubmission(selected!, detailsController.text.trim()),
                            ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Submit Report'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}
