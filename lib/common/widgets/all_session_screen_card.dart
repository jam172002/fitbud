import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/sessions/session_invite.dart';
import '../../presentation/screens/budy/controller/session_invites_controller.dart';

class AllSessionsScreenCard extends StatelessWidget {
  final String title;
  final String status;
  final bool isGrouped;
  final int sentTo;
  final VoidCallback nameOnTap;

  /// NEW: real invite (needed for accept/decline)
  final SessionInvite? invite;

  const AllSessionsScreenCard({
    super.key,
    this.title = 'Gym Practice',
    this.status = 'Pending',
    this.isGrouped = false,
    this.sentTo = 0,
    required this.nameOnTap,
    this.invite,
  });

  ImageProvider _img(String path) {
    final p = (path).trim();
    if (p.isEmpty || p == 'null') return const AssetImage('assets/images/gym.jpeg');
    if (p.startsWith('http://') || p.startsWith('https://')) return NetworkImage(p);
    return AssetImage(p);
  }

  @override
  Widget build(BuildContext context) {
    // Determine color based on status
    Color statusColor;
    switch (status) {
      case 'Accepted':
        statusColor = XColors.primary;
        break;
      case 'Rejected':
        statusColor = XColors.danger;
        break;
      case 'Pending':
      default:
        statusColor = XColors.warning;
        break;
    }

    final invC = Get.find<SessionInvitesController>();
    final inv = invite;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Image & Gradient
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: Image(
                    image: _img(inv?.sessionImageUrl ?? 'assets/images/gym.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 70,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: XColors.primaryText,
                              fontWeight: FontWeight.w500,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            // Keep UI text formatting; show real datetime if available
                            (inv?.sessionDateTime != null)
                                ? _format(inv!.sessionDateTime!)
                                : '11 Dec, 09:30 AM',
                            style: const TextStyle(color: XColors.primary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grouped Tag
                if (isGrouped)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Grouped',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: XColors.primaryText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              children: [
                Text(
                  // keeping your same placeholder (no UI change)
                  'But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system...',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 11,
                    color: XColors.bodyText.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),

                // Invited by row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Invited by', style: TextStyle(color: Colors.blue, fontSize: 12)),
                    GestureDetector(
                      onTap: nameOnTap,
                      child: Text(
                        (inv?.invitedByName?.trim().isNotEmpty == true)
                            ? inv!.invitedByName!.trim()
                            : "Ali Haider",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: XColors.bodyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Sent to row if grouped
                if (isGrouped)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sent to', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      Text(
                        '$sentTo people',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: XColors.bodyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (isGrouped)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Group', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      Text(
                        'Gym Buddies',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: XColors.bodyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Location', style: TextStyle(color: Colors.blue, fontSize: 12)),
                    Text(
                      (inv?.sessionLocationText?.trim().isNotEmpty == true)
                          ? inv!.sessionLocationText!.trim()
                          : "Fitness 360 Commercial Area Branch",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: XColors.bodyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.blue, fontSize: 12)),
                    Text(
                      status,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Accept/Reject buttons only if pending
                if (status == 'Pending') ...[
                  const SizedBox(height: 16),
                  Obx(() {
                    final busy = inv != null && invC.busyInviteIds.contains(inv.id);
                    return Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: (busy || inv == null) ? null : () => invC.accept(inv),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: XColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                busy ? '...' : 'Accept',
                                style: const TextStyle(
                                  color: XColors.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: (busy || inv == null) ? null : () => invC.decline(inv),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: XColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                busy ? '...' : 'Reject',
                                style: const TextStyle(
                                  color: XColors.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _format(DateTime dt) {
    // Keep it simple (no intl dependency)
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $hh:$mm';
  }
}
