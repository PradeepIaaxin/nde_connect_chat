// ignore_for_file: use_build_context_synchronously

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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class UploadToDriveScreen extends StatefulWidget {
  final List<PlatformFile>? selectedFiles;
  final String? parentId;
  final int? currentIndex;
  final bool isScanner;
  const UploadToDriveScreen({
    super.key,
    this.selectedFiles,
    this.parentId,
    this.currentIndex,
    this.isScanner = false,
  });

  @override
  _UploadToDriveScreenState createState() => _UploadToDriveScreenState();
}

class _UploadToDriveScreenState extends State<UploadToDriveScreen> {
  List<PlatformFile> selectedFiles = [];
  List<TextEditingController> controllers = [];
  String selectedLocation = 'My Drive';

  bool _isUploading = false;
  bool isScanner = false; // passed from previous screen
  String scannerFormat = "pdf"; // pdf OR jpeg
  @override
  void initState() {
    super.initState();
    isScanner = widget.isScanner;

    if (widget.selectedFiles != null) {
      selectedFiles = widget.selectedFiles!;
      _initControllers();
    }
  }

  void _initControllers() {
    controllers = selectedFiles.map((file) {
      var fileName = file.name;
      if (isScanner) {
        fileName = _replaceExtension(fileName, scannerFormat); // ✅ forces .pdf initially
      }
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

  String _replaceExtension(String name, String format) {
    final base = name.split('.').first;

    if (format == "pdf") {
      return "$base.pdf";
    } else {
      return "$base.jpeg";
    }
  }

  Future<Uint8List> createPdfFromImage(Uint8List imageBytes) async {
    final pdf = pw.Document();

    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    return pdf.save();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            showMoveToBinDialog(context);
          },
            child:Padding(
              padding: const EdgeInsets.all(18.0),
              child: Image.asset("assets/images/cancel_icon.png",width: 40,height: 40,),
            )),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Upload to Drive',
            style: TextStyle(color: Colors.black)),
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
                  if (isScanner && scannerFormat == "pdf") {
                    if (file.bytes == null) {
                      log("Scanner PDF ERROR → No bytes found");
                      continue;
                    }
                    final pdfBytes = await createPdfFromImage(file.bytes!);

                    final pdfFile = PlatformFile(
                      name: fileName,
                      size: pdfBytes.length,
                      bytes: pdfBytes,
                    );

                    context.read<CreateFolderBloc>().add(
                      UploadFiles(
                        file: pdfFile,
                        parentId: widget.parentId,
                        fileName: fileName,
                      ),
                    );
                  }
                  else {
                    context.read<CreateFolderBloc>().add(
                      UploadFiles(
                        file: file,
                        parentId: widget.parentId,
                        fileName: fileName,
                      ),
                    );
                  }
                }
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
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Upload',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
          )
        ],
      ),
      body: BlocListener<CreateFolderBloc, CreateFolderState>(
        listener: (context, state) {
          if (state is UploadFilesSuccess || state is ReplaceFilesSuccess) {
            log(">>>>>>.");

            context.read<MyDriveBloc>().add(FetchMyDriveFolders());
            Navigator.pop(context, true);
          }
          if (state is CreateFolderConflict) {
            showDialog(
              context: context,
              builder: (context) => FileConflictDialog(
                title: "A file with this name already exists",
                onConfirmed: (selectedOption) {
                  for (int i = 0; i < selectedFiles.length; i++) {
                    final file = selectedFiles[i];

                    context.read<CreateFolderBloc>().add(
                      ReplaceFiles(
                        file: file,
                        selectedOne: selectedOption == FileConflictOption.replace
                            ? "replace"
                            : "keepboth",
                        parentId: widget.parentId ?? '',
                        fileName: controllers[i].text.trim(),   // ✅ CRITICAL
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
                    return TextFormField(
                      controller: controllers[index],
                      readOnly: false,
                      showCursor: true,
                      inputFormatters: isScanner
                          ? [
                              _ScannerFileNameFormatter(
                                getExtension: () =>
                                    scannerFormat == "pdf" ? ".pdf" : ".jpeg",
                              ),
                            ]
                          : [
                              FilteringTextInputFormatter.deny(
                                  RegExp(r'[\\/:*?"<>|]')),
                            ],
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.insert_drive_file,
                            color: Colors.red),
                        hintText: 'File name',
                        labelText: 'File name',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _clearSelectedFileAt(index),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintStyle: const TextStyle(color: Colors.white38),
                        labelStyle: const TextStyle(color: Colors.black),
                      ),
                      style: const TextStyle(color: Colors.black),
                      cursorColor: Colors.white,
                    );
                  },
                ),
              if (isScanner) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _formatButton("PDF", "pdf"),
                    const SizedBox(width: 10),
                    _formatButton("JPEG", "jpeg"),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                dropdownColor: Colors.white,
                items: ['My Drive', 'Shared Folder', 'Team Drive'].map(
                  (loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.black),
                          const SizedBox(width: 10),
                          Text(loc,
                              style: const TextStyle(color: Colors.black)),
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
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
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

  Widget _formatButton(String label, String format) {
    final selected = scannerFormat == format;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            scannerFormat = format;

            for (int i = 0; i < controllers.length; i++) {
              controllers[i].text =
                  _replaceExtension(controllers[i].text, format);
            }
          });
        },
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
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
        child: Icon(Icons.insert_drive_file, size: 50, color: Colors.black),
      );
    }
  }
}


class _ScannerFileNameFormatter extends TextInputFormatter {
  final String Function() getExtension;

  _ScannerFileNameFormatter({required this.getExtension});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final ext = getExtension();

    final base = newValue.text.split('.').first;
    final corrected = "$base$ext";

    return TextEditingValue(
      text: corrected,
      selection: TextSelection.collapsed(offset: base.length),
    );
  }
}

void showMoveToBinDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54, // dim background
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 350,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cancel upload?",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your file won't be saved to Drive",
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel upload",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
