// lib/presentation/features/profile/buddy_profile_screen.dart
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/bottom_sheets/session_invite_sheet.dart';
import '../../../common/widgets/simple_dialog.dart';
import '../../../common/widgets/two_buttons_dialog.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/repos/repo_provider.dart';
import '../budy/controller/buddy_controller.dart';
import '../chats/chat_screen.dart';
import '../chats/widget/full_screen_media.dart';

class BuddyProfileScreen extends StatelessWidget {
  final String buddyUserId;
  final BuddyScenario scenario;
  final String? requestId; // for accept/reject screen
  final String? conversationId; // for chat screen (existing buddy)

  const BuddyProfileScreen({
    super.key,
    required this.buddyUserId,
    required this.scenario,
    this.requestId,
    this.conversationId,
  });

  Repos get repos => Get.find<Repos>();
  BuddyController get buddyC => Get.find<BuddyController>();

  int? _ageFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  ImageProvider _avatar(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty || u == 'null') return const AssetImage('assets/images/buddy.jpg');
    if (u.startsWith('http://') || u.startsWith('https://')) return NetworkImage(u);
    return AssetImage(u);
  }

  String _safe(String? v, [String fallback = '']) {
    final t = (v ?? '').trim();
    return t.isEmpty || t == 'null' ? fallback : t;
  }

  void _okDialog(String msg) {
    Get.dialog(
      SimpleDialogWidget(
        message: msg,
        icon: LucideIcons.circle_check,
        iconColor: XColors.primary,
        buttonText: "Ok",
        onOk: () => Get.back(),
      ),
    );
  }

  void _errDialog(Object e) {
    Get.dialog(
      SimpleDialogWidget(
        message: e.toString(),
        icon: LucideIcons.circle_x,
        iconColor: XColors.danger,
        buttonText: "Ok",
        onOk: () => Get.back(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: XAppBar(
        title: '',
        actions: [
          if (scenario == BuddyScenario.notBuddy)
            _NotBuddyButton(buddyUserId: buddyUserId),
          if (scenario == BuddyScenario.requestReceived)
            _RequestActionButtons(requestId: requestId),
          if (scenario == BuddyScenario.existingBuddy)
            _ExistingBuddyDropdown(
              buddyUserId: buddyUserId,
              conversationId: conversationId,
            ),
        ],
      ),
      body: FutureBuilder<AppUser>(
        future: repos.authRepo.getUser(buddyUserId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load profile.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: XColors.bodyText.withValues( alpha: .7)),
                  ),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const SafeArea(child: Center(child: Text('User not found')));
          }

          final u = snap.data!;
          final age = _ageFromDob(u.dob);
          final displayName = _safe(u.displayName, 'User');
          final gender = _safe(u.gender);
          final fav = _safe(u.favouriteActivity);
          final gymName = _safe(u.gymName);
          final city = _safe(u.city);
          final about = _safe(u.about);
          final activities = (u.activities ?? <String>[]);
          final interests = activities.isNotEmpty ? activities.take(15).toList() : <String>[];

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final path = _safe(u.photoUrl);
                            if (path.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenMedia(
                                  path: path,
                                  isVideo: false,
                                  isAsset: !(path.startsWith('http')),
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: _avatar(u.photoUrl),
                            backgroundColor: XColors.secondaryBG,
                            radius: 45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: XColors.primaryText,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (age != null)
                              _MetaItem(
                                icon: LucideIcons.calendar_days,
                                iconColor: Colors.amber,
                                text: '$age years old',
                              ),
                            if (age != null && gender.isNotEmpty) const SizedBox(width: 22),
                            if (gender.isNotEmpty)
                              _MetaItem(
                                icon: LucideIcons.venus,
                                iconColor: Colors.lightGreen,
                                text: gender,
                              ),
                            if ((age != null || gender.isNotEmpty) && fav.isNotEmpty)
                              const SizedBox(width: 22),
                            if (fav.isNotEmpty)
                              _MetaItem(
                                icon: LucideIcons.heart,
                                iconColor: Colors.pink,
                                text: fav,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (gymName.isNotEmpty)
                          _CenterRow(
                            icon: LucideIcons.dumbbell,
                            iconColor: Colors.deepPurple,
                            text: gymName,
                          ),
                        if (city.isNotEmpty)
                          _CenterRow(
                            icon: LucideIcons.map_pin,
                            iconColor: Colors.blue,
                            text: city,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Interests",
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (interests.isEmpty)
                          Text(
                            'No interests added yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: XColors.bodyText.withValues( alpha: .6),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: interests
                                .map((item) => BuddyProfileInterestItem(label: item))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          about.isEmpty ? 'No bio added yet.' : about,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 12,
                            color: XColors.bodyText.withValues( alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _MetaItem({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 11),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: XColors.bodyText, fontSize: 10),
        ),
      ],
    );
  }
}

class _CenterRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _CenterRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 11),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: XColors.bodyText, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class BuddyProfileInterestItem extends StatelessWidget {
  final String label;
  const BuddyProfileInterestItem({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: XColors.primary.withValues( alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: XColors.bodyText, fontSize: 11),
      ),
    );
  }
}

class _NotBuddyButton extends StatefulWidget {
  final String buddyUserId;
  const _NotBuddyButton({required this.buddyUserId});

  @override
  State<_NotBuddyButton> createState() => _NotBuddyButtonState();
}

class _NotBuddyButtonState extends State<_NotBuddyButton> {
  BuddyController get buddyC => Get.find<BuddyController>();

  bool _isInvited = false;

  Future<void> _handleInvite() async {
    if (_isInvited) return;

    setState(() => _isInvited = true);
    try {
      await buddyC.inviteUser(widget.buddyUserId);
      Get.dialog(
        SimpleDialogWidget(
          message: "Invitation sent to the user.",
          icon: LucideIcons.circle_check,
          iconColor: XColors.primary,
          buttonText: "Ok",
          onOk: () => Get.back(),
        ),
      );
    } catch (e) {
      setState(() => _isInvited = false);
      Get.dialog(
        SimpleDialogWidget(
          message: e.toString(),
          icon: LucideIcons.circle_x,
          iconColor: XColors.danger,
          buttonText: "Ok",
          onOk: () => Get.back(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isInvited ? LucideIcons.circle_check : LucideIcons.circle_plus,
        color: _isInvited ? XColors.primary : Colors.blue,
      ),
      onPressed: _handleInvite,
    );
  }
}

class _RequestActionButtons extends StatelessWidget {
  final String? requestId;
  const _RequestActionButtons({required this.requestId});

  BuddyController get buddyC => Get.find<BuddyController>();

  Future<void> _acceptRequest() async {
    final id = (requestId ?? '').trim();
    if (id.isEmpty) return;

    try {
      await buddyC.acceptRequest(id);
      Get.dialog(
        SimpleDialogWidget(
          message: "Request accepted.",
          icon: LucideIcons.circle_check,
          iconColor: XColors.primary,
          buttonText: "Ok",
          onOk: () => Get.back(),
        ),
      );
    } catch (e) {
      Get.dialog(
        SimpleDialogWidget(
          message: e.toString(),
          icon: LucideIcons.circle_x,
          iconColor: XColors.danger,
          buttonText: "Ok",
          onOk: () => Get.back(),
        ),
      );
    }
  }

  Future<void> _rejectRequest() async {
    final id = (requestId ?? '').trim();
    if (id.isEmpty) return;

    try {
      await buddyC.rejectRequest(id);
      Get.dialog(
        SimpleDialogWidget(
          message: "Request rejected.",
          icon: LucideIcons.circle_check,
          iconColor: XColors.primary,
          buttonText: "Ok",
          onOk: () => Get.back(),
        ),
      );
    } catch (e) {
      Get.dialog(
        SimpleDialogWidget(
          message: e.toString(),
          icon: LucideIcons.circle_x,
          iconColor: XColors.danger,
          buttonText: "Ok",
          onOk: () => Get.back(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = (requestId != null) && buddyC.busyRequestIds.contains(requestId);

    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.circle_check, color: XColors.primary),
          onPressed: busy ? null : _acceptRequest,
        ),
        IconButton(
          icon: const Icon(LucideIcons.circle_x, color: XColors.danger),
          onPressed: busy ? null : _rejectRequest,
        ),
      ],
    );
  }
}

class _ExistingBuddyDropdown extends StatelessWidget {
  final String buddyUserId;
  final String? conversationId;

  const _ExistingBuddyDropdown({
    required this.buddyUserId,
    required this.conversationId,
  });

  void _createSession(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionInviteSheet(invitedUserId: buddyUserId),
    );

  }

  Future<void> _startChat(BuildContext context) async {
    final repos = Get.find<Repos>();
    final cid = await repos.chatRepo.getOrCreateDirectConversation(otherUserId: buddyUserId);

    Get.to(() => ChatScreen(
      isGroup: false,
      conversationId: cid,
      directOtherUserId: buddyUserId,
    ));

  }

  void _removeBuddy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => XButtonsConfirmationDialog(
        message: "Are you sure you want to remove this buddy?",
        icon: Iconsax.user_remove,
        iconColor: Colors.red,
        confirmText: "Remove",
        cancelText: "Cancel",
        onConfirm: () {
          // keep existing UI; implement removal later if your Friendship repo method exists
          Get.back();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.ellipsis_vertical, color: XColors.primaryText),
      color: XColors.secondaryBG,
      onSelected: (value) {
        switch (value) {
          case 'create_session':
            _createSession(context);
            break;
          case 'chat':
            _startChat(context);
            break;
          case 'remove_buddy':
            _removeBuddy(context);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'create_session',
          child: Text("Create Session", style: TextStyle(color: XColors.bodyText)),
        ),
        PopupMenuItem(
          value: 'chat',
          child: Text("Chat", style: TextStyle(color: XColors.bodyText)),
        ),
        const PopupMenuItem(
          value: 'remove_buddy',
          child: Text(
            "Remove from Buddies",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
