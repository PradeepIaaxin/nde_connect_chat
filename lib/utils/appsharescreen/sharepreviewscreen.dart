import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/Private_Chat_Screen.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MediaPreviewScreen.dart';
import 'package:nde_email/presantation/home/home_screen.dart';
import 'package:nde_email/utils/appsharescreen/shared_widget.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class SharePreviewScreen extends StatefulWidget {
  final List<File> files;

  const SharePreviewScreen({super.key, required this.files});

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  late List<Map<String, dynamic>> processedMessages;
  ChatUserlist? selectedUser;

  @override
  void initState() {
    super.initState();
    _processFiles();
  }

  void _processFiles() {
    // Convert files to message format
    processedMessages = widget.files.map((file) {
      final fileName = file.path.split('/').last;
      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png');
      final isVideo = fileName.toLowerCase().endsWith('.mp4') ||
          fileName.toLowerCase().endsWith('.mov');
      final clientId = 'temp_${DateTime.now().microsecondsSinceEpoch}';

      return {
        'message_id':
            'temp_share_${DateTime.now().millisecondsSinceEpoch}_${widget.files.indexOf(file)}',
        'content': isImage ? '📷 Photo' : (isVideo ? '🎥 Video' : '📎 File'),
        'sender': {'_id': 'temp_user'},
        'senderId': clientId,
        'time': DateTime.now().toIso8601String(),
        'messageStatus': 'sent',
        '_isTempMessage': true,
        '_isOptimistic': true,
        'localImagePath': file.path,
        'fileName': fileName,
        'fileSize': file.lengthSync(),
        'fileType': isImage
            ? 'image/jpeg'
            : (isVideo ? 'video/mp4' : 'application/octet-stream'),
        'mimeType': isImage
            ? 'image/jpeg'
            : (isVideo ? 'video/mp4' : 'application/octet-stream'),
        '_isFromShare': true,
      };
    }).toList();
  }

  void _selectUser() async {
    final user = await showModalBottomSheet<ChatUserlist>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ShareChatList(
          onChatSelected: (user) => Navigator.pop(context, user),
        );
      },
    );

    if (user != null) {
      setState(() {
        selectedUser = user;
      });

      // Now open MediaPreviewScreen with the selected user
      _openMediaPreview(user);
    }
  }

  Future<void> _openMediaPreview(ChatUserlist user) async {
    final currentUserId = await UserPreferences.getUserId() ?? '';
    // Convert File to XFile
    final xFiles = widget.files.map((file) {
      return XFile(
        file.path,
        name: file.path.split('/').last,
      );
    }).toList();

    final localMessages = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          files: xFiles,
          conversationId: user.conversationId ?? "",
          senderId: currentUserId,
          receiverId: user.userId,
          isGroupChat: false,
        ),
      ),
    );

    // If user confirmed send, navigate to chat
    if (localMessages != null && localMessages.isNotEmpty) {
      Navigator.of(MyRouter.navigatorKey.currentContext!).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      Navigator.of(MyRouter.navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (_) => PrivateChatScreen(
            convoId: user.conversationId ?? "",
            receiverId: user.userId,
            firstname: user.firstName,
            lastname: user.lastName,
            userName: user.firstName,
            profileAvatarUrl: "",
            lastSeen: " ",
            datumId: user.userId,
            grpChat: false,
            favourite: false,
            sharedFiles: widget.files,
            initialMessages: localMessages,
          ),
        ),
      );

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => PrivateChatScreen(
      //       convoId: user.conversationId ?? "",
      //       receiverId: user.userId,
      //       firstname: user.firstName,
      //       lastname: user.lastName,
      //       userName: user.firstName,
      //       profileAvatarUrl: "",
      //       lastSeen: " ",
      //       datumId: user.userId,
      //       grpChat: false,
      //       favourite: false,
      //       sharedFiles: widget.files,
      //       initialMessages: localMessages,
      //     ),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          /// 🔹 MEDIA PREVIEW
          Expanded(
            child: PageView.builder(
              itemCount: widget.files.length,
              itemBuilder: (_, i) {
                final file = widget.files[i];
                final isImage = file.path.toLowerCase().endsWith('.jpg') ||
                    file.path.toLowerCase().endsWith('.jpeg') ||
                    file.path.toLowerCase().endsWith('.png');
                final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
                    file.path.toLowerCase().endsWith('.mov');

                return Center(
                  child: isImage
                      ? Image.file(
                          file,
                          fit: BoxFit.contain,
                        )
                      : isVideo
                          ? FutureBuilder<Uint8List?>(
                              future: VideoThumbnail.thumbnailData(
                                video: file.path,
                                imageFormat: ImageFormat.JPEG,
                                maxWidth: 1280,
                                quality: 25,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }

                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                  );
                                }

                                return const Icon(
                                  Icons.videocam_off,
                                  size: 100,
                                  color: Colors.white,
                                );
                              },
                            )
                          : const Icon(
                              Icons.insert_drive_file,
                              size: 100,
                              color: Colors.white,
                            ),
                );
              },
            ),
          ),

          /// 🔹 USER SELECTION AREA
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              children: [
                if (selectedUser != null)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        selectedUser!.firstName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      '${selectedUser!.firstName} ${selectedUser!.lastName}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      selectedUser!.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          selectedUser = null;
                        });
                      },
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _selectUser,
                  icon: Icon(Icons.person_add),
                  label: Text(
                      selectedUser == null ? 'Select Chat' : 'Change Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                if (selectedUser != null) const SizedBox(height: 10),
                if (selectedUser != null)
                  ElevatedButton.icon(
                    onPressed: () => _openMediaPreview(selectedUser!),
                    icon: Icon(Icons.send),
                    label: Text('Send ${widget.files.length} media'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
