import 'package:fitbud/presentation/screens/chats/widget/single_chat_card.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/bottom_sheets/create_group_sheet.dart';
import '../../../common/bottom_sheets/show_buddies_sheet.dart';
import '../../../common/widgets/search_with_filter.dart';
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

  final List<Map<String, dynamic>> chats = const [
    {
      'name': 'Ali Haider',
      'profilePic': '',
      'lastMessage': 'Hey! How are you?',
      'time': '5 mins ago',
      'unread': true,
      'isGroup': false,
    },
    {
      'name': 'Gym Buddies',
      'profilePic': null,
      'lastMessage': 'Let\'s meet at 7!',
      'time': '10 mins ago',
      'unread': false,
      'isGroup': true,
      'lastSenderName': 'Haider',
    },
    {
      'name': 'Iron Gym Chat',
      'profilePic': 'assets/images/buddy.jpg',
      'lastMessage': 'See you tomorrow!',
      'time': '30 mins ago',
      'unread': true,
      'isGroup': false,
    },
    {
      'name': 'Lahore Fitness Group',
      'profilePic': '',
      'lastMessage': 'Workout session starts now!',
      'time': '1 hr ago',
      'unread': false,
      'isGroup': true,
      'lastSenderName': 'Ali',
    },
    {
      'name': 'Sara Khan',
      'profilePic': '',
      'lastMessage': 'Can you send me the plan?',
      'time': '2 hrs ago',
      'unread': true,
      'isGroup': false,
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    final sortedChats = List<Map<String, dynamic>>.from(chats)
      ..sort((a, b) {
        if ((a['unread'] ?? false) && !(b['unread'] ?? false)) return -1;
        if (!(a['unread'] ?? false) && (b['unread'] ?? false)) return 1;
        return 0;
      });

    return Scaffold(
      appBar: XAppBar(
        title: 'Inbox',
        showBackIcon: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              LucideIcons.ellipsis_vertical,
              color: XColors.primary,
              size: 18,
            ),
            color: XColors.secondaryBG,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              switch (value) {
                case 'create_group':
                  showCreateGroupSheet(context);
                  break;
                case 'mark_unread':
                  // TODO
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_group',
                child: Row(
                  children: [
                    Icon(LucideIcons.users, size: 16, color: XColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Create new group',
                      style: TextStyle(
                        color: XColors.primaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mark_unread',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.mail_open,
                      size: 16,
                      color: XColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: XColors.primaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
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
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: sortedChats.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chat = sortedChats[index];
                    return SingleChatCard(
                      chatName: chat['name'],
                      profilePic: chat['profilePic'],
                      lastMessage: chat['lastMessage'],
                      time: chat['time'],
                      unread: chat['unread'] ?? false,
                      isGroup: chat['isGroup'] ?? false,
                      lastSenderName: chat['lastSenderName'],
                      onTap: () {
                        Get.to(
                          () => ChatScreen(isGroup: chat['isGroup'] ?? false),
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

      // ---------- FAB with slide + fade ----------
      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 220),
        offset: _isFabVisible ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1 : 0,
          child: FloatingActionButton(
            backgroundColor: XColors.primary.withOpacity(0.75),
            elevation: 0,
            shape: CircleBorder(),
            onPressed: () {
              showBuddiesSheet(context, chats);
            },
            child: Icon(LucideIcons.message_circle_plus, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
