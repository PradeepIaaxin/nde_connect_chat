import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';

class ProfileDialog extends StatefulWidget {
  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  String? userName;
  String? userEmail;
  String? profilePicUrl;
  bool isLoading = true;
  bool imageError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final name = await UserPreferences.getUsername();
      final email = await UserPreferences.getEmail();
      final picUrl = await UserPreferences.getProfilePicKey();

      if (mounted) {
        setState(() {
          userName = name?.isNotEmpty == true ? name : "Unknown User";
          userEmail = email ?? "No Email";
          profilePicUrl = picUrl;
          isLoading = false;
        });
      }
    } catch (e) {
      log(" Error loading profile data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
     SocketService().disconnect();
    await UserPreferences.logout(context);
    ChatSessionStorage.clear();
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return "U";
    List<String> words = name.trim().split(' ');
    return words.isNotEmpty ? words[0][0].toUpperCase() : "U";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Now Digital Easy",
              style: TextStyle(
                fontSize: 16,
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Profile row
                  Row(
                    children: [
                      // ClipOval(
                      //   child: CachedNetworkImage(
                      //     imageUrl: profilePicUrl!,
                      //     placeholder: (context, url) =>
                      //         const CircularProgressIndicator(),
                      //     errorWidget: (context, url, error) => CircleAvatar(
                      //       radius: 20,
                      //       backgroundColor: AppColors.profile,
                      //       child: Text(
                      //         userName != null && userName!.isNotEmpty
                      //             ? userName![0].toUpperCase()
                      //             : "",
                      //         style: const TextStyle(
                      //           color: AppColors.bg,
                      //           fontSize: 18,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            (profilePicUrl != null && profilePicUrl!.isNotEmpty)
                                ? NetworkImage(profilePicUrl!)
                                : null,
                        backgroundColor: Colors.grey.shade300,
                        child: (profilePicUrl == null || profilePicUrl!.isEmpty)
                            ? Text(
                                _getInitial(userName),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? "Unknown User",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userEmail ?? "example@email.com",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        "99+",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Manage your NDE Mail Account",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(thickness: 0.7),

                  Row(
                    children: [
                      const Icon(Icons.work_outline, color: Colors.grey),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Remote Work"),
                            Text("Checked Out",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Switch(value: false, onChanged: (_) {}),
                    ],
                  ),

                  SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_add_alt, color: Colors.grey),
                      const SizedBox(width: 10),
                      const Expanded(child: Text("Add another account")),
                    ],
                  ),
                  const Divider(thickness: 0.7),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () => _logout(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
