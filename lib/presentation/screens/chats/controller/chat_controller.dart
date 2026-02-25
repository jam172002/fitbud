import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../domain/models/auth/app_user.dart';
import '../../../../domain/models/chat/chat_models.dart';
import '../../../../domain/models/chat/conversation_participant.dart';
import '../../../../domain/models/chat/message.dart';
import '../../../../domain/repos/repo_provider.dart';
import '../../../../utils/chat_utils.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/enums.dart';
import '../../authentication/controllers/auth_controller.dart';
class ChatController extends GetxController {
  ChatController({
    required this.conversationId,
    required this.isGroup,
    required this.groupName,
    required this.directOtherUserId,
    required this.directTitle,
  });

  final String conversationId;
  final bool isGroup;
  final String groupName;
  final String directOtherUserId;
  final String directTitle;

  final Repos repos = Get.find<Repos>();
  final AuthController authC = Get.find<AuthController>();

  // UI controllers
  final ScrollController scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();

  // local ui state
  final RxBool isTyping = false.obs;
  final RxBool sending = false.obs;

  // pending state
  final RxList<PendingText> pendingTexts = <PendingText>[].obs;
  final RxList<PendingMedia> pendingMedias = <PendingMedia>[].obs;

  // participants cache (ids only)
  List<String> _cachedParticipantIds = [];
  StreamSubscription<List<ConversationParticipant>>? _partSub;

  // mark read throttle
  DateTime? _lastMarkReadAt;
  Timer? _markReadDebounce;

  // combined stream
  late final Stream<ChatSnapshot> chat$;
  StreamSubscription<DateTime?>? _clearedSub;
  StreamSubscription<List<Message>>? _msgsSub;
  DateTime? _latestClearedAt;

  String get uid => authC.authUser.value?.uid ?? '';

  @override
  void onInit() {
    super.onInit();

    _partSub = repos.chatRepo.watchParticipants(conversationId).listen((parts) {
      final ids = parts.map((p) => p.userId).toList();
      if (ChatUtils.listEquals(ids, _cachedParticipantIds)) return;
      _cachedParticipantIds = ids;
    });

    chat$ = _buildCombinedChatStream();
    markReadThrottled();
  }

  @override
  void onClose() {
    _partSub?.cancel();
    _markReadDebounce?.cancel();
    _clearedSub?.cancel();
    _msgsSub?.cancel();
    scrollController.dispose();
    messageController.dispose();
    super.onClose();
  }

  Stream<ChatSnapshot> _buildCombinedChatStream() {
    final controller = StreamController<ChatSnapshot>.broadcast();

    void emit(List<Message> msgs) {
      controller.add(ChatSnapshot(clearedAt: _latestClearedAt, msgsRaw: msgs));
    }

    _clearedSub = repos.chatRepo.watchMyClearedAt(conversationId).listen((c) {
      _latestClearedAt = c;
    });

    _msgsSub = repos.chatRepo.watchMessages(conversationId, limit: 50).listen(emit);

    controller.onCancel = () async {
      await _clearedSub?.cancel();
      await _msgsSub?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  Future<void> markReadThrottled() async {
    final now = DateTime.now();
    if (_lastMarkReadAt != null &&
        now.difference(_lastMarkReadAt!).inMilliseconds < 1500) {
      _markReadDebounce?.cancel();
      _markReadDebounce = Timer(const Duration(milliseconds: 900), () {
        if (!isClosed) markReadThrottled();
      });
      return;
    }

    _lastMarkReadAt = now;
    try {
      await repos.chatRepo.markConversationRead(conversationId);
    } catch (_) {}
  }

  Future<void> deleteChat() async {
    try {
      await repos.chatRepo.deleteChatForMe(conversationId);
      if (Get.isDialogOpen == true) Get.back();
      Get.back();
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
  bool _reconciling = false;
  // call from UI when snapshot updates
  void reconcileAndMark({required List<Message> msgsFiltered}) {
    if (uid.isEmpty || _reconciling) return;

    _reconciling = true;
    // run after current microtask queue (still NOT build)
    Future.microtask(() {
      if (isClosed) return;
      markReadThrottled();
      _reconcilePendingTextFast(msgsFiltered);
      _reconcilePendingMediaFast(msgsFiltered);
      _reconciling = false;
    });
  }

  void _reconcilePendingTextFast(List<Message> msgs) {
    if (pendingTexts.isEmpty) return;

    final recentMine = <String, List<DateTime>>{};
    for (final m in msgs) {
      if (m.senderUserId != uid) continue;
      if (m.type != MessageType.text) continue;
      final created = m.createdAt;
      if (created == null) continue;
      final key = m.text.trim();
      if (key.isEmpty) continue;
      (recentMine[key] ??= []).add(created);
    }

    final removeIds = <String>{};
    for (final p in pendingTexts) {
      final list = recentMine[p.text.trim()];
      if (list == null) continue;
      final minOk = p.localTime.subtract(const Duration(seconds: 3));
      final maxOk = p.localTime.add(const Duration(minutes: 2));
      final match = list.any((dt) => !dt.isBefore(minOk) && !dt.isAfter(maxOk));
      if (match) removeIds.add(p.clientId);
    }

    if (removeIds.isNotEmpty) {
      pendingTexts.removeWhere((p) => removeIds.contains(p.clientId));
    }
  }

  void _reconcilePendingMediaFast(List<Message> msgs) {
    if (pendingMedias.isEmpty) return;

    final urls = <String>{};
    for (final m in msgs) {
      if (m.senderUserId != uid) continue;
      if (m.mediaUrl.isNotEmpty) urls.add(m.mediaUrl);
    }

    pendingMedias.removeWhere((p) {
      final url = p.uploadedUrl;
      return url != null && urls.contains(url);
    });
  }

  // ---------- SEND TEXT ----------
  Future<void> sendText() async {
    final text = messageController.text.trim();
    if (text.isEmpty || sending.value) return;

    messageController.clear();

    final clientId = DateTime.now().microsecondsSinceEpoch.toString();
    pendingTexts.add(PendingText(clientId: clientId, text: text, localTime: DateTime.now()));
    scrollToBottom();

    sending.value = true;
    try {
      await repos.chatRepo.sendMessage(
        conversationId: conversationId,
        type: MessageType.text,
        text: text,
        participantIds: _cachedParticipantIds.isNotEmpty ? _cachedParticipantIds : null,
      );
      scrollToBottom();
      markReadThrottled();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send: $e",
        backgroundColor: XColors.danger.withValues(alpha: .2),
        colorText: XColors.primaryText,
      );
    } finally {
      sending.value = false;
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------- ATTACHMENTS ----------
  Future<PickedMedia?> pickMedia(MessageType type) async {
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
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.single;

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) return null;

      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'bin';
      final mime = ChatUtils.mimeTypeFromExt(ext);

      return PickedMedia(
        bytes: bytes,
        fileName: name,
        ext: ext,
        mimeType: mime,
        type: type,
        fileSize: bytes.length,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file: $e',
        backgroundColor: XColors.danger.withValues(alpha: .2),
        colorText: XColors.primaryText,
      );
      return null;
    }
  }

  Future<void> sendPickedMedia(PickedMedia picked) async {
    final clientId = DateTime.now().microsecondsSinceEpoch.toString();
    final pending = PendingMedia(clientId: clientId, picked: picked, localTime: DateTime.now());
    pendingMedias.add(pending);
    scrollToBottom();

    try {
      final url = await repos.mediaRepo.uploadChatMediaBytes(
        conversationId: conversationId,
        bytes: picked.bytes,
        ext: picked.ext,
        mimeType: picked.mimeType,
      );

      final idx = pendingMedias.indexWhere((p) => p.clientId == clientId);
      if (idx >= 0) pendingMedias[idx] = pending.copyWithUrl(url);

      await repos.chatRepo.sendMessage(
        conversationId: conversationId,
        type: picked.type,
        mediaUrl: url,
        text: '',
        participantIds: _cachedParticipantIds.isNotEmpty ? _cachedParticipantIds : null,
      );

      scrollToBottom();
      markReadThrottled();
    } catch (e) {
      pendingMedias.removeWhere((p) => p.clientId == clientId);
      Get.snackbar(
        'Error',
        'Failed to send: $e',
        backgroundColor: XColors.danger.withValues(alpha: .2),
        colorText: XColors.primaryText,
      );
    }
  }

  // ---------- HEADER HELPERS ----------
  Future<AppUser?> loadDirectOtherUser() async {
    final otherId = directOtherUserId.trim();
    if (otherId.isEmpty) return null;
    try {
      return await repos.authRepo.getUser(otherId);
    } catch (_) {
      return null;
    }
  }

  Stream<List<ConversationParticipant>> participants$() {
    return repos.chatRepo.watchParticipants(conversationId);
  }
}