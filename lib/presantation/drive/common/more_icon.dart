import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_action/file_action_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_action/file_action_event.dart';
import 'package:nde_email/presantation/drive/Bloc/file_action/file_action_state.dart';
import 'package:nde_email/presantation/drive/common/colour_picker.dart';
import 'package:nde_email/presantation/drive/view/file_deatilsScreen.dart';
import 'package:nde_email/presantation/drive/view/manage_acces_screen.dart';
import 'package:nde_email/presantation/drive/view/move_screen.dart';

import 'package:nde_email/presantation/drive/view/send_screen.dart';
import 'package:nde_email/utils/reusbale/mime.type.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:share_plus/share_plus.dart';

Future<bool?> showFileOptionsBottomSheet(
  BuildContext context,
  String fileId,
  String fileName,
  String preview,
  String type,
  String? mimetype,
  bool isStarred,
) {
  final fileBloc = context.read<FileOperationsBloc>();
  return showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (context) {
      final screenHeight = MediaQuery.of(context).size.height;
      return BlocProvider.value(
        value: fileBloc,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: screenHeight * 0.55,
            child: FileOptionsContent(
              fileId: fileId,
              fileName: fileName,
              preview: preview,
              type: type,
              mimetype: mimetype,
              isStarred: isStarred,
            ),
          ),
        ),
      );
    },
  );
}

class FileOptionsContent extends StatelessWidget {
  final String fileId;
  final String fileName;
  final String preview;
  final String type;
  final String? mimetype;
  final bool isStarred;

  const FileOptionsContent({
    super.key,
    required this.fileId,
    required this.fileName,
    required this.preview,
    required this.type,
    this.mimetype,
    required this.isStarred,
  });

  void _showRenameDialog(BuildContext context) {
    final TextEditingController _nameController =
        TextEditingController(text: fileName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename File'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter new file name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  context.read<FileOperationsBloc>().add(
                        RenameFileEvent(fileId: fileId, newName: newName),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FileOperationsBloc, FileOperationsState>(
      listener: (context, state) {
        if (state is FileOperationSuccess) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Success'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is FileOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 22),
                    child: buildIcon(type: type, mimeType: mimetype, size: 30),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 8, top: 22, bottom: 5),
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        hSpace8,
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 12,
              ),
              OptionRow(
                icon: Icons.person_add,
                title: 'Share',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShareScreen(fileId),
                    ),
                  );
                },
              ),
              OptionRow(
                icon: Icons.manage_accounts,
                title: 'Manage access',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageAccessScreenUI(fileId: fileId),
                    ),
                  );
                },
              ),

              OptionRow(
                icon: isStarred ? Icons.star : Icons.star_border,
                title: isStarred ? 'Remove from Starred' : 'Add to Starred',
                onTap: () {
                  context.read<FileOperationsBloc>().add(
                        StarFileEvent(fileId: fileId, starred: !isStarred),
                      );
                },
              ),
              const Divider(thickness: 1, indent: 60, endIndent: 0),
              OptionRow(
                icon: Icons.link,
                title: 'Copy link',
                onTap: () {
                  if (preview.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: preview));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context, false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No link available'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const Divider(thickness: 1, indent: 60, endIndent: 0),

              OptionRow(
                icon: Icons.drive_file_rename_outline,
                title: 'Rename',
                onTap: () => _showRenameDialog(context),
              ),
              // OptionRow(
              //   icon: Icons.color_lens,
              //   title: 'Change color',
              //   onTap: () {

              //   },
              // ),

              type == "folder"
                  ? OptionRow(
                      icon: Icons.color_lens,
                      title: 'Change color',
                      onTap: () {
                        MyRouter.pop();

                        showDialog(
                          context: context,
                          builder: (context) {
                            return ColorPickerDialog(
                              onColorSelected: (hex) {
                                log("Selected Color: $hex");

                                context.read<FileOperationsBloc>().add(
                                      OrganizeEvent(fileIDs: [
                                        fileId,
                                      ], pickedColor: hex),
                                    );
                              },
                            );
                          },
                        );
                      },
                    )
                  : voidBox,
              OptionRow(
                icon: Icons.move_down,
                title: 'Move',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 250),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          MoveFileScreen(movingFileId: fileId),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        final tween =
                            Tween(begin: const Offset(0, 1), end: Offset.zero);
                        final curve = CurvedAnimation(
                            parent: animation, curve: Curves.easeOut);
                        return SlideTransition(
                          position: tween.animate(curve),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),

              OptionRow(
                icon: Icons.send,
                title: 'Send a copy',
                onTap: () async {
                  MyRouter.pop();

                  await Future.delayed(const Duration(milliseconds: 300));

                  final name = fileName.trim();
                  final Preview = preview?.toString().trim() ?? '';

                  final textToShare = (name.isNotEmpty || Preview.isNotEmpty)
                      ? "$name\n\n$Preview"
                      : '';

                  if (textToShare.isNotEmpty) {
                    Share.share(textToShare);
                  } else {
                    log("Nothing to share.");
                  }
                },
              ),

              OptionRow(
                icon: Icons.info_outline,
                title: 'Details & activity',
                onTap: () {
                  MyRouter.pop();
                  MyRouter.push(
                      screen: FileDetailScreen(
                    fileID: fileId,
                  ));
                },
              ),

              OptionRow(
                icon: Icons.download,
                title: 'Download File',
                onTap: () {
                  context
                      .read<FileOperationsBloc>()
                      .add(DownloadFileEvent(fileId: fileId));
                },
              ),
              OptionRow(
                icon: Icons.delete_outline,
                title: 'Remove',
                color: const Color.fromARGB(255, 12, 12, 12),
                onTap: () {
                  context
                      .read<FileOperationsBloc>()
                      .add(DeleteFileEvent(fileId: fileId));
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class OptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showDivider;
  final Color? color;
  final VoidCallback? onTap;

  const OptionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.showDivider = true,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: color ?? Theme.of(context).iconTheme.color,
          ),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          minLeadingWidth: 24,
        ),
      ],
    );
  }
}
