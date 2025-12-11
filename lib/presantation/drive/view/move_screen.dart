import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_folder_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_bloc.dart'
    show InsideBloc;
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_event.dart';
import 'package:nde_email/presantation/drive/Bloc/move/move_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/move/move_event.dart';
import 'package:nde_email/presantation/drive/common/create_dialogue.dart';
import 'package:nde_email/presantation/drive/data/common_repo.dart';
import 'package:nde_email/presantation/drive/view/move_drive_page.dart';
import 'package:nde_email/presantation/drive/view/move_sharred_page.dart';
import 'package:nde_email/presantation/drive/view/move_starred_page.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class MoveFileScreen extends StatelessWidget {
  final String movingFileId;

  const MoveFileScreen({
    super.key,
    required this.movingFileId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MoveFileBloc(repository: FoldersRepository()),
      child: MoveFileView(movingfileid: movingFileId),
    );
  }
}

class MoveFileView extends StatefulWidget {
  final String movingfileid;

  const MoveFileView({super.key, required this.movingfileid});

  @override
  State<MoveFileView> createState() => _MoveFileViewState();
}

class _MoveFileViewState extends State<MoveFileView> {
  final ScrollController _scrollController = ScrollController();
  String? selectedFolderId;

  void _onFolderSelected(String folderId) {
    setState(() {
      selectedFolderId = folderId;
    });
  }

  void _onMoveHereTap(BuildContext context) {
    final destinationId =
        selectedFolderId?.isNotEmpty == true ? selectedFolderId! : "mydrive";

    context.read<MoveFileBloc>().add(
          MoveFileRequested(
            fileId: [widget.movingfileid],
            destinationId: destinationId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MoveFileBloc, MoveFileState>(
      listener: (context, state) {
        if (state is MoveFileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File moved successfully')),
          );
          Navigator.pop(context);
        } else if (state is MoveFileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Select destination",
                      // textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.create_new_folder_outlined),
                      tooltip: "Create new folder",
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (ctx) => BlocProvider.value(
                            value: context.read<CreateFolderBloc>(),
                            child: NewBoxDialog(parentId: selectedFolderId),
                          ),
                        );

                        if (result == true) {
                          context.read<InsideBloc>().add(InFetchStarredFolders(
                              filedId: selectedFolderId ?? "mydrive"));
                        }
                      }),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(55),
              child: TabBar(
                labelColor: const Color.fromARGB(255, 11, 74, 247),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color.fromARGB(255, 4, 106, 189),
                labelStyle: const TextStyle(fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.folder, size: 18), text: "My Drive"),
                  Tab(icon: Icon(Icons.people_alt, size: 18), text: "Shared"),
                  Tab(icon: Icon(Icons.star_border, size: 18), text: "Starred"),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    MoveDrivePage(
                      scrollController: _scrollController,
                      isSelectionMode: true,
                      onFolderTap: (id) => _onFolderSelected(id.toString()),
                      movingFileId: widget.movingfileid,
                    ),
                    MoveSharedPage(
                      scrollController: _scrollController,
                      isSelectionMode: true,
                      onFolderTap: (id) => _onFolderSelected(id.toString()),
                      movingFileId: widget.movingfileid,
                    ),
                    DriveStarredPage(
                      scrollController: _scrollController,
                      onFolderTap: (id) => _onFolderSelected(id.toString()),
                      movingFileId: widget.movingfileid,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (selectedFolderId != null)
                          Text(
                            'Selected ID: $selectedFolderId',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ElevatedButton(
                          onPressed: () => _onMoveHereTap(context),
                          child: const Text('Move Here'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
