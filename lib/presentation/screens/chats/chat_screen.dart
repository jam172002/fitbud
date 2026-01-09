import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fitbud/presentation/screens/chats/widget/add_members_to_group_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/chat_input_bar.dart';
import 'package:fitbud/presentation/screens/chats/widget/full_screen_media.dart';
import 'package:fitbud/presentation/screens/chats/widget/members_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/received_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/sent_media_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/sent_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/typing_indicator.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
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

  // -------------------- NEW: optimistic pending messages --------------------
  final List<_PendingText> _pendingTexts = [];

  @override
  void initState() {
    super.initState();
    _markRead();
    _isTyping = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _deleteChat() async {
    try {
      await repos.chatRepo.deleteChatForMe(widget.conversationId);

      // Close dialog first (if open) and go back to Inbox
      if (Get.isDialogOpen == true) Get.back();
      if (mounted) Get.back();

      Get.snackbar(
        "Deleted",
        "Chat removed for you.",
        backgroundColor: XColors.primary.withValues(alpha: .15),
        colorText: XColors.primaryText,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete chat: $e",
        backgroundColor: XColors.danger.withValues(alpha: .2),
        colorText: XColors.primaryText,
      );
    }
  }

  Future<void> _markRead() async {
    try {
      await repos.chatRepo.markConversationRead(widget.conversationId);
    } catch (_) {}
  }

  // OPTIONAL: only if you added it in ChatRepo. We call safely.
  Future<void> _markDeliveredSafe() async {
    try {
      // If method exists in your repo, it will work.
      // If not, it will throw NoSuchMethodError in runtime only if using dynamic.
      // Since repos.chatRepo is strongly typed, we must keep this call guarded by try/catch.
      // If your ChatRepo doesn't have markConversationDelivered yet, simply add it later.
      // ignore: invalid_use_of_protected_member
      // (No ignore needed; this is normal call if method exists.)
      // If not exists, you must add method in ChatRepo (recommended).
      // For now, we keep it in try-catch to avoid crashing if you add it later and forget to deploy.
      // If your analyzer fails because method doesn't exist, comment this line until you add it.
      // await repos.chatRepo.markConversationDelivered(widget.conversationId);
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

  // -------------------- NEW: pending reconciliation --------------------
  /// Removes local pending items when Firestore confirms a matching message.
  /// Since your current Message model/repo doesn't include clientMessageId yet,
  /// we use a safe heuristic:
  /// - same sender (me)
  /// - same text
  /// - createdAt is after pending.localTime - small tolerance
  void _reconcilePending({
    required List<Message> firestoreMessages,
    required String myUid,
  }) {
    if (_pendingTexts.isEmpty) return;

    final toRemoveIds = <String>{};

    for (final p in _pendingTexts) {
      final match = firestoreMessages.any((m) {
        if (m.senderUserId != myUid) return false;
        if (m.type != MessageType.text) return false;
        if (m.text.trim() != p.text.trim()) return false;

        final created = m.createdAt;
        if (created == null) return false;

        // tolerance: message time should be after pending time - 3s (server/client differences)
        final minOk = p.localTime.subtract(const Duration(seconds: 3));
        // also avoid matching very old messages (e.g. same text sent earlier)
        final maxOk = p.localTime.add(const Duration(minutes: 2));

        return !created.isBefore(minOk) && !created.isAfter(maxOk);
      });

      if (match) toRemoveIds.add(p.clientId);
    }

    if (toRemoveIds.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _pendingTexts.removeWhere((p) => toRemoveIds.contains(p.clientId));
      });
    });
  }

  // -------------------- send text (UPDATED: professional optimistic UX) --------------------
  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    // 1) Clear input immediately (WhatsApp-like)
    _messageController.clear();

    // 2) Show pending bubble instantly (clock)
    final clientId = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _pendingTexts.add(
        _PendingText(
          clientId: clientId,
          text: text,
          localTime: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    setState(() => _sending = true);
    try {
      await repos.chatRepo.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.text,
        text: text,
      );

      _scrollToBottom();
      await _markRead();
    } catch (e) {
      // Keep pending bubble (professional apps keep it for retry).
      // Also show toast.
      Get.snackbar(
        "Error",
        "Failed to send: $e",
        backgroundColor: XColors.danger.withValues(alpha: .2),
        colorText: XColors.primaryText,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // -------------------- media preview --------------------
  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final p = file.path.toLowerCase();
    final isVideo = p.endsWith('.mp4') || p.endsWith('.mov');

    setState(() {
      _localMediaMessages.add({
        'file': file,
        'isVideo': isVideo,
        'time': _timeLabel(DateTime.now()),
        'isSent': true,
      });
    });

    _scrollToBottom();

    Get.snackbar(
      "Info",
      "Media preview added. Upload/sending mediaUrl can be enabled next.",
      backgroundColor: XColors.primary.withValues(alpha: .2),
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
          'userId': p.userId, // include id for navigation
        });
      } catch (_) {
        members.add({'name': 'User', 'avatar': '', 'userId': p.userId});
      }
    }

    showDialog(
      context: context,
      builder: (_) => MembersDialog(
        members: members,
        // NOTE: your MembersDialog currently does not pass which member was tapped.
        // If it supports passing the tapped member/userId, use it to navigate.
        onGroupMemberTap: () {
          // Fallback: do nothing if we can't determine which member was tapped.
          // Recommended: update MembersDialog to provide userId in callback.
        },
      ),
    );
  }

  // -------------------- add members (group) --------------------
  Future<void> _openAddMembersDialog() async {
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
        onConfirm: (selected) {
          Get.snackbar(
            "Info",
            "Hook this dialog to real userIds next, then call chatRepo.addMembers().",
            backgroundColor: XColors.primary.withValues(alpha: .2),
            colorText: XColors.primaryText,
          );
        },
      ),
    );
  }

  void _openDirectProfile() {
    if (widget.isGroup) return;
    final buddyUserId = widget.directOtherUserId.trim();
    if (buddyUserId.isEmpty) return;

    Get.to(
          () => BuddyProfileScreen(
        buddyUserId: buddyUserId,
        scenario: BuddyScenario.existingBuddy,
        conversationId: widget.conversationId, // useful for chat dropdown
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

        // Leading avatar (tap to open profile on direct chat)
        leading: GestureDetector(
          onTap: _openDirectProfile,
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
          onTap: _openDirectProfile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isGroup
                    ? widget.groupName
                    : (widget.directTitle.isEmpty ? "Chat" : widget.directTitle),
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
            icon: const Icon(
              LucideIcons.ellipsis_vertical,
              color: XColors.primaryText,
            ),
            color: XColors.secondaryBG,
            onSelected: (value) {
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
                  _openMembersDialog();
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
                      onConfirm: () {
                        repos.chatRepo
                            .leaveConversation(widget.conversationId)
                            .then((_) => Get.back());
                      },
                    ),
                  );
                  break;

                case 'delete_chat':
                  showDialog(
                    context: context,
                    builder: (_) => XButtonsConfirmationDialog(
                      message:
                      "Delete chat for you? This will remove it from your inbox and clear message history for you.",
                      icon: Iconsax.trash,
                      iconColor: Colors.red,
                      confirmText: "Delete",
                      cancelText: "Cancel",
                      onConfirm: _deleteChat,
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
            child: StreamBuilder<DateTime?>(
              stream: repos.chatRepo.watchMyClearedAt(widget.conversationId),
              builder: (context, clearedSnap) {
                final clearedAt = clearedSnap.data;

                return StreamBuilder<List<ConversationParticipant>>(
                  stream: _participants$(),
                  builder: (context, partSnap) {
                    //final parts = partSnap.data ?? const <ConversationParticipant>[];

                    return StreamBuilder<List<Message>>(
                      stream: repos.chatRepo.watchMessages(widget.conversationId, limit: 200),
                      builder: (context, snap) {
                        final msgsRaw = snap.data ?? const <Message>[];

                        // Filter by clearedAt (hide older messages for this user)
                        final msgs = (clearedAt == null)
                            ? msgsRaw
                            : msgsRaw.where((m) {
                          final dt = m.createdAt; // DateTime?
                          if (dt == null) return true; // keep if unknown
                          return !dt.isBefore(clearedAt);
                        }).toList();

                        if (snap.hasData) {
                          _markRead();
                          _markDeliveredSafe(); // safe/no-op until you add repo method
                        }

                        // NEW: reconcile pending with Firestore confirmations
                        _reconcilePending(firestoreMessages: msgs, myUid: uid);

                        // Keep your existing combined behavior, but include pending texts
                        final combined = <dynamic>[
                          ..._localMediaMessages,
                          ..._pendingTexts,
                          ...msgs,
                        ];

                        if (combined.isEmpty) {
                          return Center(
                            child: Text(
                              'No messages yet.',
                              style: TextStyle(
                                color: XColors.bodyText.withValues(alpha: .7),
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
                            // bottom padding
                            if (index == combined.length + (_isTyping ? 1 : 0)) {
                              return const SizedBox(height: 8);
                            }

                            // typing indicator (if enabled)
                            if (_isTyping && index == combined.length) {
                              return const TypingIndicator(avatar: 'assets/images/buddy.jpg');
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

                            // NEW: Pending text bubble (clock)
                            if (item is _PendingText) {
                              final time = _timeLabel(item.localTime);
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: _PendingSentBubble(
                                  message: item.text,
                                  time: time,
                                ),
                              );
                            }

                            // Firestore message bubble
                            final m = item as Message;
                            final isSent = m.senderUserId == uid;
                            final time = _timeLabel(m.createdAt);

                            if (m.type != MessageType.text) {
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
}

// -------------------- NEW: Pending bubble UI (keeps existing UI intact) --------------------
/// This DOES NOT replace your existing SentMessage widget.
/// It only adds a "clock" indicator for pending state while keeping similar alignment.
/// You can later upgrade SentMessage itself for sent/delivered/read ticks.
class _PendingSentBubble extends StatelessWidget {
  final String message;
  final String time;

  const _PendingSentBubble({
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Use your existing bubble for consistent UI
          SentMessage(message: message, time: time),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Iconsax.clock, size: 14, color: XColors.secondaryText),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------- NEW: pending model --------------------
class _PendingText {
  final String clientId;
  final String text;
  final DateTime localTime;

  _PendingText({
    required this.clientId,
    required this.text,
    required this.localTime,
  });
}
