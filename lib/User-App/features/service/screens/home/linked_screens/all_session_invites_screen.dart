import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:fitbud/User-App/features/personalization/screens/profile/buddy_profile_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/all_session_screen_card.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/no_data_illustrations.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/instance_manager.dart';

class AllSessionInvitesScreen extends StatefulWidget {
  const AllSessionInvitesScreen({super.key});

  @override
  State<AllSessionInvitesScreen> createState() =>
      _AllSessionInvitesScreenState();
}

class _AllSessionInvitesScreenState extends State<AllSessionInvitesScreen> {
  // Currently selected filter
  String _selectedFilter = 'Pending';

  // Dummy data for each status
  final List<Map<String, dynamic>> _pendingList = List.generate(
    5,
    (index) => {
      'title': 'Pending $index',
      'status': 'Pending',
      'grouped': index % 2 == 0, // Some are grouped
      'sentTo': 10 + index,
    },
  );

  final List<Map<String, dynamic>> _acceptedList = List.generate(
    3,
    (index) => {
      'title': 'Accepted $index',
      'status': 'Accepted',
      'grouped': index % 2 == 1,
      'sentTo': 5 + index,
    },
  );

  final List<Map<String, dynamic>> _rejectedList = List.generate(
    2,
    (index) => {
      'title': 'Rejected $index',
      'status': 'Rejected',
      'grouped': false,
      'sentTo': 0,
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
              // Filter Chips with Expanded full width
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

              // Dummy vertical list for the selected filter
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: AllSessionsScreenCard(
                              title: item['title'],
                              status: item['status'],
                              isGrouped: item['grouped'],
                              sentTo: item['sentTo'],
                              nameOnTap: () {
                                Get.to(
                                  () => BuddyProfileScreen(
                                    scenario: BuddyScenario.existingBuddy,
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
    Color textColor = Colors.white;

    switch (label) {
      case 'Pending':
        bgColor = isSelected
            ? Colors.deepOrange
            : Colors.deepOrange.withOpacity(0.2);
        break;
      case 'Accepted':
        bgColor = isSelected
            ? XColors.primary
            : XColors.primary.withOpacity(0.2);
        break;
      case 'Rejected':
        bgColor = isSelected ? XColors.danger : XColors.danger.withOpacity(0.2);
        break;
      default:
        bgColor = XColors.bodyText;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
