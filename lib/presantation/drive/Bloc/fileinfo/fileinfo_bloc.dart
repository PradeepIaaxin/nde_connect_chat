import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/fileinfo/fileinfo_event.dart';
import 'package:nde_email/presantation/drive/Bloc/fileinfo/fileinfor_state.dart';
import 'package:nde_email/presantation/drive/data/info_repository.dart';
import 'package:nde_email/presantation/drive/model/folderinfo_model.dart';

class InfoDetailsBloc extends Bloc<FileDetailEvent, FileDetailState> {
  final MyInfoRepository repository;

  InfoDetailsBloc(this.repository) : super(InfoDetailsInitial()) {
    on<FetchInfoDetails>(_onLoadStarredFolders);
  }

  Future<void> _onLoadStarredFolders(
      FetchInfoDetails event, Emitter<FileDetailState> emit) async {
    emit(InfoDetailsLoading());
    try {
      final FolderResponse? folderResponse =
          await repository.fetchStarredFolders(fileId: event.fileID);

      if (folderResponse != null) {
        emit(InfoDetailsLoaded(folderResponse.data));
      } else {
        emit( InfoDetailsError('No data available'));
      }
    } catch (e) {
      emit(InfoDetailsError('Error: $e'));
    }
  }
}
