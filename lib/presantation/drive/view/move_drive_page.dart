import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/my_drive_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_event.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_state.dart';
import 'package:nde_email/presantation/drive/common/hexa_color.dart';
import 'package:nde_email/presantation/drive/data/my_drive_repository.dart';

import 'package:nde_email/presantation/drive/view/file_inside_sceen.dart';

class MoveDrivePage extends StatefulWidget {
  final ScrollController? scrollController;
  final void Function(String folderId) onFolderTap;
  final bool isSelectionMode;
  final String movingFileId;

  const MoveDrivePage({
    super.key,
    this.scrollController,
    required this.movingFileId,
    required this.onFolderTap,
    this.isSelectionMode = false,
  });

  @override
  State<MoveDrivePage> createState() => _MoveDrivePageState();
}

class _MoveDrivePageState extends State<MoveDrivePage> {
  bool gridView = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyDriveBloc(repository: MyDriveRepository())
        ..add(FetchMyDriveFolders()),
      child: BlocBuilder<MyDriveBloc, MyDriveState>(
        builder: (context, state) {
          if (state is MyDriveLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MyDriveLoaded) {
            final folders = state.folders;

            if (folders.isEmpty) {
              return const Center(child: Text('No folders found.'));
            }

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        'Folders',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            Icon(gridView ? Icons.view_list : Icons.grid_view),
                        onPressed: () => setState(() => gridView = !gridView),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: gridView
                      ? GridView.builder(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final isFolder =
                                folder.type.toLowerCase() == 'folder';

                            return GestureDetector(
                              onTap: isFolder
                                  ? () => _navigateToFolder(folder)
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isFolder
                                      ? Colors.white
                                      : Colors.grey[300],
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildMimeIcon(folder),
                                    const SizedBox(height: 8),
                                    Text(
                                      folder.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (folder.updatedAt != null)
                                      Text(
                                        "Modified ${DateFormatter.formatToReadableDate(folder.updatedAt!)}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          controller: widget.scrollController,
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final isFolder =
                                folder.type.toLowerCase() == 'folder';

                            return Container(
                              color: isFolder
                                  ? Colors.white
                                  : const Color.fromARGB(255, 226, 223, 223),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: _buildMimeIcon(folder),
                                ),
                                title: Text(folder.name),
                                subtitle: folder.updatedAt != null
                                    ? Row(
                                        children: [
                                          if (folder.starred == true)
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                          Text(
                                            " Modified ${DateFormatter.formatToReadableDate(folder.updatedAt!)}",
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      )
                                    : (folder.labels != null &&
                                            folder.labels!.isNotEmpty)
                                        ? Wrap(
                                            spacing: 2,
                                            children: folder.labels!
                                                .map((label) => Chip(
                                                      label: Text(label),
                                                      backgroundColor:
                                                          _parseColor(label),
                                                      labelStyle:
                                                          const TextStyle(
                                                              color:
                                                                  Colors.white),
                                                    ))
                                                .toList(),
                                          )
                                        : null,
                                onTap: isFolder
                                    ? () => _navigateToFolder(folder)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          } else if (state is MyDriveError) {
            return Center(child: Text('Error: ${state.message}'));
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  void _navigateToFolder(dynamic folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileInsideSceen(
          fileId: folder.id,
          folderName: folder.name,
          gridview: gridView,
          movingFileId: widget.movingFileId,
        ),
      ),
    );
  }

  Widget _buildMimeIcon(dynamic folder) {
    final type = folder.type.toLowerCase();
    final ext = folder.extname?.toLowerCase().trim() ?? "";

    if (type == 'folder') {
      return Image.asset(
        "assets/images/folder.png",
        height: 24,
        width: 24,
        color: (folder.organize != null && folder.organize!.isNotEmpty)
            ? ColorUtils.fromHex(folder.organize!)
            : Colors.amber,
      );
    }

    if (ext.contains('msword') ||
        ext.contains('.docx') ||
        ext.contains('ndocx')) {
      return Image.asset('assets/images/word.png', height: 30, width: 30);
    }

    if (ext.contains('excel') ||
        ext.contains('spreadsheet') ||
        ext.contains('.txt')) {
      return Image.asset('assets/images/sheets.png', height: 24, width: 24);
    }

    if (ext.contains('presentation') || ext.contains('powerpoint')) {
      return Image.asset('assets/images/sheets.png', height: 24, width: 24);
    }

    if (ext.contains('.pdf')) {
      return Image.asset('assets/images/pdf.png', height: 24, width: 24);
    }

    if (ext.contains('image') || ext.contains('.png') || ext.contains('.jpg')) {
      return Image.asset('assets/images/image.png', height: 24, width: 24);
    }

    if (ext.contains('video')) {
      return Image.asset('assets/images/video.png', height: 24, width: 24);
    }

    if (ext.contains('audio') || ext.contains('.mp4')) {
      return Image.asset('assets/images/headphones.png', height: 24, width: 24);
    }

    if (ext.contains('text') || ext.contains('plain')) {
      return Image.asset('assets/images/text.png', height: 24, width: 24);
    }

    if (ext.contains('.zip') ||
        ext.contains('.rar') ||
        ext.contains('compressed')) {
      return Image.asset('assets/images/pdf.png', height: 30, width: 30);
    }

    return Image.asset('assets/images/image.png', height: 24, width: 24);
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll('#', '');
      if (hexColor.length == 6) hexColor = 'FF$hexColor';
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}

class DateFormatter {
  static String formatToReadableDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
