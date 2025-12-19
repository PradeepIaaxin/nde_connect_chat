import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:objectid/objectid.dart';

import '../../../chat/chat_private_screen/messager_Bloc/widget/MediaPreviewScreen.dart';
import '../../../chat/chat_private_screen/messager_Bloc/widget/VideoPreviewScreen.dart';

class ShowAltDialog {
  static void showOptionsDialog(
    BuildContext context, {
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? roomId,
    String? workspaceId,
    bool? isGroupChat,
    required Function(List<Map<String, dynamic>>) onOptionSelected,
  }) {
    XFile? selectedFile;
    List<XFile> selectedImages = [];
    String? selectedLabel;
    List<Map<String, dynamic>> localMessages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Select an Option",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (selectedFile == null && selectedImages.isEmpty) ...[
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildOption(context, Icons.photo_library, "Gallery", () async {
                            final picker = ImagePicker();

                            // ✅ Only images from gallery
                            final List<XFile> images = await picker.pickMultiImage();

                            if (images.isEmpty) return;

                            Navigator.of(context).pop();

                            final localMessages = await Navigator.push<List<Map<String, dynamic>>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MediaPreviewScreen(
                                  files: images,
                                  conversationId: conversationId!,
                                  senderId: senderId!,
                                  receiverId: receiverId!,
                                  isGroupChat: isGroupChat ?? false,
                                ),
                              ),
                            );

                            if (localMessages != null && localMessages.isNotEmpty) {
                              onOptionSelected(localMessages);
                            }
                          }),
                          _buildOption(context, Icons.videocam, "Video", () async {
                            final picker = ImagePicker();

                            // ✅ Opens GALLERY UI (NOT document UI)
                            final List<XFile> allMedia = await picker.pickMultiVideo();

                            if (allMedia.isEmpty) return;

                            // ✅ Keep ONLY videos
                            final List<XFile> videoFiles = allMedia.where((file) {
                              final mime = lookupMimeType(file.path) ?? '';
                              return mime.startsWith('video/');
                            }).toList();

                            if (videoFiles.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No videos selected")),
                              );
                              return;
                            }

                            // ✅ Close bottom sheet
                            Navigator.of(context).pop();

                            // ✅ Open preview with MULTIPLE videos
                            final localMessages = await Navigator.push<List<Map<String, dynamic>>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MediaPreviewScreen(
                                  files: videoFiles,
                                  conversationId: conversationId!,
                                  senderId: senderId!,
                                  receiverId: receiverId!,
                                  isGroupChat: isGroupChat ?? false,
                                ),
                              ),
                            );

                            // ✅ Return messages to chat
                            if (localMessages != null && localMessages.isNotEmpty) {
                              onOptionSelected(localMessages);
                            }
                          }),

                          _buildOption(context, Icons.camera_alt, "Camera",
                              () async {
                            final XFile? file = await ImagePicker()
                                .pickImage(source: ImageSource.camera);
                            if (file != null) {
                              setState(() {
                                selectedFile = file;
                                selectedLabel = 'Image';
                              });
                            }
                          }),
                          _buildOption(context, Icons.insert_drive_file, "Document", () async {
                            final result = await FilePicker.platform.pickFiles();
                            if (result == null || result.files.single.path == null) return;

                            final xfile = XFile(result.files.single.path!);

                            Navigator.of(context).pop();

                            final localMessages = await Navigator.push<List<Map<String, dynamic>>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MediaPreviewScreen(
                                  files: [xfile],
                                  conversationId: conversationId!,
                                  senderId: senderId!,
                                  receiverId: receiverId!,
                                  isGroupChat: isGroupChat ?? false,
                                ),
                              ),
                            );

                            if (localMessages != null && localMessages.isNotEmpty) {
                              onOptionSelected(localMessages);
                            }
                          }),

                          _buildOption(context, Icons.audiotrack, "Audio",
                              () async {
                            final result = await FilePicker.platform
                                .pickFiles(type: FileType.audio);
                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                selectedFile = XFile(result.files.single.path!);
                                selectedLabel = 'Audio';
                              });
                            }
                          }),
                          _buildOption(context, Icons.location_on, "Location",
                              () async {}),
                        ],
                      )
                    ] else ...[
                      const SizedBox(height: 10),
                      if (selectedLabel == 'Media') ...[
                        if (selectedImages.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) {
                                final file = selectedImages[index];
                                final mime = lookupMimeType(file.path) ?? '';
                                final isImage = mime.startsWith('image/');
                                final isVideo = mime.startsWith('video/');

                                if (isImage) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.file(
                                      File(file.path),
                                      height: 200,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                else if (isVideo) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        // 👇 open full-screen preview BEFORE sending
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => VideoPreviewScreen(file: File(file.path)),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 200,
                                            width: 150,
                                            color: Colors.black12,
                                            child: const Icon(Icons.videocam, size: 40, color: Colors.white70),
                                          ),
                                          const Icon(
                                            Icons.play_circle_fill,
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          )
                        else if (selectedFile != null) // single media file case
                          FutureBuilder<ImageInfo>(
                            future: _loadImageDimensions(selectedFile!.path),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return const Center(child: Text('Failed to load image'));
                                }
                                return Image.file(
                                  File(selectedFile!.path),
                                  height: 500,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const CircularProgressIndicator();
                            },
                          )
                        else
                          const Text('No media selected'),
                      ]

                      // ───────── DOCUMENT / AUDIO / ETC ─────────
                      else if (selectedLabel != null && selectedFile != null) ...[
                        Column(
                          children: [
                            Icon(_getIconForType(selectedLabel!), size: 80),
                            const SizedBox(height: 10),
                            Text(
                              selectedFile!.name,
                              style: const TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ]
                      else ...[
                          const Text('No file selected'),
                        ],

                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text("Send"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          final String tempGroupId = 'temp_group_${ObjectId().toString()}';
                          final List<Map<String, dynamic>> mediaList = [];

                          localMessages.clear();
                          if (selectedImages.isNotEmpty) {
                            final groupMessageId = ObjectId().toString();
                            for (var file in selectedImages) {
                              final msg = await sendFile(
                                context: context,
                                file: file,
                                conversationId: conversationId!,
                                senderId: senderId!,
                                receiverId: receiverId!,
                                isGroupChat: isGroupChat ?? false,
                                isGroupMessage:
                                    selectedImages.length > 1 ? true : false,
                                groupMessageId: selectedImages.length > 1
                                    ? groupMessageId
                                    : null,
                              );
                              if (msg != null) localMessages.add(msg);
                            }
                          } else if (selectedFile != null) {
                            final msg = await sendFile(
                                context: context,
                                file: selectedFile!,
                                conversationId: conversationId!,
                                senderId: senderId!,
                                receiverId: receiverId!,
                                isGroupChat: isGroupChat ?? false,
                                isGroupMessage: false);
                            if (msg != null) localMessages.add(msg);
                          }

                          log("onOptionSelected");
                          onOptionSelected(localMessages);

                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          selectedFile = null;
                          selectedImages = [];
                          selectedLabel = null;
                        }),
                        child: const Text("Choose Another"),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  static Future<ImageInfo> _loadImageDimensions(String filePath) async {
    final image = Image.file(File(filePath));
    final completer = Completer<ImageInfo>();
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
        completer.complete(imageInfo);
      }),
    );
    return completer.future;
  }

  static IconData _getIconForType(String label) {
    switch (label) {
      case 'Document':
        return Icons.insert_drive_file;
      case 'Audio':
        return Icons.audiotrack;
      case 'Location':
        return Icons.location_on;
      default:
        return Icons.insert_drive_file;
    }
  }

  static Future<void> saveImagePathToSession(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('chat_image_path', imageFile.path);
    log(" Image path saved to session: ${imageFile.path}");
  }

  static Future<void> saveFilePathToSession(File fileFile) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('chat_file_path', fileFile.path);
    log(" File path saved to session: ${fileFile.path}");
  }
   double maxVideoSizeMb = 10.0;

  static Future<Map<String, dynamic>?> sendFile({
    required BuildContext context,
    required XFile file,
    required String conversationId,
    required String senderId,
    required String receiverId,
    required bool isGroupChat,
    required bool isGroupMessage,
    String? groupMessageId,
  })
  async {
    try {
      final File localFile = File(file.path);

      if (!localFile.existsSync()) {
        log("  File does not exist at: ${file.path}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected file is missing.")),
        );
        return null;
      }

      final mimeType = lookupMimeType(file.path);
      final isImage = mimeType != null && mimeType.startsWith('image/');
      final isVideo = mimeType != null && mimeType.startsWith('video/');
      const double maxVideoSizeMb = 10.0; // your limit
      final int sizeInBytes = localFile.lengthSync();

      final double sizeInMb = sizeInBytes / (1024 * 1024);

      if (isVideo && sizeInMb > maxVideoSizeMb) {
        // show dialog and STOP sending
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('File too large'),
            content: Text(
              'This video is ${sizeInMb.toStringAsFixed(1)} MB.\n'
                  'Maximum allowed size is $maxVideoSizeMb MB.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return null;
      }
      log("📄 Detected MIME type: $mimeType");
      log("🖼️ Is Image: $isImage");

      final prefs = await SharedPreferences.getInstance();

      if (isImage) {
        await prefs.setString('chat_image_path', localFile.path);
        log(" Image path saved: ${localFile.path}");
      } else {
        await prefs.setString('chat_file_path', localFile.path);
        log(" File path saved: ${localFile.path}");
      }

      final message = {
  'content': '',
  'message_id': 'temp_${ObjectId().toString()}', // 🔥 FIX collision
  'sender': {'_id': senderId},
  'receiver': {'_id': receiverId},
  'messageStatus': 'sent',
  'time': DateTime.now().toIso8601String(),

  'fileName': file.name,
  'fileType': mimeType,

  // 🔥 IMPORTANT
  'imageUrl': isImage ? file.path : null,
  'fileUrl': isVideo ? file.path : null,
  'originalUrl': file.path,
  'isVideo': isVideo,

  // 🔥 NEW FLAG
  'isLocal': true,

  'is_group_message': isGroupMessage,
  'group_message_id': groupMessageId,
};


      log("🟢 Local message metadata: $message");

      // Trigger upload via BLoC
      if (isGroupChat) {
        // context.read<GroupChatBloc>().add(
        //       GrpUploadFileEvent(
        //         localFile,
        //         conversationId,
        //         senderId,
        //         receiverId,
        //         "",
        //         isGroupMessage: isGroupMessage,
        //         groupMessageId: groupMessageId,
        //       ),
        //     );
      } else {
        context.read<MessagerBloc>().add(
              UploadFileEvent(
                localFile,
                conversationId,
                senderId,
                receiverId,
                "",
                isGroupMessage: isGroupMessage,
                groupMesageId: groupMessageId,
              ),
            );
      }

      // Return the local message for immediate UI display
      return message;
    } catch (e, stacktrace) {
      log("  Error uploading file: $e");
      log("🪵 Stacktrace: $stacktrace");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload file.")),
      );
      return null;
    }
  }

  static Widget _buildOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade200,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
