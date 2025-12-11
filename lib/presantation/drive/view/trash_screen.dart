import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_event.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_state.dart';
import 'package:nde_email/presantation/drive/common/file_preview_widget.dart'
    show FilePreviewScreen;

import 'package:nde_email/presantation/drive/common/pop.dart';
import 'package:nde_email/presantation/drive/common/show_bottom_model_sheet.dart';
import 'package:nde_email/presantation/drive/model/trash/trashfilemodel.dart';
import 'package:nde_email/presantation/drive/view/file_deatilsScreen.dart';
import 'package:nde_email/presantation/drive/view/file_deep_view.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/reusbale/dowloading_mime.dart';
import 'package:nde_email/utils/reusbale/mime.type.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';
import 'package:nde_email/utils/spacer/spacer.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _isGridView = false;
  String? sortQuery;

  String _currentSort = 'Date Modified';
  bool isEmpty = false;

  final List<String> _sortOptions = [
    'Name',
    'Date Modified',
    'Date Modified by Me',
    'Date Opened by Me',
    'A → Z',
    'Z → A',
  ];

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

  List<String>? allIds;
  @override
  void initState() {
    super.initState();
    _loadFolders(sortBy: 'updatedAt');
  }

  Set<String> selectedFolders = {};
  List<TrashFileModel> _currentFolders = [];

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
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedFolders.clear();
      isSelectionMode = false;
    });
  }

  void _loadFolders({String? sortBy}) {
    log('📤 Triggering API with sortBy: $sortBy');
    context.read<FolderBloc>().add(FetchTrashEvent(sortBy: sortBy));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text("Trash"),
        backgroundColor: Colors.transparent,
        actions: [
          isSelectionMode
              ? IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    final selectedFolderModels = _currentFolders
                        .where((folder) => selectedFolders.contains(folder.id))
                        .toList();

                    showReusableBottomSheet(
                      context,
                      [
                        BottomSheetOption(
                          icon: Icons.file_download_outlined,
                          title: "Download",
                          onTap: () async {
                            for (final folder in selectedFolderModels) {
                              await FileDownloader.downloadFile(
                                fileId: folder.id,
                                filePath: folder.preview ?? '',
                                fileName: folder.name,
                                mimeType: folder.mimetype ?? folder.type ?? "",
                              );
                            }
                            _clearSelection();
                          },
                        ),
                        BottomSheetOption(
                          icon: Icons.restore,
                          title: "Restore",
                          onTap: () {
                            context.read<FolderBloc>().add(
                                  RestoreEvent(
                                    fileIDs: selectedFolders.toList(),
                                  ),
                                );
                            _clearSelection();
                          },
                        ),
                      ],
                    );
                  },
                )
              : voidBox,
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isSelectionMode ? voidBox : vSpace36,
          isSelectionMode | isEmpty
              ? voidBox
              : Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                  ),
                  child: Text("items are deleted forever after 30 days"),
                ),
          isSelectionMode
              ? voidBox
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      context.read<FolderBloc>().add(
                            DeletePermanentlyEvent(fileIDs: allIds ?? []),
                          );
                    },
                    child: Text('Empty Trash'),
                  ),
                ),
          isSelectionMode | isEmpty ? voidBox : Divider(),
          isSelectionMode | isEmpty
              ? voidBox
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
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
                        icon: Icon(
                            _isGridView ? Icons.view_list : Icons.grid_view),
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
                } else if (state is TrashLoaded) {
                  final folders = state.trashResponse.rows;

                  return folders.isEmpty
                      ? Center(
                          child: Text("Not Found in trash"),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: _isGridView
                                  ? GridView.builder(
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
                                        allIds =
                                            folders.map((e) => e.id).toList();

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
                                                        screen:
                                                            FilePreviewScreen(
                                                          fileUrl: folder
                                                                  .previewpath ??
                                                              "",
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                                  child: Row(
                                                    children: [
                                                      buildIcon(
                                                          type: folder.type,
                                                          mimeType:
                                                              folder.mimetype),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          folder.name,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                      isSelected == false
                                                          ? IconButton(
                                                              icon: const Icon(
                                                                  Icons
                                                                      .more_vert),
                                                              onPressed: () {
                                                                showReusableBottomSheet(
                                                                    context,
                                                                    [
                                                                      BottomSheetOption(
                                                                          icon: Icons
                                                                              .link,
                                                                          title:
                                                                              "Copy link",
                                                                          onTap: () =>
                                                                              log("Copy link")),
                                                                      BottomSheetOption(
                                                                          icon: Icons
                                                                              .info_outline,
                                                                          title:
                                                                              "Details & activity",
                                                                          onTap:
                                                                              () {
                                                                            MyRouter.push(
                                                                                screen: FileDetailScreen(
                                                                              fileID: folder.id,
                                                                            ));
                                                                          }),
                                                                      BottomSheetOption(
                                                                          icon: Icons
                                                                              .delete_forever,
                                                                          title:
                                                                              "Remove",
                                                                          onTap:
                                                                              () {
                                                                            context.read<FolderBloc>().add(
                                                                                  DeletePermanentlyEvent(fileIDs: [
                                                                                    folder.id
                                                                                  ]),
                                                                                );
                                                                          }),
                                                                      BottomSheetOption(
                                                                          icon: Icons
                                                                              .restart_alt,
                                                                          title:
                                                                              "Restore",
                                                                          onTap:
                                                                              () {
                                                                            context.read<FolderBloc>().add(
                                                                                  RestoreEvent(fileIDs: [
                                                                                    folder.id
                                                                                  ]),
                                                                                );
                                                                          }),
                                                                    ],
                                                                    title: folder
                                                                        .name);
                                                              },
                                                              constraints:
                                                                  const BoxConstraints(),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            )
                                                          : Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color: chatColor),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                    child: folder.previewpath !=
                                                            null
                                                        ? Stack(
                                                            clipBehavior:
                                                                Clip.none,
                                                            children: [
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  child: Image
                                                                      .network(
                                                                    folder
                                                                        .previewpath!,
                                                                    width: double
                                                                        .infinity,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                                folder.starred
                                                                    ? Positioned(
                                                                        top: 50,
                                                                        left:
                                                                            150,
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .star,
                                                                          color:
                                                                              Colors.amber,
                                                                        ))
                                                                    : voidBox
                                                              ])
                                                        : Stack(children: [
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .shade300,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child:
                                                                  const Center(
                                                                child: Icon(
                                                                    Icons
                                                                        .folder,
                                                                    size: 40,
                                                                    color: Colors
                                                                        .black54),
                                                              ),
                                                            ),
                                                            folder.starred
                                                                ? Positioned(
                                                                    top: 50,
                                                                    left: 150,
                                                                    child: Icon(
                                                                      Icons
                                                                          .star,
                                                                      color: Colors
                                                                          .amber,
                                                                    ))
                                                                : voidBox,
                                                          ])),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      itemCount: folders.length,
                                      itemBuilder: (context, index) {
                                        final folder = folders[index];
                                        isSelected =
                                            selectedFolders.contains(folder.id);
                                        allIds =
                                            folders.map((e) => e.id).toList();

                                        log(allIds.toString());
                                        return GestureDetector(
                                          onLongPress: () {
                                            log("hii");
                                            _handleLongPressStart(folder.id);
                                          },
                                          onTap: isSelectionMode
                                              ? () {
                                                  _handleTapSelect(folder.id);
                                                }
                                              : () {
                                                  MyRouter.push(
                                                    screen: FilePreviewScreen(
                                                      fileUrl:
                                                          folder.previewpath ??
                                                              "",
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
                                                      vertical: 1,
                                                      horizontal: 8),
                                              leading: SizedBox(
                                                width: 48,
                                                height: 48,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  alignment: Alignment.center,
                                                  children: [
                                                    (folder.profilePic !=
                                                                null &&
                                                            folder.profilePic!
                                                                .isNotEmpty)
                                                        ? CircleAvatar(
                                                            radius: 20,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[200],
                                                            backgroundImage:
                                                                NetworkImage(folder
                                                                    .profilePic!),
                                                          )
                                                        : CircleAvatar(
                                                            radius: 20,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[200],
                                                            child: Icon(
                                                                Icons.person,
                                                                color: Colors
                                                                    .grey),
                                                          ),
                                                    if (isSelected)
                                                      const Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: Icon(
                                                            Icons.check_circle,
                                                            color: Colors.blue,
                                                            size: 18),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              title: Text(
                                                folder.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Row(
                                                children: [
                                                  if (folder.starred == true)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 4),
                                                      child: Icon(Icons.star,
                                                          size: 16,
                                                          color: Colors.amber),
                                                    ),
                                                  Text(
                                                    'Date Trashed ${DateTimeUtils.formatMessageTime(folder.updatedAt)}',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                  onPressed: () {
                                                    showReusableBottomSheet(
                                                        context,
                                                        [
                                                          BottomSheetOption(
                                                              icon: Icons.link,
                                                              title:
                                                                  "Copy link",
                                                              onTap: () => log(
                                                                  "Copy link")),
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
                                                                      folder.id,
                                                                ));
                                                              }),
                                                          BottomSheetOption(
                                                              icon: Icons
                                                                  .delete_forever,
                                                              title: "Remove",
                                                              onTap: () {
                                                                context
                                                                    .read<
                                                                        FolderBloc>()
                                                                    .add(
                                                                      DeletePermanentlyEvent(
                                                                          fileIDs: [
                                                                            folder.id
                                                                          ]),
                                                                    );
                                                              }),
                                                          BottomSheetOption(
                                                              icon: Icons
                                                                  .restart_alt,
                                                              title: "Restore",
                                                              onTap: () {
                                                                context
                                                                    .read<
                                                                        FolderBloc>()
                                                                    .add(
                                                                      RestoreEvent(
                                                                          fileIDs: [
                                                                            folder.id
                                                                          ]),
                                                                    );
                                                              }),
                                                        ],
                                                        title: folder.name);
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
                  return Center(child: Text('something Went wrong!'));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
