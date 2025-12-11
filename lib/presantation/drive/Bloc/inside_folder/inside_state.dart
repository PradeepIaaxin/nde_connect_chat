import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/drive/model/folderinside_model.dart';

abstract class InsidefileState {}

class InsideInitial extends InsidefileState {}

class InsideLoading extends InsidefileState {}

class InsideError extends InsidefileState {
  final String message;
  InsideError(this.message);
}

class InsideLoaded extends InsidefileState {
  final List<FolderinsideModel> folders;
  final bool hasMore;

  InsideLoaded(this.folders, this.hasMore);
}
