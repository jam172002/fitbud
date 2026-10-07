import 'package:fitbud/presentation/screens/chats/widget/attachment_sheet.dart';
import 'package:fitbud/presentation/screens/chats/widget/chat_app_bar.dart';
import 'package:fitbud/presentation/screens/chats/widget/chat_input_bar.dart';
import 'package:fitbud/presentation/screens/chats/widget/chat_message_list.dart';
import 'package:fitbud/presentation/screens/chats/widget/media_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/colors.dart';
import '../../../domain/models/chat/chat_models.dart';
import 'controller/chat_controller.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final bool isGroup;
  final String groupName;
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

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController c;

  // ✅ Use a tag so multiple chats don’t collide
  String get _tag => 'chat_${widget.conversationId}';

  @override
  void initState() {
    super.initState();

    c = Get.put(
      ChatController(
        conversationId: widget.conversationId,
        isGroup: widget.isGroup,
        groupName: widget.groupName,
        directOtherUserId: widget.directOtherUserId,
        directTitle: widget.directTitle,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    // ✅ remove controller when leaving screen
    if (Get.isRegistered<ChatController>(tag: _tag)) {
      Get.delete<ChatController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: ChatAppBar(controller: c),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<ChatSnapshot>(
              stream: c.chat$,
              builder: (_, snap) {
                final data = snap.data;
                final clearedAt = data?.clearedAt;
                final msgsRaw = data?.msgsRaw ?? const [];

                final msgs = (clearedAt == null)
                    ? msgsRaw
                    : msgsRaw.where((m) {
                  final dt = m.createdAt;
                  if (dt == null) return true;
                  return !dt.isBefore(clearedAt);
                }).toList();

                // ✅ IMPORTANT: do NOT mutate Rx during build.
                if (snap.hasData) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || c.isClosed) return;
                    c.reconcileAndMark(msgsFiltered: msgs);
                  });
                }

                return ChatMessageList(
                  controller: c,
                  firestoreMessages: msgs,
                );
              },
            ),
          ),

          Obx(
                () => ChatInputBar(
              controller: c.messageController,
              onSend: c.sendText,
              onAttach: () async {
                final type = await showAttachmentSheet(context);
                if (type == null) return;

                final picked = await c.pickMedia(type);
                if (picked == null) return;

                final ok = await showMediaPreviewSheet(context, picked);
                if (ok == true) await c.sendPickedMedia(picked);
              },
              isUploading: c.pendingMedias.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }
}