import 'package:flutter/gestures.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MixedMediaViewer.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/commonfuntion.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/replymessgae.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_viewer.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:shimmer/shimmer.dart';
import 'package:linkify/linkify.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'VideoCacheService.dart';
import 'VideoPlayerScreen.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSentByMe;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRightSwipe;
  final Function(String url, String? fileType)? onFileTap;
  final Function(String imageUrl)? onImageTap;
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
  const MessageBubble(
      {super.key,
      required this.message,
      required this.isSentByMe,
      required this.isSelected,
      this.onTap,
      this.onLongPress,
      this.onRightSwipe,
      this.onFileTap,
      this.onImageTap,
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
      required this.allMessages});

  @override
  Widget build(BuildContext context) {
    final String content = message['content']?.toString() ?? '';
    final String? imageUrl = message['imageUrl'];
    final String? replycontent = message['replyContent'];
    final String? fileUrl = message['fileUrl'];
    final String? fileName = message['fileName'];
    final String? fileTypeRaw = message['fileType']?.toString();
    final String? originalUrl = message['originalUrl']?.toString();
    final bool? isForwarded = message['isForwarded'] ?? false;
    final bool? isReplyMessage = message['isReplyMessage'];
    final String messageStatus = message['messageStatus']?.toString() ?? 'sent';
    final String fileType = fileTypeRaw?.toLowerCase() ?? '';
    final bool isVideo = fileType.startsWith('video/') ||
        (message['isVideo'] == true) ||
        ((fileUrl ?? originalUrl ?? '')
                .toString()
                .toLowerCase()
                .endsWith('.mp4') ||
            (fileUrl ?? originalUrl ?? '')
                .toString()
                .toLowerCase()
                .endsWith('.mov'));
    bool hasReply = message['reply'] != null ||
        message['reply_message_id'] != null ||
        message['replyContent'] != null;

    final bool hasFile = fileUrl != null && fileUrl.isNotEmpty;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    // If nothing to show (no text, no image, no file) -> shimmer placeholder
    if (content.isEmpty && !hasImage && !hasFile) {
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          constraints: const BoxConstraints(maxWidth: 260),
          child: const ShimmerImagePlaceholder(
            width: 260,
            height: 300,
          ),
        ),
      );
    }
    //log("properties ${message['reply']}");

    return Padding(
      padding: EdgeInsets.symmetric(vertical: emojpicker != null ? 8.0 : 0),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () {
          _showReactionPicker(context);
          onLongPress?.call();
        },
        child: Align(
          alignment: isReply
              ? Alignment.centerLeft
              : isSentByMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.only(
                  left: 9,
                  right: 9,
                  bottom: (message['reactions'] != null &&
                          (message['reactions'] as List).isNotEmpty)
                      ? 20
                      : 8,
                ),
                padding: isReply
                    ? null
                    : const EdgeInsets.only(
                        left: 5, right: 5, top: 5, bottom: 10),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: isReply
                      ? null
                      : isSelected
                          ? selectedMessageColor
                          : (isSentByMe
                              ? sentMessageColor
                              : receivedMessageColor),
                  borderRadius: BorderRadius.only(
                    topLeft: isSentByMe
                        ? const Radius.circular(18)
                        : const Radius.circular(18),
                    topRight: isSentByMe
                        ? const Radius.circular(18)
                        : const Radius.circular(18),
                    bottomLeft:
                        isSentByMe ? const Radius.circular(18) : Radius.zero,
                    bottomRight:
                        isSentByMe ? Radius.zero : const Radius.circular(16),
                  ),
                  border: isSelected
                      ? Border.all(color: borderColor, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: hasReply
                      ? CrossAxisAlignment.stretch
                      : CrossAxisAlignment.start,
                  children: [
                    if (hasReply)
                      RepliedMessagePreview(
                        key: ValueKey(message['isReplyMessage']?.hashCode ??
                            message['reply']),
                        replied: message['reply'] ?? {},
                        receiver: message['receiver'] is Map
                            ? Map<String, dynamic>.from(message['receiver'])
                            : {},
                        isSender: isSentByMe,
                        onTap: onReplyTap,
                        groupMediaLength: groupMediaLength,
                      ),

                    if (!isSentByMe && isForwarded == true)
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

                    // Image preview (only if not video)
                    if (!isVideo && hasImage)
                      _buildImage(context, content, imageUrl!, fileName,
                          isSentByMe: isSentByMe),

                    // File preview (if file exists)
                    if (hasFile)
                      _buildFile(context, fileUrl!, fileName, fileType, content,
                          isSentByMe: isSentByMe),

                    // Text content
                    if (content.isNotEmpty)
                      _buildTextMessage(content, messageStatus, hasReply),
                  ],
                ),
              ),

              // reactions bar (if exists)
              if (message['reactions'] != null &&
                  (message['reactions'] as List).isNotEmpty &&
                  buildReactionsBar != null)
                Positioned(
                  bottom: -15,
                  right: isSentByMe ? 12 : null,
                  left: isSentByMe ? null : 12,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        // show reaction picker on tap too
                        _showReactionPicker(context);
                      },
                      child: buildReactionsBar!(message, isSentByMe),
                    ),
                  ),
                ),

              if (isVideo ||
                  hasImage ||
                  hasFile ||
                  (content.isNotEmpty &&
                      RegExp(r'((https?:\/\/)|(www\.))[^\s]+',
                              caseSensitive: false)
                          .hasMatch(content)))
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: isSentByMe ? -60 : null,
                  right: isSentByMe ? null : -60,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        log("FORWARD ICON TAP"); // ✅ WILL PRINT
                        MyRouter.push(
                          screen: ForwardMessageScreen(
                            messages: [message],
                            currentUserId: message['senderId'] ?? '',
                            conversionalid: "",
                            username: message['senderName'] ?? '',
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
                )
            ],
          ),
        ),
      ),
    );
  }

  void _openConversationViewer(BuildContext context, String tappedUrl) {
    final media = buildConversationMedia(allMessages);

    final index = media.indexWhere((m) => m.mediaUrl == tappedUrl);
    if (index == -1) return;

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

  void _showReactionPicker(BuildContext context) {
    if (onReact == null) return;
    final List<String> emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
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
            children: emojis
                .map((emoji) => GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);

                        onReact?.call(message, emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ))
                .toList(),
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
  }) {
    if (content == "Message Deleted") return const SizedBox();

    final String name = fileName ?? 'Unknown file';
    final String extension =
        name.split('.').isNotEmpty ? name.split('.').last.toLowerCase() : '';
    final String? fileSize = message['fileSize']?.toString();

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
              onPressed: () => onFileTap?.call(imageUrl, null),
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
            placeholder: (context, url) => const ShimmerImagePlaceholder(
              width: 260,
              height: 200,
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
        //    debugPrint('MessageBubble: image tapped => $imageUrl');
            // if it's an actual image, open viewer; otherwise, try to download/open file
            if (looksImage) {
              _openConversationViewer(context, imageUrl);
            } else {
              // treat as file
              onFileTap?.call(imageUrl, null);
            }
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
        Positioned(
          bottom: 5,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TimeUtils.formatUtcToIst(message['time']),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                if (isSentByMe) ...[
                  const SizedBox(width: 4),
                  buildStatusIcon?.call(
                          message['messageStatus']?.toString() ?? 'sent') ??
                      const Icon(Icons.done, size: 12, color: Colors.white),
                ],
              ],
            ),
          ),
        ),

        // forward button
        //     Positioned(
        //   top: 0,
        //   bottom: 0,
        //   left: isSentByMe ? -60 : null,
        //   right: isSentByMe ? null : -60,
        //   child: IgnorePointer(
        // ignoring: false, // 🔥 FORCE pointer
        // child: Material(
        //   color: Colors.transparent,
        //   child: InkWell(
        //     borderRadius: BorderRadius.circular(20),
        //     onTap: () {
        //       log("FORWARD ICON TAP"); // ✅ WILL PRINT
        //       MyRouter.push(
        //         screen: ForwardMessageScreen(
        //           messages: [message],
        //           currentUserId: message['senderId'] ?? '',
        //           conversionalid: "",
        //           username: message['senderName'] ?? '',
        //         ),
        //       );
        //     },
        //     child: CircleAvatar(
        //       maxRadius: 16,
        //       backgroundColor: Colors.white,
        //       child: Image.asset(
        //         "assets/images/forward.png",
        //         height: 20,
        //         width: 20,
        //       ),
        //     ),
        //   ),
        // ),
        //   ),
        // )
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
    // If you store objectKey in message, pass that. If you only have URL, you may need the server
    // to map from object key extracted from URL to a new presigned URL.
    // Example pseudo:
    // final resp = await Api.get('/presign?key=$imageKey');
    // return resp?.data?.url;
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
          final fetched = await cacheManager.getSingleFile(fresh);
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
    final String? imageUrl = message['imageUrl'] ?? message['originalUrl'];
    final String? fileUrl = message['fileUrl'] ?? message['originalUrl'];
    final String? fileType = message['fileType']?.toString().toLowerCase();

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
      return _buildVideoPreviewTile(context, fileUrl, name, isSentByMe);
    }

    // 🔹 Otherwise fall back to your existing document UI...
    // (keep your existing code below, but with the new _getFileIcon)
    return Container(
      width: 300,
      height: 100,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getFileIcon(fileType), color: chatColor, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName ?? 'Download file',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => onFileTap?.call(fileUrl, fileType),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: isSentByMe ? -60 : null,
            right: isSentByMe ? null : -60,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    print("Forwarding file: $fileName");
                    MyRouter.push(
                      screen: ForwardMessageScreen(
                        messages: [message],
                        currentUserId: message['senderId'] ?? '',
                        conversionalid: "",
                        username: message['senderName'] ?? '',
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

  Widget _buildTextMessage(
      String content, String messageStatus, bool shouldStretch) {
    final bool useIntrinsic = content.trim().length < 25;
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        final Widget messageContent = Column(
          crossAxisAlignment: shouldStretch
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
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
                              return TextSpan(
                                text: element.text,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black87),
                              );
                            }
                          }),
                          WidgetSpan(
                            child: SizedBox(
                                width: isSentByMe ? 75 : 60, height: 20),
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
                          TimeUtils.formatUtcToIst(message['time']),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                        ),
                        const SizedBox(width: 4),
                        if (isSentByMe)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: buildStatusIcon?.call(messageStatus) ??
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
                      TimeUtils.formatUtcToIst(message['time']),
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(width: 4),
                    if (isSentByMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: buildStatusIcon?.call(messageStatus) ??
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
          child: (useIntrinsic && !shouldStretch)
              ? IntrinsicWidth(child: constrainedBox)
              : constrainedBox,
        );

        final bool hasLinkLocal = content.isNotEmpty &&
            RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false)
                .hasMatch(content);

        return hasLinkLocal
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  textBubble,
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: isSentByMe ? -60 : null,
                    right: isSentByMe ? null : -60,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            print("Forwarding link: $content");
                            MyRouter.push(
                              screen: ForwardMessageScreen(
                                messages: [message],
                                currentUserId: message['senderId'] ?? '',
                                conversionalid: "",
                                username: message['senderName'] ?? '',
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

  Future<File?> _generateVideoThumbnail(String videoUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();

      // ✅ CREATE UNIQUE FILE NAME PER VIDEO (CRITICAL FIX)
      final uniqueName = videoUrl.hashCode.toString();
      final thumbPath = '${tempDir.path}/thumb_$uniqueName.png';

      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: thumbPath, // ✅ UNIQUE FILE
        imageFormat: ImageFormat.PNG,
        maxHeight: 300,
        quality: 75,
      );

      if (generatedPath == null) return null;
      return File(generatedPath);
    } catch (e, st) {
      debugPrint('❌ Thumbnail error for $videoUrl: $e\n$st');
      return null;
    }
  }

  Widget _buildVideoPreviewTile(
    BuildContext context,
    String videoUrl,
    String fileName,
    bool isSentByMe,
  ) {
    final isNetwork =
        videoUrl.startsWith('http://') || videoUrl.startsWith('https://');

    return GestureDetector(
      onTap: () {
        // 👇 open your full-screen player
        _openConversationViewer(context, videoUrl);
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
                    message['localThumbPath'] = snapshot.data!.path;
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
                  Navigator.push(
                    context,
                    _bottomToTopRoute(
                      VideoPlayerScreen(
                        path: videoUrl,
                        isNetwork: isNetwork,
                      ),
                    ),
                  );
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
            Positioned(
              bottom: -19,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  // color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TimeUtils.formatUtcToIst(message['time']),
                      style: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                    if (isSentByMe) ...[
                      const SizedBox(width: 4),
                      buildStatusIcon?.call(
                            message['messageStatus']?.toString() ?? 'sent',
                          ) ??
                          const Icon(Icons.done, size: 12, color: Colors.black),
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
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Future<String> _getVideoDuration(String path, bool isNetwork) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(path));

    try {
      await controller.initialize();
      final duration = controller.value.duration;

      final minutes =
          duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds =
          duration.inSeconds.remainder(60).toString().padLeft(2, '0');

      return '$minutes:$seconds';
    } catch (e) {
      return "00:00";
    } finally {
      await controller.dispose();
    }
  }

  Widget _buildTimeRow(String messageStatus) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            TimeUtils.formatUtcToIst(message['time']),
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(width: 4),
          if (isSentByMe)
            buildStatusIcon?.call(messageStatus) ?? const SizedBox(),
        ],
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
