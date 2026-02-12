import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/main.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/whatapp_recoreder_widget.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/reusbale/common_import.dart' hide Category;
import 'package:flutter/foundation.dart' as foundation;
import '../../../chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';

class MessageInputField extends StatefulWidget {
  final TextEditingController messageController;
  final String conversionId;
  final FocusNode focusNode;
  final VoidCallback onSendPressed;
  final VoidCallback onEmojiPressed;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onRecordPressed;
  final bool isRecording;
  final Map<String, dynamic>? replyText;
  final VoidCallback? onCancelReply;
  final bool thereORleft;
  final bool isGroupChat;
  final String reciverID;
  final ValueChanged<String>? onDraftChanged;
  final VoidCallback? onLockRecording;
  final VoidCallback? onCancelRecording;
  final Function(String path, int duration)? onSendRecording;
  final bool isRecordingLocked;
  final List<Map<String, dynamic>>? groupMembers;

  final String? currentUserId;

  const MessageInputField({
    super.key,
    required this.messageController,
    required this.conversionId,
    required this.focusNode,
    required this.onSendPressed,
    required this.onEmojiPressed,
    required this.onAttachmentPressed,
    required this.onCameraPressed,
    required this.onRecordPressed,
    required this.isRecording,
    required this.reciverID,
    this.replyText,
    this.onCancelReply,
    this.thereORleft = false,
    this.isGroupChat = false,
    this.onDraftChanged,
    this.onLockRecording,
    this.onCancelRecording,
    this.onSendRecording,
    this.isRecordingLocked = false,
    this.groupMembers,
    this.currentUserId,
  });

  @override
  _MessageInputFieldState createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  bool _showEmoji = false;
  String? detectedUrl;
  Timer? _draftDebounceTimer;

  final mq = MediaQueryData.fromView(WidgetsBinding.instance.window);

  // Mention Logic
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _filteredMembers = [];
  String _mentionQuery = "";

  void _toggleEmojiKeyboard() {
    if (_showEmoji) {
      // Closing emoji → open keyboard
      setState(() {
        _showEmoji = false;
      });
      widget.focusNode.requestFocus();
    } else {
      // Opening emoji → hide keyboard first
      widget.focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _showEmoji = true;
          });
        }
      });
    }
  }

  /// Simple URL regex matcher
  String? extractUrl(String text) {
    final urlRegex = RegExp(r"(https?:\/\/[^\s]+)", caseSensitive: false);
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
      if (!widget.focusNode.hasFocus) {
        _removeOverlay();
      }
    });

    widget.messageController.addListener(() {
      setState(() {});
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width * 0.9,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -200), // Adjust to show above input
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = _filteredMembers[index];
                  final user = member['user'] ?? member;
                  final firstName =
                      user['first_name'] ?? user['firstName'] ?? '';
                  final lastName = user['last_name'] ?? user['lastName'] ?? '';
                  String name = "$firstName $lastName".trim();
                  if (name.isEmpty) {
                    name = user['username'] ?? user['name'] ?? 'Unknown';
                  }
                  final username = user['username'] ?? user['name'] ?? name;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(name.isNotEmpty ? name : "Unknown"),
                    subtitle: Text("@$username"),
                    onTap: () => _onMemberSelected(member),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_filteredMembers.isEmpty) {
      _removeOverlay();
    } else {
      if (_overlayEntry == null) {
        _showOverlay();
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    }
  }

  void _onMemberSelected(Map<String, dynamic> member) {
    final user = member['user'] ?? member;
    final firstName = user['first_name'] ?? user['firstName'] ?? '';
    final lastName = user['last_name'] ?? user['lastName'] ?? '';
    String name = "$firstName $lastName".trim();

    if (name.isEmpty) {
      name = user['username'] ?? user['name'] ?? 'Unknown';
    }

    final text = widget.messageController.text;
    final selection = widget.messageController.selection;
    final cursorPos = selection.baseOffset;

    // Find the start of the mention query
    final lastAt = text.lastIndexOf('@', cursorPos - 1);
    if (lastAt != -1) {
      final newText = text.replaceRange(lastAt, cursorPos, "@$name ");
      widget.messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: lastAt + name.length + 2),
      );
    }

    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.messageController.text.trim();
    detectedUrl = extractUrl(text);

    return widget.thereORleft
        ? voidBox
        : Padding(
            padding: EdgeInsets.symmetric(
              vertical: mq.size.height * .01,
              horizontal: mq.size.width * .025,
            ),
            child: widget.isRecordingLocked
                ? WhatsAppRecorderWidget(
                    onStop: widget.onCancelRecording ?? () {},
                    onSend: widget.onSendRecording ?? (path, duration) {},
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------- optional link preview (like you already have) ----------
                      if (detectedUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: AnyLinkPreview(
                            link: detectedUrl!,
                            displayDirection: UIDirection.uiDirectionHorizontal,
                            showMultimedia: true,
                            bodyMaxLines: 3,
                            bodyTextOverflow: TextOverflow.ellipsis,
                            titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            bodyStyle: const TextStyle(color: Colors.black),
                          ),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: CompositedTransformTarget(
                              link: _layerLink,
                              child: Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                margin: EdgeInsets.zero,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.replyText != null)
                                      _buildReplyPreviewInline(),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _toggleEmojiKeyboard,
                                          icon: const Icon(
                                            Icons.emoji_emotions_outlined,
                                            color: Colors.grey,
                                            size: 24,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                widget.messageController,
                                            focusNode: widget.focusNode,
                                            decoration: const InputDecoration(
                                              hintText: 'Message',
                                              hintStyle: TextStyle(
                                                  color: Colors.black),
                                              border: InputBorder.none,
                                            ),
                                            style: const TextStyle(
                                                color: Colors.black),
                                            minLines: 1,
                                            maxLines: 5,
                                            onChanged: _onTextChanged,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: widget.onAttachmentPressed,
                                          icon: const Icon(Icons.attach_file,
                                              color: Colors.grey, size: 24),
                                        ),
                                        widget.messageController.text.isEmpty
                                            ? IconButton(
                                                onPressed:
                                                    widget.onCameraPressed,
                                                icon: const Icon(
                                                    Icons.camera_alt_rounded,
                                                    color: Colors.grey,
                                                    size: 24),
                                              )
                                            : const SizedBox(),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ========== RIGHT: mic / send button ==========
                          const SizedBox(width: 6),
                          widget.messageController.text.trim().isEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    widget.onLockRecording?.call();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.isRecording
                                          ? Colors.red
                                          : chatColor,
                                    ),
                                    child: Icon(
                                      widget.isRecording
                                          ? Icons.mic
                                          : Icons.mic_none,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                )
                              : MaterialButton(
                                  onPressed: widget.onSendPressed,
                                  minWidth: 0,
                                  padding: const EdgeInsets.all(10),
                                  shape: const CircleBorder(),
                                  color: chatColor,
                                  child: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                        ],
                      ),

                      // ========== Emoji panel below input ==========
                      if (_showEmoji)
                        SizedBox(
                          height: 280,
                          child: ep.EmojiPicker(
                            onEmojiSelected:
                                (ep.Category? category, ep.Emoji emoji) {
                              _insertEmoji(emoji.emoji);
                            },
                            onBackspacePressed: _handleEmojiBackspace,
                            config: ep.Config(
                              height: 256,
                              checkPlatformCompatibility: true,
                              viewOrderConfig: const ep.ViewOrderConfig(),
                              emojiViewConfig: ep.EmojiViewConfig(
                                emojiSizeMax: 28 *
                                    (foundation.defaultTargetPlatform ==
                                            TargetPlatform.iOS
                                        ? 1.2
                                        : 1.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          );
  }

  Widget _buildReplyPreviewInline() {
    if (widget.replyText == null) return const SizedBox();

    final String content = widget.replyText?['content']?.toString() ?? '';
    final String? imageUrl =
        widget.replyText?['originalUrl'] ?? widget.replyText?['imageUrl'];
    final String? fileName = widget.replyText?['fileName'];
    final String? fileType = widget.replyText?['fileType'] ??
        widget.replyText?['mimeType'] ??
        widget.replyText?['mimetype'] ??
        widget.replyText?['ContentType'];
    final String? fileUrl = widget.replyText?['fileUrl'];
    // final String userName = widget.replyText?['userName'] ?? '';
    final String? originalUrl = widget.replyText?['originalUrl'];

    // final bool isSendMe = widget.replyText?['isSendMe'];
    final String senderId = widget.replyText?['senderId']?.toString() ?? "";

    log("sssssssss $senderId");
    log("sssssssss $senderId");
    log("originalUrl $originalUrl");

// 🔥 Detect grouped media safely
    final bool hasGroupId = widget.replyText?['group_message_id'] != null;

    final int localImageCount = int.tryParse(
          widget.replyText?['imageCount']?.toString() ?? '0',
        ) ??
        0;

    final int localVideoCount = int.tryParse(
          widget.replyText?['videoCount']?.toString() ?? '0',
        ) ??
        0;

    final bool isGroupedMedia =
        hasGroupId && (localImageCount + localVideoCount > 1);

    // Type label like WhatsApp
    // Type label like WhatsApp
    String typeLabel = '';

    // Decide if this reply is a video
    final bool isVideoReply =
        ((fileType ?? '').toLowerCase().startsWith('video/') ||
                widget.replyText?['isVideo'] == true) &&
            (originalUrl != null && originalUrl.isNotEmpty);

    final bool isImage =
        (fileType != null && fileType.toLowerCase().startsWith('image/')) ||
            (widget.replyText?['ContentType'] == 'image') ||
            (widget.replyText?['contentType'] == 'image') ||
            (fileName != null &&
                ['.jpg', '.jpeg', '.png', '.gif', '.webp']
                    .any((ext) => fileName.toLowerCase().endsWith(ext))) ||
            (imageUrl != null &&
                imageUrl.isNotEmpty &&
                ['.jpg', '.jpeg', '.png', '.gif', '.webp']
                    .any((ext) => imageUrl.toLowerCase().contains(ext)));

    final bool isAudio =
        (fileType != null && fileType.toLowerCase().startsWith('audio/')) ||
            (widget.replyText?['ContentType'] == 'audio') ||
            (widget.replyText?['contentType'] == 'audio') ||
            (fileName != null &&
                ['.mp3', '.wav', '.aac', '.m4a', '.flac', '.ogg', '.opus']
                    .any((ext) => fileName.toLowerCase().endsWith(ext)));

    final bool isDocument = !isVideoReply &&
        !isAudio &&
        !isImage &&
        ((fileType != null &&
                !fileType.toLowerCase().startsWith('image/') &&
                !fileType.toLowerCase().startsWith('video/') &&
                !fileType.toLowerCase().startsWith('audio/') &&
                fileType.isNotEmpty) ||
            widget.replyText?['isDocument'] == true ||
            widget.replyText?['ContentType'] == 'file' ||
            widget.replyText?['contentType'] == 'file' ||
            widget.replyText?['ContentType'] == 'document' ||
            widget.replyText?['contentType'] == 'document' ||
            (fileUrl != null && fileUrl.isNotEmpty));
    if (isGroupedMedia) {
      if (localImageCount > 0 && localVideoCount > 0) {
        typeLabel = 'Media x ${localImageCount + localVideoCount}';
      } else if (localImageCount > 0) {
        typeLabel = 'Photo x $localImageCount';
      } else if (localVideoCount > 0) {
        typeLabel = 'Video x $localVideoCount';
      }
    } else {
      if (isVideoReply) {
        typeLabel = 'Video';
      } else if (isAudio) {
        typeLabel = 'Audio';
      } else if (isImage) {
        typeLabel = 'Photo';
      } else if (isDocument) {
        typeLabel = 'Document';
      }
    }
    Widget buildVideoThumb(String videoPathOrUrl) {
      const double size = 70;

      return SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<File?>(
          future: VideoThumbUtil.generateFromUrl(videoPathOrUrl),
          builder: (context, snapshot) {
            // ⏳ Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            // ✅ Thumbnail generated
            if (snapshot.hasData && snapshot.data != null) {
              final file = snapshot.data!;
              if (file.existsSync()) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        file,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                );
              }
            }

            // ❌ Fallback (thumbnail failed)
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: size,
                height: size,
                color: Colors.black,
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            );
          },
        ),
      );
    }

    // ---------- build trailing thumbnail (image / video) ----------
    Widget? trailingThumb;

    if (!isGroupedMedia) {
      if (isVideoReply) {
        trailingThumb = buildVideoThumb(originalUrl);
      } else if (isAudio) {
        // Don't show thumbnail for audio, just icon + text
        trailingThumb = null;
      } else if (isDocument) {
        // Don't show thumbnail for documents, just icon + text
        trailingThumb = null;
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        trailingThumb = imageUrl.startsWith('/')
            ? Image.file(File(imageUrl),
                width: 70, height: 70, fit: BoxFit.cover)
            : Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover);
      }
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: Colors.blueAccent, width: 5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 8),

            // text info
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "You",
                          style: TextStyle(
                            color: AppColors.primaryButton,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (typeLabel.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                typeLabel == 'Photo'
                                    ? Icons.photo
                                    : typeLabel == 'Video'
                                        ? Icons.video_camera_back_rounded
                                        : typeLabel.startsWith('Audio')
                                            ? Icons.music_note
                                            : typeLabel == 'Document'
                                                ? Icons.insert_drive_file
                                                : null,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                typeLabel,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        // Only show caption for non-media messages
                        if (content.isNotEmpty &&
                            !isImage &&
                            !isVideoReply &&
                            !isDocument)
                          Text(
                            content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// ✅ Close icon at TOP RIGHT
                  if (trailingThumb == null)
                    Positioned(
                      top: -7,
                      right: 0,
                      child: InkWell(
                        onTap: widget.onCancelReply,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // thumbnail + close button (works for image & video)
            if (trailingThumb != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  trailingThumb,
                  Positioned(
                    top: -6,
                    right: -6,
                    child: InkWell(
                      onTap: widget.onCancelReply,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;
    final cursor = sel.start >= 0 ? sel.start : text.length;

    final newText = text.replaceRange(cursor, cursor, emoji);
    widget.messageController.text = newText;
    widget.messageController.selection =
        TextSelection.fromPosition(TextPosition(offset: cursor + emoji.length));
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _handleEmojiBackspace() {
    final controller = widget.messageController;
    final text = controller.text;
    final selection = controller.selection;

    if (selection.start <= 0) return;

    final chars = text.characters.toList();
    final cursorIndex = text.characters
        .takeWhile((c) => text.indexOf(c) < selection.start)
        .length;

    if (cursorIndex == 0) return;

    chars.removeAt(cursorIndex - 1);

    final newText = chars.join();

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.characters.take(cursorIndex - 1).string.length,
      ),
    );

    setState(() {});
  }

  void _onTextChanged(String value) async {
    final capitalized = capitalizeFirstLetter(value);

    // ✅ Prevent infinite loop
    if (capitalized != widget.messageController.text) {
      final cursorPosition = widget.messageController.selection.baseOffset;

      widget.messageController.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(
          offset: cursorPosition.clamp(0, capitalized.length),
        ),
      );
    }

    // Mention Logic
    if (widget.isGroupChat && widget.groupMembers != null) {
      final cursorPosition = widget.messageController.selection.baseOffset;
      if (cursorPosition > 0) {
        final textBeforeCursor = value.substring(0, cursorPosition);
        final lastAt = textBeforeCursor.lastIndexOf('@');

        if (lastAt != -1) {
          final query = textBeforeCursor.substring(lastAt + 1);
          // Check if there's a space after @, if so, stop mentioning unless it's part of a name
          // For simplicity, let's assume mentions don't have spaces for now or handle it smarter
          // Actually WhatsApp allows spaces in names.
          // Let's check if there is a space before @ or if it's the start of the string
          bool isValidStart =
              lastAt == 0 || textBeforeCursor[lastAt - 1] == ' ';

          if (isValidStart) {
            setState(() {
              _mentionQuery = query.toLowerCase();
              debugPrint("🔎 Mention Query: $_mentionQuery");
              debugPrint("👥 Total Members: ${widget.groupMembers?.length}");

              _filteredMembers = widget.groupMembers!.where((member) {
                // Handle both direct keys and nested 'user' object
                final user = member['user'] ?? member;
                final memberId =
                    (user['_id'] ?? user['id'] ?? user['member_id'] ?? '')
                        .toString();

                if (widget.currentUserId != null &&
                    memberId == widget.currentUserId) {
                  return false;
                }

                // Check for various name keys
                final firstName = user['first_name'] ?? user['firstName'] ?? '';
                final lastName = user['last_name'] ?? user['lastName'] ?? '';
                final name = "$firstName $lastName".trim();
                final username =
                    (user['username'] ?? user['name'] ?? '').toString();

                final matches = name.toLowerCase().contains(_mentionQuery) ||
                    username.toLowerCase().contains(_mentionQuery);

                // debugPrint("Checking member: $name ($username) -> $matches");
                return matches;
              }).toList();
              debugPrint("✅ Filtered Members: ${_filteredMembers.length}");
            });
            _updateOverlay();
          } else {
            _removeOverlay();
          }
        } else {
          _removeOverlay();
        }
      } else {
        _removeOverlay();
      }
    }

    setState(() {});

    // ---- existing typing indicator logic ----
    if (capitalized.trim().isNotEmpty) {
      final userId = await UserPreferences.getUserId() ?? "Unknown";

      final userFullName = await UserPreferences.getUsername() ?? "Unknown";
      socketService.sendTyping(
          convoId: widget.conversionId,
          userName: userFullName,
          userId: userId,
          recervirId: widget.reciverID);
    }

    // ---- draft debounce ----
    _draftDebounceTimer?.cancel();
    _draftDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onDraftChanged?.call(capitalized.trim());
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _draftDebounceTimer?.cancel();
    super.dispose();
  }
}
