import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/my_drive_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_event.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_event.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_folder_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_state.dart';
import 'package:nde_email/presantation/drive/common/alertbox.dart';
import 'package:nde_email/utils/router/router.dart';

class UploadToDriveScreen extends StatefulWidget {
  final List<PlatformFile>? selectedFiles;
  final String? parentId;

  const UploadToDriveScreen({super.key, this.selectedFiles, this.parentId});

  @override
  _UploadToDriveScreenState createState() => _UploadToDriveScreenState();
}

class _UploadToDriveScreenState extends State<UploadToDriveScreen> {
  List<PlatformFile> selectedFiles = [];
  List<TextEditingController> controllers = [];
  String selectedLocation = 'My Drive';

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedFiles != null) {
      selectedFiles = widget.selectedFiles!;
      _initControllers();
    }
  }

  void _initControllers() {
    controllers = selectedFiles.map((file) {
      final fileName = file.name;
      final dotIndex = fileName.lastIndexOf('.');
      if (dotIndex != -1) {
        final nameWithoutExt = fileName.substring(0, dotIndex);
        final extension = fileName.substring(dotIndex);
        return TextEditingController(text: nameWithoutExt + extension);
      } else {
        return TextEditingController(text: file.name);
      }
    }).toList();
  }

  Future<void> pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFiles = result.files;
        _initControllers();
      });
    }
  }

  void _clearSelectedFileAt(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Upload to Drive',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () async {
              if (selectedFiles.isEmpty) return;

              setState(() => _isUploading = true);

              try {
                for (int i = 0; i < selectedFiles.length; i++) {
                  final file = selectedFiles[i];
                  final fileName = controllers[i].text.trim();

                  log('Uploading: $fileName');

                  context.read<CreateFolderBloc>().add(
                        UploadFiles(
                          file: file,
                          parentId: widget.parentId,
                        ),
                      );
                }

                // Close upload screen and refresh drive folders
                MyRouter.pop();
                context.read<MyDriveBloc>().add(FetchMyDriveFolders());
              } catch (e) {
                log("Upload failed: $e");

                context.read<MyDriveBloc>().add(FetchMyDriveFolders());
              } finally {
                setState(() => _isUploading = false);
              }
            },
            child: _isUploading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Upload',
                    style: TextStyle(color: Colors.white),
                  ),
          )
        ],
      ),
      body: BlocListener<CreateFolderBloc, CreateFolderState>(
        listener: (context, state) {
          if (state is CreateFolderConflict) {
            showDialog(
              context: context,
              builder: (context) => FileConflictDialog(
                title: "A file with this name already exists",
                onConfirmed: (selectedOption) {
                  for (final file in selectedFiles) {
                    context.read<CreateFolderBloc>().add(
                          ReplaceFiles(
                            file: file,
                            selectedOne:
                                selectedOption == FileConflictOption.replace
                                    ? "replace"
                                    : "keepboth",
                            parentId: widget.parentId ?? '',
                          ),
                        );
                  }
                },
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: pickFiles,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Pick Files",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              const SizedBox(height: 10),
              if (selectedFiles.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedFiles.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildFilePreview(selectedFiles[index]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              if (selectedFiles.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final file = selectedFiles[index];
                    final ext = file.extension ?? '';
                    return TextFormField(
                      controller: controllers[index],
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.insert_drive_file,
                            color: Colors.red),
                        hintText: 'File name',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _clearSelectedFileAt(index),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintStyle: const TextStyle(color: Colors.white38),
                      ),
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [
                        _FileNameWithExtensionFormatter(extension: ".$ext"),
                        FilteringTextInputFormatter.deny(
                            RegExp(r'[\\/:*?"<>|]')),
                      ],
                      cursorColor: Colors.white,
                    );
                  },
                ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedLocation,
                dropdownColor: Colors.grey[900],
                items: ['My Drive', 'Shared Folder', 'Team Drive'].map(
                  (loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(loc,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedLocation = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(PlatformFile file) {
    final ext = file.extension?.toLowerCase();
    if ((ext == 'jpg' || ext == 'jpeg' || ext == 'png') && file.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(file.bytes!, fit: BoxFit.cover),
      );
    } else {
      return const Center(
        child: Icon(Icons.insert_drive_file, size: 50, color: Colors.white),
      );
    }
  }
}

class _FileNameWithExtensionFormatter extends TextInputFormatter {
  final String extension;

  _FileNameWithExtensionFormatter({required this.extension});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (extension.isEmpty) return newValue;

    final newText = newValue.text;

    if (!newText.endsWith(extension)) {
      String base = newText.replaceAll(extension, '');
      final corrected = base + extension;
      final cursorPos = corrected.length - extension.length;

      return TextEditingValue(
        text: corrected,
        selection: TextSelection.collapsed(offset: cursorPos),
      );
    }
    return newValue;
  }
}
