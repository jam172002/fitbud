import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/instance_manager.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/buddy_request_card.dart';
import '../../../common/widgets/no_data_illustrations.dart';
import '../profile/buddy_profile_screen.dart';

class AllBuddyRequestsScreen extends StatefulWidget {
  const AllBuddyRequestsScreen({super.key});

  @override
  State<AllBuddyRequestsScreen> createState() => _AllBuddyRequestsScreenState();
}

class _AllBuddyRequestsScreenState extends State<AllBuddyRequestsScreen> {
  String _selectedFilter = 'Pending';

  // Remove the comment to test the ui for no data
  // final List<Map<String, String>> _pendingRequests = [];
  // final List<Map<String, String>> _acceptedRequests = [];
  // final List<Map<String, String>> _rejectedRequests = [];

  // Dummy data for Buddy Requests
  final List<Map<String, String>> _pendingRequests = List.generate(
    5,
    (index) => {
      'name': 'Alice $index',
      'gender': 'Female',
      'age': '${20 + index}',
      'interest': 'Yoga',
      'location': 'City ${index + 1}',
      'time': '${index + 1}h ago',
      'avatar': 'assets/images/buddy.jpg',
      'status': 'pending',
    },
  );

  final List<Map<String, String>> _acceptedRequests = List.generate(
    3,
    (index) => {
      'name': 'Bob $index',
      'gender': 'Male',
      'age': '${25 + index}',
      'interest': 'Gym',
      'location': 'City ${index + 5}',
      'time': '${index + 2}h ago',
      'avatar': 'assets/images/buddy.jpg',
      'status': 'accepted',
    },
  );

  final List<Map<String, String>> _rejectedRequests = List.generate(
    2,
    (index) => {
      'name': 'Charlie $index',
      'gender': 'Male',
      'age': '${22 + index}',
      'interest': 'Running',
      'location': 'City ${index + 8}',
      'time': '${index + 3}h ago',
      'avatar': 'assets/images/buddy.jpg',
      'status': 'rejected',
    },
  );

  List<Map<String, String>> get _currentList {
    switch (_selectedFilter) {
      case 'Accepted':
        return _acceptedRequests;
      case 'Rejected':
        return _rejectedRequests;
      case 'Pending':
      default:
        return _pendingRequests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: XAppBar(title: 'Buddy Requests'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Filter Chips
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
              // Buddy Requests List
              Expanded(
                child: _currentList.isEmpty
                    ? const NoDataIllustration(
                        imagePath: 'assets/images/no-requests.png',
                        message: 'No Requests Found',
                      )
                    : ListView.builder(
                        itemCount: _currentList.length,
                        itemBuilder: (context, index) {
                          final buddy = _currentList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: BuddyRequestCard(
                              name: buddy['name']!,
                              gender: buddy['gender']!,
                              age: buddy['age']!,
                              interest: buddy['interest']!,
                              location: buddy['location']!,
                              time: buddy['time']!,
                              avatar: buddy['avatar']!,
                              status: buddy['status']!,
                              onAccept: () {},
                              onReject: () {},
                              onCardTap: () {
                                Get.to(
                                  () => BuddyProfileScreen(
                                    scenario: BuddyScenario.requestReceived,
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
