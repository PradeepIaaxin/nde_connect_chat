import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/send/send_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/send/send_events.dart';
import 'package:nde_email/presantation/drive/Bloc/send/send_state.dart';
import 'package:nde_email/presantation/drive/data/common_repo.dart';
import 'package:nde_email/presantation/drive/model/search_model/search_model.dart';
import 'package:nde_email/presantation/drive/model/send/send_model.dart';
import 'package:nde_email/presantation/drive/view/manage_acces_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';

class ShareScreen extends StatefulWidget {
  final String fileId;
  const ShareScreen(this.fileId, {super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final TextEditingController searchController = TextEditingController();
  final List<String> emailList = [];
  late Future<SendData> shareDetailsFuture;
  List<UserSearchResult> suggestions = [];
  bool isLoading = false;
  String _selectedPermission = 'editor';
  bool _shouldNotify = false;
  OwnerDetails? _ownerDetails;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    shareDetailsFuture = FoldersRepository().getShareDetails(widget.fileId)
      ..then((details) {
        if (mounted) {
          setState(() {
            _ownerDetails = details.owner;
          });
        }
      });
  }

  void _addEmail(String email) {
    if (email.isNotEmpty &&
        _isValidEmail(email) &&
        !emailList.contains(email)) {
      setState(() {
        emailList.add(email);
      });
      searchController.clear();
      suggestions.clear();
    }
  }

  void _removeEmail(String email) {
    setState(() {
      emailList.remove(email);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  void _onSearchChanged(String query) async {
    setState(() => isLoading = true);

    try {
      final results = await FoldersRepository().searchUsers(query);
      setState(() {
        suggestions = results;
      });
    } catch (e) {
      log("Search error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showPermissionBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Set permission',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildPermissionOption('editor', Icons.edit, 'Can edit'),
            _buildPermissionOption('commenter', Icons.comment, 'Can comment'),
            _buildPermissionOption('viewer', Icons.visibility, 'Can view'),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildPermissionOption(
      String value, IconData icon, String description) {
    return ListTile(
      leading: Icon(icon),
      title: Text(value),
      subtitle: Text(description),
      trailing: _selectedPermission == value
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        setState(() {
          _selectedPermission = value;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShareBloc, ShareState>(
        listener: (context, state) {
          if (state is ShareSuccess) {
            // Show success message (optional)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File shared successfully")),
            );
            // Navigate back to previous screen
            Navigator.pop(context);
          } else if (state is ShareFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to share: ${state.error}")),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Share'),
            actions: [
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (emailList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please add at least one email")),
                    );
                    return;
                  }
                  context.read<ShareBloc>().add(
                        ShareFileEvent(
                          fileId: widget.fileId,
                          emails: emailList,
                          permission: _selectedPermission,
                          notify: _shouldNotify,
                          message: _messageController.text.trim(),
                        ),
                      );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ManageAccessScreenUI(fileId: widget.fileId),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildMainContent(),
              ),
              if (emailList.isEmpty &&
                  suggestions.isEmpty &&
                  _ownerDetails != null)
                _buildBottomBar(context, widget.fileId),
            ],
          ),
        ));
  }

  Widget _buildMainContent() {
    const maxVisibleChips = 3;
    final remainingCount = emailList.length - maxVisibleChips;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Add people or groups (email)',
              prefixIcon: const Icon(Icons.person_add),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() => suggestions = []);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _addEmail,
          ),
          const SizedBox(height: 12),
          if (emailList.isNotEmpty) ...[
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ...emailList
                    .take(emailList.length > maxVisibleChips
                        ? maxVisibleChips
                        : emailList.length)
                    .map((email) => Chip(
                          label: Text(email),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => _removeEmail(email),
                        ))
                    .toList(),
                if (emailList.length > maxVisibleChips)
                  Chip(
                    label: Text('+$remainingCount more'),
                    avatar: const Icon(Icons.add, size: 18),
                    onDeleted: null,
                    deleteIcon: null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          if (emailList.isNotEmpty) ...[
            InkWell(
              onTap: _showPermissionBottomSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Text(
                      '',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      _selectedPermission,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _shouldNotify,
                      onChanged: (value) {
                        setState(() {
                          _shouldNotify = value ?? false;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notify people',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (_shouldNotify) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Add a message (optional)',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontSize: 13,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ],
          Expanded(
            child: FutureBuilder<SendData>(
              future: shareDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final data = snapshot.data!;
                return ListView(
                  children: [
                    if (isLoading)
                      ShimmerListLoader(
                        iconSize: 40,
                        titleHeight: 18,
                        subtitleHeight: 14,
                        trailingIconSize: 20,
                        padding: EdgeInsets.all(10),
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[50]!,
                        titleWidthFactor: 0.8,
                        subtitleWidth: 100,
                      ),
                    if (suggestions.isNotEmpty)
                      ...suggestions.map(
                        (user) => ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(user.userName ?? user.email),
                          subtitle: Text(user.email),
                          onTap: () => _addEmail(user.email),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, String fileId) {
    final owner = _ownerDetails;

    if (owner == null) {
      return const SizedBox.shrink();
    }

    final String initials = (owner.firstName?.isNotEmpty ?? false)
        ? owner.firstName![0].toUpperCase()
        : '?';

    final bool hasProfilePic = owner.profilePic?.isNotEmpty ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManageAccessScreenUI(fileId: fileId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Text(
                  "Manage Access",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 16, 17, 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color.fromARGB(255, 54, 138, 206),
                  backgroundImage:
                      hasProfilePic ? NetworkImage(owner.profilePic!) : null,
                  child: !hasProfilePic
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
