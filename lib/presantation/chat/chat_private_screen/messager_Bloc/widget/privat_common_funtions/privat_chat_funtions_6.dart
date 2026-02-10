import 'package:dio/dio.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_5.dart';
import 'package:path/path.dart' as p;

import '../../../../../../utils/imports/common_imports.dart';
import '../../../../../../utils/reusbale/common_import.dart';
import '../../../../../widgets/chat_widgets/Common/grouped_media_viewer.dart';

import '../../MessagerEvent.dart';
import '../MixedMediaViewer.dart';
import '../VideoPlayerScreen.dart';

bool isValidUrl(String url) =>
    url.startsWith('http://') || url.startsWith('https://');

void onRecentEmojisChanged(List<String> list,void Function(void Function()) setState,  List<String> recentEmojis ) {
  setState(() {
    recentEmojis = list;
  });
}

void openFile({
  required String urlOrPath,
  required String? fileType,
  required BuildContext context,
  required String currentUser,
  required String convoId,
  required String userName,
}) async
{
  // ✅ 1. VIDEO: open in your own player
  if (fileType != null && fileType.startsWith('video/')) {
    final isNetwork =
        urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          path: urlOrPath,
          isNetwork: isNetwork,
        ),
      ),
    );
    return;
  }

  // ✅ 2. IMAGE: open in MixedMediaViewer
  final lower = urlOrPath.toLowerCase();
  final bool isImage = (fileType != null && fileType.startsWith('image/')) ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.gif');

  if (isImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MixedMediaViewer(
          items: [
            GroupMediaItem(
              previewUrl: urlOrPath,
              mediaUrl: urlOrPath,
              isVideo: false,
              senderName:userName,
            ),
          ],
          initialIndex: 0,
          currentUserId: currentUser,
          conversionalId: convoId,
        ),
      ),
    );
    return;
  }

  // ✅ 3. everything else = Download if needed and open locally

  // If it's a local file, just open it
  if (!urlOrPath.startsWith('http')) {
    final result = await OpenFile.open(urlOrPath);
    if (result.type != ResultType.done) {
      Messenger.alertError("Could not open local file.");
    }
    return;
  }

  // It's a URL - Check if we already have it downloaded
  try {
    final String packageName = "com.nowdigitaleasy.NDEconnect";
    final String baseDir =
        "/storage/emulated/0/Android/media/$packageName/NowDigitalEasy/Media";

    final Directory directory = Directory(baseDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Extract filename
    final String fileName = urlOrPath.split('/').last.split('?').first;
    String safeFileName = fileName.isEmpty
        ? 'document_${DateTime.now().millisecondsSinceEpoch}'
        : fileName;

    // Check for extension
    String extension = p.extension(safeFileName);
    if (extension.isEmpty) {
      if (fileType != null) {
        final lowerType = fileType.toLowerCase();
        if (lowerType.contains('pdf')) {
          extension = '.pdf';
        } else if (lowerType.contains('word') ||
            lowerType.contains('doc') ||
            lowerType.contains('msword')) {
          extension = '.docx';
        } else if (lowerType.contains('excel') ||
            lowerType.contains('sheet') ||
            lowerType.contains('spreadsheet')) {
          extension = '.xlsx';
        } else if (lowerType.contains('presentation') ||
            lowerType.contains('powerpoint')) {
          extension = '.pptx';
        } else if (lowerType.contains('image')) {
          extension = '.jpg';
        } else if (lowerType.contains('video')) {
          extension = '.mp4';
        } else if (lowerType.contains('text') ||
            lowerType.contains('plain')) {
          extension = '.txt';
        } else if (lowerType.contains('csv')) {
          extension = '.csv';
        } else if (lowerType.contains('zip')) {
          extension = '.zip';
        } else if (lowerType.contains('rar')) {
          extension = '.rar';
        } else if (lowerType.contains('json')) {
          extension = '.json';
        } else if (lowerType.contains('xml')) {
          extension = '.xml';
        }
      }

      // Fallback checks on filename/url matching common patterns if no type or type didn't match
      if (extension.isEmpty) {
        final lowerName = safeFileName.toLowerCase();
        if (lowerName.contains('pdf')) {
          extension = '.pdf';
        } else if (lowerName.contains('doc')) {
          extension = '.docx';
        } else if (lowerName.contains('xls')) {
          extension = '.xlsx';
        } else if (lowerName.contains('ppt')) {
          extension = '.pptx';
        }
      }

      if (extension.isNotEmpty) {
        safeFileName += extension;
      }
    }

    final String finalPath = p.join(baseDir, safeFileName);
    final File targetFile = File(finalPath);

    if (await targetFile.exists()) {
      // Open existing
      final result = await OpenFile.open(finalPath);
      if (result.type != ResultType.done) {
        Messenger.alertError("Could not open file.");
      }
      return;
    }

    // Not downloaded - Request Permission
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      final status2 = await Permission.manageExternalStorage.request();
      if (!status.isGranted && !status2.isGranted) {}
    }

    // Download
    Messenger.alertSuccess('Downloading document...');
    await Dio().download(urlOrPath, finalPath);
    Messenger.alertSuccess('Saved to NowDigitalEasy/Media');

    // Open
    final result = await OpenFile.open(finalPath);
    if (result.type != ResultType.done) {
      Messenger.alertError("Could not open downloaded file.");
    }
  } catch (e) {
    print("Error downloading/opening file: $e");
    Messenger.alertError("Failed to open file.");
  }
}

void updateLocalReactions({
 required String targetMessageId,
  required String? newEmoji,
  required String currentUserId,
  required String firstname,
  required String lastname,
  required String convoId,
  required void Function(void Function()) setState,
  required List<Map<String, dynamic>> allMessages,
  required ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
})
{
  if (targetMessageId.trim().isEmpty) return;

  bool changed = false;
  log("newEmoji..> $newEmoji");
  void updateList(List<Map<String, dynamic>> list) {
    for (final msg in list) {
      final msgId =
      (msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? msg['_id'])
          ?.toString();

      if (msgId != targetMessageId) continue;

      final reactions = extractReactionsFromMessage(msg);

      // 🔥 remove my old reaction
      reactions.removeWhere((r) => r['userId']?.toString() == currentUserId);

      // 🔥 add new reaction
      if (newEmoji != null && newEmoji.isNotEmpty) {
        reactions.add({
          'emoji': newEmoji,
          'userId': currentUserId,
          'user': {
            '_id': currentUserId,
            'first_name':firstname ?? "",
            'last_name': lastname ?? "",
          },
          'reacted_at': DateTime.now().toIso8601String(),
        });
      }

      msg['reactions'] = reactions;
      changed = true;
    }
  }

  setState(() {
    // ✅ ONLY update the list used by UI
    updateList(allMessages);

    if (changed) {
      updateNotifierFromAll(allMessages:allMessages, messagesNotifier: messagesNotifier);

      LocalChatStorage.saveMessages(convoId, allMessages);
    }
  });
}

void toggleMessageSelection({
  required Map<String, dynamic> msg,
  required void Function(void Function()) setState,
  required Set<String> selectedMessageKeys,
  required  Set<String> selectedMessageIds,
  required  bool isSelectionMode,
  required  List<Map<String, dynamic>> selectedMessages,
  required  String Function(Map<String, dynamic>) generateMessageKey,

}) {
  final key = generateMessageKey(msg);
  final String? messageId = msg['message_id']?.toString();

  setState(() {
    if (selectedMessageIds.contains(messageId)) {
      selectedMessageIds.remove(messageId);
      selectedMessageKeys.remove(key);
      selectedMessages.removeWhere((m) => generateMessageKey(m) == key);
    } else if (messageId != null) {
      selectedMessageIds.add(messageId);
      selectedMessageKeys.add(key);
      selectedMessages.add(msg);
    }
    isSelectionMode = selectedMessageIds.isNotEmpty;
  });
}

void markMessagesAsDeleted({
String deleteFor = 'everyone',
required List<String> messageIds,
  required void Function(void Function()) setState,
  required  List<Map<String, dynamic>> dbMessages,
  required  List<Map<String, dynamic>> messages,
  required  List<Map<String, dynamic>> socketMessages,
  required void Function({bool isInitialLoad}) updateNotifier,
  required void Function() scheduleSaveMessages,
  required  String convoId,
})
{
  if (messageIds.isEmpty) return;

  bool changed = false;

  void markInList(List<Map<String, dynamic>> list) {
    if (deleteFor == 'me') {
      final initialLen = list.length;
      list.removeWhere((msg) {
        final id = (msg['message_id'] ?? msg['messageId'] ?? '').toString();
        return id.isNotEmpty && messageIds.contains(id);
      });
      if (list.length != initialLen) changed = true;
    } else {
      for (var i = 0; i < list.length; i++) {
        final msg = list[i];
        final id = (msg['message_id'] ?? msg['messageId'] ?? '').toString();
        if (id.isNotEmpty && messageIds.contains(id)) {
          msg['content'] = "🚫 This message was deleted";
          msg['imageUrl'] = "";
          msg['fileUrl'] = "";
          msg['fileName'] = "";
          msg['mimeType'] = msg['mimeType'] ?? msg['fileType'] ?? "";
          msg['messageStatus'] = 'deleted';
          msg['is_deleted'] = true;
          changed = true;
        }
      }
    }
  }

  setState(() {
    markInList(socketMessages);
    markInList(messages);
    markInList(dbMessages);
  });

  if (changed) {
    try {
      updateNotifier();
    } catch (_) {}
    try {
      scheduleSaveMessages();
    } catch (_) {
      if (convoId.isNotEmpty) {
        final combined = [...dbMessages, ...messages, ...socketMessages];
        LocalChatStorage.saveMessages(convoId, combined);
      }
    }
  }
}

void deleteSelectedMessages({
required  String deleteFor,
  required void Function(void Function()) setState,
  required Set<String> selectedMessageKeys,
  required  Set<String> selectedMessageIds,
  required  bool isSelectionMode,
  required  List<Map<String, dynamic>> selectedMessages,
  required  void Function(Map<String, dynamic>) generateMessageKey,
  required void Function() scheduleSaveMessages,
  required void Function(List<String>, {String deleteFor}) markMessagesAsDeleted,
  required MessagerBloc messagerBloc,
  required  String convoId,
  required  String currentUserId,
  required  String receiverId,
  required   Future<void> Function() fetchMessages,
})
{
  if (selectedMessageIds.isEmpty) return;

  markMessagesAsDeleted(selectedMessageIds.toList(), deleteFor: deleteFor);

  messagerBloc.add(DeleteMessagesEvent(
      messageIds: selectedMessageIds.toList(),
      convoId: convoId,
      senderId: currentUserId,
      receiverId:receiverId ,
      message:
      selectedMessageKeys.isNotEmpty ? selectedMessageKeys.first : "",
      deleteFor: deleteFor));

  setState(() {
    selectedMessages.clear();
    selectedMessageIds.clear();
    selectedMessageKeys.clear();
    isSelectionMode = false;
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    fetchMessages();
  });

  scheduleSaveMessages();
}

void starSelectedMessages(
{
  required void Function(void Function()) setState,
  required Set<String> selectedMessageKeys,
  required  Set<String> selectedMessageIds,
  required  bool isSelectionMode,
  required  List<Map<String, dynamic>> selectedMessages,
}
    ) {
  setState(() {
    selectedMessages.clear();
    selectedMessageKeys.clear();
    selectedMessageIds.clear();
    isSelectionMode = false;
  });
}

List<Map<String, dynamic>> extractReactionsFromMessage(
    Map<String, dynamic> message)
{
  final List<Map<String, dynamic>> list = [];

  // 1️⃣ Normal reactions array
  if (message['reactions'] is List) {
    for (final r in message['reactions']) {
      if (r is! Map) continue;

      final map = Map<String, dynamic>.from(r);

      // Normalize userId
      String? userId = map['userId']?.toString() ??
          map['user']?['_id']?.toString() ??
          map['user']?['id']?.toString();

      if (userId == null || userId.isEmpty) continue;

      list.add({
        'emoji': map['emoji'],
        'reacted_at': map['reacted_at'] ?? map['createdAt'],
        'userId': userId,
        'user': map['user'] is Map
            ? Map<String, dynamic>.from(map['user'])
            : {'_id': userId},
      });
    }
  }

  // 2️⃣ Legacy / properties-based reactions
  if (message['properties'] is List) {
    for (final p in message['properties']) {
      if (p is! Map || p['reaction'] == null) continue;

      final r = p['reaction'];
      final userId = p['member_id']?.toString();

      if (userId == null || userId.isEmpty) continue;

      list.add({
        'emoji': r['emoji'],
        'reacted_at': r['reacted_at'],
        'userId': userId,
        'user': {
          '_id': userId,
        },
      });
    }
  }

  return list;
}

Future<void> handleReactionTap(
{
  required Map<String, dynamic> message,
  required String emoji,
  required String currentUserId,
  required MessagerBloc messagerBloc,
  required String convoId,
  required String receiverId,
  required String firstname,
  required String lastname,
  required void Function(void Function()) setState,
  required  List<Map<String, dynamic>> allMessages,
  required  ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
}
    ) async
{
  try {
    final rawId = (message['message_id'] ??
        message['messageId'] ??
        message['id'] ??
        message['_id'] ??
        '')
        .toString();

    if (rawId.isEmpty) {
      log('⚠️ Skipping reaction: message has empty id');
      return;
    }

    final apiMessageId = normalizeMessageIdForApi(rawId);

    // 🔥 Extract reactions safely
    final List<Map<String, dynamic>> reactions =
    extractReactionsFromMessage(message);

    int myIndex = -1;
    String? oldEmoji;

    for (var i = 0; i < reactions.length; i++) {
      final r = reactions[i];
      final uid = (r['userId'] ??
          r['user']?['_id'] ??
          r['user']?['id'] ??
          r['senderId'])
          ?.toString();

      if (uid == currentUserId) {
        myIndex = i;
        oldEmoji = r['emoji']?.toString();
        break;
      }
    }

    final bool hasMyReaction = myIndex != -1;

    // CASE 1: remove
    if (hasMyReaction && oldEmoji == emoji) {
      _updateLocalReactionss(setState:setState,currentUserId: currentUserId,convoId: convoId,allMessages: allMessages,firstname: firstname,lastname: lastname,messagesNotifier: messagesNotifier,newEmoji: null,targetMessageId: rawId);

      messagerBloc.add(RemoveReaction(
        messageId: apiMessageId,
        conversationId: convoId,
        emoji: emoji,
        userId: currentUserId,
        receiverId:receiverId,
        firstName: firstname,
        lastName: lastname,
      ));
      return;
    }

    // CASE 2: change emoji
    if (hasMyReaction && oldEmoji != emoji) {
      _updateLocalReactionss(setState:setState,currentUserId: currentUserId,convoId: convoId,allMessages: allMessages,firstname: firstname,lastname: lastname,messagesNotifier: messagesNotifier,newEmoji: null,targetMessageId: rawId);


      messagerBloc.add(RemoveReaction(
        messageId: apiMessageId,
        conversationId:convoId,
        emoji: oldEmoji ?? '',
        userId: currentUserId!,
        receiverId:receiverId ,
        firstName:firstname ,
        lastName: lastname ,
      ));

      messagerBloc.add(AddReaction(
        messageId: apiMessageId,
        conversationId:convoId,
        emoji: emoji,
        userId: currentUserId,
        receiverId:receiverId ,
        firstName: firstname,
        lastName:lastname,
      ));
      _updateLocalReactionss(setState:setState,currentUserId: currentUserId,convoId: convoId,allMessages: allMessages,firstname: firstname,lastname: lastname,messagesNotifier: messagesNotifier,newEmoji: emoji,targetMessageId: rawId);

      return;
    }

    // CASE 3: new reaction
    _updateLocalReactionss(setState:setState,currentUserId: currentUserId,convoId: convoId,allMessages: allMessages,firstname: firstname,lastname: lastname,messagesNotifier: messagesNotifier,newEmoji: emoji,targetMessageId: rawId);


    messagerBloc.add(AddReaction(
      messageId: apiMessageId,
      conversationId:convoId,
      emoji: emoji,
      userId: currentUserId,
      receiverId: receiverId,
      firstName: firstname ,
      lastName:lastname,
    ));
  } catch (e, st) {
    log('❌ Error handling reaction tap: $e\n$st');
  }
}

void _updateLocalReactionss({
 required String targetMessageId,
  required String? newEmoji,
  required String currentUserId,
  required String firstname,
  required String lastname,
  required String convoId,
  required void Function(void Function()) setState,
  required  List<Map<String, dynamic>> allMessages,
  required  ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
})
{
  if (targetMessageId.trim().isEmpty) return;

  bool changed = false;
  log("newEmoji..> $newEmoji");
  void updateList(List<Map<String, dynamic>> list) {
    for (final msg in list) {
      final msgId =
      (msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? msg['_id'])
          ?.toString();

      if (msgId != targetMessageId) continue;

      final reactions = extractReactionsFromMessage(msg);

      // 🔥 remove my old reaction
      reactions.removeWhere((r) => r['userId']?.toString() == currentUserId);

      // 🔥 add new reaction
      if (newEmoji != null && newEmoji.isNotEmpty) {
        reactions.add({
          'emoji': newEmoji,
          'userId': currentUserId,
          'user': {
            '_id': currentUserId,
            'first_name': firstname ?? "",
            'last_name':lastname ?? "",
          },
          'reacted_at': DateTime.now().toIso8601String(),
        });
      }

      msg['reactions'] = reactions;
      changed = true;
    }
  }

  setState(() {
    // ✅ ONLY update the list used by UI
    updateList(allMessages);

    if (changed) {
      updateNotifierFromAll(allMessages:allMessages, messagesNotifier: messagesNotifier);

      LocalChatStorage.saveMessages(convoId, allMessages);
    }
  });
}

String anyId(Map<String, dynamic> m) {
  final candidates = [
    m['message_id'],
    m['messageId'],
    m['id'],
    m['_id'],
    m['reply_message_id'],
    m['replyMessageId'],
    if (m['reply'] is Map) m['reply']['reply_message_id'],
    if (m['reply'] is Map) m['reply']['message_id'],
    if (m['reply'] is Map) m['reply']['id'],
    if (m['repliedMessage'] is Map) m['repliedMessage']['reply_message_id'],
    if (m['repliedMessage'] is Map) m['repliedMessage']['message_id'],
    if (m['repliedMessage'] is Map) m['repliedMessage']['id'],
  ];

  for (final c in candidates) {
    if (c != null && c.toString().isNotEmpty) {
      return c.toString();
    }
  }
  return '';
}

void onMessageTap({
  required Map<String, dynamic> message,
  required bool isSelectionMode,
  required void Function(Map<String, dynamic>) toggleMessageSelection,
  required ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
  required  Map<String, BuildContext> messageContexts,
  required   void Function(String) highlightMessage,
  required   ScrollController scrollController,
  required  List<Map<String, dynamic>> dbMessages,
  required  List<Map<String, dynamic>> messages,
  required  List<Map<String, dynamic>> socketMessages,
  required DateTime Function(dynamic) parseTime,
  required  bool Function(Map<String, dynamic>) hasReplyForMessage,
  required  bool hasNextPage,
  required  MessagerBloc messagerBloc,
  required  String convoId,
  required   int currentPage,
  required   int initialLimit,
  required bool mounted,
  required bool Function(DateTime?, DateTime?) isSameDay,
}) async {
  if (isSelectionMode) {
    toggleMessageSelection(message);
    return;
  }
  final bool isDeleted =
      message['is_deleted'] == true || message['messageStatus'] == 'deleted';

  if (isDeleted) return;

  debugPrint('📩 tapped message id: ${anyId(message)}');
  log('📩 tapped message raw: $message');

  String? extractReplyId(Map<String, dynamic> m) {
    final reply = m['reply'];

    if (reply is Map<String, dynamic>) {
      for (final key in [
        'reply_message_id',
        'message_id',
        'messageId',
        'id',
        '_id',
      ]) {
        final v = reply[key];
        if (v != null && v.toString().isNotEmpty) {
          return v.toString();
        }
      }
    }

    // 2️⃣ Check top-level reply fields
    for (final key in [
      'reply_message_id',
      'replyId',
      'reply_to_id',
      'replyMessageId'
    ]) {
      final v = m[key];
      if (v != null && v.toString().isNotEmpty) {
        return v.toString();
      }
    }

    // 3️⃣ Check repliedMessage map (from MessageHandler)
    final replied = m['repliedMessage'];
    if (replied is Map<String, dynamic>) {
      for (final key in [
        'reply_message_id',
        'message_id',
        'messageId',
        'id',
        '_id',
      ]) {
        final v = replied[key];
        if (v != null && v.toString().isNotEmpty) {
          return v.toString();
        }
      }
    }

    return null;
  }

  final replyId = extractReplyId(message);
  debugPrint('📌 extracted replyId: $replyId');
  final groupId = message["reply"]?['group_message_id']?.toString() ?? "";
  debugPrint('📌 extracted groupId: $groupId');

  if (replyId != null && replyId.isNotEmpty) {
    final found = await scrollToMessageById(replyId!,
      fetchIfMissing: true,
      messageContexts: messageContexts,
      highlightAndScrollToContext: (ctx, messageId) {
        highlightAndScrollToContext(
          ctx,
          messageId,
          highlightMessage,
        );
      },
      messagesNotifier: messagesNotifier,
      scrollController: scrollController,
      estimateScrollOffset:(listIndex, messageId) {
        return estimateScrollOffset(listIndex,messageId,parseTime,isSameDay);
      } ,

      highlightMessage: highlightMessage,
      fetchUntilMessageFound: (listIndex) {
        return fetchUntilMessageFound(messageId: replyId, mounted: mounted, dbMessages:dbMessages, messages:messages, socketMessages: socketMessages, parseTime:parseTime, hasReplyForMessage: hasReplyForMessage, hasNextPage: hasNextPage, messagerBloc: messagerBloc, convoId: convoId, currentPage: currentPage, initialLimit: initialLimit);
      },


      estimateMessageHeight: (listIndex,messageId) {
        return estimateMessageHeight(listIndex,messageId,parseTime,isSameDay);
      },);

    if (!found) {
      Messenger.alert(
        msg: "Original message not loaded. Scroll up to load older messages.",
      );
    }
  }
}

void onMessageLongPress({
 required Map<String, dynamic> message,
  required bool isSelectionMode,
  required  void Function(void Function()) setState,
  required   void Function(Map<String, dynamic>) toggleMessageSelection,

}) {
  if (message['is_deleted'] == true) {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
      });
    }
    toggleMessageSelection(message);
    return;
  }

  if (!isSelectionMode) {
    setState(() {
      isSelectionMode = true;
    });
  }
  toggleMessageSelection(message);
}