
import 'package:nde_email/presantation/chat/chat_group_Screen/group_repliedmessage_preview.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/message_caption.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/whatsapp_swipe_to_reply.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/audio_message_widget.dart';

import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/utils/reusbale/mime.type.dart';

class GroupMessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSentByMe;
  final String currentUserId;
  final bool isSelectionMode;
  final Set<String> selectedMessageKeys;
  final String searchText;
  final File? imageFile;
  final File? fileUrl;
  final String conversationId;
  final String groupName;
  final Map<String, BuildContext> messageContexts;

  // Callbacks
  final Function(Map<String, dynamic>) onMessageTap;
  final Function(Map<String, dynamic>) onReplyToMessage;
  final Function(BuildContext, Map<String, dynamic>) onShowReactionPicker;
  final Function(Map<String, dynamic>) onToggleMessageSelection;
  final Function(BuildContext, String, {Map<String, dynamic>? message})
      onShowFullImage;
  final Function(String, String?) onOpenFilex;
  final Function(String, {bool fetchIfMissing}) onScrollToMessageById;

  // Helper functions
  final String Function(String?) sanitizeString;
  final List<InlineSpan> Function(String, TextStyle) buildHighlightSpans;
  final int Function(Map<String, dynamic>?) calculateGroupMediaLength;
  final bool Function(Map<String, dynamic>?) hasMixedMediaTypes;
  final Map<String, dynamic> Function(dynamic) mergeReplyData;
  final Map<String, dynamic> Function(Map<String, dynamic>) normalizeMessage;
  final Widget Function(String, Map<String, dynamic>) buildStatusIcon;
  final List<InlineSpan> Function(String, bool) buildMessageTextSpans;
  final Widget Function(
          BuildContext, String, String, bool, Map<String, dynamic>)
      buildVideoPreviewTile;
  final Widget Function(Map<String, dynamic>, bool) buildReactionsBar;
  final Widget Function(String) buildAvatarWithInitial;
  final String Function(Map<String, dynamic>) generateMessageKey;

  const GroupMessageBubbleWidget({
    super.key,
    required this.message,
    required this.isSentByMe,
    required this.currentUserId,
    required this.isSelectionMode,
    required this.selectedMessageKeys,
    required this.searchText,
    this.imageFile,
    this.fileUrl,
    required this.conversationId,
    required this.groupName,
    required this.messageContexts,
    required this.onMessageTap,
    required this.onReplyToMessage,
    required this.onShowReactionPicker,
    required this.onToggleMessageSelection,
    required this.onShowFullImage,
    required this.onOpenFilex,
    required this.onScrollToMessageById,
    required this.sanitizeString,
    required this.buildHighlightSpans,
    required this.calculateGroupMediaLength,
    required this.hasMixedMediaTypes,
    required this.mergeReplyData,
    required this.normalizeMessage,
    required this.buildStatusIcon,
    required this.buildMessageTextSpans,
    required this.buildVideoPreviewTile,
    required this.buildReactionsBar,
    required this.buildAvatarWithInitial,
    required this.generateMessageKey,
  });

  static const voidBox = SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    // Sanitize message content early to avoid invalid strings in any downstream Text widgets
    final String content = sanitizeString(message['content']?.toString() ?? '');
    final String? imageUrl = message['imageUrl'] ?? imageFile?.path;
    final String? fileUrlValue = message['fileUrl'] ?? fileUrl?.path;
    final String? fileName = message['fileName']?.toString() ?? '';
    final String? fileType = message['fileType'];
    final bool? isForwarded = message['isForwarded'] ?? false;

    final String userName =
        (message['userName']?.toString().trim().isNotEmpty == true)
            ? sanitizeString(message['userName']?.toString())
            : (() {
                final s = message['sender'];
                if (s is Map) {
                  final first =
                      sanitizeString(s['first_name'] ?? s['firstName'] ?? '');
                  final last =
                      sanitizeString(s['last_name'] ?? s['lastName'] ?? '');
                  return [first, last, sanitizeString(s['name'] ?? '')]
                      .where((e) => e.toString().trim().isNotEmpty)
                      .join(' ')
                      .trim();
                }
                return '';
              })();

    final String contentType = message['ContentType'] ?? "";
    final senderData = message['sender'] is Map ? message['sender'] : {};
    final String profileImageUrl = senderData['profile_pic_path']?.toString() ??
        senderData['profilePic']?.toString() ??
        senderData['avatar']?.toString() ??
        message['profile_pic_path']?.toString() ??
        "";

    final bool isImage =
        (fileType != null && fileType.toLowerCase().startsWith("image")) ||
            (fileName != null &&
                RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$', caseSensitive: false)
                    .hasMatch(fileName));

    final bool isVideo =
        (fileType != null && fileType.toLowerCase().startsWith("video")) ||
            (fileName != null &&
                RegExp(r'\.(mp4|mov|avi|mkv|webm)$', caseSensitive: false)
                    .hasMatch(fileName));

    final bool isAudio = (fileType != null &&
            fileType.toLowerCase().startsWith("audio")) ||
        (fileName != null &&
            RegExp(r'\.(mp3|wav|aac|m4a|flac|ogg|opus)$', caseSensitive: false)
                .hasMatch(fileName));

    final String messageStatus =
        message['messageStatus']?.toString() ?? 'delivered';

    if (content.isEmpty &&
        (imageUrl == null || imageUrl.isEmpty) &&
        (fileUrlValue == null || fileUrlValue.isEmpty)) {
      return const SizedBox.shrink();
    }

    final isSelected =
        selectedMessageKeys.contains(generateMessageKey(message));
    final bool isDeleted = message['is_deleted'] == true ||
        message['isDeleted'] == true ||
        message['messageStatus'] == 'deleted' ||
        message['content'] == '🚫 This message was deleted';

    final bool hasReply = !isDeleted &&
            (message['repliedMessage'] is Map &&
                (message['repliedMessage']['id'] ??
                        message['repliedMessage']['message_id'] ??
                        message['repliedMessage']['messageId']) !=
                    null) ||
        (message['reply'] is Map &&
            (message['reply']['id'] ??
                    message['reply']['message_id'] ??
                    message['reply']['messageId']) !=
                null);

    final messageId = (message['message_id'] ??
                message['messageId'] ??
                message['id'] ??
                message['_id'])
            ?.toString() ??
        '';
    final bool hasFile = fileUrlValue != null && fileUrlValue.isNotEmpty;

    return message['content'].contains('Group created by')
        ? voidBox
        : (contentType == "system" &&
                (content.contains('added') || content.contains('left')))
            ? voidBox
            : Builder(
                builder: (context) {
                  // Register context for scrolling
                  if (messageId.isNotEmpty) {
                    messageContexts[messageId] = context;
                  }

                  return SwipeToReply(
                      icon: Icons.reply,
                      iconColor: Colors.grey.shade600,
                      onReply: isDeleted
                          ? null
                          : () {
                              onReplyToMessage(message);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () => onMessageTap(message),
                          onLongPress: () {
                            if (isSelectionMode) {
                              onToggleMessageSelection(message);
                            } else if (!isDeleted) {
                              onShowReactionPicker(context, message);

                              // Enter selection mode is handled by parent
                              onToggleMessageSelection(message);
                            } else {
                              // If deleted, only enter selection mode
                              onToggleMessageSelection(message);
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Align(
                                alignment: isSentByMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                widthFactor: hasReply ? 1.0 : null,
                                child:
                                    Stack(clipBehavior: Clip.none, children: [
                                  Row(
                                    mainAxisAlignment: isSentByMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      if (isSentByMe &&
                                          (isVideo ||
                                              isImage ||
                                              hasFile ||
                                              (content.isNotEmpty &&
                                                  RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                                                          caseSensitive: false)
                                                      .hasMatch(content))))
                                        Center(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap: () {
                                                MyRouter.pushReplace(
                                                  screen: ForwardMessageScreen(
                                                    messages: [
                                                      normalizeMessage(message)
                                                    ],
                                                    currentUserId:
                                                        currentUserId,
                                                    conversionalid:
                                                        conversationId,
                                                    username: groupName,
                                                  ),
                                                );
                                              },
                                              child: CircleAvatar(
                                                maxRadius: 16,
                                                backgroundColor: Colors.white,
                                                child: Image.asset(
                                                  "assets/images/forward.png",
                                                  height: 20,
                                                  width: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Flexible(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 30),
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              left: 5,
                                              right: 5,
                                              top: 0,
                                              bottom: (message['reactions'] !=
                                                          null &&
                                                      message['reactions']
                                                          .isNotEmpty)
                                                  ? 20
                                                  : 0,
                                            ),
                                            padding: hasReply
                                                ? EdgeInsets.only(
                                                    left: 5,
                                                    bottom: 3,
                                                    right: 6)
                                                : const EdgeInsets.only(
                                                    top: 8,
                                                    left: 10,
                                                    right: 6,
                                                    bottom: 8),
                                            constraints: BoxConstraints(
                                                maxWidth: 250,
                                                minWidth: hasReply ? 120 : 0),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? senderColor.withValues(alpha:0.2)
                                                  : (isSentByMe
                                                      ? senderColor
                                                      : receiverColor),
                                              borderRadius: BorderRadius.only(
                                                topLeft: isSentByMe
                                                    ? const Radius.circular(18)
                                                    : const Radius.circular(18),
                                                topRight: isSentByMe
                                                    ? const Radius.circular(18)
                                                    : const Radius.circular(18),
                                                bottomLeft: isSentByMe
                                                    ? const Radius.circular(18)
                                                    : Radius.zero,
                                                bottomRight: isSentByMe
                                                    ? Radius.zero
                                                    : const Radius.circular(16),
                                              ),
                                              border: isSelected
                                                  ? Border.all(
                                                      color: Colors.blue,
                                                      width: 2)
                                                  : null,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha:0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (!isSentByMe &&
                                                          userName.isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  bottom: 4,
                                                                  left: 7,
                                                                  right: 6,
                                                                  top: hasReply
                                                                      ? 6.5
                                                                      : 0),
                                                          child: Text(
                                                            userName,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: ColorUtil
                                                                  .getColorFromAlphabet(
                                                                      userName),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),

                                                      if (isForwarded == true)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 4.0,
                                                                  left: 7,
                                                                  right: 6),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Image.asset(
                                                                "assets/images/forward.png",
                                                                height: 14,
                                                                width: 14,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                "Forwarded",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                          .grey[
                                                                      700],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                      // REPLY PREVIEW - opacity trick for measurement
                                                      if (hasReply)
                                                        Opacity(
                                                          opacity: 0,
                                                          child:
                                                              GroupRepliedMessagePreview(
                                                            key: ValueKey(
                                                                '${messageId}_${message['replyContent']}_placeholder'),
                                                            replied: (message[
                                                                            'repliedMessage'] ??
                                                                        message[
                                                                            'reply'])
                                                                    is Map
                                                                ? Map<String,
                                                                    dynamic>.from(message[
                                                                        'repliedMessage'] ??
                                                                    message[
                                                                        'reply'])
                                                                : <String,
                                                                    dynamic>{},
                                                            receiver: message[
                                                                        'receiver']
                                                                    is Map
                                                                ? Map<String,
                                                                        dynamic>.from(
                                                                    message[
                                                                        'receiver'])
                                                                : {},
                                                            isSender:
                                                                isSentByMe,
                                                            groupMediaLength:
                                                                calculateGroupMediaLength(
                                                                    mergeReplyData(message[
                                                                            'repliedMessage'] ??
                                                                        message[
                                                                            'reply'])),
                                                            onTap: null,
                                                          ),
                                                        ),

                                                      // Main content with proper padding when reply exists
                                                      Padding(
                                                        padding: hasReply
                                                            ? const EdgeInsets
                                                                .only(
                                                                left: 7,
                                                                right: 0,
                                                                bottom: 0,
                                                                top: 0)
                                                            : EdgeInsets.zero,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            _buildMediaContent(
                                                              context,
                                                              imageUrl,
                                                              fileUrlValue,
                                                              fileName,
                                                              isImage,
                                                              isVideo,
                                                              isAudio,
                                                              content,
                                                              isSentByMe,
                                                              messageStatus,
                                                              fileType,
                                                              isDeleted,
                                                              profileImageUrl,
                                                            ),
                                                            _buildTextContent(
                                                              content,
                                                              isImage,
                                                              isVideo,
                                                              isAudio,
                                                              imageUrl,
                                                              fileUrlValue,
                                                              hasReply,
                                                              isSentByMe,
                                                              messageStatus,
                                                              isDeleted,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ]),

                                                // Positioned reply preview (visible)
                                                if (hasReply)
                                                  Positioned(
                                                    top: (!isSentByMe &&
                                                            userName.isNotEmpty)
                                                        ? 25
                                                        : 0,
                                                    left: 0,
                                                    right: 0,
                                                    child:
                                                        GroupRepliedMessagePreview(
                                                      key: ValueKey(
                                                          '${messageId}_${message['replyContent']}'),
                                                      replied: mergeReplyData(
                                                          message['repliedMessage'] ??
                                                              message['reply']),
                                                      receiver: message[
                                                              'receiver'] is Map
                                                          ? Map<String,
                                                                  dynamic>.from(
                                                              message[
                                                                  'receiver'])
                                                          : {},
                                                      isSender: isSentByMe,
                                                      groupMediaLength:
                                                          calculateGroupMediaLength(
                                                              mergeReplyData(message[
                                                                      'repliedMessage'] ??
                                                                  message[
                                                                      'reply'])),
                                                      hasMixedMedia: hasMixedMediaTypes(
                                                          mergeReplyData(message[
                                                                  'repliedMessage'] ??
                                                              message[
                                                                  'reply'])),
                                                      onTap: () async {
                                                        final replyId = ((message[
                                                                                'repliedMessage'] ??
                                                                            message[
                                                                                'reply'])?[
                                                                        'id'] ??
                                                                    (message['repliedMessage'] ??
                                                                            message['reply'])?[
                                                                        'message_id'] ??
                                                                    (message[
                                                                            'repliedMessage'] ??
                                                                        message[
                                                                            'reply'])?['messageId'])
                                                                ?.toString() ??
                                                            '';
                                                        if (replyId
                                                            .isNotEmpty) {
                                                          await onScrollToMessageById(
                                                              replyId,
                                                              fetchIfMissing:
                                                                  true);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                // TIMESTAMP & STATUS - Positioned at Container Stack level for replied messages
                                                if (hasReply &&
                                                    content.isNotEmpty)
                                                  Positioned(
                                                    bottom: 3,
                                                    right: 3,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          TimeUtils
                                                              .formatUtcToIst(
                                                                  message[
                                                                      'time']),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .black54),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        if (isSentByMe &&
                                                            content !=
                                                                "Message Deleted")
                                                          buildStatusIcon(
                                                              messageStatus,
                                                              message),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!isSentByMe &&
                                          (isVideo ||
                                              isImage ||
                                              hasFile ||
                                              (content.isNotEmpty &&
                                                  RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                                                          caseSensitive: false)
                                                      .hasMatch(content))))
                                        Center(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 15.0),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                onTap: () {
                                                  MyRouter.pushReplace(
                                                    screen:
                                                        ForwardMessageScreen(
                                                      messages: [
                                                        normalizeMessage(
                                                            message)
                                                      ],
                                                      currentUserId:
                                                          currentUserId,
                                                      conversionalid:
                                                          conversationId,
                                                      username: groupName,
                                                    ),
                                                  );
                                                },
                                                child: CircleAvatar(
                                                  maxRadius: 16,
                                                  backgroundColor: Colors.white,
                                                  child: Image.asset(
                                                    "assets/images/forward.png",
                                                    height: 20,
                                                    width: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ]),
                              ),
                              // Avatar positioned outside the message bubble
                              if (!isSentByMe)
                                Positioned(
                                  left: -2,
                                  top: 10,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.transparent,
                                    child: ClipOval(
                                      child: profileImageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: profileImageUrl,
                                              width: 32,
                                              height: 32,
                                              memCacheWidth: 480,
                                              memCacheHeight: 600,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  buildAvatarWithInitial(
                                                      userName),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      buildAvatarWithInitial(
                                                          userName),
                                            )
                                          : buildAvatarWithInitial(userName),
                                    ),
                                  ),
                                ),
                              // REACTIONS BAR - Positioned outside the message bubble
                              if (message['reactions'] != null &&
                                  message['reactions'].isNotEmpty)
                                Positioned(
                                  bottom: hasReply ? -20 : -18,
                                  left: isSentByMe ? null : 40,
                                  right: isSentByMe ? 14 : null,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 12,
                                      left: isSentByMe ? 5 : 0,
                                    ),
                                    child:
                                        buildReactionsBar(message, isSentByMe),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ));
                },
              );
  }

  Widget _buildMediaContent(
    BuildContext context,
    String? imageUrl,
    String? fileUrlValue,
    String? fileName,
    bool isImage,
    bool isVideo,
    bool isAudio,
    String content,
    bool isSentByMe,
    String messageStatus,
    String? fileType,
    bool isDeleted,
    String profileImageUrl,
  ) {
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        isImage &&
        !isVideo &&
        !isAudio) {
      return content == "Message Deleted"
          ? const SizedBox.shrink()
          : Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () =>
                      onShowFullImage(context, imageUrl, message: message),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.startsWith('https') ||
                            imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 240,
                            memCacheWidth: 480,
                            memCacheHeight: 600,
                            height: 300,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          )
                        : Image.file(File(imageUrl),
                            width: 240, height: 320, fit: BoxFit.cover),
                  ),
                ),
                if (content.isEmpty)
                  Positioned(
                    bottom: 5,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        color: Colors.black45.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            TimeUtils.formatUtcToIst(message['time']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          if (isSentByMe) ...[
                            const SizedBox(width: 4),
                            Builder(builder: (context) {
                              switch (messageStatus) {
                                case 'sent':
                                  return const Icon(Icons.check,
                                      size: 12, color: Colors.white);
                                case 'delivered':
                                  return const Icon(Icons.done_all_rounded,
                                      size: 12, color: Colors.white);
                                case 'read':
                                  return const Icon(Icons.done_all,
                                      size: 12, color: Colors.blue);
                                default:
                                  return const SizedBox.shrink();
                              }
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
    }

    if (fileUrlValue != null && fileUrlValue.isNotEmpty && isVideo) {
      return buildVideoPreviewTile(
        context,
        fileUrlValue,
        fileName ?? "",
        isSentByMe,
        message,
      );
    }

    if (fileUrlValue != null && fileUrlValue.isNotEmpty && isAudio) {
      return AudioMessageWidget(
        audioUrl: fileUrlValue,
        profileAvatarUrl: profileImageUrl,
        isSender: isSentByMe,
        duration: message['duration']?.toString(),
        timestamp: TimeUtils.formatUtcToIst(message['time']),
        status: messageStatus,
        showContainer: false,
      );
    }

    if (fileUrlValue != null &&
        fileUrlValue.isNotEmpty &&
        !(content == "Message Deleted" ||
            isImage ||
            (fileType != null && fileType.toLowerCase().startsWith("image")) ||
            (fileName != null &&
                RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$', caseSensitive: false)
                    .hasMatch(fileName)))) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 300,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildIcon(
                        type: '',
                        mimeType: (fileType != null && fileType.isNotEmpty)
                            ? fileType
                            : fileName,
                        size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: buildHighlightSpans(
                            isDeleted ? '' : (fileName ?? 'Download file'),
                            const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => onOpenFilex(fileUrlValue, fileType),
                    ),
                  ],
                ),
              ),
              // Only show time/status for documents without caption
              if (content.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 0, right: 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TimeUtils.formatUtcToIst(message['time']),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54),
                      ),
                      const SizedBox(width: 4),
                      if (isSentByMe) buildStatusIcon(messageStatus, message),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTextContent(
    String content,
    bool isImage,
    bool isVideo,
    bool isAudio,
    String? imageUrl,
    String? fileUrlValue,
    bool hasReply,
    bool isSentByMe,
    String messageStatus,
    bool isDeleted,
  ) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use MessageCaption for image/video/document captions to position time/status in the right corner
    if ((isImage && (imageUrl != null && imageUrl.isNotEmpty)) ||
        (isVideo && fileUrlValue != null && fileUrlValue.isNotEmpty) ||
        (fileUrlValue != null &&
            fileUrlValue.isNotEmpty &&
            !isImage &&
            !isVideo &&
            !isAudio)) {
      return MessageCaption(
        content: content,
        time: TimeUtils.formatUtcToIst(message['time']),
        isSentByMe: isSentByMe,
        messageStatus: messageStatus,
        buildStatusIcon: (status) => buildStatusIcon(status, message),
        searchText: searchText,
        isDeleted: isDeleted,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Column(
        crossAxisAlignment:
            hasReply ? CrossAxisAlignment.start : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false)
              .hasMatch(content))
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnyLinkPreview(
                      link: (() {
                        final match = RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                                caseSensitive: false)
                            .firstMatch(content);
                        if (match == null) {
                          return '';
                        }
                        String url = match.group(0)!;
                        try {
                          final uri = Uri.parse(
                              url.startsWith('www.') ? 'https://$url' : url);
                          return uri.toString();
                        } catch (e) {
                          return url;
                        }
                      })(),
                      displayDirection: UIDirection.uiDirectionVertical,
                      showMultimedia: true,
                      backgroundColor: Colors.grey.shade100,
                      bodyStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      titleStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      cache: const Duration(hours: 1),
                      borderRadius: 12,
                      errorBody: 'Could not load link preview',
                      errorTitle: 'Link Preview',
                      errorWidget: Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.link_off)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Stack(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  const maxCharsPerLine = 30;
                  final bool isTextLong =
                      (content.length / maxCharsPerLine).ceil() > 10;
                  bool isExpanded = (message['isExpanded'] ?? false) == true;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3.0, top: 1.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              maxLines: !isExpanded && isTextLong ? 9 : null,
                              overflow: !isExpanded && isTextLong
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.visible,
                              text: TextSpan(
                                children: [
                                  ...buildMessageTextSpans(content, isDeleted),
                                  WidgetSpan(
                                    child: SizedBox(
                                        width: isSentByMe ? 75 : 60,
                                        height: 20),
                                  ),
                                ],
                              ),
                            ),
                            if (!isExpanded && isTextLong)
                              GestureDetector(
                                onTap: () => setState(
                                    () => message['isExpanded'] = true),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    "Read more",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            if (isExpanded)
                              GestureDetector(
                                onTap: () => setState(
                                    () => message['isExpanded'] = false),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    "Read less",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            if (!isExpanded && isTextLong)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      TimeUtils.formatUtcToIst(message['time']),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.black54),
                                    ),
                                    const SizedBox(width: 4),
                                    if (isSentByMe &&
                                        content != "Message Deleted")
                                      buildStatusIcon(messageStatus, message),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      /// ---- TIMESTAMP & STATUS (Positioned like private chat) ----
                      if (!(!isExpanded && isTextLong) && !hasReply)
                        Positioned(
                          bottom: 3,
                          right: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                TimeUtils.formatUtcToIst(message['time']),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black54),
                              ),
                              const SizedBox(width: 4),
                              if (isSentByMe && content != "Message Deleted")
                                buildStatusIcon(messageStatus, message),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
