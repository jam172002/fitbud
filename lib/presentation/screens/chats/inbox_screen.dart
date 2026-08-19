import 'package:fitbud/presentation/screens/chats/widget/single_chat_card.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import '../../../common/appbar/common_appbar.dart';
import '../../../common/bottom_sheets/create_group_sheet.dart';
import '../../../common/bottom_sheets/show_buddies_sheet.dart';
import '../../../common/widgets/search_with_filter.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/chat/conversation.dart';
import '../../../domain/models/chat/user_conversation_index.dart';
import '../../../domain/repos/repo_provider.dart';
import '../authentication/controllers/auth_controller.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  double _lastOffset = 0;

  final Repos repos = Get.find<Repos>();
  final AuthController authC = Get.find<AuthController>();

  // cache other user futures to avoid re-fetch on rebuild
  final Map<String, Future<AppUser?>> _directOtherUserCache = {};

  @override
  void initState() {
    super.initState();
    const double sensitivity = 8;

    _scrollController.addListener(() {
      final offset = _scrollController.position.pixels;
      final diff = offset - _lastOffset;

      if (diff > sensitivity) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (diff < -sensitivity) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }

      _lastOffset = offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Deterministic direct id format: direct_a_b
  String _otherIdFromDirectConversationId(String convId) {
    final uid = authC.authUser.value?.uid ?? '';
    if (!convId.startsWith('direct_') || uid.isEmpty) return '';
    final parts = convId.split('_'); // direct, a, b
    if (parts.length < 3) return '';
    final a = parts[1];
    final b = parts[2];
    return a == uid ? b : a;
  }

  Future<AppUser?> _loadOtherUserCached(String conversationId) {
    return _directOtherUserCache.putIfAbsent(conversationId, () async {
      final otherId = _otherIdFromDirectConversationId(conversationId);
      if (otherId.isEmpty) return null;
      try {
        return await repos.authRepo.getUser(otherId);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: XAppBar(
        title: 'Inbox',
        showBackIcon: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.ellipsis_vertical, color: XColors.primary, size: 18),
            color: XColors.secondaryBG,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (value) {
              if (value == 'create_group') {
                showCreateGroupSheet(context);
              }
              // mark all read can be implemented by iterating index docs and calling markConversationRead()
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_group',
                child: Row(
                  children: [
                    Icon(LucideIcons.users, size: 16, color: XColors.primary),
                    const SizedBox(width: 8),
                    Text('Create new group', style: TextStyle(color: XColors.primaryText, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mark_unread',
                child: Row(
                  children: [
                    Icon(LucideIcons.mail_open, size: 16, color: XColors.primary),
                    const SizedBox(width: 8),
                    Text('Mark all as read', style: TextStyle(color: XColors.primaryText, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SearchWithFilter(horPadding: 0, showFilter: false),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<(UserConversationIndex idx, Conversation? conv)>>(
                  stream: repos.chatRepo.watchMyInbox(limit: 30),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snap.data ?? const [];
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No conversations yet.',
                          style: TextStyle(color: XColors.bodyText.withOpacity(0.7), fontSize: 13),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final (idx, conv) = items[index];
                        final type = conv?.type ?? idx.type;
                        final isGroup = type == ConversationType.group;

                        final time = _relativeTime(idx.lastMessageAt ?? conv?.lastMessageAt);
                        final lastMsg = (idx.lastMessagePreview.isNotEmpty)
                            ? idx.lastMessagePreview
                            : (conv?.lastMessagePreview ?? '');

                        if (isGroup) {
                          final groupName = (conv?.title ?? idx.title).trim().isEmpty ? 'Group' : (conv?.title ?? idx.title);
                          return SingleChatCard(
                            chatName: groupName,
                            profilePic: null,
                            lastMessage: lastMsg,
                            time: time,
                            unreadCount: idx.unreadCount,
                            isGroup: true,
                            lastSenderName: null,
                            onTap: () {
                              Get.to(() => ChatScreen(
                                conversationId: idx.conversationId,
                                isGroup: true,
                                groupName: groupName,
                              ));
                            },
                          );
                        }

                        // Direct: resolve other user by deterministic id
                        return FutureBuilder<AppUser?>(
                          future: _loadOtherUserCached(idx.conversationId),
                          builder: (context, uSnap) {
                            final u = uSnap.data;
                            final name = (u?.displayName?.trim().isNotEmpty == true) ? u!.displayName! : 'Chat';
                            final pic = (u?.photoUrl?.trim().isNotEmpty == true) ? u!.photoUrl! : '';

                            return SingleChatCard(
                              chatName: name,
                              profilePic: pic,
                              lastMessage: lastMsg,
                              time: time,
                              unreadCount: idx.unreadCount,
                              isGroup: false,
                              lastSenderName: null,
                              onTap: () {
                                Get.to(() => ChatScreen(
                                  conversationId: idx.conversationId,
                                  isGroup: false,
                                  directOtherUserId: u?.id ?? _otherIdFromDirectConversationId(idx.conversationId),
                                  directTitle: name,
                                ));
                              },
                            );
                          },
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

      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1 : 0,
          child: FloatingActionButton(
            backgroundColor: XColors.primary.withOpacity(0.75),
            elevation: 0,
            shape: const CircleBorder(),
            onPressed: () async {
              // open real buddies list from friendships
              final buddies = await repos.buddyRepo.watchMyBuddiesUsers().first;
              showBuddiesSheet(context, buddies);
            },
            child: const Icon(LucideIcons.message_circle_plus, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
