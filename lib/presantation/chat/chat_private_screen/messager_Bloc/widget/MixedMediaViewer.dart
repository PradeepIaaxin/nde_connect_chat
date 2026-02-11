import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/usermedia_screen.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart'
    as group_bloc;
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart'
    as private;
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart'
    as private_event;
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart'
    as group_event;
import 'package:nde_email/presantation/chat/widget/delete_dialogue.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../../utils/router/router.dart';
import '../../../../widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/videocacheservice.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as p;
import '../../../../widgets/chat_widgets/Common/grouped_media_viewer.dart';

class MixedMediaViewer extends StatefulWidget {
  final List<GroupMediaItem> items;
  final int initialIndex;
  final String? currentUserId;
  final String? conversionalId;
  final String? fullName;
  final bool isGroup;
  final String? receiverId;

  const MixedMediaViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    this.currentUserId,
    this.conversionalId,
    this.fullName,
    this.isGroup = false,
    this.receiverId,
  });

  @override
  State<MixedMediaViewer> createState() => _MixedMediaViewerState();
}

class _MixedMediaViewerState extends State<MixedMediaViewer> {
  late final PageController _controller;
  late final ScrollController _scrollController;
  late int _currentIndex;
  bool _showUI = true;
  double _dragOffset = 0;
  final Map<int, int> _rotationTurns = {};
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
    _scrollController = ScrollController();

    // After first frame, scroll to the initial index thumbnail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(_currentIndex);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    // Restore status bar when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (_showUI) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  String _formatDateTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr);
      return DateTimeUtils.formatMessageTime(dt);
    } catch (e) {
      return '';
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const double itemWidth = 78.0;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetOffset =
        (index * itemWidth) + (itemWidth / 2) - (screenWidth / 2) + 10;
    // +10 for the ListView horizontal padding

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double finalOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      finalOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveMedia(String url, bool isVideo) async {
    try {
      // 1. Request Permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        final status2 = await Permission.manageExternalStorage.request();
        if (!status.isGranted && !status2.isGranted) {
          Messenger.alertError('Storage permission denied');

          return;
        }
      }

      // 2. Construct Unified Path
      final String packageName = "com.nowdigitaleasy.NDEconnect";
      final String baseDir =
          "/storage/emulated/0/Android/media/$packageName/NowDigitalEasy/Media";
      final Directory directory = Directory(baseDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String fileName = url.split('/').last.split('?').first;
      String safeFileName = fileName.isEmpty
          ? 'media_${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}'
          : fileName;

      // Ensure extension is present
      final String extension = isVideo ? '.mp4' : '.jpg';
      if (!safeFileName.toLowerCase().endsWith(extension)) {
        safeFileName += extension;
      }

      final String finalPath = p.join(baseDir, safeFileName);

      // 3. Download or Copy
      if (url.startsWith('http')) {
        await Dio().download(url, finalPath);
      } else {
        final File sourceFile = File(url);
        await sourceFile.copy(finalPath);
      }

      // 4. Update Gallery via MediaScanner
      await MediaScanner.loadMedia(path: finalPath);

      Messenger.alertSuccess('Saved to NowDigitalEasy/Media');
    } catch (e) {
      print("Error saving media: $e");
    }
  }

  void _showAllMedia() {
    MyRouter.push(
      screen: UsermediaScreen(
        username: widget.fullName ?? 'Media',
        userId: widget.conversionalId ?? '',
      ),
    );
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];
    final currentMessage = currentItem.message;
    final bool isSentByMe =
        currentMessage?['senderId']?.toString() == widget.currentUserId;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha:0.4),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentItem.senderName ?? 'Media',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (currentItem.time != null)
                    Text(
                      _formatDateTime(currentItem.time),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              actions: [
                Icon(Icons.star_border),
                SizedBox(
                  width: 20,
                ),
                GestureDetector(
                  onTap: () {
                    log("currentMessage?????????? $currentMessage");
                    if (currentMessage == null) return;
                    Navigator.pop(context);
                    MyRouter.pushReplace(
                      screen: ForwardMessageScreen(
                        isForward: isSentByMe,
                        messages: [currentMessage],
                        currentUserId: currentMessage['sender']?["_id"] ??
                            currentMessage['senderId'] ??
                            '',
                        conversionalid: "",
                        username: currentMessage['senderName'] ?? '',
                      ),
                    );
                  },
                  child: Image.asset(
                    "assets/images/forward.png",
                    height: 20,
                    width: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'save') {
                      _saveMedia(currentItem.mediaUrl, currentItem.isVideo);
                    }
                    if (value == 'all_media') {
                      _showAllMedia();
                    }
                    if (value == 'share') {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (currentMessage == null) return;
                        log("Sharing message:\n${jsonEncode(currentMessage)}");

                        String textToShare = '';
                        if (currentMessage['content']
                                ?.toString()
                                .trim()
                                .isNotEmpty ??
                            false) {
                          textToShare = currentMessage['content'];
                        } else if (currentMessage['imageUrl']
                                ?.toString()
                                .trim()
                                .isNotEmpty ??
                            false) {
                          textToShare = currentMessage['imageUrl'];
                        } else if (currentMessage['fileUrl']
                                ?.toString()
                                .trim()
                                .isNotEmpty ??
                            false) {
                          textToShare =
                              "${currentMessage['fileName'] ?? 'Document'}:\n${currentMessage['fileUrl']}";
                        }

                        if (textToShare.trim().isNotEmpty) {
                          Share.share(textToShare);
                        } else {
                          log("Nothing to share.");
                        }
                      });
                    }
                    if (value == 'delete') {
                      _deleteMedia();
                    }
                    if (value == 'rotate') {
                      setState(() {
                        _rotationTurns[_currentIndex] =
                            ((_rotationTurns[_currentIndex] ?? 0) + 1) % 4;
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'all_media',
                      child: Text('All media'),
                    ),
                    // const PopupMenuItem<String>(
                    //   value: 'show_in_chat',
                    //   child: Text('Show in chat'),
                    // ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('Share'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'save',
                      child: Text('Save'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'rotate',
                      child: Text('Rotate'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
                SizedBox(
                  width: 10,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          Dismissible(
            key: const Key('media_viewer'),
            direction: DismissDirection.down,
            onDismissed: (_) {
              Navigator.pop(context);
            },
            confirmDismiss: (_) async {
              // allow dismiss only if not zoomed
              return true;
            },
            background: Container(color: Colors.black),
            child: _buildGallery(),
          ),
          if (_showUI) _buildBottomThumbnails(),
        ],
      ),
    );
  }

  void _deleteMedia() {
    final currentItem = widget.items[_currentIndex];
    final currentMessage = currentItem.message;
    if (currentMessage == null) return;

    final String messageId = (currentMessage['message_id'] ??
            currentMessage['messageId'] ??
            currentMessage['id'] ??
            currentMessage['_id'] ??
            '')
        .toString();

    if (messageId.isEmpty) return;

    DeleteMessageDialog.show(
      context: context,
      onDeleteForEveryone: () => _performDelete(messageId, 'everyone'),
      onDeleteForMe: () => _performDelete(messageId, 'me'),
    );
  }

  void _performDelete(String messageId, String deleteFor) {
    if (widget.isGroup) {
      context
          .read<group_bloc.GroupChatBloc>()
          .add(group_event.DeleteMessagesEvent(
            messageIds: [messageId],
            convoId: widget.conversionalId ?? "",
            senderId: widget.currentUserId ?? "",
            receiverId: widget.receiverId ?? "",
            message: "",
            deleteFor: deleteFor,
          ));
      log("Group msg deleting..");
    } else {
      context
          .read<private.MessagerBloc>()
          .add(private_event.DeleteMessagesEvent(
            messageIds: [messageId],
            convoId: widget.conversionalId ?? "",
            senderId: widget.currentUserId ?? "",
            receiverId: widget.receiverId ?? "",
            message: "",
            deleteFor: deleteFor,
          ));
      log("Private msg deleting..");
    }
    Navigator.pop(context);
  }

  Widget _buildGallery() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset.abs() > 150) {
          Navigator.pop(context);
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      onTap: _toggleUI,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Opacity(
          opacity: (1 - (_dragOffset / 400)).clamp(0.0, 1.0),
          child: PhotoViewGallery.builder(
            pageController: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              _scrollToIndex(i);
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            builder: (context, index) {
              final item = widget.items[index];

              // 🎥 VIDEO PAGE
              if (item.isVideo) {
                return PhotoViewGalleryPageOptions.customChild(
                  disableGestures: true,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: _rotationTurns[index] ?? 0,
                      child: InlineVideoPlayer(
                        path: item.mediaUrl,
                        isNetwork: item.mediaUrl.startsWith('http'),
                      ),
                    ),
                  ),
                );
              }

              // 🖼 IMAGE PAGE (ZOOMABLE)
              return PhotoViewGalleryPageOptions.customChild(
                heroAttributes: PhotoViewHeroAttributes(tag: item.mediaUrl),
                child: RotatedBox(
                  quarterTurns: _rotationTurns[index] ?? 0,
                  child: PhotoView(
                    imageProvider: item.mediaUrl.startsWith('http')
                        ? CachedNetworkImageProvider(item.mediaUrl)
                        : FileImage(File(item.mediaUrl)) as ImageProvider,
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.transparent),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BOTTOM THUMBNAILS STRIP
  // ==========================================================
  Widget _buildBottomThumbnails() {
    const double thumbSize = 60;
    const double borderSize = 3;

    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 78,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final bool isSelected = index == _currentIndex;

            return GestureDetector(
              onTap: () {
                _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(borderSize),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.transparent,
                    width: borderSize,
                  ),
                ),
                child: Transform.scale(
                  scale: isSelected ? 1.08 : 1.0, // 🔥 smooth zoom
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: thumbSize,
                      height: thumbSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildThumbnail(item),
                          if (item.isVideo)
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // THUMBNAIL BUILDER (IMAGE + VIDEO)
  // ==========================================================
  Widget _buildThumbnail(GroupMediaItem item) {
    const double size = 60;

    // 🖼 IMAGE THUMB
    if (!item.isVideo) {
      return item.mediaUrl.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: item.mediaUrl,
              width: size,
              height: size,
              memCacheWidth: 480,
              memCacheHeight: 600,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade300),
              errorWidget: (_, __, ___) =>
                  Container(color: Colors.grey.shade400),
            )
          : Image.file(
              File(item.mediaUrl),
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
    }

    // 🎥 VIDEO THUMB
    return FutureBuilder<File?>(
      future: VideoCacheService.instance.getThumbnailFuture(item.mediaUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: size,
            height: size,
            color: Colors.black26,
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            snapshot.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        }

        return Container(
          width: size,
          height: size,
          color: Colors.black,
          alignment: Alignment.center,
          child: const Icon(
            Icons.videocam,
            color: Colors.white,
            size: 18,
          ),
        );
      },
    );
  }
}

class InlineVideoPlayer extends StatefulWidget {
  final String path;
  final bool isNetwork;

  const InlineVideoPlayer({
    super.key,
    required this.path,
    required this.isNetwork,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _controller = widget.isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const CircularProgressIndicator();

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
