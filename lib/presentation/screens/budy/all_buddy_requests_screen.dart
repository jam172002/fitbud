import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/buddy_request_card.dart';
import '../../../common/widgets/no_data_illustrations.dart';
import 'package:fitbud/utils/enums.dart';

import '../profile/buddy_profile_screen.dart';
import 'controller/buddy_controller.dart';

class AllBuddyRequestsScreen extends StatefulWidget {
  const AllBuddyRequestsScreen({super.key});

  @override
  State<AllBuddyRequestsScreen> createState() => _AllBuddyRequestsScreenState();
}

class _AllBuddyRequestsScreenState extends State<AllBuddyRequestsScreen> {
  String _selectedFilter = 'Pending';

  BuddyController get buddyC => Get.find<BuddyController>();

  List<BuddyRequestVM> _filter(List<BuddyRequestVM> list) {
    switch (_selectedFilter) {
      case 'Accepted':
        return list.where((e) => e.req.status.name == 'accepted').toList();
      case 'Rejected':
        return list.where((e) => e.req.status.name == 'rejected').toList();
      case 'Pending':
      default:
        return list.where((e) => e.req.status.name == 'pending').toList();
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
                child: Obx(() {
                  // incoming requests (received by me)
                  final incoming = _filter(buddyC.incoming);

                  if (incoming.isEmpty) {
                    return const NoDataIllustration(
                      imagePath: 'assets/images/no-requests.png',
                      message: 'No Requests Found',
                    );
                  }

                  return ListView.builder(
                    itemCount: incoming.length,
                    itemBuilder: (context, index) {
                      final item = incoming[index];
                      final u = item.other;

                      final busy = buddyC.busyRequestIds.contains(item.req.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BuddyRequestCard(
                          name: (u.displayName ?? 'User'),
                          gender: (u.gender ?? ''),
                          age: _ageFromDob(u.dob)?.toString() ?? '',
                          interest: (u.favouriteActivity ?? ''),
                          location: (u.city ?? ''),
                          time: _timeAgo(item.req.createdAt),
                          avatar: (u.photoUrl?.isNotEmpty == true)
                              ? u.photoUrl!
                              : 'assets/images/buddy.jpg',
                          status: item.req.status.name, // pending/accepted/rejected
                          onAccept: () {
                            if (busy) return;
                            buddyC.acceptRequest(item.req.id);
                          },
                          onReject: () {
                            if (busy) return;
                            buddyC.rejectRequest(item.req.id);
                          },
                          onCardTap: () {
                            final buddyId = u.id;
                            if (buddyId.isEmpty) return;

                            Get.to(
                                  () => BuddyProfileScreen(
                                buddyUserId: buddyId,
                                scenario: BuddyScenario.requestReceived,
                                requestId: item.req.id, // IMPORTANT for accept/reject flow
                                // conversationId: null (not applicable here)
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }),
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

  int? _ageFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
