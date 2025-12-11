import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/spacer/spacer.dart';

class Endrawer extends StatefulWidget {
  final String userName;
  final String? profileUrl;
  final String? gmail;
  const Endrawer(
      {super.key, required this.userName, this.profileUrl, this.gmail});

  @override
  State<Endrawer> createState() => _EndrawerState();
}

class _EndrawerState extends State<Endrawer> {
  Future<void> _logout(BuildContext context) async {
    await UserPreferences.logout(context);
    ChatSessionStorage.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "         ${widget.gmail}",
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent,
                child:
                    widget.profileUrl != null && widget.profileUrl!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.profileUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (_, __, ___) => CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.profile,
                                child: Text(
                                  widget.userName.isNotEmpty == true
                                      ? widget.userName[0].toUpperCase()
                                      : "",
                                  style: const TextStyle(
                                    color: AppColors.bg,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.profile,
                            child: Text(
                              widget.userName.isNotEmpty == true
                                  ? widget.userName[0].toUpperCase()
                                  : "",
                              style: const TextStyle(
                                color: AppColors.bg,
                                fontSize: 18,
                              ),
                            ),
                          ),
              ),
              const SizedBox(height: 12),
              Text("Hi, ${widget.userName}!",
                  style: const TextStyle(color: Colors.black, fontSize: 20)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  foregroundColor: Colors.black,
                ),
                child: const Text("Manage your Google Account"),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("Privacy Policy",
                        style: TextStyle(color: Colors.black87)),
                    SizedBox(width: 8),
                    Text("•", style: TextStyle(color: Colors.black87)),
                    SizedBox(width: 8),
                    Text("Terms of Service",
                        style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
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
              vSpace36,
            ],
          ),
        ),
      ),
    );
  }
}
