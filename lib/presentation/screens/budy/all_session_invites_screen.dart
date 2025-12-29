import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/all_session_screen_card.dart';
import '../../../common/widgets/no_data_illustrations.dart';
import '../profile/buddy_profile_screen.dart';

class AllSessionInvitesScreen extends StatefulWidget {
  const AllSessionInvitesScreen({super.key});

  @override
  State<AllSessionInvitesScreen> createState() => _AllSessionInvitesScreenState();
}

class _AllSessionInvitesScreenState extends State<AllSessionInvitesScreen> {
  String _selectedFilter = 'Pending';

  // Dummy data for each status
  // IMPORTANT: include buddyUserId (required by BuddyProfileScreen) + optional conversationId
  final List<Map<String, dynamic>> _pendingList = List.generate(
    5,
        (index) => {
      'title': 'Pending $index',
      'status': 'Pending',
      'grouped': index % 2 == 0,
      'sentTo': 10 + index,
      'buddyUserId': 'buddy_user_$index',
      'conversationId': 'conv_pending_$index',
    },
  );

  final List<Map<String, dynamic>> _acceptedList = List.generate(
    3,
        (index) => {
      'title': 'Accepted $index',
      'status': 'Accepted',
      'grouped': index % 2 == 1,
      'sentTo': 5 + index,
      'buddyUserId': 'buddy_user_acc_$index',
      'conversationId': 'conv_accepted_$index',
    },
  );

  final List<Map<String, dynamic>> _rejectedList = List.generate(
    2,
        (index) => {
      'title': 'Rejected $index',
      'status': 'Rejected',
      'grouped': false,
      'sentTo': 0,
      'buddyUserId': 'buddy_user_rej_$index',
      'conversationId': 'conv_rejected_$index',
    },
  );

  List<Map<String, dynamic>> get _currentList {
    switch (_selectedFilter) {
      case 'Accepted':
        return _acceptedList;
      case 'Rejected':
        return _rejectedList;
      case 'Pending':
      default:
        return _pendingList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: XAppBar(title: 'Session Invites'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildFilterChip('Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Accepted'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _currentList.isEmpty
                    ? const NoDataIllustration(
                  imagePath: 'assets/images/no-sessions.png',
                  message: 'No session invites found',
                )
                    : ListView.builder(
                  itemCount: _currentList.length,
                  itemBuilder: (context, index) {
                    final item = _currentList[index];

                    final String buddyUserId =
                    (item['buddyUserId'] ?? '').toString();
                    final String? conversationId =
                    (item['conversationId']?.toString().isNotEmpty == true)
                        ? item['conversationId'].toString()
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: AllSessionsScreenCard(
                        title: item['title'],
                        status: item['status'],
                        isGrouped: item['grouped'],
                        sentTo: item['sentTo'],
                        nameOnTap: () {
                          if (buddyUserId.isEmpty) return;

                          Get.to(
                                () => BuddyProfileScreen(
                              buddyUserId: buddyUserId,
                              scenario: BuddyScenario.existingBuddy,
                              conversationId: conversationId,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    Color bgColor;

    switch (label) {
      case 'Pending':
        bgColor =
        isSelected ? Colors.deepOrange : Colors.deepOrange.withOpacity(0.2);
        break;
      case 'Accepted':
        bgColor =
        isSelected ? XColors.primary : XColors.primary.withOpacity(0.2);
        break;
      case 'Rejected':
        bgColor =
        isSelected ? XColors.danger : XColors.danger.withOpacity(0.2);
        break;
      default:
        bgColor = XColors.bodyText;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
