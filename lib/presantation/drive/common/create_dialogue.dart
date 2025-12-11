import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_event.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_folder_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_state.dart';

class NewBoxDialog extends StatelessWidget {
  final TextEditingController folderName = TextEditingController();
  final String? parentId;

  NewBoxDialog({super.key, this.parentId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateFolderBloc, CreateFolderState>(
      listener: (context, state) {
        if (state is CreateFolderSuccess) {
          Navigator.pop(context, true);
        } else if (state is CreateFolderFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        title: const Text(
          'Create Folder',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: SizedBox(
          height: 120,
          child: Column(
            children: [
              TextField(
                controller: folderName,
                decoration: InputDecoration(
                  hintText: 'Enter folder name',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<CreateFolderBloc, CreateFolderState>(
                builder: (context, state) {
                  if (state is CreateFolderLoading) {
                    return const CircularProgressIndicator();
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          final name = folderName.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Folder name is required')),
                            );
                            return;
                          }

                          context.read<CreateFolderBloc>().add(
                                CreateFolderPressed(
                                  name: name,
                                  parentId: parentId ?? "",
                                  context: context,
                                ),
                              );
                        },
                        child: const Text(
                          'Create',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
