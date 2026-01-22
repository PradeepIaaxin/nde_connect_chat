import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MixedMediaViewer.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/commonfuntion.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/replymessgae.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_viewer.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/message_caption.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/AudioMessageWidget.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:shimmer/shimmer.dart';
import 'package:linkify/linkify.dart';
import 'VideoCacheService.dart';
import 'VideoPlayerScreen.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isSentByMe;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRightSwipe;
  final Function(String url, String? fileType)? onFileTap;
  final Widget Function(String status)? buildStatusIcon;
  final Widget Function(Map<String, dynamic> msg, bool isSentByMe)?
      buildReactionsBar;
  final Color sentMessageColor;
  final Color receivedMessageColor;
  final Color selectedMessageColor;
  final Color borderColor;
  final Color chatColor;
  final Function(Map<String, dynamic> message, String emoji)? onReact;
  final VoidCallback? emojpicker;
  final VoidCallback? onReplyTap;
  final bool isReply;
  final int? groupMediaLength;
  final List<Map<String, dynamic>> allMessages;
  final String? currentUserId;
  final String? receiverName;
  final bool stretchReply;
  final String? searchText;
  final List<String> recentEmojis;
  final Function(List<String>) onEmojiUpdated;
  final bool isSelectionMode;

  const MessageBubble(
      {super.key,
      required this.message,
      required this.isSentByMe,
      required this.isSelected,
      this.onTap,
      this.onLongPress,
      this.onRightSwipe,
      this.onFileTap,
      this.buildStatusIcon,
      this.buildReactionsBar,
      required this.sentMessageColor,
      required this.receivedMessageColor,
      required this.selectedMessageColor,
      required this.borderColor,
      required this.chatColor,
      this.onReact,
      this.emojpicker,
      required this.isReply,
      this.onReplyTap,
      this.groupMediaLength,
      required this.allMessages,
      this.currentUserId,
      this.receiverName,
      this.stretchReply = false,
      required this.recentEmojis,
      required this.onEmojiUpdated,
      this.searchText,
      required this.isSelectionMode});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  List<String> _recentEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    final String content = widget.message['content']?.toString() ?? '';
    final String? fileUrl = widget.message['fileUrl'];
    final String? fileName = widget.message['fileName'];
    final String? fileTypeRaw = widget.message['fileType']?.toString();
    final String fileType = fileTypeRaw?.toLowerCase() ?? '';

    final bool isImage = fileType.startsWith('image/') ||
        (fileName != null &&
            RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp|heic|heif|svg)$',
                    caseSensitive: false)
                .hasMatch(fileName));

    final bool isVideo = fileType.startsWith('video/') ||
        (widget.message['isVideo'] == true) ||
        (fileName != null &&
            RegExp(r'\.(mp4|mov|avi|mkv|webm)$', caseSensitive: false)
                .hasMatch(fileName));

    final bool isAudio = (widget.message['ContentType'] == 'audio') ||
        (fileType.startsWith('audio')) ||
        (fileName != null &&
            RegExp(r'\.(mp3|wav|aac|m4a|flac|ogg|opus)$', caseSensitive: false)
                .hasMatch(fileName));

    final String? imageUrl = widget.message['imageUrl'];
    final String? originalUrl = widget.message['originalUrl']?.toString();
    final String? displayImageUrl = originalUrl ??
        imageUrl ??
        ((isImage || (fileUrl != null && isImage)) ? fileUrl : null);

    final bool? isForwarded = widget.message['isForwarded'] ?? false;
    final bool? isReplyMessage = widget.message['isReplyMessage'];
    final String messageStatus =
        widget.message['messageStatus']?.toString() ?? 'sent';

    final replyData = widget.message['reply'];
    final replyId =
        widget.message['reply_message_id'] ?? widget.message['replyMessageId'];
    final replyContent = widget.message['replyContent'];
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDeleted = widget.message['is_deleted'] == true ||
        widget.message['messageStatus'] == 'deleted';

    bool hasReply = ((replyData is Map && replyData.isNotEmpty) ||
            (replyId != null && replyId.toString().isNotEmpty) ||
            (replyContent != null && replyContent.toString().isNotEmpty)) &&
        !isDeleted;

    final bool hasFile = fileUrl != null && fileUrl.isNotEmpty;
    final bool hasImageContent = displayImageUrl != null &&
        displayImageUrl.isNotEmpty &&
        (isImage || (displayImageUrl != fileUrl));

    if (content.isEmpty &&
        !hasImageContent &&
        !hasFile &&
        !isAudio &&
        !isVideo) {
      return const SizedBox.shrink();
    }
    bool _ignoreParentTap = false;

    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: widget.emojpicker != null ? 6.0 : 0),
      child: Align(
        alignment:
            widget.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: widget.isReply ? 1.0 : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                if (widget.isSelectionMode) {
                  widget.onLongPress?.call();
                } else if (widget.isReply) {
                  widget.onReplyTap?.call();
                } else {
                  widget.onTap?.call();
                }
              },

              // onTap: () {
              //   log("messsssssage ${widget.message}");
              //   log("relosveeee ${widget.message["resolvedReplys"]}");
              // },
              onLongPress: () {
                log(widget.message.toString());
                _showReactionPicker(context);
                widget.onLongPress?.call();
              },
              child: Container(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.only(
                  left: 9,
                  right: 9,
                  bottom: (widget.message['reactions'] != null &&
                          (widget.message['reactions'] as List).isNotEmpty)
                      ? 8
                      : 0,
                ),
                padding: widget.isReply
                    ? null
                    : const EdgeInsets.only(
                        top: 3, left: 7, right: 6, bottom: 5),
                constraints: const BoxConstraints(maxWidth: 250),
                decoration: BoxDecoration(
                  color: widget.isReply
                      ? null
                      : widget.isSelected
                          ? widget.selectedMessageColor
                          : (widget.isSentByMe
                              ? widget.sentMessageColor
                              : widget.receivedMessageColor),
                  borderRadius: BorderRadius.only(
                    topLeft: widget.isSentByMe
                        ? const Radius.circular(18)
                        : const Radius.circular(18),
                    topRight: widget.isSentByMe
                        ? const Radius.circular(18)
                        : const Radius.circular(18),
                    bottomLeft: widget.isSentByMe
                        ? const Radius.circular(18)
                        : Radius.zero,
                    bottomRight: widget.isSentByMe
                        ? Radius.zero
                        : const Radius.circular(16),
                  ),
                  border: widget.isReply
                      ? null
                      : widget.isSelected
                          ? Border.all(color: widget.borderColor, width: 2)
                          : null,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasReply)
                          RepliedMessagePreview(
                            key: ValueKey(
                                '${widget.message['message_id']}_${widget.message['replyContent']}_placeholder'),
                            replied: widget.message['resolvedReply'] ??
                                widget.message['reply'] ??
                                _buildSyntheticReply(widget.message),
                            receiver: widget.message['sender'] is Map
                                ? Map<String, dynamic>.from(
                                    widget.message['sender'])
                                : {},
                            isSender: widget.isSentByMe,
                            onTap: () {
                              if (widget.isSelectionMode) {
                                widget.onLongPress?.call();
                              } else {
                                widget.onReplyTap?.call();
                              }
                            },
                            groupMediaLength: widget.groupMediaLength,
                          ),

                        if (isForwarded == true)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/images/forward.png",
                                height: 14,
                                width: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Forwarded",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),

                        // Audio Message
                        if (isAudio && hasFile)
                          AudioMessageWidget(
                            audioUrl: fileUrl,
                            profileAvatarUrl: widget.message['sender']
                                    ?['profile_pic_path'] ??
                                widget.message['sender']?['profilePic'] ??
                                widget.message['profile_pic_path'] ??
                                '',
                            isSender: widget.isSentByMe,
                            duration: widget.message['duration']?.toString(),
                            timestamp: TimeUtils.formatUtcToIst(
                                widget.message['time']),
                            status:
                                widget.message['messageStatus']?.toString() ??
                                    'sent',
                            showContainer: false,
                          )

                        // 2. Video Preview
                        else if (isVideo && hasFile)
                          _buildVideoPreviewTile(
                              context,
                              fileUrl,
                              fileName ?? "",
                              widget.isSentByMe,
                              content.isEmpty)

                        // 3. Image preview
                        else if (isImage && (hasImageContent || hasFile))
                          _buildImage(context, content,
                              displayImageUrl ?? fileUrl ?? "", fileName,
                              isSentByMe: widget.isSentByMe,
                              showTime: content.isEmpty)

                        // 4. General File preview (Document)
                        else if (hasFile)
                          _buildFile(
                              context, fileUrl, fileName, fileType, content,
                              isSentByMe: widget.isSentByMe),

                        // Text content
                        if (content.isNotEmpty)
                          // Use MessageCaption for image/video/document captions to position time/status in the right corner
                          if ((isImage && (hasImageContent || hasFile)) ||
                              (isVideo && hasFile) ||
                              (hasFile &&
                                  !isImage &&
                                  !isVideo &&
                                  !isAudio)) // Document
                            MessageCaption(
                              content: content,
                              time: TimeUtils.formatUtcToIst(
                                  widget.message['time']),
                              isSentByMe: widget.isSentByMe,
                              messageStatus: messageStatus,
                              buildStatusIcon: widget.buildStatusIcon,
                              searchText: widget.searchText,
                            )
                          else
                            _buildTextMessage(content, messageStatus),
                      ],
                    ),
                    if (isVideo ||
                        hasImageContent ||
                        hasFile ||
                        (content.isNotEmpty &&
                            RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                                    caseSensitive: false)
                                .hasMatch(content)))
                      Positioned(
                        top: 160,
                        right: widget.isSentByMe ? 420 : null,
                        left: widget.isSentByMe ? null : 420,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                log("hhhhhhhhhhh");
                                MyRouter.pushReplace(
                                  screen: ForwardMessageScreen(
                                    isForward: widget.isSentByMe,
                                    messages: [widget.message],
                                    currentUserId:
                                        widget.message['senderId'] ?? '',
                                    conversionalid: "",
                                    username:
                                        widget.message['senderName'] ?? '',
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 16,
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
                    if (hasReply && widget.stretchReply)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: RepliedMessagePreview(
                          key: ValueKey(
                              '${widget.message['message_id']}_${widget.message['replyContent']}'),
                          replied: widget.message['resolvedReply'] ??
                              widget.message['reply'] ??
                              _buildSyntheticReply(widget.message),
                          receiver: widget.message['sender'] is Map
                              ? Map<String, dynamic>.from(
                                  widget.message['sender'])
                              : {},
                          isSender: widget.isSentByMe,
                          onTap: () {
                            if (widget.isSelectionMode) {
                              widget.onLongPress?.call();
                            } else {
                              widget.onReplyTap?.call();
                            }
                          },
                          groupMediaLength: widget.groupMediaLength,
                        ),
                      )
                    else if (hasReply)
                      RepliedMessagePreview(
                        key: ValueKey(
                            '${widget.message['message_id']}_${widget.message['replyContent']}'),
                        replied: widget.message['resolvedReply'] ??
                            widget.message['reply'] ??
                            _buildSyntheticReply(widget.message),
                        receiver: widget.message['sender'] is Map
                            ? Map<String, dynamic>.from(
                                widget.message['sender'])
                            : {},
                        isSender: widget.isSentByMe,
                        onTap: () {
                          if (widget.isSelectionMode) {
                            widget.onLongPress?.call();
                          } else {
                            widget.onReplyTap?.call();
                          }
                        },
                        groupMediaLength: widget.groupMediaLength,
                      ),
                  ],
                ),
              ),
            ),
            if (widget.message['reactions'] != null &&
                (widget.message['reactions'] as List).isNotEmpty &&
                widget.buildReactionsBar != null)
              Positioned(
                bottom: (isReplyMessage ?? false) ? -40 : -28,
                right: widget.isSentByMe ? 12 : null,
                left: widget.isSentByMe ? null : 12,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      // show reaction picker on tap too
                      _showReactionPicker(context);
                    },
                    child: widget.buildReactionsBar!(
                        widget.message, widget.isSentByMe),
                  ),
                ),
              ),
            if (isVideo ||
                hasImageContent ||
                hasFile ||
                (content.isNotEmpty &&
                    RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                            caseSensitive: false)
                        .hasMatch(content)))
              Positioned(
                top: 0,
                bottom: 0,
                left: widget.isSentByMe ? -35 : screenWidth * 0.65,
                right: widget.isSentByMe ? null : -52,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        log("hhhhhhhhhhh");
                        MyRouter.pushReplace(
                          screen: ForwardMessageScreen(
                            isForward: widget.isSentByMe,
                            messages: [widget.message],
                            currentUserId: widget.message['senderId'] ?? '',
                            conversionalid: "",
                            username: widget.message['senderName'] ?? '',
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 16,
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
      ),
    );
  }

  Map<String, dynamic> _buildSyntheticReply(Map<String, dynamic> message) {
    // Extract the message ID being replied to (if available)
    final replyToMsgId = message['replyToMessageId'] ??
        message['reply_message_id'] ??
        message['replyMessageId'] ??
        '';
    return {
      'id': replyToMsgId,
      'message_id': replyToMsgId,
      'reply_message_id': replyToMsgId,
      'replyContent': message['replyContent'] ?? '',
      'content': message['replyContent'] ?? '',
      'ContentType': message['ContentType'] ?? 'text',
      'fileName': message['fileName'] ?? '',
      'originalUrl': message['originalUrl'] ?? '',
      'thumbnailUrl': message['thumbnailUrl'] ?? '',
      'fileUrl': message['fileUrl'],
      'imageUrl': message['imageUrl'],
      'first_name': message['receiver']?['first_name'] ?? '',
      'last_name': message['receiver']?['last_name'] ?? '',
      'group_message_id': message['group_message_id'],
      'is_grouped_message': message['is_grouped_message'] ?? false,
      'mimeType': message['mimeType'] ?? message['fileType'],
      'duration': message['duration'],
    };
  }

  void _openConversationViewer(BuildContext context, String tappedUrl) {
    final media = buildConversationMedia(
      widget.allMessages,
      currentUserId: widget.currentUserId,
      receiverName: widget.receiverName,
    );
    print("urlllllll $tappedUrl");
    final index = media.indexWhere((m) => m.mediaUrl == tappedUrl);
    print("index $index");

    if (index == -1) {
      print("❌ NO MATCH FOUND for $tappedUrl in ${media.length} items");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MixedMediaViewer(
          items: media,
          initialIndex: index,
        ),
      ),
    );
  }

  // void _showReactionPicker(BuildContext context) {

  void _showReactionPicker(BuildContext context) {
    if (widget.onReact == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...widget.recentEmojis.map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onReact?.call(widget.message, emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  )),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _openFullEmojiPicker(context);
                },
                child: const Icon(Icons.add_circle_outline, size: 26),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFullEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: 350,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              final list = List<String>.from(widget.recentEmojis);

              if (!list.contains(emoji.emoji)) {
                if (list.length >= 6) list.removeAt(0);
                list.add(emoji.emoji);
              }

              widget.onEmojiUpdated(list);

              widget.onReact?.call(widget.message, emoji.emoji);

              Navigator.pop(context);
            },

            // onEmojiSelected: (category, emoji) {
            //   Navigator.pop(context);
            //
            //   setState(() {
            //     if (!_recentEmojis.contains(emoji.emoji)) {
            //       _recentEmojis.removeAt(0); // keep max 6
            //       _recentEmojis.add(emoji.emoji);
            //     }
            //   });
            //
            //   widget.onReact?.call(widget.message, emoji.emoji);
            // },
          ),
        );
      },
    );
  }

  Widget _buildImage(
    BuildContext context,
    String content,
    String imageUrl,
    String? fileName, {
    required bool isSentByMe,
    bool showTime = true,
  }) {
    if (content == "Message Deleted") return const SizedBox();
    final String name = fileName ?? 'Unknown file';
    final String extension =
        name.split('.').isNotEmpty ? name.split('.').last.toLowerCase() : '';
    widget.message['fileSize']?.toString();

    // List of image extensions
    final Set<String> imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif'
    };

    // Helper: heuristically decide if the URL/filename is an image
    bool looksLikeImage(String url, String fileName, String ext) {
      try {
        final lowerUrl = (url).toLowerCase();
        if (imageExtensions.contains(ext)) return true;
        if (lowerUrl
            .contains(RegExp(r'\.(jpe?g|png|gif|webp|bmp|heic|heif)($|\?)'))) {
          return true;
        }
        final uri = Uri.tryParse(lowerUrl);
        if (uri != null && uri.path.toLowerCase().contains('.')) {
          final pExt = uri.path.split('.').last.toLowerCase();
          if (imageExtensions.contains(pExt)) return true;
        }
      } catch (_) {}
      return false;
    }

    final bool looksImage = looksLikeImage(imageUrl, name, extension);
    final bool showTime = content.isEmpty;

    // Choose fallback document tile (so PDFs/docs don't show the red '!') ----------------
    Widget documentFallbackTile() {
      IconData icon = Icons.insert_drive_file;
      switch (extension) {
        case 'pdf':
          icon = Icons.picture_as_pdf;
          break;
        case 'doc':
        case 'docx':
          icon = Icons.description;
          break;
        case 'xls':
        case 'xlsx':
          icon = Icons.table_chart;
          break;
        case 'ppt':
        case 'pptx':
          icon = Icons.slideshow;
          break;
        case 'zip':
        case 'rar':
        case '7z':
          icon = Icons.archive;
          break;
        default:
          icon = Icons.insert_drive_file;
      }

      return Container(
        width: 260,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () => widget.onFileTap?.call(imageUrl, null),
            ),
          ],
        ),
      );
    }

    // Build the image preview -------------------------------------------------------------
    Widget imageWidget() {
      try {
        if (imageUrl.startsWith('http')) {
          return CachedNetworkImage(
            imageUrl: imageUrl,
            width: 260,
            height: imageExtensions.contains(extension) ? 300 : 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 260,
              height: 200,
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 260,
              height: 200,
              color: Colors.grey.shade300,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file,
                        size: 36, color: Colors.grey.shade700),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // local file path
          final f = File(imageUrl);
          if (f.existsSync()) {
            return Image.file(
              f,
              width: 260,
              height: imageExtensions.contains(extension) ? 300 : 200,
              fit: BoxFit.cover,
            );
          } else {
            return documentFallbackTile();
          }
        }
      } catch (e) {
        debugPrint('Error in _imageWidget: $e');
        return documentFallbackTile();
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.deferToChild, // 🔥 IMPORTANT
          onTapDown: (details) {
            final dx = details.localPosition.dx;
            if (dx < 40 || dx > 220) {
              // tap near forward icon area → ignore
              return;
            }
            // openSingleMediaViewer(context);
          },
          onTap: () async {
            if (widget.isSelectionMode) {
              widget.onLongPress?.call();
            } else if (looksImage) {
              _openConversationViewer(context, imageUrl);
            } else {
              // treat as file
              widget.onFileTap?.call(imageUrl, null);
            }
            // if (looksImage) {
            //  _openConversationViewer(context, imageUrl);
            // } else {
            //   // treat as file
            //   widget.onFileTap?.call(imageUrl, null);
            // }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: looksImage ? imageWidget() : documentFallbackTile(),
            ),
          ),
        ),

        // time + status badge

        if (showTime)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TimeUtils.formatUtcToIst(widget.message['time']),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 4),
                    widget.buildStatusIcon?.call(
                            widget.message['messageStatus']?.toString() ??
                                'sent') ??
                        const Icon(Icons.done, size: 12, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _isPresignedUrlExpired(String url) {
    try {
      final u = Uri.parse(url);
      final xDate =
          u.queryParameters['X-Amz-Date'] ?? u.queryParameters['x-amz-date'];
      final expires = int.tryParse(u.queryParameters['X-Amz-Expires'] ??
              u.queryParameters['x-amz-expires'] ??
              '') ??
          0;
      if (xDate == null || expires == 0) return false;
      // xDate like 20251204T052751Z
      final year = int.parse(xDate.substring(0, 4));
      final month = int.parse(xDate.substring(4, 6));
      final day = int.parse(xDate.substring(6, 8));
      final hour = int.parse(xDate.substring(9, 11));
      final minute = int.parse(xDate.substring(11, 13));
      final second = int.parse(xDate.substring(13, 15));
      final signedAt = DateTime.utc(year, month, day, hour, minute, second);
      final expiryAt = signedAt.add(Duration(seconds: expires));
      return DateTime.now().toUtc().isAfter(expiryAt);
    } catch (e) {
      debugPrint('presign-check parse failed: $e');
      return false;
    }
  }

  Future<String?> fetchFreshPresignedUrlFromServer(String imageKeyOrUrl) async {
    return null;
  }

  Future<void> openImageSmart(BuildContext context, String imageUrl) async {
    debugPrint('openImageSmart: try open $imageUrl');

    try {
      final cacheManager = DefaultCacheManager();

      // 1) Try to get the file from cache (fast, uses the same cache used by CachedNetworkImage)
      final cached = await cacheManager.getFileFromCache(imageUrl);
      if (cached != null && await cached.file.exists()) {
        debugPrint('openImageSmart: using cached file ${cached.file.path}');
        // Open with your viewer using local file path
        openSingleMediaViewer(context);
        return;
      }

      // 2) If URL looks like an S3 presigned and expired, request a fresh URL
      if (_isPresignedUrlExpired(imageUrl)) {
        debugPrint(
            'openImageSmart: presigned URL appears expired, asking server for fresh URL.');
        final fresh = await fetchFreshPresignedUrlFromServer(imageUrl);
        if (fresh != null && fresh.isNotEmpty) {
          debugPrint('openImageSmart: got fresh presigned url.');
          // download and cache fresh file
          await cacheManager.getSingleFile(fresh);
          openSingleMediaViewer(context);
          return;
        } else {
          debugPrint(
              'openImageSmart: failed to obtain fresh presigned url from server.');
          // fallthrough to attempt direct download (may fail)
        }
      }

      // 3) Download and cache the file (will store in same cache)
      debugPrint('openImageSmart: downloading and caching $imageUrl');
      final file = await cacheManager.getSingleFile(imageUrl);
      if (file.existsSync()) {
        debugPrint('openImageSmart: downloaded to ${file.path}');
        openSingleMediaViewer(context);
        return;
      }

      // 4) final fallback -> show error dialog
      debugPrint(
          'openImageSmart: file not available after attempts for $imageUrl');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Unable to open image'),
          content: const Text('Image failed to load.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('openImageSmart: error opening image $e\n$st');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Could not open image: $e'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    }
  }

  void openSingleMediaViewer(BuildContext context) {
    final String? imageUrl =
        widget.message['imageUrl'] ?? widget.message['originalUrl'];
    final String? fileUrl =
        widget.message['fileUrl'] ?? widget.message['originalUrl'];
    final String? fileType =
        widget.message['fileType']?.toString().toLowerCase();

    if (imageUrl == null && fileUrl == null) return;

    final bool isVideo = fileType?.startsWith('video/') == true ||
        (fileUrl ?? '').toLowerCase().endsWith('.mp4') ||
        (fileUrl ?? '').toLowerCase().endsWith('.mov');

    final String mediaUrl =
        isVideo ? (fileUrl ?? imageUrl!) : (imageUrl ?? fileUrl!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MixedMediaViewer(
          items: [
            GroupMediaItem(
              mediaUrl: mediaUrl,
              isVideo: isVideo,
              previewUrl: '',
            ),
          ],
          initialIndex: 0,
        ),
      ),
    );
  }

  Widget _buildFile(
    BuildContext context,
    String fileUrl,
    String? fileName,
    String? fileType,
    String content, {
    required bool isSentByMe,
  }) {
    if (content == "Message Deleted") return const SizedBox();

    final String name = fileName ?? 'Unknown file';

    final String extFromName = name.split('.').last.toLowerCase();
    final String mime = (fileType ?? '').toLowerCase();

    // Detect by MIME first, fallback to extension
    final bool isImage = mime.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif']
            .contains(extFromName);

    final bool isVideo = mime.startsWith('video/') ||
        ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extFromName);

    // 🔹 If it's an image, we already show it via imageUrl -> _buildImage, so hide here
    if (isImage) {
      return const SizedBox.shrink();
    }

    // 🔹 If it's a video, show a "media preview" style tile instead of document card
    if (isVideo) {
      return _buildVideoPreviewTile(context, fileUrl, name, isSentByMe, true);
    }

    // 🔹 Otherwise fall back to your existing document UI...
    // (keep your existing code below, but with the new _getFileIcon)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_getFileIcon(fileType), color: widget.chatColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => widget.onFileTap?.call(fileUrl, fileType),
                ),
              ],
            ),
          ),
        ),
        if (content.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TimeUtils.formatUtcToIst(widget.message['time']),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                if (isSentByMe) ...[
                  const SizedBox(width: 4),
                  widget.buildStatusIcon?.call(
                          widget.message['messageStatus']?.toString() ??
                              'sent') ??
                      const Icon(Icons.done, size: 12, color: Colors.black54),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Map<String, dynamic>? resolveRepliedMessage({
    required Map<String, dynamic> message,
    required List<Map<String, dynamic>> allMessages,
  }) {
    if (message['isReplyMessage'] != true) return null;

    // already resolved
    if (message['repliedMessage'] != null) {
      return Map<String, dynamic>.from(message['repliedMessage']);
    }

    final String? replyId = message['replyMessageId']?.toString();
    if (replyId == null || replyId.isEmpty) return null;

    try {
      final original = allMessages.firstWhere(
        (m) => m['message_id']?.toString() == replyId,
      );

      return {
        'content': original['content'],
        'imageUrl': original['imageUrl'],
        'fileUrl': original['fileUrl'],
        'fileType': original['fileType'],
        'originalUrl': original['originalUrl'],
        'isVideo': original['isVideo'],
        'fileName': original['fileName'],
        'senderName': original['senderName'],
      };
    } catch (_) {
      return null;
    }
  }

  Widget _buildTextMessage(String content, String messageStatus) {
    final bool hasLinkLocal = content.isNotEmpty &&
        RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false)
            .hasMatch(content);
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        final Widget messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false)
                .hasMatch(content))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnyLinkPreview(
                    link: (() {
                      final match = RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                              caseSensitive: false)
                          .firstMatch(content);
                      if (match == null) return '';
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

            /// 💬 WhatsApp-like Stack (Message + Time + Tick)
            Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5,
                      bottom: 5,
                    ),
                    child: RichText(
                      maxLines: isExpanded ? null : 9,
                      overflow: isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          ...linkify(
                            content,
                            options: const LinkifyOptions(
                              humanize: true,
                              looseUrl: true,
                              defaultToHttps: true,
                            ),
                            linkifiers: [
                              const EmailLinkifier(),
                              const UrlLinkifier(),
                              CustomPhoneNumberLinkifier(),
                            ],
                          ).map((element) {
                            if (element is LinkableElement) {
                              return TextSpan(
                                text: element.text,
                                style: const TextStyle(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    try {
                                      final uri = Uri.parse(element.url);
                                      if (!await launchUrl(uri,
                                          mode:
                                              LaunchMode.externalApplication)) {
                                        throw 'Could not launch $uri';
                                      }
                                    } catch (e) {
                                      debugPrint('Could not launch url: $e');
                                    }
                                  },
                              );
                            } else {
                              if (widget.searchText != null &&
                                  widget.searchText!.isNotEmpty &&
                                  element.text.toLowerCase().contains(
                                      widget.searchText!.toLowerCase())) {
                                final List<TextSpan> highlightedSpans = [];
                                final String text = element.text;
                                final String query =
                                    widget.searchText!.toLowerCase();
                                int start = 0;
                                int indexOfMatch;

                                while ((indexOfMatch = text
                                        .toLowerCase()
                                        .indexOf(query, start)) !=
                                    -1) {
                                  if (indexOfMatch > start) {
                                    highlightedSpans.add(TextSpan(
                                      text: text.substring(start, indexOfMatch),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ));
                                  }

                                  highlightedSpans.add(TextSpan(
                                    text: text.substring(indexOfMatch,
                                        indexOfMatch + query.length),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      backgroundColor: Colors.yellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ));

                                  start = indexOfMatch + query.length;
                                }

                                if (start < text.length) {
                                  highlightedSpans.add(TextSpan(
                                    text: text.substring(start),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ));
                                }

                                return TextSpan(children: highlightedSpans);
                              }
                              return TextSpan(
                                text: element.text,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black87),
                              );
                            }
                          }),
                          WidgetSpan(
                            child: SizedBox(
                                width: widget.isSentByMe ? 75 : 60, height: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!(!isExpanded && _isTextLong(content)))
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TimeUtils.formatUtcToIst(widget.message['time']),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                        ),
                        const SizedBox(width: 4),
                        if (widget.isSentByMe)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child:
                                widget.buildStatusIcon?.call(messageStatus) ??
                                    const SizedBox(),
                          ),
                      ],
                    ),
                  ),
              ],
            ),

            if (!isExpanded && _isTextLong(content)) ...[
              GestureDetector(
                onTap: () => setState(() => isExpanded = true),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "Read more",
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TimeUtils.formatUtcToIst(widget.message['time']),
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(width: 4),
                    if (widget.isSentByMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: widget.buildStatusIcon?.call(messageStatus) ??
                            const SizedBox(),
                      ),
                  ],
                ),
              ),
            ]
          ],
        );

        final constrainedBox = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: messageContent,
        );

        final textBubble = Padding(
          padding: const EdgeInsets.only(top: 6),
          child: constrainedBox,
        );

        // final bool hasLinkLocal = content.isNotEmpty &&
        //     RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false)
        //         .hasMatch(content);

        return hasLinkLocal
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  textBubble,
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: widget.isSentByMe ? -60 : null,
                    right: widget.isSentByMe ? null : -60,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            print("Forwarding link: $content");
                            MyRouter.push(
                              screen: ForwardMessageScreen(
                                messages: [widget.message],
                                currentUserId: widget.message['senderId'] ?? '',
                                conversionalid: "",
                                username: widget.message['senderName'] ?? '',
                              ),
                            );
                          },
                          child: CircleAvatar(
                            maxRadius: 16,
                            backgroundColor: Colors.white,
                            child: Image.asset(
                              "assets/images/forward.png",
                              height: 18,
                              width: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : textBubble;
      },
    );
  }

  bool _isTextLong(String text) {
    const maxCharsPerLine = 40;
    return (text.length / maxCharsPerLine).ceil() > 9;
  }

  Route _bottomToTopRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 1), // bottom
          end: Offset.zero, // final position
        ).animate(curved);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Widget _buildVideoPreviewTile(
    BuildContext context,
    String videoUrl,
    String fileName,
    bool isSentByMe,
    bool showTime,
  ) {
    final isNetwork =
        videoUrl.startsWith('http://') || videoUrl.startsWith('https://');

    return GestureDetector(
      onTap: () {
        // 👇 open your full-screen player
        if (widget.isSelectionMode) {
          widget.onLongPress?.call();
        } else {
          _openConversationViewer(context, videoUrl);
        }
      },
      child: Container(
        width: 250,
        height: 300,
        margin: const EdgeInsets.only(top: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FutureBuilder<File?>(
              future: VideoCacheService.instance.getThumbnailFuture(videoUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _videoShimmerPlaceholder();
                }

                if (snapshot.hasData && snapshot.data != null) {
                  // optional: cache local path into message map for instant reuse later
                  try {
                    widget.message['localThumbPath'] = snapshot.data!.path;
                  } catch (_) {}

                  return _videoThumbnailImage(snapshot.data!);
                }

                return _videoFallbackBlack(); // only if thumbnail fails
              },
            ),

            // ✅ PLAY BUTTON
            Center(
              child: GestureDetector(
                onTap: () {
                  // 👇 open your full-screen player
                  if (widget.isSelectionMode) {
                    widget.onLongPress?.call();
                  } else {
                    _openConversationViewer(context, videoUrl);
                  }
                  // Navigator.push(
                  //   context,
                  //   _bottomToTopRoute(
                  //     VideoPlayerScreen(
                  //       path: videoUrl,
                  //       isNetwork: isNetwork,
                  //     ),
                  //   ),
                  // );
                },
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    FutureBuilder<String?>(
                      future: VideoCacheService.instance
                          .getDurationFuture(videoUrl, isNetwork: isNetwork),
                      builder: (context, snap) {
                        final text = snap.data ?? '00:00';
                        return Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // ✅ TIME + TICKS

            if (showTime)
              Positioned(
                bottom: 12,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TimeUtils.formatUtcToIst(widget.message['time']),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 4),
                        widget.buildStatusIcon?.call(
                              widget.message['messageStatus']?.toString() ??
                                  'sent',
                            ) ??
                            const Icon(Icons.done,
                                size: 12, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _videoThumbnailImage(File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        width: 300,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _videoFallbackBlack() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 300,
        height: 300,
        color: Colors.black,
        alignment: Alignment.center,
        child: const Icon(
          Icons.videocam,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _videoShimmerPlaceholder() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileType) {
    final ft = (fileType ?? '').toLowerCase();

    if (ft.startsWith('image/')) return Icons.image;
    if (ft.startsWith('video/')) return Icons.video_file;
    if (ft.startsWith('audio/')) return Icons.audio_file;

    // PDFs
    if (ft.contains('pdf')) return Icons.picture_as_pdf;

    // Word / Docs
    if (ft.contains('word') || ft.contains('doc')) return Icons.description;

    // Excel / Sheets
    if (ft.contains('sheet') ||
        ft.contains('excel') ||
        ft.contains('spreadsheet')) {
      return Icons.table_chart;
    }

    // PPT
    if (ft.contains('powerpoint') ||
        ft.contains('presentation') ||
        ft.contains('ppt')) {
      return Icons.slideshow;
    }

    // Archives
    if (ft.contains('zip') || ft.contains('rar') || ft.contains('7z')) {
      return Icons.archive;
    }

    return Icons.insert_drive_file;
  }
}

class CustomPhoneNumberLinkifier extends Linkifier {
  final RegExp _phoneRegex = RegExp(r'(\+?\d{10,15})');

  @override
  List<LinkifyElement> parse(
      List<LinkifyElement> elements, LinkifyOptions options) {
    final List<LinkifyElement> result = [];
    for (final element in elements) {
      if (element is TextElement) {
        final text = element.text;
        int start = 0;
        for (final match in _phoneRegex.allMatches(text)) {
          if (match.start != start) {
            result.add(TextElement(text.substring(start, match.start)));
          }
          result.add(LinkableElement(match.group(0)!, match.group(0)!));
          start = match.end;
        }
        if (start < text.length) {
          result.add(TextElement(text.substring(start)));
        }
      } else {
        result.add(element);
      }
    }
    return result;
  }
}

class ShimmerImagePlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerImagePlaceholder({
    super.key,
    this.width = 100,
    this.height = 200,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Colors.white,
        ),
      ),
    );
  }
}
