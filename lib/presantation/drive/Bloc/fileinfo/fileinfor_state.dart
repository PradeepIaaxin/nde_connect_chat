import 'package:nde_email/presantation/drive/model/folderinfo_model.dart';

abstract class FileDetailState {}

class InfoDetailsInitial extends FileDetailState {}

class InfoDetailsLoading extends FileDetailState {}

class InfoDetailsLoaded extends FileDetailState {
  final List<INfoModelItem> infoResponse;

  InfoDetailsLoaded(this.infoResponse);
}

class InfoDetailsError extends FileDetailState {
  final String message;

  InfoDetailsError(this.message);
}
