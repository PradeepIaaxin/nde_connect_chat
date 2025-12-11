import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/my_drive_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_event.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_state.dart';
import 'package:nde_email/presantation/drive/common/colour_picker.dart';
import 'package:nde_email/presantation/drive/common/file_preview_widget.dart';
import 'package:nde_email/presantation/drive/common/show_bottom_model_sheet.dart';
import 'package:nde_email/presantation/drive/common/show_rename.dart';
import 'package:nde_email/presantation/drive/model/mydrive_model.dart'
    as drive_model;
import 'package:nde_email/presantation/drive/model/mydrive_model.dart';
import 'package:nde_email/presantation/drive/view/file_deatilsScreen.dart';
import 'package:nde_email/presantation/drive/view/file_deep_view.dart';
import 'package:nde_email/presantation/drive/view/manage_acces_screen.dart';
import 'package:nde_email/presantation/drive/view/move_screen.dart';
import 'package:nde_email/presantation/drive/view/send_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/dowloading_mime.dart';
import 'package:nde_email/utils/reusbale/mime.type.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:share_plus/share_plus.dart';

enum SortOption {
  name('Name'),
  dateModified('Date Modified'),
  nameAsc(' A-Z'),
  nameDesc(' Z-A'),
  dateModifiedByMe('Date Modified by Me'),
  dateOpenedByMe('Date Opened by Me');

  final String label;
  const SortOption(this.label);
}

class DrivePage extends StatefulWidget {
  final ScrollController scrollController;

  const DrivePage({super.key, required this.scrollController});

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;
  final SortOption _selectedSortOption = SortOption.name;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.scrollController.addListener(_onScroll);
    _fetchFolders();
  }

  void _fetchFolders() {
    final sort = _getSortParams(_selectedSortOption);
    context.read<MyDriveBloc>().resetPagination();
    context.read<MyDriveBloc>().add(
          FetchMyDriveFolders(
            sortBy: sort['sortBy']!,
            order: sort['order']!,
            showLoading: false,
          ),
        );
  }

  void _onScroll() {
    if (!mounted) return;

    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      final sort = _getSortParams(_selectedSortOption);
      context.read<MyDriveBloc>().add(FetchMyDriveFolders(
            sortBy: sort['sortBy']!,
            order: sort['order']!,
          ));
    }
  }

  Set<String> selectedFolders = {};

  List<Rows> _currentFolders = [];

  bool isSelectionMode = false;
  bool isSelected = false;

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

  bool selectAll = false;

  Map<String, String> _getSortParams(SortOption sortType) {
    switch (sortType) {
      case SortOption.name:
        return {'sortBy': 'name', 'order': 'asc'};
      case SortOption.nameAsc:
        return {'sortBy': 'name', 'order': 'asc'};
      case SortOption.nameDesc:
        return {'sortBy': 'name', 'order': 'desc'};
      case SortOption.dateModified:
        return {'sortBy': 'updatedAt', 'order': 'desc'};
      case SortOption.dateModifiedByMe:
        return {'sortBy': 'modifiedByMe', 'order': 'desc'};
      case SortOption.dateOpenedByMe:
        return {'sortBy': 'openedByMe', 'order': 'desc'};
      default:
        return {'sortBy': 'updatedAt', 'order': 'desc'};
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSliverFilesList(
      List<drive_model.Rows> suggestions, bool isgridview) {
    if (suggestions.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text("No drive found.")),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final file = suggestions[index];

          final isSelected = selectedFolders.contains(file.id);
          return GestureDetector(
            onLongPress: () {
              log("hii");
              _handleLongPressStart(file.id);
            },
            onTap: isSelectionMode
                ? () {
                    _handleTapSelect(file.id);
                  }
                : file.type == "folder"
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FileDeepView(
                              fileId: file.id,
                              folderName: file.name,
                              gridview: false,
                            ),
                          ),
                        );
                      }
                    : () {
                        MyRouter.push(
                            screen:
                                FilePreviewScreen(fileUrl: file.preview ?? ""));
                      },
            child: Container(
              color: isSelected ? chatColor.withOpacity(0.1) : null,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                leading: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomRight,
                    children: [
                      buildIcon(
                          type: file.type,
                          mimeType: file.mimetype,
                          colortype: file.organize),
                      if (isSelected)
                        const Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(Icons.check_circle,
                              color: Colors.blue, size: 18),
                        ),
                    ]),
                title: Text(
                  file.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    if (file.starred == true)
                      const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(Icons.star, size: 16, color: Colors.amber),
                      ),
                    Text(
                        'Opened: ${DateFormatted.formatToReadableDate(file.updatedAt)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () async {
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
                                  builder: (context) => ShareScreen(file.id)),
                            );
                          },
                        ),
                        BottomSheetOption(
                          icon: Icons.manage_accounts,
                          title: "Manage access",
                          onTap: () {
                            MyRouter.push(
                                screen: ManageAccessScreenUI(fileId: file.id));
                          },
                        ),
                        BottomSheetOption(
                          icon: file.starred == true
                              ? Icons.star
                              : Icons.star_border,
                          title: file.starred == true
                              ? "Remove to Starred"
                              : "Add to Starred",
                          onTap: () {
                            log('hii');

                            log(file.starred.toString());
                            context.read<MyDriveBloc>().add(
                                  StarredData(fileID: [file.id]),
                                );
                          },
                        ),
                        BottomSheetOption(
                          icon: Icons.link,
                          title: "Copy link",
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: file.preview.toString()),
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
                              initialName: file.name,
                              onRename: (newName) {
                                context.read<MyDriveBloc>().add(
                                      RenameEvent(
                                          fileIDs: [file.id],
                                          editedName: newName.trim()),
                                    );
                              },
                            );
                          },
                        ),
                        file.type == "folder"
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

                                          context.read<MyDriveBloc>().add(
                                                OrganizeEvent(fileIDs: [
                                                  file.id,
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
                                screen: MoveFileScreen(movingFileId: file.id));
                          },
                        ),
                        BottomSheetOption(
                          icon: Icons.turn_right_outlined,
                          title: "Send a copy",
                          onTap: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 300));

                            final name = file.name.trim();
                            final preview =
                                file.preview?.toString().trim() ?? '';

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
                              screen: FileDetailScreen(fileID: file.id),
                            );
                          },
                        ),
                        BottomSheetOption(
                          icon: Icons.file_download_outlined,
                          title: "Download",
                          onTap: () async {
                            log("Downloading: ${file.name}");
                            log("File ID: ${file.id}");
                            log("File Path: ${file.preview ?? ''}");
                            log("MIME Type: ${file.mimetype ?? file.type}");

                            await FileDownloader.downloadFile(
                              fileId: file.id,
                              fileName: file.name,
                              filePath: file.preview ?? '',
                              mimeType: file.mimetype ?? file.type,
                            );
                          },
                        ),
                        BottomSheetOption(
                          icon: Icons.delete,
                          title: "Remove",
                          onTap: () {
                            context.read<MyDriveBloc>().add(
                                  MoveToTrashEvent(fileIDs: [file.id]),
                                );
                          },
                        ),
                      ],
                      title: file.name,
                      foldertype: file.type,
                      mimetype: file.mimetype,
                    );
                  },
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          );
        },
        childCount: suggestions.length,
      ),
    );
  }

  Widget _buildSliverGridView(
      List<drive_model.Rows> suggestions, bool gridview) {
    if (suggestions.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text("No drive found.")),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final file = suggestions[index];
            isSelected = selectedFolders.contains(file.id);
            return GestureDetector(
              onLongPress: () {
                log("hii");
                _handleLongPressStart(file.id);
              },
              onTap: isSelectionMode
                  ? () {
                      _handleTapSelect(file.id);
                    }
                  : file.type == "folder"
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FileDeepView(
                                fileId: file.id,
                                folderName: file.name,
                                gridview: false,
                              ),
                            ),
                          );
                        }
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FilePreviewScreen(
                                  fileUrl: file.previewpath ?? ''),
                            ),
                          );
                        },
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildIcon(
                              type: file.type,
                              mimeType: file.mimetype,
                              colortype: file.organize),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              file.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
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
                                                      ShareScreen(file.id)),
                                            );
                                          },
                                        ),
                                        BottomSheetOption(
                                          icon: Icons.manage_accounts,
                                          title: "Manage access",
                                          onTap: () {
                                            MyRouter.push(
                                                screen: ManageAccessScreenUI(
                                                    fileId: file.id));
                                          },
                                        ),
                                        BottomSheetOption(
                                          icon: file.starred == true
                                              ? Icons.star
                                              : Icons.star_border,
                                          title: file.starred == true
                                              ? "Remove to Starred"
                                              : "Add to Starred",
                                          onTap: () {
                                            log('hii');

                                            log(file.starred.toString());
                                            context.read<MyDriveBloc>().add(
                                                  StarredData(
                                                      fileID: [file.id]),
                                                );
                                          },
                                        ),
                                        BottomSheetOption(
                                          icon: Icons.link,
                                          title: "Copy link",
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                  text:
                                                      file.preview.toString()),
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
                                              initialName: file.name,
                                              onRename: (newName) {
                                                context.read<MyDriveBloc>().add(
                                                      RenameEvent(
                                                          fileIDs: [file.id],
                                                          editedName:
                                                              newName.trim()),
                                                    );
                                              },
                                            );
                                          },
                                        ),
                                        file.type == "folder"
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
                                                              .read<
                                                                  MyDriveBloc>()
                                                              .add(
                                                                OrganizeEvent(
                                                                    fileIDs: [
                                                                      file.id,
                                                                    ],
                                                                    pickedColor:
                                                                        hex),
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
                                                    movingFileId: file.id));
                                          },
                                        ),
                                        BottomSheetOption(
                                          icon: Icons.turn_right_outlined,
                                          title: "Send a copy",
                                          onTap: () async {
                                            await Future.delayed(const Duration(
                                                milliseconds: 300));

                                            final name = file.name.trim();
                                            final preview = file.preview
                                                    ?.toString()
                                                    .trim() ??
                                                '';

                                            final textToShare =
                                                (name.isNotEmpty ||
                                                        preview.isNotEmpty)
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
                                              screen: FileDetailScreen(
                                                  fileID: file.id),
                                            );
                                          },
                                        ),
                                        BottomSheetOption(
                                          icon: Icons.file_download_outlined,
                                          title: "Download",
                                          onTap: () async {
                                            print(file.preview);
                                            print(file.mimetype);
                                            print(file.type);
                                            print(file.name);

                                            log("Downloading: ${file.name}");
                                            log("File ID: ${file.id}");
                                            log("File Path: ${file.preview ?? ''}");
                                            log("MIME Type: ${file.mimetype ?? file.type}");
                                            await FileDownloader.downloadFile(
                                              fileId: file.id,
                                              fileName: file.name,
                                              mimeType:
                                                  file.mimetype ?? file.type,
                                              filePath: file.preview ?? '',
                                            );
                                          },
                                        ),
                                        BottomSheetOption(
                                          icon: Icons.delete,
                                          title: "Remove",
                                          onTap: () {
                                            context.read<MyDriveBloc>().add(
                                                  MoveToTrashEvent(
                                                      fileIDs: [file.id]),
                                                );
                                          },
                                        ),
                                      ],
                                      title: file.name,
                                      foldertype: file.type,
                                      mimetype: file.mimetype,
                                    );
                                  })
                              : Icon(Icons.check_circle, color: chatColor),
                        ],
                      ),
                    ),
                    Expanded(
                      child:
                          file.mimetype != 'application/vnd.google-apps.folder'
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: file.thumbnail != null &&
                                              file.thumbnail!.isNotEmpty
                                          ? Image.network(
                                              file.thumbnail!,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                  child: getMimeTypeImage(
                                                      file.mimetype ?? ""),
                                                );
                                              },
                                            )
                                          : Center(
                                              child: getMimeTypeImage(
                                                  file.mimetype ?? "")),
                                    ),
                                    if (file.starred == true)
                                      const Positioned(
                                        bottom: 10,
                                        right: 8,
                                        child: Icon(Icons.star,
                                            size: 20, color: Colors.amber),
                                      ),
                                  ],
                                )
                              : Center(
                                  child: getMimeTypeImage(file.mimetype ?? "")),
                    ),
                    ListTile(
                      leading:
                          file.profilePic != null && file.profilePic!.isNotEmpty
                              ? CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: file.profilePic!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          CircleAvatar(
                                        backgroundColor: AppColors.profile,
                                        child: Text(file.name.isNotEmpty
                                            ? file.name[0].toUpperCase()
                                            : ""),
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: AppColors.profile,
                                  child: Text(file.name.isNotEmpty
                                      ? file.name[0].toUpperCase()
                                      : ""),
                                ),
                      title: const Text("You opened"),
                      subtitle: Text(
                        DateFormatted.formatToReadableDate(file.updatedAt),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: suggestions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "MyDrive"),
            Tab(text: "Labels"),
          ],
          labelColor: AppColors.iconActive,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.iconActive,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              BlocBuilder<MyDriveBloc, MyDriveState>(
                builder: (context, state) {
                  if (state is MyDriveLoading) {
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
                  } else if (state is MyDriveLoaded) {
                    _currentFolders = state.folders;
                    return CustomScrollView(
                      controller: widget.scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: isSelectionMode
                                ? Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          _clearSelection();
                                        },
                                        icon: Icon(Icons.clear),
                                      ),
                                      Text(
                                        "${selectedFolders.length} selected",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          setState(() {
                                            if (selectAll) {
                                              selectedFolders.clear();
                                            } else {
                                              // Select all
                                              selectedFolders.addAll(
                                                  _currentFolders
                                                      .map((f) => f.id));
                                            }
                                            selectAll = !selectAll;
                                          });
                                        },
                                        icon: Icon(
                                          selectAll
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          color: chatColor,
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(_isGridView
                                            ? Icons.list
                                            : Icons.grid_view),
                                        onPressed: () {
                                          setState(() {
                                            _isGridView = !_isGridView;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          final selectedFolderModels =
                                              _currentFolders
                                                  .where((f) => selectedFolders
                                                      .contains(f.id))
                                                  .toList();

                                          if (selectedFolderModels.isEmpty)
                                            return;

                                          showReusableBottomSheet(
                                            context,
                                            [
                                              BottomSheetOption(
                                                icon: selectedFolderModels
                                                        .every((f) =>
                                                            f.starred ?? true)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                title: selectedFolderModels
                                                        .every((f) =>
                                                            f.starred ?? false)
                                                    ? "Remove from Starred"
                                                    : "Add to Starred",
                                                onTap: () {
                                                  context
                                                      .read<MyDriveBloc>()
                                                      .add(
                                                        StarredData(
                                                            fileID:
                                                                selectedFolders
                                                                    .toList()),
                                                      );
                                                  _clearSelection();
                                                },
                                              ),
                                              BottomSheetOption(
                                                icon: Icons
                                                    .file_download_outlined,
                                                title: "Download",
                                                onTap: () async {
                                                  for (var folder
                                                      in selectedFolderModels) {
                                                    log("Downloading: ${folder.name}");
                                                    log("File ID: ${folder.id}");
                                                    log("File Path: ${folder.preview ?? ''}");
                                                    log("MIME Type: ${folder.mimetype ?? folder.type}");
                                                    await FileDownloader
                                                        .downloadFile(
                                                      fileId: folder.id,
                                                      filePath:
                                                          folder.preview ?? '',
                                                      fileName: folder.name,
                                                      mimeType:
                                                          folder.mimetype ??
                                                              folder.type,
                                                    );
                                                  }
                                                  _clearSelection();
                                                },
                                              ),
                                              BottomSheetOption(
                                                icon: Icons.delete,
                                                title: "Delete",
                                                onTap: () {
                                                  context
                                                      .read<MyDriveBloc>()
                                                      .add(
                                                        MoveToTrashEvent(
                                                            fileIDs:
                                                                selectedFolders
                                                                    .toList()),
                                                      );
                                                  _clearSelection();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                        icon: const Icon(Icons.more_vert),
                                      )
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Text(
                                        "Files",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isGridView = !_isGridView;
                                          });
                                        },
                                        icon: Icon(
                                          _isGridView
                                              ? Icons.list
                                              : Icons.grid_view,
                                        ),
                                      )
                                    ],
                                  ),
                          ),
                        ),
                        _isGridView
                            ? _buildSliverGridView(state.folders, _isGridView)
                            : _buildSliverFilesList(state.folders, _isGridView),
                      ],
                    );
                  } else if (state is MyDriveError) {
                    return Center(child: Text("Error: ${state.message}"));
                  }
                  return const SizedBox();
                },
              ),
              const MyComputer(),
            ],
          ),
        ),
      ],
    );
  }
}

class MyComputer extends StatelessWidget {
  const MyComputer({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Computer tab content here"));
  }
}

class DateFormatted {
  static String formatToReadableDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
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
