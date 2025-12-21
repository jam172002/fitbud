import 'dart:io';
import 'package:fitbud/presentation/screens/chats/widget/add_members_to_group_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/chat_input_bar.dart';
import 'package:fitbud/presentation/screens/chats/widget/full_screen_media.dart';
import 'package:fitbud/presentation/screens/chats/widget/members_dialog.dart';
import 'package:fitbud/presentation/screens/chats/widget/received_media_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/received_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/sent_media_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/sent_message_bubble.dart';
import 'package:fitbud/presentation/screens/chats/widget/typing_indicator.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:file_picker/file_picker.dart';

import '../../../common/bottom_sheets/session_invite_sheet.dart';
import '../../../common/widgets/two_buttons_dialog.dart';
import '../profile/buddy_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final bool isGroup;
  final String groupName;
  final int groupMembers;

  const ChatScreen({
    super.key,
    this.isGroup = false,
    this.groupName = 'Gym Buddies',
    this.groupMembers = 15,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  late List<Map<String, String>> members;
  @override
  void initState() {
    super.initState();

    // Dummy members
    members = [
      {'name': 'Ali', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Sufyan', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Hassan', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Ayesha', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Zara', 'avatar': 'assets/images/buddy.jpg'},
    ];

    // Add dummy received messages
    _messages.addAll([
      {
        'text': 'Hello! How are you?',
        'time': _getCurrentTime(),
        'isSent': false,
        'senderName': 'Ali',
        'avatar': 'assets/images/buddy.jpg',
      },
      {
        'text': 'Check out the new project images!',
        'time': _getCurrentTime(),
        'isSent': false,
        'senderName': 'Ali',
        'avatar': 'assets/images/buddy.jpg',
      },
    ]);

    // Simulate other user typing after 2 sec
    Future.delayed(Duration(seconds: 2), () {
      setState(() => _isTyping = true);
      Future.delayed(Duration(seconds: 4), () {
        setState(() => _isTyping = false);
      });
    });
  }

  Future<void> _pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      bool isVideo = file.path.endsWith('.mp4') || file.path.endsWith('.mov');

      setState(() {
        _messages.add({
          'file': file,
          'isVideo': isVideo,
          'time': _getCurrentTime(),
          'isSent': true,
        });
      });
      _scrollToBottom();
    }
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'time': _getCurrentTime(), 'isSent': true});
    });
    _messageController.clear();
    _scrollToBottom();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return "${hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openFullScreen(File file, {required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FullScreenMedia(path: file.path, isVideo: isVideo, isAsset: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesCount = _messages.length;

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: AppBar(
        backgroundColor: XColors.primaryBG,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (!widget.isGroup) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BuddyProfileScreen(scenario: BuddyScenario.existingBuddy),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/buddy.jpg'),
            ),
          ),
        ),

        title: GestureDetector(
          onTap: () {
            if (!widget.isGroup) {
              Get.to(
                () => BuddyProfileScreen(scenario: BuddyScenario.existingBuddy),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isGroup ? widget.groupName : "Ali Haider",
                style: TextStyle(
                  color: XColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.isGroup)
                Text(
                  "${widget.groupMembers} members",
                  style: TextStyle(color: XColors.secondaryText, fontSize: 12),
                ),
            ],
          ),
        ),

        actions: [
          // Add user icon for group chat
          if (widget.isGroup)
            GestureDetector(
              onTap: _openAddMembersDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Iconsax.user_add, color: Colors.blue, size: 22),
              ),
            ),

          // Action dropdown menu
          PopupMenuButton<String>(
            icon: Icon(
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
                      membersCount: widget.groupMembers,
                    ),
                  );
                  break;

                case 'members':
                  // Show members dialog
                  showDialog(
                    context: context,
                    builder: (_) => MembersDialog(
                      members: members,
                      onGroupMemberTap: () {
                        Get.to(
                          () => BuddyProfileScreen(
                            scenario: BuddyScenario.existingBuddy,
                          ),
                        );
                      },
                    ),
                  );
                  break;

                case 'leave':
                  // Show leave group confirmation
                  showDialog(
                    context: context,
                    builder: (_) => XButtonsConfirmationDialog(
                      message: "Are you sure you want to leave the group?",
                      icon: Iconsax.logout,
                      iconColor: Colors.red,
                      confirmText: "Leave",
                      cancelText: "Cancel",
                      onConfirm: () {
                        // Add your leave group logic here
                        print("Group left");
                      },
                    ),
                  );
                  break;

                case 'delete_chat':
                  // Show delete chat confirmation
                  showDialog(
                    context: context,
                    builder: (_) => XButtonsConfirmationDialog(
                      message: "Are you sure you want to delete this chat?",
                      icon: Iconsax.trash,
                      iconColor: Colors.red,
                      confirmText: "Delete",
                      cancelText: "Cancel",
                      onConfirm: () {
                        // Add your delete chat logic here
                        print("Chat deleted");
                      },
                    ),
                  );
                  break;

                case 'remove_buddy':
                  // Show remove buddy confirmation
                  showDialog(
                    context: context,
                    builder: (_) => XButtonsConfirmationDialog(
                      message: "Are you sure you want to remove this buddy?",
                      icon: Iconsax.user_remove,
                      iconColor: Colors.red,
                      confirmText: "Remove",
                      cancelText: "Cancel",
                      onConfirm: () {
                        // Add your remove buddy logic here
                        print("Buddy removed");
                      },
                    ),
                  );
                  break;
              }
            },

            itemBuilder: (_) {
              if (widget.isGroup) {
                return [
                  PopupMenuItem(
                    value: 'session_invite',
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.message_text,
                          size: 18,
                          color: XColors.primaryText,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Session Invite",
                          style: TextStyle(color: XColors.bodyText),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'members',
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.people,
                          size: 18,
                          color: XColors.primaryText,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Members",
                          style: TextStyle(color: XColors.bodyText),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
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
                      children: [
                        Icon(
                          Iconsax.message_text,
                          size: 18,
                          color: XColors.primaryText,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Session Invite",
                          style: TextStyle(color: XColors.bodyText),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_chat',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          "Delete Chat",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove_buddy',
                    child: Row(
                      children: [
                        Icon(Iconsax.user_remove, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          "Remove Buddy",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ];
              }
            },
          ),
          SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messagesCount + (_isTyping ? 1 : 0) + 1,
              itemBuilder: (_, index) {
                // Date separator
                if (index == 0) return _dateSeparator("Today");

                // Typing indicator
                if (_isTyping && index == messagesCount + 1) {
                  return TypingIndicator(avatar: 'assets/images/buddy.jpg');
                }

                // Message index
                final msg = _messages[index - 1];
                final prevMsg = index > 1 ? _messages[index - 2] : null;

                final sameSenderAsPrevious =
                    prevMsg != null &&
                    prevMsg.containsKey('isSent') &&
                    prevMsg['isSent'] == msg['isSent'] &&
                    ((msg.containsKey('text') && prevMsg.containsKey('text')) ||
                        (msg.containsKey('file') &&
                            prevMsg.containsKey('file')));

                EdgeInsets msgMargin = sameSenderAsPrevious
                    ? EdgeInsets.symmetric(vertical: 4)
                    : EdgeInsets.symmetric(vertical: 12);

                if (msg.containsKey('file')) {
                  return Container(
                    margin: msgMargin,
                    child: msg['isSent'] == true
                        ? SentMedia(
                            file: msg['file'],
                            isVideo: msg['isVideo'],
                            time: msg['time'],
                            onTap: () => _openFullScreen(
                              msg['file'],
                              isVideo: msg['isVideo'],
                            ),
                          )
                        : ReceivedMedia(
                            file: msg['file'],
                            isVideo: msg['isVideo'],
                            time: msg['time'],
                            senderName: msg['senderName'],
                            avatar: msg['avatar'],
                            showSender: widget.isGroup,
                            onTap: () => _openFullScreen(
                              msg['file'],
                              isVideo: msg['isVideo'],
                            ),
                          ),
                  );
                } else {
                  return Container(
                    margin: msgMargin,
                    child: msg['isSent'] == true
                        ? SentMessage(message: msg['text'], time: msg['time'])
                        : ReceivedMessage(
                            message: msg['text'],
                            time: msg['time'],
                            senderName: msg['senderName'],
                            avatar: msg['avatar'],
                            isGroup: widget.isGroup,
                          ),
                  );
                }
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
    child: Text(
      text,
      style: TextStyle(color: XColors.primaryText, fontSize: 12),
    ),
  );

  void _openAddMembersDialog() {
    final allBuddies = [
      {'name': 'Ali', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Sufyan', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Hassan', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Ayesha', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'Zara', 'avatar': 'assets/images/buddy.jpg'},
      {'name': 'John Doe', 'avatar': ''},
      {'name': 'Fatima', 'avatar': ''},
    ];

    showDialog(
      context: context,
      builder: (_) => AddMembersDialog(
        allBuddies: allBuddies,
        existingMembers: members,
        onConfirm: (selected) {
          setState(() {
            members.addAll(selected);
          });
        },
      ),
    );
  }
}
