import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/all_session_screen_card.dart';
import '../../../common/widgets/no_data_illustrations.dart';
import '../../../domain/models/sessions/session_invite.dart';
import '../../../domain/repos/repo_provider.dart';
import '../profile/buddy_profile_screen.dart';

class AllSessionInvitesScreen extends StatefulWidget {
  const AllSessionInvitesScreen({super.key});

  @override
  State<AllSessionInvitesScreen> createState() => _AllSessionInvitesScreenState();
}

class _AllSessionInvitesScreenState extends State<AllSessionInvitesScreen> {
  String _selectedFilter = 'Pending';

  Repos get repos => Get.find<Repos>();

  InviteStatus _statusFromUi(String filter) {
    switch (filter) {
      case 'Accepted':
        return InviteStatus.accepted;
      case 'Rejected':
        return InviteStatus.declined; // maps to your Firestore "declined"
      case 'Pending':
      default:
        return InviteStatus.pending;
    }
  }

  String _uiStatusFromInvite(InviteStatus s) {
    switch (s) {
      case InviteStatus.accepted:
        return 'Accepted';
      case InviteStatus.declined:
      case InviteStatus.cancelled:
        return 'Rejected';
      case InviteStatus.pending:
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusFromUi(_selectedFilter);

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
                child: StreamBuilder<List<SessionInvite>>(
                  stream: repos.sessionRepo.watchMySessionInvitesByStatus(
                    status: status,
                    limit: 100,
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Failed to load session invites.\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: XColors.bodyText.withValues(alpha: .7),
                            ),
                          ),
                        ),
                      );
                    }

                    final list = snap.data ?? const <SessionInvite>[];

                    if (list.isEmpty) {
                      return const NoDataIllustration(
                        imagePath: 'assets/images/no-sessions.png',
                        message: 'No session invites found',
                      );
                    }

                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final inv = list[index];

                        // buddyUserId = who invited me (invitedByUserId)
                        final buddyUserId = (inv.invitedByUserId).trim();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: AllSessionsScreenCard(
                            // Keep the UI; just populate from Firestore snapshot fields
                            title: (inv.sessionCategory?.trim().isNotEmpty == true)
                                ? inv.sessionCategory!.trim()
                                : 'Session',
                            status: _uiStatusFromInvite(inv.status),
                            isGrouped: false,
                            sentTo: 0,

                            // IMPORTANT: if you updated card to accept invite object, pass it
                            invite: inv,

                            nameOnTap: () {
                              if (buddyUserId.isEmpty) return;

                              Get.to(
                                    () => BuddyProfileScreen(
                                  buddyUserId: buddyUserId,
                                  scenario: BuddyScenario.existingBuddy,
                                  // conversationId not part of session invite model
                                  conversationId: null,
                                ),
                              );
                            },
                          ),
                        );
                      },
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
        bgColor = isSelected ? Colors.deepOrange : Colors.deepOrange.withValues(alpha: 0.2);
        break;
      case 'Accepted':
        bgColor = isSelected ? XColors.primary : XColors.primary.withValues(alpha: 0.2);
        break;
      case 'Rejected':
        bgColor = isSelected ? XColors.danger : XColors.danger.withValues(alpha: 0.2);
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
