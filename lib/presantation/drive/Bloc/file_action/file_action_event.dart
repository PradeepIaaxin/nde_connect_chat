import 'package:equatable/equatable.dart';

abstract class FileOperationsEvent extends Equatable {
  const FileOperationsEvent();

  @override
  List<Object> get props => [];
}

class StarFileEvent extends FileOperationsEvent {
  final String fileId;
  final bool starred;

  const StarFileEvent({required this.fileId, required this.starred});

  @override
  List<Object> get props => [fileId, starred];
}

class RenameFileEvent extends FileOperationsEvent {
  final String fileId;
  final String newName;

  const RenameFileEvent({required this.fileId, required this.newName});

  @override
  List<Object> get props => [fileId, newName];
}

class DeleteFileEvent extends FileOperationsEvent {
  final String fileId;

  const DeleteFileEvent({required this.fileId});

  @override
  List<Object> get props => [fileId];
}

class DownloadFileEvent extends FileOperationsEvent {
  final String fileId;

  const DownloadFileEvent({required this.fileId});

  @override
  List<Object> get props => [fileId];
}

class OrganizeEvent extends FileOperationsEvent {
  final List<String> fileIDs;
  final String pickedColor;
  const OrganizeEvent({required this.fileIDs, required this.pickedColor});
}
