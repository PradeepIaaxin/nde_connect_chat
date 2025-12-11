import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/starred_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/starred_event.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/starred_state.dart';
import 'package:nde_email/presantation/drive/common/colour_picker.dart';
import 'package:nde_email/presantation/drive/common/file_preview_widget.dart';
import 'package:nde_email/presantation/drive/common/hexa_color.dart';
import 'package:nde_email/presantation/drive/common/pop.dart';
import 'package:nde_email/presantation/drive/common/show_bottom_model_sheet.dart';
import 'package:nde_email/presantation/drive/common/show_rename.dart';
import 'package:nde_email/presantation/drive/model/starred/starred_model.dart';
import 'package:nde_email/presantation/drive/view/file_deatilsScreen.dart';
import 'package:nde_email/presantation/drive/view/file_deep_view.dart';
import 'package:nde_email/presantation/drive/view/manage_acces_screen.dart';
import 'package:nde_email/presantation/drive/view/move_screen.dart';
import 'package:nde_email/presantation/drive/view/send_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/dateFormatter.dart';
import 'package:nde_email/utils/reusbale/dowloading_mime.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:share_plus/share_plus.dart';

class StarredPage extends StatefulWidget {
  final ScrollController scrollController;

  const StarredPage({super.key, required this.scrollController});

  @override
  State<StarredPage> createState() => _StarredPageState();
}

class _StarredPageState extends State<StarredPage> {
  bool gridview = false;
  String _currentSort = 'Name';

  final List<String> _sortOptions = [
    'Name',
    'Date Modified',
    'Date Modified by Me',
    'Date Opened by Me',
    'New to old',
    'Old to new',
  ];

  bool selectAll = false;
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _loadStarredFolders();
  }

  void _onScroll() {
    if (!mounted) return;

    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      context.read<StarredBloc>().add(
            FetchStarredFolders(sortBy: sortQuery ?? 'name', isLoadMore: true),
          );
    }
  }

  String? sortQuery;

  void _handleSortChange(String selectedOption) {
    setState(() {
      _currentSort = selectedOption;
    });

    switch (selectedOption) {
      case 'Name':
        sortQuery = 'name';
        break;
      case 'Date Modified':
        sortQuery = 'updatedAt';
        break;
      case 'Date Modified by Me':
        sortQuery = 'modifiedByMe';
        break;
      case 'Date Opened by Me':
        sortQuery = 'openedByMe';
        break;
      case 'New to old':
        sortQuery = 'asc';
        break;
      case 'Old to new':
        sortQuery = 'dsc';
        break;
      default:
        sortQuery = 'name';
    }

    _loadStarredFolders(sortBy: sortQuery);
  }

  void _loadStarredFolders({String? sortBy}) {
    context.read<StarredBloc>().add(FetchStarredFolders(sortBy: sortBy));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocConsumer<StarredBloc, StarredState>(
        listener: (context, state) {
          if (state is StarredError) {
            log(state.message.toString());
          }
        },
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
          }

          if (state is StarredLoaded) {
            final folders = state.folders;

            if (folders.isEmpty) {
              return const Center(
                child: Text('No starred files found'),
              );
            }

            return Stack(
              children: [
                _buildDriveLayout(folders, state.hasMore),
              ],
            );
          }

          if (state is StarredError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Something went wrong!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<StarredBloc>().add(
                            FetchStarredFolders(
                              sortBy: sortQuery ?? 'name',
                              isLoadMore: false,
                            ),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDriveLayout(List<StarredFolder> folders, bool ismore) {
    return Column(
      children: [
        isSelectionMode
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _clearSelection();
                      },
                      icon: Icon(Icons.clear),
                    ),
                    Text(
                      "${selectedFolders.length} selected",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    _buildViewToggle(),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          if (selectAll) {
                            selectedFolders.clear();
                          } else {
                            selectedFolders.addAll(folders.map((f) => f.id));
                          }
                          selectAll = !selectAll;
                        });
                      },
                      icon: Icon(
                        selectAll
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final selectedFolderModels = folders
                            .where((f) => selectedFolders.contains(f.id))
                            .toList();

                        if (selectedFolderModels.isEmpty) return;

                        showReusableBottomSheet(context, [
                          BottomSheetOption(
                            icon: selectedFolderModels.every((f) => f.starred)
                                ? Icons.star
                                : Icons.star_border,
                            title: selectedFolderModels.every((f) => f.starred)
                                ? "Remove from Starred"
                                : "Add to Starred",
                            onTap: () {
                              context.read<StarredBloc>().add(
                                    StarredData(
                                        fileID: selectedFolders.toList()),
                                  );
                              _clearSelection();
                            },
                          ),
                          BottomSheetOption(
                            icon: Icons.file_download_outlined,
                            title: "Download",
                            onTap: () async {
                              for (var folder in selectedFolderModels) {
                                await FileDownloader.downloadFile(
                                  fileId: folder.id,
                                  filePath: folder.preview ?? '',
                                  fileName: folder.name,
                                  mimeType: folder.mimetype ?? folder.type,
                                );
                              }
                              _clearSelection();
                            },
                          ),
                          BottomSheetOption(
                            icon: Icons.delete,
                            title: "Delete",
                            onTap: () {
                              context.read<StarredBloc>().add(
                                    MoveToTrashEvent(
                                      fileIDs: selectedFolders.toList(),
                                    ),
                                  );
                              _clearSelection();
                            },
                          ),
                        ]);
                      },
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  hSpace18,
                  vSpace4,
                  Text(_currentSort),
                  SortPopupMenu(
                    sortOptions: _sortOptions,
                    selectedOption: _currentSort,
                    onSelected: _handleSortChange,
                  ),
                  const Spacer(),
                  _buildViewToggle(),
                ],
              ),
        Expanded(
          child: folders.isEmpty
              ? const Center(child: Text('No folders found'))
              : gridview
                  ? _buildFolderGrid(folders, ismore)
                  : _buildFolderList(folders, ismore),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          gridview
              ? IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    setState(() {
                      gridview = false;
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      gridview = true;
                    });
                  },
                ),
        ],
      ),
    );
  }

  Set<String> selectedFolders = {};
  bool isSelectionMode = false;

  void _handleLongPressStart(String folderId) {
    setState(() {
      isSelectionMode = true;
      selectedFolders.add(folderId);
      log("Selected IDs: $selectedFolders");
      log("Total selected: ${selectedFolders.length}");
    });
  }

  void _handleTapSelect(String folderId) {
    setState(() {
      if (selectedFolders.contains(folderId)) {
        selectedFolders.remove(folderId);
        log("Selected IDs: $selectedFolders");
        log("Total selected: ${selectedFolders.length}");
        if (selectedFolders.isEmpty) isSelectionMode = false;
      } else {
        selectedFolders.add(folderId);
        log("Selected IDs: $selectedFolders");
        log("Total selected: ${selectedFolders.length}");
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedFolders.clear();
      isSelectionMode = false;
    });
  }

  Widget _buildFolderList(List<StarredFolder> folders, bool ismore) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return _FolderListItem(
          folder: folder,
          isGridView: gridview,
          onLongPressStart: _handleLongPressStart,
          onTapSelect: _handleTapSelect,
          isSelectionMode: isSelectionMode,
          isSelected: selectedFolders.contains(folder.id),
        );
      },
    );
  }

  Widget _buildFolderGrid(List<StarredFolder> folders, bool ismore) {
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];

        return _FolderGridItem(
          folder: folder,
          isGridView: gridview,
          onLongPressStart: _handleLongPressStart,
          onTapSelect: _handleTapSelect,
          isSelectionMode: isSelectionMode,
          isSelected: selectedFolders.contains(folder.id),
        );
      },
    );
  }
}

class _FolderGridItem extends StatelessWidget {
  final StarredFolder folder;
  final bool isGridView;
  final Function(String) onLongPressStart;
  final Function(String) onTapSelect;
  final bool isSelected;
  final bool isSelectionMode;

  const _FolderGridItem({
    required this.folder,
    required this.isGridView,
    required this.onLongPressStart,
    required this.onTapSelect,
    required this.isSelected,
    required this.isSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        log("hii");
        onLongPressStart(folder.id);
      },
      onTap: () {
        if (isSelectionMode) {
          onTapSelect(folder.id);
        } else {
          if (folder.type == "folder") {
            MyRouter.push(
              screen: FileDeepView(
                fileId: folder.id,
                folderName: folder.name,
                gridview: isGridView,
              ),
            );
          } else {}
        }
      },
      child: Card(
        color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _buildMimeIcon(
                    folder,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      folder.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  isSelected == false
                      ? IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            showReusableBottomSheet(
                              context,
                              [
                                BottomSheetOption(
                                  icon: Icons.person_add,
                                  title: "Share",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ShareScreen(folder.id)),
                                    );
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.manage_accounts,
                                  title: "Manage access",
                                  onTap: () {
                                    MyRouter.push(
                                        screen: ManageAccessScreenUI(
                                            fileId: folder.id));
                                  },
                                ),
                                BottomSheetOption(
                                  icon: folder.starred == true
                                      ? Icons.star
                                      : Icons.star_border,
                                  title: folder.starred == true
                                      ? "Remove to Starred"
                                      : "Add to Starred",
                                  onTap: () {
                                    log('hii');

                                    context.read<StarredBloc>().add(
                                          StarredData(fileID: [folder.id]),
                                        );
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.link,
                                  title: "Copy link",
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                          text: folder.preview.toString()),
                                    );
                                    Messenger.alertSuccess("Copied");
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.drive_file_rename_outline,
                                  title: "Rename",
                                  onTap: () async {
                                    await showRenameDialog(
                                      context: context,
                                      initialName: folder.name,
                                      onRename: (newName) {
                                        context.read<StarredBloc>().add(
                                              RenameEvent(
                                                  fileIDs: [folder.id],
                                                  editedName: newName.trim()),
                                            );
                                      },
                                    );
                                  },
                                ),
                                folder.type == "folder"
                                    ? BottomSheetOption(
                                        icon: Icons.color_lens,
                                        title: "Change Color",
                                        onTap: () {
                                          MyRouter.pop();

                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return ColorPickerDialog(
                                                onColorSelected: (hex) {
                                                  log("Selected Color: $hex");

                                                  context
                                                      .read<StarredBloc>()
                                                      .add(
                                                        OrganizeEvent(fileIDs: [
                                                          folder.id,
                                                        ], pickedColor: hex),
                                                      );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      )
                                    : BottomSheetOption(
                                        icon: Icons.file_copy,
                                        title: "Make a copy ",
                                        onTap: () {},
                                      ),
                                BottomSheetOption(
                                  icon: Icons.drive_file_move,
                                  title: "Move",
                                  onTap: () {
                                    MyRouter.pop();
                                    MyRouter.push(
                                        screen: MoveFileScreen(
                                            movingFileId: folder.id));
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.turn_right_outlined,
                                  title: "Send a copy",
                                  onTap: () async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 300));

                                    final name = folder.name.trim();
                                    final preview =
                                        folder.preview?.toString().trim() ?? '';

                                    final textToShare =
                                        (name.isNotEmpty || preview.isNotEmpty)
                                            ? "$name\n\n$preview"
                                            : '';

                                    if (textToShare.isNotEmpty) {
                                      Share.share(textToShare);
                                    } else {
                                      log("Nothing to share.");
                                    }
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.info_outline,
                                  title: "Details & activity",
                                  onTap: () {
                                    log("deatils");
                                    MyRouter.push(
                                      screen:
                                          FileDetailScreen(fileID: folder.id),
                                    );
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.file_download_outlined,
                                  title: "Download",
                                  onTap: () async {
                                    await FileDownloader.downloadFile(
                                      fileId: folder.id,
                                      filePath: folder.preview ?? '',
                                      fileName: folder.name,
                                      mimeType: folder.mimetype ?? folder.type,
                                    );
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.delete,
                                  title: "Remove",
                                  onTap: () {
                                    context.read<StarredBloc>().add(
                                          MoveToTrashEvent(
                                              fileIDs: [folder.id]),
                                        );
                                  },
                                ),
                              ],
                              title: folder.name,
                              foldertype: folder.type,
                              mimetype: folder.mimetype,
                            );
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        )
                      : Icon(Icons.check_circle, color: chatColor),
                ],
              ),
            ),
            Expanded(
              child: folder.mimetype != 'application/vnd.google-apps.folder'
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: folder.thumbnail != null &&
                                  folder.thumbnail!.isNotEmpty
                              ? Image.network(
                                  folder.thumbnail!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: getMimeTypeImage(
                                          folder.mimetype ?? ""),
                                    );
                                  },
                                )
                              : Center(
                                  child:
                                      getMimeTypeImage(folder.mimetype ?? "")),
                        ),
                        folder.starred
                            ? const Positioned(
                                bottom: 10,
                                right: 8,
                                child: Icon(Icons.star, color: Colors.amber),
                              )
                            : const SizedBox.shrink(),
                      ],
                    )
                  : Center(child: getMimeTypeImage(folder.mimetype ?? "")),
            )
          ],
        ),
      ),
    );
  }
}

class _FolderListItem extends StatelessWidget {
  final StarredFolder folder;
  final bool isGridView;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(String) onLongPressStart;
  final Function(String) onTapSelect;

  const _FolderListItem({
    required this.folder,
    required this.isGridView,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onLongPressStart,
    required this.onTapSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onLongPressStart(folder.id),
      onTap: () {
        if (isSelectionMode) {
          onTapSelect(folder.id);
          log(folder.id);
        } else {
          if (folder.type == "folder") {
            MyRouter.push(
              screen: FileDeepView(
                fileId: folder.id,
                folderName: folder.name,
                gridview: isGridView,
              ),
            );
          } else {
            MyRouter.push(
                screen: FilePreviewScreen(fileUrl: folder.preview ?? ""));
          }
        }
      },
      child: Container(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.transparent,
                child: _buildMimeIcon(
                  folder,
                ),
              ),
              if (isSelected)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.check_circle, color: Colors.blue, size: 18),
                ),
            ],
          ),
          title: Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: folder.updatedAt.isNotEmpty
              ? Row(
                  children: [
                    if (folder.starred)
                      Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      " Modified ${DateFormatter.formatToReadableDate(folder.updatedAt.toString())}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : folder.labels.isNotEmpty
                  ? Wrap(
                      spacing: 2,
                      children: folder.labels
                          .map(
                            (label) => Chip(
                              label: Text(label.name),
                              backgroundColor: _parseColor(label.color, folder),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : null,
          trailing: IconButton(
            onPressed: () {
              showReusableBottomSheet(
                context,
                [
                  BottomSheetOption(
                    icon: Icons.person_add,
                    title: "Share",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ShareScreen(folder.id)),
                      );
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.manage_accounts,
                    title: "Manage access",
                    onTap: () {
                      MyRouter.push(
                          screen: ManageAccessScreenUI(fileId: folder.id));
                    },
                  ),
                  BottomSheetOption(
                    icon:
                        folder.starred == true ? Icons.star : Icons.star_border,
                    title: folder.starred == true
                        ? "Remove to Starred"
                        : "Add to Starred",
                    onTap: () {
                      log('hii');

                      log(folder.starred.toString());
                      context.read<StarredBloc>().add(
                            StarredData(fileID: [folder.id]),
                          );
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.link,
                    title: "Copy link",
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: folder.preview.toString()),
                      );
                      Messenger.alertSuccess("Copied");
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.drive_file_rename_outline,
                    title: "Rename",
                    onTap: () async {
                      await showRenameDialog(
                        context: context,
                        initialName: folder.name,
                        onRename: (newName) {
                          context.read<StarredBloc>().add(
                                RenameEvent(
                                    fileIDs: [folder.id],
                                    editedName: newName.trim()),
                              );
                        },
                      );
                    },
                  ),
                  folder.type == "folder"
                      ? BottomSheetOption(
                          icon: Icons.color_lens,
                          title: "Change Color",
                          onTap: () {
                            MyRouter.pop();

                            showDialog(
                              context: context,
                              builder: (context) {
                                return ColorPickerDialog(
                                  onColorSelected: (hex) {
                                    log("Selected Color: $hex");

                                    context.read<StarredBloc>().add(
                                          OrganizeEvent(fileIDs: [
                                            folder.id,
                                          ], pickedColor: hex),
                                        );
                                  },
                                );
                              },
                            );
                          },
                        )
                      : BottomSheetOption(
                          icon: Icons.file_copy,
                          title: "Make a copy ",
                          onTap: () {},
                        ),
                  BottomSheetOption(
                    icon: Icons.drive_file_move,
                    title: "Move",
                    onTap: () {
                      MyRouter.pop();
                      MyRouter.push(
                          screen: MoveFileScreen(movingFileId: folder.id));
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.turn_right_outlined,
                    title: "Send a copy",
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 300));

                      final name = folder.name.trim();
                      final preview = folder.preview?.toString().trim() ?? '';

                      final textToShare =
                          (name.isNotEmpty || preview.isNotEmpty)
                              ? "$name\n\n$preview"
                              : '';

                      if (textToShare.isNotEmpty) {
                        Share.share(textToShare);
                      } else {
                        log("Nothing to share.");
                      }
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.info_outline,
                    title: "Details & activity",
                    onTap: () {
                      log("deatils");
                      MyRouter.push(
                        screen: FileDetailScreen(fileID: folder.id),
                      );
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.file_download_outlined,
                    title: "Download",
                    onTap: () async {
                      await FileDownloader.downloadFile(
                        fileId: folder.id,
                        fileName: folder.name,
                        filePath: folder.preview ?? '',
                        mimeType: folder.mimetype ?? folder.type,
                      );
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.delete,
                    title: "Remove",
                    onTap: () {
                      context.read<StarredBloc>().add(
                            MoveToTrashEvent(fileIDs: [folder.id]),
                          );
                    },
                  ),
                ],
                title: folder.name,
                foldertype: folder.type,
                mimetype: folder.mimetype,
              );
            },
            icon: const Icon(Icons.more_vert),
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String hexColor, StarredFolder folder) {
  try {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return Colors.blue;
  }
}

Widget _buildMimeIcon(StarredFolder folder) {
  final type = folder.type.toLowerCase();
  final mimeType = folder.mimetype?.toLowerCase() ?? '';
  final fileName = folder.name?.toLowerCase() ?? '';

  // If it's a folder
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

  // Word Documents
  if (mimeType.contains('msword') ||
      mimeType.contains('officedocument.word') ||
      fileName.endsWith('.doc') ||
      fileName.endsWith('.docx')) {
    return Image.asset('assets/images/word.png', height: 30, width: 30);
  }

  // Excel Sheets
  if (mimeType.contains('excel') ||
      mimeType.contains('spreadsheet') ||
      fileName.endsWith('.xls') ||
      fileName.endsWith('.xlsx')) {
    return Image.asset('assets/images/sheets.png', height: 24, width: 24);
  }

  // PowerPoint Presentations
  if (mimeType.contains('presentation') ||
      mimeType.contains('powerpoint') ||
      fileName.endsWith('.ppt') ||
      fileName.endsWith('.pptx')) {
    return Image.asset('assets/images/text.png', height: 24, width: 24);
  }

  // PDF
  if (mimeType.contains('pdf') || fileName.endsWith('.pdf')) {
    return Image.asset('assets/images/pdf.png', height: 24, width: 24);
  }

  // Images
  if (mimeType.contains('image') ||
      fileName.endsWith('.png') ||
      fileName.endsWith('.jpg') ||
      fileName.endsWith('.jpeg')) {
    return Image.asset('assets/images/image.png', height: 24, width: 24);
  }

  // Video
  if (mimeType.contains('video') ||
      fileName.endsWith('.mp4') ||
      fileName.endsWith('.mov') ||
      fileName.endsWith('.avi')) {
    return Image.asset('assets/images/video.png', height: 24, width: 24);
  }

  // Audio
  if (mimeType.contains('audio') ||
      fileName.endsWith('.mp3') ||
      fileName.endsWith('.wav')) {
    return Image.asset('assets/images/headphones.png', height: 24, width: 24);
  }

  // Text
  if (mimeType.contains('text') ||
      mimeType.contains('plain') ||
      fileName.endsWith('.txt')) {
    return Image.asset('assets/images/text.png', height: 24, width: 24);
  }

  // Zip or compressed files
  if (fileName.endsWith('.zip') ||
      fileName.endsWith('.rar') ||
      mimeType.contains('compressed')) {
    return Image.asset('assets/images/zip.png', height: 30, width: 30);
  }

  // Default icon
  return Image.asset('assets/images/folder.png', height: 24, width: 24);
}

Widget getMimeTypeImage(String mimeType) {
  if (mimeType.contains('pdf')) {
    return Image.asset('assets/images/pdf.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else if (mimeType.contains('image')) {
    return Image.asset('assets/images/image.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else if (mimeType.contains('video')) {
    return Image.asset('assets/images/video.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else if (mimeType.contains('audio')) {
    return Image.asset('assets/images/headphones.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else if (mimeType.contains('msword') ||
      mimeType.contains('document') ||
      mimeType.contains('docx')) {
    return Image.asset('assets/images/word.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
    return Image.asset('assets/images/sheets.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else if (mimeType.contains('presentation') ||
      mimeType.contains('powerpoint') ||
      mimeType.contains('slides')) {
    return Image.asset('assets/images/slides.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else if (mimeType.contains('zip') ||
      mimeType.contains('.zip') ||
      mimeType.contains('rar') ||
      mimeType.contains('compressed')) {
    return Image.asset('assets/images/zip.png',
        height: 40, width: 40, fit: BoxFit.cover);
  } else {
    return Image.asset('assets/images/folder.png',
        height: 40, width: 40, fit: BoxFit.cover);
  }
}
