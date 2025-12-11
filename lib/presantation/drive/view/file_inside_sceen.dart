import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_folder_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_event.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_state.dart';
import 'package:nde_email/presantation/drive/Bloc/move/move_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/move/move_event.dart';
import 'package:nde_email/presantation/drive/common/create_dialogue.dart';
import 'package:nde_email/presantation/drive/data/insidefile_repo.dart';
import 'package:nde_email/presantation/drive/model/folderinside_model.dart';

import 'package:nde_email/presantation/drive/data/common_repo.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/simmer_effect.dart/drive_simmer.dart';

class FileInsideSceen extends StatefulWidget {
  final String fileId;
  final String folderName;
  final bool gridview;
  final String movingFileId;

  const FileInsideSceen({
    super.key,
    required this.fileId,
    required this.folderName,
    required this.gridview,
    required this.movingFileId,
  });

  @override
  State<FileInsideSceen> createState() => _FileInsideSceenState();
}

class _FileInsideSceenState extends State<FileInsideSceen> {
  late bool gridview;
  String? selectedFolderId;

  @override
  void initState() {
    super.initState();
    gridview = widget.gridview;
    selectedFolderId = widget.fileId;
  }

  void _onMoveHereTap(BuildContext context) {
    if (selectedFolderId != null && selectedFolderId!.isNotEmpty) {
      context.read<MoveFileBloc>().add(
            MoveFileRequested(
              fileId: [widget.movingFileId],
              destinationId: selectedFolderId!,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => InsideBloc(repository: InsidefileRepo())
            ..add(InFetchStarredFolders(filedId: widget.fileId)),
        ),
        BlocProvider(
          create: (_) => MoveFileBloc(repository: FoldersRepository()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MoveFileBloc, MoveFileState>(
            listener: (context, moveState) {
              if (moveState is MoveFileSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File moved successfully')),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              } else if (moveState is MoveFileFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Move failed: ${moveState.message}')),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<MoveFileBloc, MoveFileState>(
          builder: (context, moveState) {
            return Scaffold(
              backgroundColor: AppColors.bg,
              body: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildAppBar(),
                        if (moveState is MoveFileLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        Expanded(
                          child: BlocBuilder<InsideBloc, InsidefileState>(
                            builder: (context, state) {
                              if (state is InsideLoading) {
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
                              } else if (state is InsideLoaded) {
                                return RefreshIndicator(
                                  onRefresh: () async {
                                    context.read<InsideBloc>().add(
                                          InFetchStarredFolders(
                                              filedId: widget.fileId),
                                        );
                                  },
                                  child: gridview
                                      ? _buildGridView(state.folders)
                                      : _buildListView(state.folders),
                                );
                              } else if (state is InsideError) {
                                return Center(
                                    child: Text("Error: ${state.message}"));
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: (selectedFolderId != null &&
                                    selectedFolderId!.isNotEmpty)
                                ? () => _onMoveHereTap(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(45),
                            ),
                            child: const Text("Move Here"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => MyRouter.pop(),
          ),
          Expanded(
            child: Text(
              widget.folderName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'Create Folder',
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (ctx) => BlocProvider.value(
                    value: context.read<CreateFolderBloc>(),
                    child: NewBoxDialog(parentId: widget.fileId),
                  ),
                );

                if (result == true) {
                  context
                      .read<InsideBloc>()
                      .add(InFetchStarredFolders(filedId: widget.fileId));
                }
              }),
          IconButton(
            icon: Icon(gridview ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                gridview = !gridview;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<FolderinsideModel> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedFolderId == item.id;

        return GestureDetector(
          onTap: () => _handleTap(item),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMimeIconForInside(item),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<FolderinsideModel> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedFolderId == item.id;

        return ListTile(
          leading: _buildMimeIconForInside(item),
          title: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          tileColor: isSelected ? Colors.blue[100] : null,
          onTap: () => _handleTap(item),
        );
      },
    );
  }

  void _handleTap(FolderinsideModel file) {
    if (file.type.toLowerCase() == "folder") {
      setState(() {
        selectedFolderId = file.id;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileInsideSceen(
            fileId: file.id,
            folderName: file.name,
            gridview: gridview,
            movingFileId: widget.movingFileId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Tapped on file: ${file.name} (ID: ${file.id})")),
      );
    }
  }

  Widget _buildMimeIconForInside(FolderinsideModel file) {
    final type = file.type.toLowerCase();
    final ext = file.extname?.toLowerCase().trim() ?? "";

    if (type == 'folder') {
      return Image.asset("assets/images/folder.png",
          height: 24, width: 24, color: Colors.amber);
    } else if (ext.contains('doc') || ext.contains('msword')) {
      return Image.asset('assets/images/word.png', height: 24, width: 24);
    } else if (ext.contains('excel') || ext.contains('spreadsheet')) {
      return Image.asset('assets/images/sheets.png', height: 24, width: 24);
    } else if (ext.contains('pdf')) {
      return Image.asset('assets/images/pdf.png', height: 24, width: 24);
    } else if (ext.contains('ppt') || ext.contains('presentation')) {
      return Image.asset('assets/images/sheets.png', height: 24, width: 24);
    } else if (ext.contains('image') ||
        ext.contains('png') ||
        ext.contains('jpg')) {
      return Image.asset('assets/images/image.png', height: 24, width: 24);
    } else if (ext.contains('video')) {
      return Image.asset('assets/images/video.png', height: 24, width: 24);
    } else if (ext.contains('audio') || ext.contains('mp4')) {
      return Image.asset('assets/images/headphones.png', height: 24, width: 24);
    } else if (ext.contains('zip') || ext.contains('rar')) {
      return Image.asset('assets/images/pdf.png', height: 24, width: 24);
    }
    return Image.asset('assets/images/image.png', height: 24, width: 24);
  }
}
