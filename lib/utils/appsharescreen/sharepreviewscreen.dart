import 'package:nde_email/presantation/chat/chat_private_screen/Private_Chat_Screen.dart';
import 'package:nde_email/utils/appsharescreen/shared_widget.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class SharePreviewScreen extends StatelessWidget {
  final List<File> files;

  const SharePreviewScreen({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          /// 🔹 MEDIA PREVIEW
          Expanded(
            child: PageView.builder(
              itemCount: files.length,
              itemBuilder: (_, i) {
                return Center(
                  child: Image.file(
                    files[i],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),

          /// 🔹 CHAT LIST (BOTTOM)
          ShareChatList(
            onChatSelected: (user) {
              Navigator.pushReplacement(
                context,
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
                    sharedFiles: files,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
