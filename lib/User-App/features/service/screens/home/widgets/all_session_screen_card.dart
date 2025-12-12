import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

class AllSessionsScreenCard extends StatelessWidget {
  final String title;
  final String status;
  final bool isGrouped;
  final int sentTo;
  final VoidCallback nameOnTap;

  const AllSessionsScreenCard({
    super.key,
    this.title = 'Gym Practice',
    this.status = 'Pending',
    this.isGrouped = false,
    this.sentTo = 0,
    required this.nameOnTap,
  });

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
                  child: Image.asset(
                    'assets/images/gym.jpeg',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                            '11 Dec, 09:30 AM',
                            style: const TextStyle(
                              color: XColors.primary,
                              fontSize: 11,
                            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.9),
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
                    const Text(
                      'Invited by',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: nameOnTap,
                      child: const Text(
                        "Ali Haider",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
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
                      const Text(
                        'Sent to',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                      Text(
                        '$sentTo people',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
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
                    children: [
                      const Text(
                        'Group',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
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
                  children: const [
                    Text(
                      'Location',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    Text(
                      "Fitness 360 Commercial Area Branch",
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
                    const Text(
                      'Status',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: XColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Accept',
                              style: TextStyle(
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
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: XColors.danger,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                color: XColors.primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
