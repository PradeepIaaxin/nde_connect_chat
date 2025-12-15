import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/replymessgae.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../../../widget/image_viewer.dart';
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
  final bool isReply;
  MessageBubble({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final String content = message['content']?.toString() ?? '';
    final String? imageUrl = message['imageUrl'];
    final String? replycontent = message['replyContent'];
    final String? fileUrl = message['fileUrl'];
    final String? fileName = message['fileName'];
    final String? fileType = message['fileType'];
    final bool? isForwarded = message['isForwarded'];
    final bool? isReplyMessage = message['isReplyMessage'];
    final String messageStatus = message['messageStatus']?.toString() ?? 'sent';

    if (content.isEmpty &&
        (imageUrl == null || imageUrl.isEmpty) &&
        (fileUrl == null || fileUrl.isEmpty)) {
      // Show a side-aligned shimmer bubble instead of a full-width block
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          constraints: const BoxConstraints(maxWidth: 260),
          child: const ShimmerImagePlaceholder(
            width: 260, // <= adjust as you like
            height: 300, // or 150 / 180
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: emojpicker != null ? 8.0 : 0),
      child: SwipeTo(
        animationDuration: const Duration(milliseconds: 350),
        iconOnRightSwipe: Icons.reply,
        iconColor: Colors.grey.shade600,
        iconSize: 24.0,
        offsetDx: 0.3,
        swipeSensitivity: 5,
        onRightSwipe: (details) => onRightSwipe?.call(),
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
                  margin: EdgeInsets.only(
                    left: 9,
                    right: 9,
                    bottom: (message['reactions'] != null &&
                            message['reactions'].isNotEmpty)
                        ? 20 // WHEN REACTION EXISTS
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
                    borderRadius: isReply
                        ? null
                        : BorderRadius.only(
                            topLeft: isSentByMe
                                ? Radius.zero
                                : const Radius.circular(18),
                            topRight: isSentByMe
                                ? const Radius.circular(18)
                                : Radius.zero,
                            bottomLeft: isSentByMe
                                ? const Radius.circular(18)
                                : Radius.zero,
                            bottomRight: isSentByMe
                                ? Radius.zero
                                : const Radius.circular(16),
                          ),
                    border: isSelected
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.containsKey('repliedMessage') &&
                          isReplyMessage == true &&
                          message['repliedMessage'] != null)
                        RepliedMessagePreview(
                          message: message,
                          isSentByMe: isSentByMe,
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
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        _buildImage(context, content, imageUrl, fileName,
                            isSentByMe: isSentByMe),
                      if (fileUrl != null && fileUrl.isNotEmpty)
                        _buildFile(
                            context, fileUrl, fileName, fileType, content,
                            isSentByMe: isSentByMe),
                      if (content.isNotEmpty)
                        _buildTextMessage(content, messageStatus),
                      //if (content.isEmpty) _buildTimeRow(messageStatus),
                    ],
                  ),
                ),
                if (message['reactions'] != null &&
                    message['reactions'].isNotEmpty &&
                    buildReactionsBar != null)
                  Positioned(
                    bottom: -15,
                    right: isSentByMe ? 12 : null,
                    left: isSentByMe ? null : 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 12,
                        left: isSentByMe ? 0 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          print("hiiiiieeeee");
                          // open detailed picker (who reacted, change emoji, etc.)
                          if (emojpicker != null) {
                            _showReactionPicker(context);
                          } else {
                            _showReactionPicker(context);
                          }
                        },
                        child: buildReactionsBar!(message, isSentByMe),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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

  Widget _buildReactionsBarWidget(Map<String, dynamic> msg) {
    final reactionsRaw = msg['reactions'] ?? [];

    final reactions = (reactionsRaw as List?)
            ?.where((r) => r is Map)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList() ??
        [];

    if (reactions.isEmpty) return const SizedBox.shrink();

    // Count occurrences of each emoji
    final Map<String, int> reactionCounts = {};
    for (final reaction in reactions) {
      final emoji = reaction['emoji']?.toString();
      if (emoji != null && emoji.isNotEmpty) {
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionCounts.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
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
    final String extension = name.split('.').last.toLowerCase();
    final String? fileSize = message['fileSize']?.toString();
    print("imageUrl $imageUrl");
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

    final bool isImage = imageExtensions.contains(extension);

    // Determine file icon
    IconData getFileIcon() {
      switch (extension) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'doc':
        case 'docx':
          return Icons.description;
        case 'xls':
        case 'xlsx':
          return Icons.table_chart;
        case 'ppt':
        case 'pptx':
          return Icons.slideshow;
        case 'zip':
        case 'rar':
        case '7z':
          return Icons.archive;
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'mkv':
          return Icons.video_file;
        case 'mp3':
        case 'wav':
        case 'aac':
          return Icons.audio_file;
        default:
          if (isImage) return Icons.image;
          return Icons.insert_drive_file;
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          // previous: onTap: () => onImageTap?.call(imageUrl),
          onTap: () async {
            debugPrint('MessageBubble: image tapped => $imageUrl');
            await ImageViewer.show(context, imageUrl);
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
              child: imageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 260,
                      height: isImage ? 350 : 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ShimmerImagePlaceholder(
                        width: 260,
                        height: 200, // or 350 if you always want tall preview
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 260,
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                    )
                  : Image.file(
                      File(imageUrl),
                      width: 260,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        Positioned(
          bottom: 5,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
              //color: Colors.black.withOpacity(0.4),
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
                  buildStatusIcon?.call(
                          message['messageStatus']?.toString() ?? 'sent') ??
                      const Icon(Icons.done, size: 12, color: Colors.white),
                ],
              ],
            ),
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
                  print("Forwarding image: $imageUrl");
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
        ImageViewer.show(context, cached.file.path);
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
          ImageViewer.show(context, fetched.path);
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
        ImageViewer.show(context, file.path);
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

  Widget _buildTextMessage(String content, String messageStatus) {
    final bool useIntrinsic = content.trim().length < 25;
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        final Widget textWidget = Padding(
          padding: const EdgeInsets.only(
            left: 5,
          ),
          child: Linkify(
            text: content,
            maxLines: isExpanded ? null : 9,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            onOpen: (link) async {
              final uri = Uri.parse(link.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            linkStyle: const TextStyle(color: Colors.blue),
            options: LinkifyOptions(
              humanize: true,
              looseUrl: true,
              defaultToHttps: true,
            ),
            linkifiers: [
              EmailLinkifier(),
              UrlLinkifier(),
              CustomPhoneNumberLinkifier(),
            ],
          ),
        );

        final Widget messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (RegExp(r'https?:\/\/[^\s]+').hasMatch(content))
              AnyLinkPreview(
                link: RegExp(r'https?:\/\/[^\s]+')
                        .firstMatch(content)
                        ?.group(0) ??
                    '',
                displayDirection: UIDirection.uiDirectionVertical,
                showMultimedia: true,
                backgroundColor: Colors.grey.shade200,
                bodyStyle: const TextStyle(color: Colors.transparent),
                cache: const Duration(hours: 1),
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
          child: useIntrinsic
              ? IntrinsicWidth(child: constrainedBox)
              : constrainedBox,
        );

        final hasLink = RegExp(r'https?:\/\/[^\s]+').hasMatch(content);

        return hasLink
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
      child: Container(
        width: 250,
        height: 300,
        margin: const EdgeInsets.only(top: 8),
        child: Stack(
          children: [
            FutureBuilder<File?>(
              future: isNetwork ? _generateVideoThumbnail(videoUrl) : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _videoShimmerPlaceholder();
                }

                if (snapshot.hasData && snapshot.data != null) {
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
                    FutureBuilder<String>(
                      future: _getVideoDuration(videoUrl, isNetwork),
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
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
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
                            message['messageStatus']?.toString() ?? 'sent',
                          ) ??
                          const Icon(Icons.done, size: 12, color: Colors.white),
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
