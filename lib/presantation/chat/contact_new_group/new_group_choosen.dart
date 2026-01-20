import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/socket_service.dart'
    show SocketService;
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:objectid/objectid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;
import 'package:flutter/foundation.dart' as foundation;

class NewGroupChoosen extends StatefulWidget {
  final List<ChatUserlist> selectedPeople;

  const NewGroupChoosen({super.key, required this.selectedPeople});

  @override
  State<NewGroupChoosen> createState() => _NewGroupChoosenState();
}

class _NewGroupChoosenState extends State<NewGroupChoosen> {
  final TextEditingController _groupNameController = TextEditingController();
  final SocketService socketService = SocketService();
  bool isCreating = false;
  File? _imageFile;
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;

  String base64Image = "";

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      final imageTemp = File(pickedFile.path);
      final bytes = await imageTemp.readAsBytes();
      final base64 = base64Encode(bytes);

      setState(() {
        _imageFile = imageTemp;
        base64Image = base64;
        print("Base64 image: $base64Image");
      });
    }
  }

  // IO.Socket? socket;
  String? currentUserId;
  String? token;
  String? wrkspacetoken;

  @override
  void initState() {
    super.initState();
    _socketContet();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });

    _groupNameController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _socketContet() async {
    currentUserId = await UserPreferences.getUserId();
    token = await UserPreferences.getAccessToken();
    wrkspacetoken = await UserPreferences.getDefaultWorkspace();
    await SocketService().initialize();
  }

  void removeRoomId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomId');
  }

  @override
  void dispose() {
    // socket?.dispose();
    removeRoomId();
    // SocketService().disconnect();
    _groupNameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<String?> getRoomId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('roomId');
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      Messenger.alertError("Please enter a group name");
      return;
    }

    setState(() => isCreating = true);

    // 🔥 GENERATE AVATAR IF NO IMAGE SELECTED
    if (_imageFile == null && base64Image.isEmpty) {
      // No image selected, base64Image remains empty or can be set to a default if needed
    }

    final userIds = widget.selectedPeople.map((e) => e.userId).toList();
    final messageId = ObjectId().toString();
    log(userIds.toString());
    log(messageId);

    final groupPayload = {
      "groupName": groupName,
      "membersList": userIds,
      "userId": currentUserId,
      "description": "",
      "roomId": wrkspacetoken,
      "group_avatar": base64Image,
      "workspaceId": wrkspacetoken,
      "messageId": messageId,
    };

    log(groupPayload.toString());
    log(socketService.isConnected.toString());

    if (socketService.isConnected == true) {
      socketService.socket!.emitWithAck('create_group', [groupPayload],
          ack: (data) {
        setState(() => isCreating = false);

        if (data != null) {
          var responseData = data is List && data.isNotEmpty ? data[0] : data;

          if (responseData['success'] == true) {
            Messenger.alertSuccess(responseData['message'] ?? '');

            Navigator.popUntil(context, (route) => route.isFirst);
            _groupNameController.clear();
          } else {
            Messenger.alertError(
                responseData['message'] ?? 'Failed to create group');
          }
        } else {
          Messenger.alertError('No response from server.');
        }
      });
    } else {
      Messenger.alertError('Socket is not connected.');
    }
  }

  void _removeMember(int index) {
    setState(() {
      widget.selectedPeople.removeAt(index);
    });
  }

  void _toggleEmojiKeyboard() {
    if (_showEmoji) {
      // Closing emoji → open keyboard
      setState(() {
        _showEmoji = false;
      });
      _focusNode.requestFocus();
    } else {
      // Opening emoji → hide keyboard first
      _focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _showEmoji = true;
          });
        }
      });
    }
  }

  void _insertEmoji(String emoji) {
    final text = _groupNameController.text;
    final sel = _groupNameController.selection;
    final cursor = sel.start >= 0 ? sel.start : text.length;

    final newText = text.replaceRange(cursor, cursor, emoji);
    _groupNameController.text = newText;
    _groupNameController.selection =
        TextSelection.fromPosition(TextPosition(offset: cursor + emoji.length));
  }

  void _handleEmojiBackspace() {
    final controller = _groupNameController;
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

  @override
  Widget build(BuildContext context) {
    // Determine what to show in the circle avatar
    // 1. Picked Image
    // 2. Dynamic Avatar (Letter/Emoji)
    // 3. Default Icon
    ImageProvider? bgImage;
    Widget? childWidget;
    Color? bgColor = Colors.grey[700];

    if (_imageFile != null) {
      bgImage = FileImage(_imageFile!);
      childWidget = null;
    } else if (_groupNameController.text.trim().isNotEmpty) {
      String firstChar = _groupNameController.text.trim().characters.first;
      bgColor = ColorUtil.getColorFromAlphabet(firstChar);
      childWidget = Text(
        firstChar.toUpperCase(),
        style: const TextStyle(fontSize: 24, color: Colors.white),
      );
    } else {
      childWidget = const Icon(Icons.camera_alt, color: Colors.white);
    }

    return PopScope(
      canPop: !_showEmoji,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _showEmoji = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("New group"),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {},
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      vSpace8,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    const Color.fromARGB(255, 133, 162, 175),
                                backgroundImage: bgImage,
                                child: childWidget,
                              ),
                            ),
                            hSpace8,
                            Expanded(
                              child: TextField(
                                controller: _groupNameController,
                                focusNode: _focusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Group name',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _toggleEmojiKeyboard,
                              icon: Icon(
                                _showEmoji
                                    ? Icons.keyboard
                                    : Icons.emoji_emotions_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      vSpace18,
                      ListTile(
                        leading: const Icon(Icons.timer_outlined,
                            color: Colors.black),
                        title: const Text("Disappearing messages"),
                        subtitle: const Text("Off",
                            style: TextStyle(color: Colors.grey)),
                        onTap: () {},
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.settings, color: Colors.black),
                        title: const Text("Group permissions"),
                        onTap: () {},
                      ),
                      vSpace8,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Members: ${widget.selectedPeople.length}",
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      vSpace18,
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.selectedPeople.length,
                          itemBuilder: (context, index) {
                            final user = widget.selectedPeople[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            ColorUtil.getColorFromAlphabet(user
                                                .firstName
                                                .trim()
                                                .characters
                                                .first),
                                        radius: 24,
                                        child: Text(
                                          user.firstName
                                              .trim()
                                              .characters
                                              .first
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      Positioned(
                                        top: -6,
                                        right: -6,
                                        child: GestureDetector(
                                          onTap: () => _removeMember(index),
                                          child: const CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.red,
                                            child: Icon(Icons.close,
                                                size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(user.firstName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (isCreating)
                    Container(
                      color: Colors.black45,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: _createGroup,
          backgroundColor: chatColor,
          child: const Icon(Icons.check, color: Colors.white),
        ),
      ),
    );
  }
}
