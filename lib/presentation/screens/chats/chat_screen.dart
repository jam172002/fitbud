import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:file_picker/file_picker.dart';
import 'package:fitbud/presentation/screens/chats/widget/add_members_to_group_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/chat_input_bar.dart';
import 'package:fitbud/presentation/screens/chats/widget/full_screen_media.dart';
import 'package:fitbud/presentation/screens/chats/widget/members_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/received_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/sent_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/typing_indicator.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/foundation.dart';
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

  bool _isTyping = false;
  bool _sending = false;
  final List<_PendingMedia> _pendingMedias = [];

  List<String> _cachedParticipantIds = [];
  StreamSubscription<List<ConversationParticipant>>? _partSub;

  // -------------------- optimistic pending messages --------------------
  final List<_PendingText> _pendingTexts = [];

  @override
  void initState() {
    super.initState();
    _markRead();
    _isTyping = false;
    _partSub = repos.chatRepo
        .watchParticipants(widget.conversationId)
        .listen((parts) {
      if (mounted) {
        setState(() {
          _cachedParticipantIds = parts.map((p) => p.userId).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _partSub?.cancel();
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
        participantIds: _cachedParticipantIds.isNotEmpty ? _cachedParticipantIds : null,
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

  // -------------------- WhatsApp-style attachment flow --------------------

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: XColors.secondaryBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: XColors.secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AttachOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Photo',
                  color: Colors.purple,
                  onTap: () { Navigator.pop(ctx); _pickFileForType(MessageType.image); },
                ),
                _AttachOption(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () { Navigator.pop(ctx); _pickFileForType(MessageType.video); },
                ),
                _AttachOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () { Navigator.pop(ctx); _pickFileForType(MessageType.file); },
                ),
                _AttachOption(
                  icon: Icons.headset_rounded,
                  label: 'Audio',
                  color: Colors.orange,
                  onTap: () { Navigator.pop(ctx); _pickFileForType(MessageType.audio); },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFileForType(MessageType type) async {
    final fileType = switch (type) {
      MessageType.image => FileType.image,
      MessageType.video => FileType.video,
      MessageType.audio => FileType.audio,
      _ => FileType.any,
    };

    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        _showError('Could not read file.');
        return;
      }

      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'bin';
      final mimeType = _getMimeType(ext, type);

      final picked = _PickedMedia(
        bytes: bytes,
        fileName: name,
        ext: ext,
        mimeType: mimeType,
        type: type,
        fileSize: bytes.length,
      );

      if (!mounted) return;
      await _showPreviewSheet(picked);
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  String _getMimeType(String ext, MessageType type) {
    const map = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'webp': 'image/webp', 'heic': 'image/heic',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'avi': 'video/x-msvideo',
      'mp3': 'audio/mpeg', 'aac': 'audio/aac', 'wav': 'audio/wav', 'm4a': 'audio/mp4',
      'pdf': 'application/pdf', 'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  Future<void> _showPreviewSheet(_PickedMedia picked) async {
    final shouldSend = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: XColors.secondaryBG,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MediaPreviewSheet(picked: picked),
    );

    if (shouldSend == true && mounted) {
      await _sendMedia(picked);
    }
  }

  Future<void> _sendMedia(_PickedMedia picked) async {
    final clientId = DateTime.now().microsecondsSinceEpoch.toString();
    final pending = _PendingMedia(
      clientId: clientId,
      picked: picked,
      localTime: DateTime.now(),
    );

    setState(() => _pendingMedias.add(pending));
    _scrollToBottom();

    try {
      final url = await repos.mediaRepo.uploadChatMediaBytes(
        conversationId: widget.conversationId,
        bytes: picked.bytes,
        ext: picked.ext,
        mimeType: picked.mimeType,
      );

      if (mounted) {
        setState(() {
          final idx = _pendingMedias.indexWhere((p) => p.clientId == clientId);
          if (idx >= 0) _pendingMedias[idx] = pending.copyWithUrl(url);
        });
      }

      await repos.chatRepo.sendMessage(
        conversationId: widget.conversationId,
        type: picked.type,
        mediaUrl: url,
        text: '',
        participantIds: _cachedParticipantIds.isNotEmpty ? _cachedParticipantIds : null,
      );

      _scrollToBottom();
      await _markRead();
    } catch (e) {
      if (mounted) setState(() => _pendingMedias.removeWhere((p) => p.clientId == clientId));
      _showError('Failed to send: $e');
    }
  }

  void _reconcileMedia({required List<Message> msgs, required String myUid}) {
    if (_pendingMedias.isEmpty) return;
    final toRemove = <String>{};
    for (final pm in _pendingMedias) {
      if (pm.uploadedUrl == null) continue;
      final matched = msgs.any((m) =>
          m.senderUserId == myUid && m.mediaUrl == pm.uploadedUrl);
      if (matched) toRemove.add(pm.clientId);
    }
    if (toRemove.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _pendingMedias.removeWhere((p) => toRemove.contains(p.clientId)));
    });
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      backgroundColor: XColors.danger.withValues(alpha: .2),
      colorText: XColors.primaryText,
    );
  }

  void _openNetworkImageFullScreen(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMedia(
          path: url,
          isVideo: false,
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

                      //THIS is the buddy of the direct chat
                      invitedUserId: widget.isGroup ? '' : widget.directOtherUserId,
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
                      stream: repos.chatRepo.watchMessages(widget.conversationId, limit: 50),
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

                        // Reconcile pending text messages
                        _reconcilePending(firestoreMessages: msgs, myUid: uid);
                        // Reconcile pending media messages
                        _reconcileMedia(msgs: msgs, myUid: uid);

                        final combined = <dynamic>[
                          ..._pendingMedias,
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

                            // Pending media bubble (optimistic — shows while uploading)
                            if (item is _PendingMedia) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: _PendingMediaBubble(pending: item),
                              );
                            }

                            // Pending text bubble (optimistic)
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

                            // Image bubble
                            if (m.type == MessageType.image && m.mediaUrl.isNotEmpty) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: _ImageBubble(
                                  url: m.mediaUrl,
                                  time: time,
                                  isSent: isSent,
                                  onTap: () => _openNetworkImageFullScreen(m.mediaUrl),
                                ),
                              );
                            }

                            // Text bubble (and fallback for other types)
                            final displayText = m.type == MessageType.text
                                ? m.text
                                : (m.text.isNotEmpty ? m.text : '[${m.type.name}]');

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: isSent
                                  ? SentMessage(message: displayText, time: time)
                                  : ReceivedMessage(
                                message: displayText,
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
            onAttach: _showAttachmentSheet,
            isUploading: _pendingMedias.isNotEmpty,
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

// -------------------- pending model --------------------
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

// -------------------- image bubble --------------------
class _ImageBubble extends StatelessWidget {
  final String url;
  final String time;
  final bool isSent;
  final VoidCallback onTap;

  const _ImageBubble({
    required this.url,
    required this.time,
    required this.isSent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isSent
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isSent
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: url,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  width: 200,
                  color: XColors.secondaryBG,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: XColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  width: 200,
                  color: XColors.secondaryBG,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey, size: 40),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
                color: XColors.secondaryText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ======================== DATA MODELS ========================

class _PickedMedia {
  final Uint8List bytes;
  final String fileName;
  final String ext;
  final String mimeType;
  final MessageType type;
  final int fileSize;

  const _PickedMedia({
    required this.bytes,
    required this.fileName,
    required this.ext,
    required this.mimeType,
    required this.type,
    required this.fileSize,
  });
}

class _PendingMedia {
  final String clientId;
  final _PickedMedia picked;
  final DateTime localTime;
  final String? uploadedUrl;

  const _PendingMedia({
    required this.clientId,
    required this.picked,
    required this.localTime,
    this.uploadedUrl,
  });

  _PendingMedia copyWithUrl(String url) => _PendingMedia(
        clientId: clientId,
        picked: picked,
        localTime: localTime,
        uploadedUrl: url,
      );
}

// ======================== ATTACHMENT OPTION BUTTON ========================

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: XColors.primaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== MEDIA PREVIEW SHEET ========================

class _MediaPreviewSheet extends StatelessWidget {
  final _PickedMedia picked;

  const _MediaPreviewSheet({required this.picked});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _typeIcon(MessageType t) {
    switch (t) {
      case MessageType.video:
        return Icons.videocam_rounded;
      case MessageType.audio:
        return Icons.headset_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: XColors.secondaryText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Send ${picked.type == MessageType.image ? 'Photo' : picked.type == MessageType.video ? 'Video' : picked.type == MessageType.audio ? 'Audio' : 'File'}',
            style: const TextStyle(
              color: XColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (picked.type == MessageType.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                picked.bytes,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: XColors.primaryBG,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: XColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_typeIcon(picked.type),
                        color: XColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          picked.fileName,
                          style: const TextStyle(
                            color: XColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSize(picked.fileSize),
                          style: const TextStyle(
                            color: XColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: XColors.secondaryText),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Send',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================== PENDING MEDIA BUBBLE ========================

class _PendingMediaBubble extends StatelessWidget {
  final _PendingMedia pending;

  const _PendingMediaBubble({required this.pending});

  IconData _typeIcon(MessageType t) {
    switch (t) {
      case MessageType.video:
        return Icons.videocam_rounded;
      case MessageType.audio:
        return Icons.headset_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = pending.picked.type == MessageType.image;
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            child: Stack(
              children: [
                if (isImage)
                  Image.memory(
                    pending.picked.bytes,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 72,
                    width: 220,
                    color: XColors.secondaryBG,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(_typeIcon(pending.picked.type),
                            color: XColors.primary, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pending.picked.fileName,
                            style: const TextStyle(
                                color: XColors.primaryText, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Uploading overlay with clock icon
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Iconsax.clock, size: 12, color: XColors.secondaryText),
              SizedBox(width: 3),
              Text('Sending…',
                  style:
                      TextStyle(color: XColors.secondaryText, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
