import 'package:equatable/equatable.dart';

abstract class FileOperationsState extends Equatable {
  const FileOperationsState();

  @override
  List<Object> get props => [];
}

class FileOperationsInitial extends FileOperationsState {}

class FileOperationSuccess extends FileOperationsState {
  final String? message;

  const FileOperationSuccess([this.message]);

  @override
  List<Object> get props => [message ?? ''];
}

class FileOperationError extends FileOperationsState {
  final String message;

  const FileOperationError(this.message);

  @override
  List<Object> get props => [message];
}
