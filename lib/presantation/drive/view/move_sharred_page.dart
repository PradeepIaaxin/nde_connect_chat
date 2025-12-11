import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_event.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_state.dart';
import 'package:nde_email/presantation/drive/data/sharred_repository.dart';
import 'package:nde_email/presantation/drive/view/file_inside_sceen.dart';

import 'package:nde_email/utils/datetime/dateFormatter.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';

class MoveSharedPage extends StatefulWidget {
  final ScrollController? scrollController;
  final void Function(String folderId) onFolderTap;
  final String currentSort;
  final String movingFileId;

  const MoveSharedPage({
    super.key,
    this.scrollController,
    required this.onFolderTap,
    required this.movingFileId,
    this.currentSort = "Modified",
    required bool isSelectionMode,
  });

  @override
  State<MoveSharedPage> createState() => _MoveSharedPageState();
}

class _MoveSharedPageState extends State<MoveSharedPage> {
  bool gridView = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FolderBloc(SharedRepository())..add(FetchFolderData()),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          if (state is FolderLoading) {
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
          } else if (state is FolderLoaded) {
            final folders = state.folderResponse.rows;
            if (folders.isEmpty) {
              return const Center(child: Text("No shared folders"));
            }

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        'Shared',
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isFolder
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
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
                              color: isFolder ? Colors.white : Colors.grey[300],
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                leading: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: folder.profilePic.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey[200],
                                          backgroundImage:
                                              NetworkImage(folder.profilePic),
                                        )
                                      : CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey[200],
                                          child: const Icon(Icons.person,
                                              color: Colors.grey),
                                        ),
                                ),
                                title: Text(
                                  folder.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isFolder ? Colors.black : Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  children: [
                                    if (folder.starred)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(Icons.star,
                                            size: 16, color: Colors.amber),
                                      ),
                                    Text(
                                      widget.currentSort == "Date Opened by Me"
                                          ? 'Opened by Me ${DateFormatter.formatToReadableDate(folder.updatedAt!)}'
                                          : 'Modified ${DateFormatter.formatToReadableDate(folder.updatedAt!)}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
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
          } else if (state is FolderError) {
            return Center(child: Text("Error: ${state.message}"));
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
    return const Icon(Icons.folder);
  }
}
