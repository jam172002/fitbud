import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fitbud/presentation/screens/chats/widget/add_members_to_group_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/chat_input_bar.dart';
import 'package:fitbud/presentation/screens/chats/widget/full_screen_media.dart';
import 'package:fitbud/presentation/screens/chats/widget/members_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/received_media_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/received_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/sent_media_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/sent_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/typing_indicator.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../common/bottom_sheets/session_invite_sheet.dart';
import '../../../common/widgets/two_buttons_dialog.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/chat/conversation_participant.dart';
import '../../../domain/models/chat/message.dart';
import '../../../domain/repos/repo_provider.dart';
import '../authentication/controllers/auth_controller.dart';
import '../profile/buddy_profile_screen.dart';
import 'package:fitbud/utils/enums.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  // UI hints
  final bool isGroup;
  final String groupName;

  // optional: for direct header
  final String directOtherUserId;
  final String directTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.isGroup = false,
    this.groupName = 'Gym Buddies',
    this.directOtherUserId = '',
    this.directTitle = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final Repos repos = Get.find<Repos>();
  final AuthController authC = Get.find<AuthController>();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  bool _isTyping = false; // (keep UI; wire later)
  bool _sending = false;

  // for media preview only (optional)
  final List<Map<String, dynamic>> _localMediaMessages = [];

  @override
  void initState() {
    super.initState();
    _markRead();

    // keep your typing indicator demo off by default
    _isTyping = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await repos.chatRepo.markConversationRead(widget.conversationId);
    } catch (_) {}
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return "${hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -------------------- send text --------------------
  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await repos.chatRepo.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.text,
        text: text,
      );

      _messageController.clear();
      _scrollToBottom();
      await _markRead();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send: $e",
        backgroundColor: XColors.danger.withOpacity(.2),
        colorText: XColors.primaryText,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // -------------------- media (UI kept, sending can be added later) --------------------
  Future<void> _pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
        file.path.toLowerCase().endsWith('.mov');

    // Keep your UI feel: show local bubble immediately (preview).
    setState(() {
      _localMediaMessages.add({
        'file': file,
        'isVideo': isVideo,
        'time': _timeLabel(DateTime.now()),
        'isSent': true,
      });
    });
    _scrollToBottom();

    // Actual upload + send mediaUrl should be wired through MediaRepo.
    Get.snackbar(
      "Info",
      "Media preview added. Upload/sending mediaUrl can be enabled next.",
      backgroundColor: XColors.primary.withOpacity(.2),
      colorText: XColors.primaryText,
    );
  }

  void _openFullScreen(File file, {required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMedia(
          path: file.path,
          isVideo: isVideo,
          isAsset: false,
        ),
      ),
    );
  }

  // -------------------- header helpers --------------------
  Future<AppUser?> _loadDirectOtherUser() async {
    final otherId = widget.directOtherUserId.trim();
    if (otherId.isEmpty) return null;
    try {
      return await repos.authRepo.getUser(otherId);
    } catch (_) {
      return null;
    }
  }

  Stream<List<ConversationParticipant>> _participants$() {
    return repos.chatRepo.watchParticipants(widget.conversationId);
  }

  // -------------------- members dialog (group) --------------------
  Future<void> _openMembersDialog() async {
    final parts = await _participants$().first;
    final members = <Map<String, String>>[];

    for (final p in parts) {
      try {
        final u = await repos.authRepo.getUser(p.userId);
        members.add({
          'name': (u.displayName ?? '').isEmpty ? 'User' : (u.displayName ?? ''),
          'avatar': (u.photoUrl ?? ''),
        });
      } catch (_) {
        members.add({'name': 'User', 'avatar': ''});
      }
    }

    showDialog(
      context: context,
      builder: (_) => MembersDialog(
        members: members,
        onGroupMemberTap: () {
          Get.to(() => BuddyProfileScreen(scenario: BuddyScenario.existingBuddy));
        },
      ),
    );
  }

  // -------------------- add members (group) --------------------
  Future<void> _openAddMembersDialog() async {
    // For now we keep your existing UI dialog.
    // To make it real: you should pass real buddies list (ids + names + avatar).
    final allBuddies = [
      {'name': 'Ali', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Sufyan', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Hassan', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Ayesha', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Zara', 'avatar': 'assets/images/buddy.jpg'},
    ];

    showDialog(
      context: context,
      builder: (_) => AddMembersDialog(
        allBuddies: allBuddies,
        existingMembers: const [],
        onConfirm: (selected) async {
          // This dialog currently returns name/avatar, not userIds.
          // Real implementation should return userIds and call:
          // await repos.chatRepo.addMembers(conversationId: widget.conversationId, userIds: ids);
          Get.snackbar(
            "Info",
            "Hook this dialog to real userIds next, then call chatRepo.addMembers().",
            backgroundColor: XColors.primary.withOpacity(.2),
            colorText: XColors.primaryText,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = authC.authUser.value?.uid ?? '';

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: AppBar(
        backgroundColor: XColors.primaryBG,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (!widget.isGroup && widget.directOtherUserId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BuddyProfileScreen(
                    scenario: BuddyScenario.existingBuddy,
                    buddyId: widget.directOtherUserId,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: FutureBuilder<AppUser?>(
              future: widget.isGroup ? Future.value(null) : _loadDirectOtherUser(),
              builder: (_, snap) {
                final u = snap.data;
                final provider = (u?.photoUrl?.trim().isNotEmpty == true)
                    ? NetworkImage(u!.photoUrl!)
                    : const AssetImage('assets/images/buddy.jpg') as ImageProvider;

                return CircleAvatar(radius: 18, backgroundImage: provider);
              },
            ),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            if (!widget.isGroup && widget.directOtherUserId.isNotEmpty) {
              Get.to(() => BuddyProfileScreen(
                scenario: BuddyScenario.existingBuddy,
                buddyId: widget.directOtherUserId,
              ));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isGroup ? widget.groupName : (widget.directTitle.isEmpty ? "Chat" : widget.directTitle),
                style: const TextStyle(
                  color: XColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.isGroup)
                StreamBuilder<List<ConversationParticipant>>(
                  stream: _participants$(),
                  builder: (_, snap) {
                    final c = (snap.data ?? const []).length;
                    return Text(
                      "$c members",
                      style: const TextStyle(
                        color: XColors.secondaryText,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          if (widget.isGroup)
            GestureDetector(
              onTap: _openAddMembersDialog,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Iconsax.user_add, color: Colors.blue, size: 22),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsis_vertical, color: XColors.primaryText),
            color: XColors.secondaryBG,
            onSelected: (value) async {
              switch (value) {
                case 'session_invite':
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SessionInviteSheet(
                      isGroup: widget.isGroup,
                      groupName: widget.groupName,
                      membersCount: 0,
                    ),
                  );
                  break;

                case 'members':
                  await _openMembersDialog();
                  break;

                case 'leave':
                  showDialog(
                    context: context,
                    builder: (_) => XButtonsConfirmationDialog(
                      message: "Are you sure you want to leave the group?",
                      icon: Iconsax.logout,
                      iconColor: Colors.red,
                      confirmText: "Leave",
                      cancelText: "Cancel",
                      onConfirm: () async {
                        await repos.chatRepo.leaveConversation(widget.conversationId);
                      },
                    ),
                  );
                  break;

                case 'delete_chat':
                // For now: you can implement delete by soft-deleting or removing participants + messages.
                  showDialog(
                    context: context,
                    builder: (_) => XButtonsConfirmationDialog(
                      message: "Delete chat is not implemented yet.",
                      icon: Iconsax.trash,
                      iconColor: Colors.red,
                      confirmText: "Ok",
                      cancelText: "Cancel",
                      onConfirm: () {},
                    ),
                  );
                  break;

                case 'remove_buddy':
                // TODO: remove buddy logic (not chat repo).
                  break;
              }
            },
            itemBuilder: (_) {
              if (widget.isGroup) {
                return [
                  PopupMenuItem(
                    value: 'session_invite',
                    child: Row(
                      children: const [
                        Icon(Iconsax.message_text, size: 18, color: XColors.primaryText),
                        SizedBox(width: 8),
                        Text("Session Invite", style: TextStyle(color: XColors.bodyText)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'members',
                    child: Row(
                      children: const [
                        Icon(Iconsax.people, size: 18, color: XColors.primaryText),
                        SizedBox(width: 8),
                        Text("Members", style: TextStyle(color: XColors.bodyText)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Iconsax.logout, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Leave", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              } else {
                return [
                  PopupMenuItem(
                    value: 'session_invite',
                    child: Row(
                      children: const [
                        Icon(Iconsax.message_text, size: 18, color: XColors.primaryText),
                        SizedBox(width: 8),
                        Text("Session Invite", style: TextStyle(color: XColors.bodyText)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_chat',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Delete Chat", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove_buddy',
                    child: Row(
                      children: [
                        Icon(Iconsax.user_remove, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Remove Buddy", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: repos.chatRepo.watchMessages(widget.conversationId, limit: 200),
              builder: (context, snap) {
                final msgs = snap.data ?? const <Message>[];

                // mark read on updates (safe)
                if (snap.hasData) {
                  _markRead();
                }

                // Reverse list: your repo returns DESC (newest first).
                // Your UI expects chronological; we can keep descending but scroll accordingly.
                // Your existing UI uses "maxScrollExtent" approach; here we use reverse list view.
                final combined = <dynamic>[
                  ..._localMediaMessages,
                  ...msgs,
                ];

                if (combined.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(
                        color: XColors.bodyText.withOpacity(.7),
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: combined.length + (_isTyping ? 1 : 0) + 1,
                  itemBuilder: (_, index) {
                    if (index == combined.length + (_isTyping ? 1 : 0)) {
                      return const SizedBox(height: 8);
                    }

                    if (index == combined.length + 1 && _isTyping) {
                      return const TypingIndicator(avatar: 'assets/images/buddy.jpg');
                    }

                    // Date separator placeholder (keep your UI)
                    if (index == combined.length + (_isTyping ? 1 : 0)) {
                      return _dateSeparator("Today");
                    }

                    final item = combined[index];

                    // Local media preview bubble
                    if (item is Map<String, dynamic> && item.containsKey('file')) {
                      final file = item['file'] as File;
                      final isVideo = item['isVideo'] as bool;
                      final time = item['time'] as String;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: SentMedia(
                          file: file,
                          isVideo: isVideo,
                          time: time,
                          onTap: () => _openFullScreen(file, isVideo: isVideo),
                        ),
                      );
                    }

                    // Firestore message bubble
                    final m = item as Message;
                    final isSent = m.senderUserId == uid;
                    final time = _timeLabel(m.createdAt);

                    // Only text supported here; you can expand for image/video by checking m.type + mediaUrl
                    if (m.type != MessageType.text) {
                      // Keep your UI: show as text fallback (preview)
                      final fallback = m.text.isNotEmpty ? m.text : 'Message';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: isSent
                            ? SentMessage(message: fallback, time: time)
                            : ReceivedMessage(
                          message: fallback,
                          time: time,
                          senderName: 'User',
                          avatar: 'assets/images/buddy.jpg',
                          isGroup: widget.isGroup,
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: isSent
                          ? SentMessage(message: m.text, time: time)
                          : ReceivedMessage(
                        message: m.text,
                        time: time,
                        senderName: 'User',
                        avatar: 'assets/images/buddy.jpg',
                        isGroup: widget.isGroup,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          ChatInputBar(
            controller: _messageController,
            onSend: _sendTextMessage,
            onPickMedia: _pickMedia,
          ),
        ],
      ),
    );
  }

  Widget _dateSeparator(String text) => Center(
    child: Text(text, style: const TextStyle(color: XColors.primaryText, fontSize: 12)),
  );
}
