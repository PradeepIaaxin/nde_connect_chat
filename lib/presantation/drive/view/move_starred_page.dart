import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/starred_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/starred_event.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/starred_state.dart';
import 'package:nde_email/presantation/drive/common/hexa_color.dart';
import 'package:nde_email/presantation/drive/data/starred_reppo.dart';
import 'package:nde_email/presantation/drive/model/starred/starred_model.dart';
import 'package:nde_email/presantation/drive/view/file_inside_sceen.dart'
    show FileInsideSceen;

import 'package:nde_email/utils/datetime/dateFormatter.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';

class DriveStarredPage extends StatefulWidget {
  final ScrollController? scrollController;
  final void Function(String folderId) onFolderTap;
  final bool isSelectionMode;
  final String movingFileId;

  const DriveStarredPage({
    super.key,
    this.scrollController,
    required this.onFolderTap,
    this.isSelectionMode = false,
    required this.movingFileId,
  });

  @override
  State<DriveStarredPage> createState() => _DriveStarredPageState();
}

class _DriveStarredPageState extends State<DriveStarredPage> {
  bool gridView = false;
  String? selectedFolderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StarredBloc(repository: DriveRepository())
        ..add(FetchStarredFolders()),
      child: BlocBuilder<StarredBloc, StarredState>(
        builder: (context, state) {
          if (state is StarredLoading) {
            return ShimmerListLoader(
              iconSize: 40,
              titleHeight: 18,
              subtitleHeight: 14,
              trailingIconSize: 20,
              padding: EdgeInsets.all(10),
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              titleWidthFactor: 0.8,
              subtitleWidth: 100,
            );
          } else if (state is StarredLoaded) {
            if (state.folders.isEmpty) {
              return const Center(child: Text("No starred folders found"));
            }

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Starred',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
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
                      ? _buildGridView(state.folders)
                      : _buildListView(state.folders),
                ),
              ],
            );
          } else if (state is StarredError) {
            return Center(child: Text("Error: ${state.message}"));
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildGridView(List<StarredFolder> folders) {
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final isFolder = folder.type?.toLowerCase() == 'folder';
        final isSelected = folder.id == selectedFolderId;

        return GestureDetector(
          onTap: isFolder
              ? () {
                  setState(() {
                    selectedFolderId = folder.id;
                  });
                  widget.isSelectionMode
                      ? widget.onFolderTap(folder.id)
                      : _navigateToFolder(folder);
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: !isFolder
                  ? Colors.grey[200]
                  : (isSelected ? Colors.blue[50] : Colors.white),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMimeIcon(folder),
                const SizedBox(height: 8),
                Text(
                  folder.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isFolder ? Colors.black : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (folder.updatedAt.isNotEmpty)
                  Text(
                    "Modified ${DateFormatter.formatToReadableDate(folder.updatedAt)}",
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<StarredFolder> folders) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final isFolder = folder.type?.toLowerCase() == 'folder';
        final isSelected = folder.id == selectedFolderId;

        return ListTile(
          onTap: isFolder
              ? () {
                  setState(() {
                    selectedFolderId = folder.id;
                  });
                  widget.isSelectionMode
                      ? widget.onFolderTap(folder.id)
                      : _navigateToFolder(folder);
                }
              : null,
          tileColor: isSelected ? Colors.blue[50] : null,
          shape: isSelected
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.blue),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: _buildMimeIcon(folder),
          ),
          title: Text(
            folder.name,
            style: TextStyle(
              color: isFolder ? Colors.black : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: folder.updatedAt.isNotEmpty
              ? Row(
                  children: [
                    if (folder.starred)
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      " Modified ${DateFormatter.formatToReadableDate(folder.updatedAt)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : folder.labels.isNotEmpty
                  ? Wrap(
                      spacing: 2,
                      children: folder.labels.map((label) {
                        return Chip(
                          label: Text(label.name),
                          backgroundColor: _parseColor(label.color),
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    )
                  : null,
        );
      },
    );
  }

  void _navigateToFolder(StarredFolder folder) {
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

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Widget _buildMimeIcon(StarredFolder folder) {
    final ext = folder.extname?.toLowerCase().trim() ?? "";
    final type = folder.type?.toLowerCase();

    if (type == 'folder') {
      return Image.asset(
        "assets/images/folder.png",
        height: 24,
        width: 24,
        color: (folder.organize.isNotEmpty)
            ? ColorUtils.fromHex(folder.organize)
            : Colors.amber,
      );
    }

    if (ext.contains('doc') || ext.contains('msword')) {
      return Image.asset('assets/images/word.png', height: 24, width: 24);
    } else if (ext.contains('excel') ||
        ext.contains('spreadsheet') ||
        ext.contains('.txt')) {
      return Image.asset('assets/images/sheets.png', height: 24, width: 24);
    } else if (ext.contains('ppt') || ext.contains('presentation')) {
      return Image.asset('assets/images/sheets.png', height: 24, width: 24);
    } else if (ext.contains('pdf')) {
      return Image.asset('assets/images/pdf.png', height: 24, width: 24);
    } else if (ext.contains('image') ||
        ext.contains('png') ||
        ext.contains('jpg')) {
      return Image.asset('assets/images/image.png', height: 24, width: 24);
    } else if (ext.contains('video')) {
      return Image.asset('assets/images/video.png', height: 24, width: 24);
    } else if (ext.contains('audio') || ext.contains('.mp4')) {
      return Image.asset('assets/images/headphones.png', height: 24, width: 24);
    } else if (ext.contains('zip') ||
        ext.contains('rar') ||
        ext.contains('compressed')) {
      return Image.asset('assets/images/pdf.png', height: 24, width: 24);
    }

    return Image.asset('assets/images/folder.png', height: 24, width: 24);
  }
}
