import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/recent_bloc/recent.event.dart';
import 'package:nde_email/presantation/drive/Bloc/recent_bloc/recent_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/recent_bloc/recent_state.dart';

import 'package:nde_email/presantation/drive/common/file_preview_widget.dart';
import 'package:nde_email/presantation/drive/common/hexa_color.dart'
    show ColorUtils;
import 'package:nde_email/presantation/drive/common/show_bottom_model_sheet.dart';
import 'package:nde_email/presantation/drive/model/recent/recent_model.dart';
import 'package:nde_email/presantation/drive/view/file_deatilsScreen.dart';
import 'package:nde_email/presantation/drive/view/file_deep_view.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/dateFormatter.dart';
import 'package:nde_email/utils/reusbale/dowloading_mime.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:share_plus/share_plus.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  bool gridview = false;

  final scrollController = ScrollController();

  bool selectAll = false;
  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    _loadStarredFolders();
  }

  void _onScroll() {
    if (!mounted) return;

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      context.read<RecentBloc>().add(
            FetchStarredFolders(
                sortBy: sortQuery ?? 'updateAt', isLoadMore: true),
          );
    }
  }

  String? sortQuery;

  void _loadStarredFolders({String? sortBy}) {
    context.read<RecentBloc>().add(FetchStarredFolders(sortBy: sortBy));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          surfaceTintColor: Colors.white,
        title: Text('Recent'),
        backgroundColor: Colors.transparent,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.search))],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<RecentBloc, RecentState>(
              listener: (context, state) {
                if (state is StarredError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
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
                  return _buildDriveLayout(folders, state.hasMore);
                }

                if (state is StarredError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Something Went Wrong !'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStarredFolders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveLayout(List<RecentModel> folders, bool ismore) {
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
                            // Select all
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
                              context.read<RecentBloc>().add(
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
                              context.read<RecentBloc>().add(
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
            : _buildViewToggle(),
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

  Widget _buildFolderList(List<RecentModel> folders, bool ismore) {
    return ListView.builder(
      controller: scrollController,
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

  Widget _buildFolderGrid(List<RecentModel> folders, bool ismore) {
    return GridView.builder(
      controller: scrollController,
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
  final RecentModel folder;
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
          } else {
            MyRouter.push(screen: FilePreviewScreen(fileUrl: folder.preview??""));
          }
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
                  _buildMimeIcon(folder),
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
                                  icon: folder.starred == true
                                      ? Icons.star
                                      : Icons.star_border,
                                  title: folder.starred == true
                                      ? "Remove to Starred"
                                      : "Add to Starred",
                                  onTap: () {
                                    log('hii');

                                    context.read<RecentBloc>().add(
                                          StarredData(fileID: [folder.id]),
                                        );
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.person_add,
                                  title: "Share",
                                  onTap: () => log("Share tapped"),
                                ),
                                BottomSheetOption(
                                  icon: Icons.manage_accounts,
                                  title: "Manage access",
                                  onTap: () => log("Manage access tapped"),
                                ),
                                BottomSheetOption(
                                  icon: Icons.link,
                                  title: "Copy link",
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: folder.preview.toString(),
                                      ),
                                    );

                                    Messenger.alertSuccess("Copied");
                                  },
                                ),
                                BottomSheetOption(
                                  icon: Icons.turn_right_outlined,
                                  title: "Send a copy",
                                  onTap: () async {
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );

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
                                  icon: Icons.file_copy,
                                  title: "Make a copy ",
                                  onTap: () {},
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
                                  icon: Icons.drive_file_move,
                                  title: "Move",
                                  onTap: () => log("Move"),
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
                                  icon: Icons.print,
                                  title: "Print",
                                  onTap: () {},
                                ),
                                BottomSheetOption(
                                  icon: Icons.delete,
                                  title: "Remove",
                                  onTap: () {
                                    context.read<RecentBloc>().add(
                                          MoveToTrashEvent(
                                              fileIDs: [folder.id]),
                                        );
                                  },
                                ),
                              ],
                              foldertype: folder.type,
                              mimetype: folder.mimetype,
                              title: folder.name,
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
              child: folder.thumbnail != null
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            folder.thumbnail!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        folder.starred
                            ? Positioned(
                                top: 50,
                                left: 150,
                                child: Icon(Icons.star, color: Colors.amber),
                              )
                            : voidBox,
                      ],
                    )
                  : Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.folder,
                              size: 40,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        folder.starred
                            ? Positioned(
                                top: 50,
                                left: 150,
                                child: Icon(Icons.star, color: Colors.amber),
                              )
                            : voidBox,
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderListItem extends StatelessWidget {
  final RecentModel folder;
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
            MyRouter.push(screen: FilePreviewScreen(fileUrl: folder.preview??""));
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
                child: _buildMimeIcon(folder),
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
                              backgroundColor: _parseColor(label.color),
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
                    icon:
                        folder.starred == true ? Icons.star : Icons.star_border,
                    title: folder.starred == true
                        ? "Remove to Starred"
                        : "Add to Starred",
                    onTap: () {
                      log('hii');

                      context.read<RecentBloc>().add(
                            StarredData(fileID: [folder.id]),
                          );
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.person_add,
                    title: "Share",
                    onTap: () => log("Share tapped"),
                  ),
                  BottomSheetOption(
                    icon: Icons.manage_accounts,
                    title: "Manage access",
                    onTap: () => log("Manage access tapped"),
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
                    icon: Icons.file_copy,
                    title: "Make a copy ",
                    onTap: () {},
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
                    icon: Icons.drive_file_move,
                    title: "Move",
                    onTap: () => log("Move"),
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
                    icon: Icons.print,
                    title: "Print",
                    onTap: () {},
                  ),
                  BottomSheetOption(
                    icon: Icons.delete,
                    title: "Remove",
                    onTap: () {
                      context.read<RecentBloc>().add(
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

Color _parseColor(String hexColor) {
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

Widget _buildMimeIcon(RecentModel folder) {
  final type = folder.type?.toLowerCase();
  final ext = folder.extname?.toLowerCase().trim() ?? "";
  final mimetype = folder.mimetype?.toLowerCase().trim() ?? "";
  log(mimetype);

  if (type == 'folder') {
    return Image.asset(
      "assets/images/folder.png",
      height: 24,
      width: 24,
      color: ColorUtils.fromHex(folder.organize),
    );
  }

  // Word
  if (mimetype.contains('msword') ||
      mimetype.contains('officedocument.word') ||
      mimetype.contains('ndocx') ||
      ext.endsWith('.doc') ||
      ext.endsWith('.docx') ||
      ext.contains('ndocx')) {
    return Image.asset('assets/images/word.png', height: 30, width: 30);
  }

  // Excel
  if (mimetype.contains('excel') ||
      mimetype.contains('spreadsheet') ||
      ext.endsWith('.xls') ||
      ext.endsWith('.xlsx')) {
    return Image.asset('assets/images/sheets.png', height: 24, width: 24);
  }

  // PowerPoint
  if (mimetype.contains('presentation') ||
      mimetype.contains('powerpoint') ||
      ext.endsWith('.ppt') ||
      ext.endsWith('.pptx')) {
    return Image.asset('assets/images/sheets.png', height: 24, width: 24);
  }

  // PDF
  if (mimetype.contains('pdf') || ext.endsWith('.pdf')) {
    return Image.asset('assets/images/pdf.png', height: 24, width: 24);
  }

  // Images
  if (mimetype.startsWith('image') ||
      ext.endsWith('.png') ||
      ext.endsWith('.jpg') ||
      ext.endsWith('.jpeg') ||
      ext.endsWith('.gif') ||
      ext.endsWith('.bmp')) {
    return Image.asset('assets/images/image.png', height: 24, width: 24);
  }

  // Video
  if (mimetype.startsWith('video') ||
      ext.endsWith('.mov') ||
      ext.endsWith('.avi') ||
      ext.endsWith('.mkv')) {
    return Image.asset('assets/images/video.png', height: 24, width: 24);
  }

  // Audio
  if (mimetype.startsWith('audio') ||
      ext.endsWith('.mp3') ||
      ext.endsWith('.mp4') ||
      ext.endsWith('.wav') ||
      ext.endsWith('.aac')) {
    return Image.asset('assets/images/headphones.png', height: 24, width: 24);
  }

  // Text
  if (mimetype.startsWith('text') ||
      ext.endsWith('.txt') ||
      ext.endsWith('.csv')) {
    return Image.asset('assets/images/text.png', height: 24, width: 24);
  }

  // Zip/Compressed
  if (mimetype.contains('compressed') ||
      mimetype.contains('zip') ||
      ext.endsWith('.zip') ||
      ext.endsWith('.rar') ||
      ext.endsWith('.7z')) {
    return Image.asset('assets/images/pdf.png', height: 30, width: 30);
  }

  // Default icon
  return Image.asset('assets/images/image.png', height: 24, width: 24);
}
