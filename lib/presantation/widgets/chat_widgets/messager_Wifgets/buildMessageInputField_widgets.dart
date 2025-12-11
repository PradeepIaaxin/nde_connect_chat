import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/main.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/reusbale/common_import.dart' hide Category, Emoji;
import 'package:flutter/foundation.dart' as foundation;

import '../../../chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';

class MessageInputField extends StatefulWidget {
  final TextEditingController messageController;
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
  final String reciverID;


  const MessageInputField(
      {super.key,
      required this.messageController,
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
      this.onDraftChanged});

 final ValueChanged<String>? onDraftChanged;
  @override
  _MessageInputFieldState createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  bool _showEmoji = false;
  String? detectedUrl;
  Timer? _draftDebounceTimer;

  final mq = MediaQueryData.fromView(WidgetsBinding.instance.window);

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

  Widget _buildReplyPreview() {
    if (widget.replyText == null) return const SizedBox();

    final String content = widget.replyText?['content']?.toString() ?? '';
    final String? imageUrl = widget.replyText?['imageUrl'];
    final String? fileName = widget.replyText?['fileName'];
    final String? fileType = widget.replyText?['fileType'];
    final String userName = widget.replyText?['userName'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(
          left: BorderSide(color: Colors.blue.shade300, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userName.isNotEmpty)
                  Text(
                    'Replying to $userName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrl,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                if (fileName != null &&
                    fileName.trim().isNotEmpty &&
                    fileName.trim().toLowerCase() != 'file')
                  Text(
                    '📄 $fileName (${fileType ?? 'file'})',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                if (content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(content),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus && _showEmoji) {
        setState(() {
          _showEmoji = false;
        });
      }
    });
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
      child: Column(
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

          // -------- MAIN ROW: input bubble + mic/send button ----------
          Row(
            children: [
              // ========== LEFT: the bubble (reply + textfield) ==========
              Expanded(
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
                        _buildReplyPreviewInline(), // <= NEW (see below)

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
                              controller: widget.messageController,
                              focusNode: widget.focusNode,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                hintStyle:
                                TextStyle(color: Colors.black),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.black),
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
                          widget.messageController.text.isEmpty? IconButton(
                            onPressed: widget.onCameraPressed,
                            icon: const Icon(Icons.camera_alt_rounded,
                                color: Colors.grey, size: 24),
                          ):SizedBox(),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ========== RIGHT: mic / send button ==========
              const SizedBox(width: 6),
              MaterialButton(
                onPressed: widget.messageController.text.trim().isEmpty
                    ? widget.onRecordPressed
                    : widget.onSendPressed,
                minWidth: 0,
                padding: const EdgeInsets.all(10),
                shape: const CircleBorder(),
                color: widget.messageController.text.trim().isEmpty
                    ? (widget.isRecording ? Colors.red : chatColor)
                    : chatColor,
                child: Icon(
                  widget.messageController.text.trim().isEmpty
                      ? (widget.isRecording ? Icons.stop : Icons.mic)
                      : Icons.send,
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
                onEmojiSelected: (ep.Category? category, ep.Emoji emoji) {
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
    final String? imageUrl = widget.replyText?['imageUrl'];
    final String? fileName = widget.replyText?['fileName'];
    final String? fileType = widget.replyText?['fileType'];
    final String userName = widget.replyText?['userName'] ?? '';
    final String? originalUrl = widget.replyText?['originalUrl'];

    // Type label like WhatsApp
    // Type label like WhatsApp
    String typeLabel = '';

    // Decide if this reply is a video
    final bool isVideoReply =
        ((fileType ?? '').toLowerCase().startsWith('video/') ||
            widget.replyText?['isVideo'] == true) &&
            (originalUrl != null && originalUrl.isNotEmpty);

    if (isVideoReply) {
      typeLabel = 'Video';
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      typeLabel = 'Photo';
    } else if (fileName != null && fileName.isNotEmpty) {
      typeLabel = 'Document';
    }


    // ---------- build trailing thumbnail (image / video) ----------
    Widget? trailingThumb;

    // ---------- build trailing thumbnail (image / video) ----------

    const double thumbSize = 70;

    if (isVideoReply) {
      trailingThumb = SizedBox(
        width: thumbSize,
        height: thumbSize,
        child: FutureBuilder<File?>(
          future: VideoThumbUtil.generateFromUrl(originalUrl!),
          builder: (context, snapshot) {
            final thumbFile = snapshot.data;
            if (thumbFile==null) {
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


            if (thumbFile != null && thumbFile.existsSync()) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      thumbFile,
                      width: thumbSize,
                      height: thumbSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: thumbSize,
                height: thumbSize,
                color: Colors.black,
                child: const Icon(Icons.videocam, color: Colors.white),
              ),
            );
          },
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      trailingThumb = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: thumbSize,
          height: thumbSize,
          fit: BoxFit.cover,
        ),
      );
    }


    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // vertical strip
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryButton,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),

          // text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userName.isNotEmpty)
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryButton,
                      fontSize: 13,
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
                            : Icons.note_outlined,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (content.isNotEmpty)
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                          const TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        InkWell(
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
                        )
                      ],
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
                  top: -2,
                  right: -3,
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

  void _handleEmojiBackspace() {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;
    int cursor = sel.start;
    if (cursor <= 0) return;

    final newText = text.replaceRange(cursor - 1, cursor, '');
    widget.messageController.text = newText;
    widget.messageController.selection =
        TextSelection.fromPosition(TextPosition(offset: cursor - 1));
  }

  void _onTextChanged(String value) async {
    setState(() {}); // update send/mic icon

    if (value.trim().isNotEmpty) {
      final userId = await UserPreferences.getUserId() ?? "Unknown";
      final roomId = socketService.generateRoomId(userId, widget.reciverID);
      final userFullName =
          await UserPreferences.getUsername() ?? "Unknown";
      socketService.sendTyping(roomId: roomId, userName: userFullName);
    }

    if (_draftDebounceTimer?.isActive ?? false) {
      _draftDebounceTimer!.cancel();
    }
    _draftDebounceTimer =
        Timer(const Duration(milliseconds: 500), () {
          widget.onDraftChanged?.call(value.trim());
        });
  }

  @override
  void dispose() {
    _draftDebounceTimer?.cancel();
    super.dispose();
  }

}
