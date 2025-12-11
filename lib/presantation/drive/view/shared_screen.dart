import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_event.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_state.dart';
import 'package:nde_email/presantation/drive/common/colour_picker.dart';
import 'package:nde_email/presantation/drive/common/file_preview_widget.dart';
import 'package:nde_email/presantation/drive/common/pop.dart';
import 'package:nde_email/presantation/drive/common/show_bottom_model_sheet.dart';
import 'package:nde_email/presantation/drive/common/show_rename.dart';
import 'package:nde_email/presantation/drive/model/shared/sharred_model.dart';
import 'package:nde_email/presantation/drive/view/file_deatilsScreen.dart';
import 'package:nde_email/presantation/drive/view/file_deep_view.dart';
import 'package:nde_email/presantation/drive/view/manage_acces_screen.dart';
import 'package:nde_email/presantation/drive/view/move_screen.dart';
import 'package:nde_email/presantation/drive/view/send_screen.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/dateFormatter.dart';
import 'package:nde_email/utils/icons/reuable_icon.dart';
import 'package:nde_email/utils/reusbale/dowloading_mime.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:share_plus/share_plus.dart';

class SharedPage extends StatefulWidget {
  final ScrollController scrollController;

  const SharedPage({super.key, required this.scrollController});

  @override
  State<SharedPage> createState() => _SharedPageState();
}

class _SharedPageState extends State<SharedPage> {
  bool _isGridView = false;
  String _currentSort = 'Name';

  final List<String> _sortOptions = [
    'Name',
    'Date Modified',
    'Date Modified by Me',
    'Date Opened by Me',
    'A → Z',
    'Z → A',
  ];

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _loadFolders();
  }

  void _onScroll() {
    if (!mounted) return;

    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      context.read<FolderBloc>().add(
            FetchFolderData(sortBy: sortQuery ?? 'name', isLoadMore: true),
          );
    }
  }

  void _loadFolders({String? sortBy}) {
    log('📤 Triggering API with sortBy: $sortBy');
    context.read<FolderBloc>().add(FetchFolderData(sortBy: sortBy));
  }

  String? sortQuery;

  void _handleSortChange(String selectedOption) {
    setState(() {
      _currentSort = selectedOption;
    });

    String sortQuery;
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
      case 'A → Z':
        sortQuery = 'asc';
        break;
      case 'Z → A':
        sortQuery = 'dsc';
        break;
      default:
        sortQuery = 'name';
    }

    _loadFolders(sortBy: sortQuery);
  }

  Set<String> selectedFolders = {};
  List<FolderItem> _currentFolders = [];

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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                            selectedFolders
                                .addAll(_currentFolders.map((f) => f.id));
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
                      icon:
                          Icon(_isGridView ? Icons.view_list : Icons.grid_view),
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
                        final selectedFolderModels = _currentFolders
                            .where((f) => selectedFolders.contains(f.id))
                            .toList();

                        if (selectedFolderModels.isEmpty) return;

                        showReusableBottomSheet(
                          context,
                          [
                            BottomSheetOption(
                              icon: selectedFolderModels.every((f) => f.starred)
                                  ? Icons.star
                                  : Icons.star_border,
                              title:
                                  selectedFolderModels.every((f) => f.starred)
                                      ? "Remove from Starred"
                                      : "Add to Starred",
                              onTap: () {
                                context.read<FolderBloc>().add(
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
                                    fileName: folder.name,
                                    filePath: folder.previewpath ?? '',
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
                                context.read<FolderBloc>().add(
                                      MoveToTrashEvent(
                                          fileIDs: selectedFolders.toList()),
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    hSpace8,
                    vSpace4,
                    Text(_currentSort),
                    SortPopupMenu(
                      sortOptions: _sortOptions,
                      selectedOption: _currentSort,
                      onSelected: _handleSortChange,
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                    )
                  ],
                ),
        ),
        Expanded(
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
                _currentFolders = state.folderResponse.rows;
                final folders = state.folderResponse.rows;

                if (folders.isEmpty) {
                  return Center(
                    child: Text(
                      'No shared folders available',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: _isGridView
                          ? GridView.builder(
                              controller: widget.scrollController,
                              padding: const EdgeInsets.all(10),
                              itemCount: folders.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.2,
                              ),
                              itemBuilder: (context, index) {
                                final folder = folders[index];
                                isSelected =
                                    selectedFolders.contains(folder.id);
                                return GestureDetector(
                                  onLongPress: () {
                                    log("hii");
                                    _handleLongPressStart(folder.id);
                                  },
                                  onTap: isSelectionMode
                                      ? () {
                                          _handleTapSelect(folder.id);
                                        }
                                      : folder.type == "folder"
                                          ? () {
                                              MyRouter.push(
                                                  screen: FileDeepView(
                                                fileId: folder.id,
                                                folderName: folder.name,
                                                gridview: _isGridView,
                                              ));
                                            }
                                          : () {
                                              MyRouter.push(
                                                screen: FilePreviewScreen(
                                                  fileUrl:
                                                      folder.previewpath ?? "",
                                                ),
                                              );
                                            },
                                  child: Card(
                                    color: isSelected
                                        ? Colors.blue.shade100
                                        : Colors.grey.shade100,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: Row(
                                            children: [
                                              buildMimeIcon(folder),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  folder.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                              isSelected == false
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.more_vert),
                                                      onPressed: () {
                                                        showReusableBottomSheet(
                                                          context,
                                                          [
                                                            BottomSheetOption(
                                                                icon: Icons
                                                                    .person_add,
                                                                title: "Share",
                                                                onTap: () {
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                ShareScreen(folder.id)),
                                                                  );
                                                                }),
                                                            BottomSheetOption(
                                                              icon: Icons
                                                                  .manage_accounts,
                                                              title:
                                                                  "Manage access",
                                                              onTap: () {
                                                                MyRouter.push(
                                                                    screen: ManageAccessScreenUI(
                                                                        fileId:
                                                                            folder.id));
                                                              },
                                                            ),
                                                            BottomSheetOption(
                                                                icon: folder.starred ==
                                                                        true
                                                                    ? Icons.star
                                                                    : Icons
                                                                        .star_border,
                                                                title: folder
                                                                            .starred ==
                                                                        true
                                                                    ? "Remove to Starred"
                                                                    : "Add to Starred",
                                                                onTap: () {
                                                                  log('hii');

                                                                  context
                                                                      .read<
                                                                          FolderBloc>()
                                                                      .add(
                                                                        StarredData(
                                                                            fileID: [
                                                                              folder.id
                                                                            ]),
                                                                      );
                                                                }),
                                                            BottomSheetOption(
                                                                icon:
                                                                    Icons.link,
                                                                title:
                                                                    "Copy link",
                                                                onTap: () {
                                                                  Clipboard.setData(ClipboardData(
                                                                      text: folder
                                                                          .previewpath
                                                                          .toString()));
                                                                  Messenger
                                                                      .alertSuccess(
                                                                          "Copied");
                                                                }),
                                                            BottomSheetOption(
                                                              icon: Icons
                                                                  .drive_file_rename_outline,
                                                              title: "Rename",
                                                              onTap: () async {
                                                                await showRenameDialog(
                                                                  context:
                                                                      context,
                                                                  initialName:
                                                                      folder
                                                                          .name,
                                                                  onRename:
                                                                      (newName) {
                                                                    context
                                                                        .read<
                                                                            FolderBloc>()
                                                                        .add(
                                                                          RenameEvent(
                                                                              fileIDs: [
                                                                                folder.id
                                                                              ],
                                                                              editedName: newName.trim()),
                                                                        );
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                            folder.type ==
                                                                    "folder"
                                                                ? BottomSheetOption(
                                                                    icon: Icons
                                                                        .color_lens,
                                                                    title:
                                                                        "Change Color",
                                                                    onTap: () {
                                                                      MyRouter
                                                                          .pop();

                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (context) {
                                                                          return ColorPickerDialog(
                                                                            onColorSelected:
                                                                                (hex) {
                                                                              log("Selected Color: $hex");

                                                                              // context
                                                                              //     .read<FolderBloc>()
                                                                              //     .add(
                                                                              //       InOrganizeEvent(fileIDs: [
                                                                              //         folder.id,
                                                                              //       ], pickedColor: hex),
                                                                              //     );
                                                                            },
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  )
                                                                : BottomSheetOption(
                                                                    icon: Icons
                                                                        .file_copy,
                                                                    title:
                                                                        "Make a copy ",
                                                                    onTap:
                                                                        () {},
                                                                  ),
                                                            BottomSheetOption(
                                                                icon: Icons
                                                                    .drive_file_move,
                                                                title: "Move",
                                                                onTap: () {
                                                                  MyRouter
                                                                      .pop();
                                                                  MyRouter.push(
                                                                      screen: MoveFileScreen(
                                                                          movingFileId:
                                                                              folder.id));
                                                                }),
                                                            BottomSheetOption(
                                                              icon: Icons
                                                                  .turn_right_outlined,
                                                              title:
                                                                  "Send a copy",
                                                              onTap: () async {
                                                                await Future.delayed(
                                                                    const Duration(
                                                                        milliseconds:
                                                                            300));

                                                                final name =
                                                                    folder.name
                                                                        .trim();
                                                                final preview = folder
                                                                        .previewpath
                                                                        ?.toString()
                                                                        .trim() ??
                                                                    '';

                                                                final textToShare = (name
                                                                            .isNotEmpty ||
                                                                        preview
                                                                            .isNotEmpty)
                                                                    ? "$name\n\n$preview"
                                                                    : '';

                                                                if (textToShare
                                                                    .isNotEmpty) {
                                                                  Share.share(
                                                                      textToShare);
                                                                } else {
                                                                  log("Nothing to share.");
                                                                }
                                                              },
                                                            ),
                                                            BottomSheetOption(
                                                                icon: Icons
                                                                    .info_outline,
                                                                title:
                                                                    "Details & activity",
                                                                onTap: () {
                                                                  MyRouter.push(
                                                                      screen:
                                                                          FileDetailScreen(
                                                                    fileID:
                                                                        folder
                                                                            .id,
                                                                  ));
                                                                }),
                                                            BottomSheetOption(
                                                                icon: Icons
                                                                    .file_download_outlined,
                                                                title:
                                                                    "Download",
                                                                onTap: () {}),
                                                            BottomSheetOption(
                                                                icon: Icons
                                                                    .delete,
                                                                title: "Remove",
                                                                onTap: () {
                                                                  context
                                                                      .read<
                                                                          FolderBloc>()
                                                                      .add(MoveToTrashEvent(
                                                                          fileIDs: [
                                                                            folder.id
                                                                          ]));
                                                                }),
                                                          ],
                                                          title: folder.name,
                                                          foldertype:
                                                              folder.type,
                                                          mimetype:
                                                              folder.mimetype,
                                                        );
                                                      },
                                                      constraints:
                                                          const BoxConstraints(),
                                                      padding: EdgeInsets.zero,
                                                    )
                                                  : Icon(Icons.check_circle,
                                                      color: chatColor),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: folder.mimetype !=
                                                  'application/vnd.google-apps.folder'
                                              ? Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: folder.thumbnail !=
                                                                  null &&
                                                              folder.thumbnail!
                                                                  .isNotEmpty
                                                          ? Image.network(
                                                              folder.thumbnail!,
                                                              width: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Center(
                                                                  child: getMimeTypeImage(
                                                                      folder.mimetype ??
                                                                          ""),
                                                                );
                                                              },
                                                            )
                                                          : Center(
                                                              child: getMimeTypeImage(
                                                                  folder.mimetype ??
                                                                      "")),
                                                    ),
                                                    folder.starred
                                                        ? const Positioned(
                                                            bottom: 10,
                                                            right: 8,
                                                            child: Icon(
                                                                Icons.star,
                                                                color: Colors
                                                                    .amber),
                                                          )
                                                        : const SizedBox
                                                            .shrink(),
                                                  ],
                                                )
                                              : Center(
                                                  child: getMimeTypeImage(
                                                      folder.mimetype ?? "")),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              controller: widget.scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              itemCount: folders.length,
                              itemBuilder: (context, index) {
                                final folder = folders[index];
                                final isSelected =
                                    selectedFolders.contains(folder.id);
                                return GestureDetector(
                                  onLongPress: () {
                                    log("hii");
                                    _handleLongPressStart(folder.id);
                                  },
                                  onTap: isSelectionMode
                                      ? () {
                                          _handleTapSelect(folder.id);
                                        }
                                      : folder.type == "folder"
                                          ? () {
                                              MyRouter.push(
                                                  screen: FileDeepView(
                                                fileId: folder.id,
                                                folderName: folder.name,
                                                gridview: _isGridView,
                                              ));
                                            }
                                          : () {
                                              print(folder.previewpath);
                                              MyRouter.push(
                                                screen: FilePreviewScreen(
                                                  fileUrl:
                                                      folder.previewpath ?? "",
                                                ),
                                              );
                                            },
                                  child: Container(
                                    color: isSelected
                                        ? chatColor.withOpacity(0.1)
                                        : null,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 1, horizontal: 8),
                                      leading: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.center,
                                          children: [
                                            if (folder.profilePic.isNotEmpty)
                                              CircleAvatar(
                                                radius: 30,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child: folder
                                                        .profilePic.isNotEmpty
                                                    ? ClipOval(
                                                        child: Image.network(
                                                          folder.profilePic,
                                                          width: 60,
                                                          height: 60,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return const Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.grey,
                                                              size: 30,
                                                            );
                                                          },
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.person,
                                                        color: Colors.grey,
                                                        size: 30,
                                                      ),
                                              ),
                                            if (isSelected)
                                              const Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: Colors.blue,
                                                  size: 18,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      title: Text(
                                        folder.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Row(
                                        children: [
                                          if (folder.starred == true)
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(right: 4),
                                              child: Icon(Icons.star,
                                                  size: 16,
                                                  color: Colors.amber),
                                            ),
                                          Text(
                                            _currentSort == "Date Opened by Me"
                                                ? 'Opened by Me ${DateFormatter.formatToReadableDate(folder.updatedAt)}'
                                                : 'Modified ${DateFormatter.formatToReadableDate(folder.updatedAt)}',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
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
                                                            builder: (context) =>
                                                                ShareScreen(
                                                                    folder.id)),
                                                      );
                                                    }),
                                                BottomSheetOption(
                                                  icon: Icons.manage_accounts,
                                                  title: "Manage access",
                                                  onTap: () {
                                                    MyRouter.push(
                                                        screen:
                                                            ManageAccessScreenUI(
                                                                fileId:
                                                                    folder.id));
                                                  },
                                                ),
                                                BottomSheetOption(
                                                    icon: folder.starred == true
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    title: folder.starred ==
                                                            true
                                                        ? "Remove to Starred"
                                                        : "Add to Starred",
                                                    onTap: () {
                                                      log('hii');

                                                      context
                                                          .read<FolderBloc>()
                                                          .add(
                                                            StarredData(
                                                                fileID: [
                                                                  folder.id
                                                                ]),
                                                          );
                                                    }),
                                                BottomSheetOption(
                                                    icon: Icons.link,
                                                    title: "Copy link",
                                                    onTap: () {
                                                      Clipboard.setData(
                                                          ClipboardData(
                                                              text: folder
                                                                  .previewpath
                                                                  .toString()));
                                                      Messenger.alertSuccess(
                                                          "Copied");
                                                    }),
                                                BottomSheetOption(
                                                  icon: Icons
                                                      .drive_file_rename_outline,
                                                  title: "Rename",
                                                  onTap: () async {
                                                    await showRenameDialog(
                                                      context: context,
                                                      initialName: folder.name,
                                                      onRename: (newName) {
                                                        context
                                                            .read<FolderBloc>()
                                                            .add(
                                                              RenameEvent(
                                                                  fileIDs: [
                                                                    folder.id
                                                                  ],
                                                                  editedName:
                                                                      newName
                                                                          .trim()),
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
                                                                onColorSelected:
                                                                    (hex) {
                                                                  log("Selected Color: $hex");

                                                                  // context
                                                                  //     .read<FolderBloc>()
                                                                  //     .add(
                                                                  //       InOrganizeEvent(fileIDs: [
                                                                  //         folder.id,
                                                                  //       ], pickedColor: hex),
                                                                  //     );
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
                                                          screen:
                                                              MoveFileScreen(
                                                                  movingFileId:
                                                                      folder
                                                                          .id));
                                                    }),
                                                BottomSheetOption(
                                                  icon:
                                                      Icons.turn_right_outlined,
                                                  title: "Send a copy",
                                                  onTap: () async {
                                                    await Future.delayed(
                                                        const Duration(
                                                            milliseconds: 300));

                                                    final name =
                                                        folder.name.trim();
                                                    final preview = folder
                                                            .previewpath
                                                            ?.toString()
                                                            .trim() ??
                                                        '';

                                                    final textToShare = (name
                                                                .isNotEmpty ||
                                                            preview.isNotEmpty)
                                                        ? "$name\n\n$preview"
                                                        : '';

                                                    if (textToShare
                                                        .isNotEmpty) {
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
                                                      MyRouter.push(
                                                          screen:
                                                              FileDetailScreen(
                                                        fileID: folder.id,
                                                      ));
                                                    }),
                                                BottomSheetOption(
                                                    icon: Icons
                                                        .file_download_outlined,
                                                    title: "Download",
                                                    onTap: () {}),
                                                BottomSheetOption(
                                                    icon: Icons.delete,
                                                    title: "Remove",
                                                    onTap: () {
                                                      context
                                                          .read<FolderBloc>()
                                                          .add(MoveToTrashEvent(
                                                              fileIDs: [
                                                                folder.id
                                                              ]));
                                                    }),
                                              ],
                                              title: folder.name,
                                              foldertype: folder.type,
                                              mimetype: folder.mimetype,
                                            );
                                          },
                                          icon: Icon(Icons.more_vert)),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              } else if (state is FolderError) {
                return Center(child: Text('Something Went Wrong!'));
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
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
