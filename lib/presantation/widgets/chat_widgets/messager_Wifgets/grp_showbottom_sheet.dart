import 'package:file_picker/file_picker.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart';

class GrpShowAltDialog {
  static void grpshowOptionsDialog(
    BuildContext context, {
    required String conversationId,
    required String senderId,
    required String receiverId,
    required bool isGroupChat,
    required VoidCallback onOptionSelected,
    Function(List<XFile>)? onFilesSelected,
  }) {
    List<XFile>? selectedFiles;
    String? selectedLabel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Select an Option",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // ---------------- SELECT GRID -------------------
                      if (selectedFiles == null) ...[
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            // GALLERY (Images)
                            _buildOption(
                              context,
                              Icons.photo_library,
                              "Gallery",
                              () async {
                                final files =
                                    await ImagePicker().pickMultiImage();
                                if (files.isNotEmpty) {
                                  setState(() {
                                    selectedFiles = files;
                                    selectedLabel = 'Image';
                                  });
                                }
                              },
                            ),

                            // VIDEO
                            _buildOption(
                              context,
                              Icons.videocam,
                              "Video",
                              () async {
                                final files =
                                    await ImagePicker().pickMultiVideo();
                                if (files.isNotEmpty) {
                                  setState(() {
                                    selectedFiles = files;
                                    selectedLabel = 'Video';
                                  });
                                }
                              },
                            ),

                            // CAMERA
                            _buildOption(
                              context,
                              Icons.camera_alt,
                              "Camera",
                              () async {
                                final file = await ImagePicker().pickImage(
                                  source: ImageSource.camera,
                                );
                                if (file != null) {
                                  setState(() {
                                    selectedFiles = [file];
                                    selectedLabel = 'Image';
                                  });
                                }
                              },
                            ),

                            // DOCUMENTS
                            _buildOption(
                              context,
                              Icons.insert_drive_file,
                              "Document",
                              () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  allowMultiple: true,
                                );
                                if (result != null) {
                                  setState(() {
                                    selectedFiles = result.paths
                                        .whereType<String>()
                                        .map((e) => XFile(e))
                                        .toList();
                                    selectedLabel = 'File';
                                  });
                                }
                              },
                            ),

                            // AUDIO
                            _buildOption(
                              context,
                              Icons.audiotrack,
                              "Audio",
                              () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.audio,
                                  allowMultiple: true,
                                );
                                if (result != null) {
                                  setState(() {
                                    selectedFiles = result.paths
                                        .whereType<String>()
                                        .map((e) => XFile(e))
                                        .toList();
                                    selectedLabel = 'Audio';
                                  });
                                }
                              },
                            ),

                            // LOCATION
                            _buildOption(
                              context,
                              Icons.location_on,
                              "Location",
                              () async {
                                // Placeholder for location logic
                              },
                            ),
                          ],
                        )
                      ]
                      // ---------------- PREVIEW -------------------
                      else ...[
                        const SizedBox(height: 10),

                        // IMAGE OR VIDEO PREVIEW
                        if (selectedLabel == "Image" ||
                            selectedLabel == "Video")
                          SizedBox(
                            height:
                                200, // Reduced height to match private chat style
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedFiles!.length,
                              itemBuilder: (context, index) {
                                final file = selectedFiles![index];
                                final mime = lookupMimeType(file.path) ?? '';
                                final isVideo = mime.startsWith('video/') ||
                                    selectedLabel == 'Video';

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: isVideo
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 150,
                                              height: 200,
                                              color: Colors.black12,
                                              child: const Icon(Icons.videocam,
                                                  size: 50,
                                                  color: Colors.white70),
                                            ),
                                            const Icon(Icons.play_circle_fill,
                                                size: 40, color: Colors.white),
                                          ],
                                        )
                                      : Image.file(
                                          File(file.path),
                                          width: 150,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                );
                              },
                            ),
                          )
                        else
                          // FILE/AUDIO PREVIEW
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: selectedFiles!.length,
                              itemBuilder: (context, index) {
                                final name =
                                    selectedFiles![index].path.split("/").last;

                                return ListTile(
                                  leading:
                                      Icon(_getIconForType(selectedLabel!)),
                                  title: Text(name),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),

                        // ---------------- SEND BUTTON -------------------
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text("Send"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () async {
                            if (onFilesSelected != null &&
                                selectedFiles != null) {
                              // ✅ New path: Pass files back to caller to handle optimistic updates
                              onFilesSelected(selectedFiles!);
                              Navigator.of(context).pop();
                              return;
                            }

                            // ⚠️ Legacy path: Handling internally (race condition prone for optimistic IO)
                            final count = selectedFiles!.length;
                            final isGrouped = count >= 4;
                            final String? groupMessageId =
                                isGrouped ? ObjectId().toString() : null;

                            for (final file in selectedFiles!) {
                              await _sendFile(
                                context: context,
                                file: file,
                                conversationId: conversationId,
                                senderId: senderId,
                                receiverId: receiverId,
                                isGroupChat: isGroupChat,
                                isGroupMessage: isGrouped,
                                groupMessageId: groupMessageId,
                              );
                            }

                            onOptionSelected();
                            Navigator.of(context).pop();
                          },
                        ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFiles = null;
                              selectedLabel = null;
                            });
                          },
                          child: const Text("Choose Another"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------

  static Future<void> _sendFile({
    required BuildContext context,
    required XFile file,
    required String conversationId,
    required String senderId,
    required String receiverId, // GROUP ID
    required bool isGroupChat,
    required bool isGroupMessage,
    required String? groupMessageId,
  }) async {
    try {
      final localFile = File(file.path);

      if (!localFile.existsSync()) {
        log("❌ File Missing: ${file.path}");
        return;
      }

      final mimeType = lookupMimeType(file.path);
      final bool isImage = mimeType != null && mimeType.startsWith('image/');

      final prefs = await SharedPreferences.getInstance();

      // Save local path for preview
      if (isImage) {
        await prefs.setString('chat_image_path', localFile.path);
      } else {
        await prefs.setString('chat_file_path', localFile.path);
      }

      final localMessage = {
        "content": "",
        "sender": {"_id": senderId},
        "receiver": {"_id": receiverId},
        "messageStatus": "pending",
        "time": DateTime.now().toIso8601String(),
        "localImagePath": isImage ? file.path : null,
        "fileName": file.name,
        "fileType": mimeType,
        "imageUrl": isImage ? file.path : null,
        "fileUrl": !isImage ? file.path : null,
      };

      log("🟢 Local message: $localMessage");

      // ---------- SEND TO BLOC ----------
      if (isGroupChat) {
        context.read<GroupChatBloc>().add(
              GrpUploadFileEvent(
                file: localFile,
                convoId: conversationId,
                senderId: senderId,
                receiverId: receiverId,
                groupId: receiverId,
                message: "",
                isGroupMessage: isGroupMessage,
                groupMessageId: groupMessageId,
              ),
            );
      } else {
        context.read<MessagerBloc>().add(
              UploadFileEvent(
                localFile,
                conversationId,
                senderId,
                receiverId,
                "",
              ),
            );
      }
    } catch (e, s) {
      log("ERROR: $e\n$s");
    }
  }

  // --------------------------------------------------

  static IconData _getIconForType(String label) {
    switch (label) {
      case 'File':
        return Icons.insert_drive_file;
      case 'Audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  // --------------------------------------------------

  static Widget _buildOption(
      BuildContext context, IconData icon, String label, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blue.shade300,
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
