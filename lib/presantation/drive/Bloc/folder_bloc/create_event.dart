import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

abstract class CreateFolderEvent {}

class CreateFolderPressed extends CreateFolderEvent {
  final String name;
  final String? parentId;
  final BuildContext context;
  CreateFolderPressed(
      {required this.name, this.parentId, required this.context});
}

class UploadFiles extends CreateFolderEvent {
  final PlatformFile? file;
  final String? parentId;

  UploadFiles({required this.file, this.parentId});
}

class ReplaceFiles extends CreateFolderEvent {
  final PlatformFile? file;
  final String? selectedOne;
  final String? parentId;

  ReplaceFiles({this.selectedOne, required this.file, this.parentId});
}
