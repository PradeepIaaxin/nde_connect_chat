import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart'
    show SocketService;
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:objectid/objectid.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  Future<void> _socketContet() async {
    currentUserId = await UserPreferences.getUserId();
    token = await UserPreferences.getAccessToken();
    wrkspacetoken = await UserPreferences.getDefaultWorkspace();
    await SocketService().ensureConnected();

    // socketService.grpCreatSocket(
    //     token ?? "",
    //     currentUserId ?? "",
    //     wrkspacetoken ?? "",
    //     currentUserId ?? "",
    //     wrkspacetoken ?? "",
    //     (p0) => "",
    //     false);
  }

  void removeRoomId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomId');
  }

  @override
  void dispose() {
    // socket?.dispose();
    removeRoomId();
    SocketService().disconnect();
    _groupNameController.dispose();
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
      //  "group_profile": base64Image,
      "workspaceId": wrkspacetoken,
      "messageId": messageId,
    };

    log(groupPayload.toString());
    log(socketService.isConnected.toString());
    log(groupPayload.toString());
    if (socketService.isConnected == true) {
      socketService.socket!.emitWithAck('create_group', [groupPayload],
          ack: (data) {
        setState(() => isCreating = false);

        if (data != null) {
          var responseData = data is List && data.isNotEmpty ? data[0] : data;

          if (responseData['success'] == true) {
            Messenger.alertSuccess(
                responseData['message'] ?? 'Group created successfully');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Stack(
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
                        backgroundColor: Colors.grey[700],
                        backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.camera_alt, color: Colors.white)
                            : null,
                      ),
                    ),
                    hSpace8,
                    Expanded(
                      child: TextField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          hintText: 'Group name',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.grey),
                  ],
                ),
              ),
              vSpace18,
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.black),
                title: const Text("Disappearing messages"),
                subtitle:
                    const Text("Off", style: TextStyle(color: Colors.grey)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.black),
                title: const Text("Group permissions"),
                onTap: () {},
              ),
              vSpace8,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Members: ${widget.selectedPeople.length}",
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold),
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
                                backgroundColor: ColorUtil.getColorFromAlphabet(
                                    user.firstName[0]),
                                radius: 24,
                                child: Text(
                                  user.firstName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _createGroup,
        backgroundColor: chatColor,
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
