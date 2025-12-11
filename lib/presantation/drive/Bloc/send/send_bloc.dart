import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/send/send_events.dart'
    show ShareEvent, ShareFileEvent;

import 'package:nde_email/presantation/drive/Bloc/send/send_state.dart';
import 'package:nde_email/presantation/drive/data/common_repo.dart';

class ShareBloc extends Bloc<ShareEvent, ShareState> {
  ShareBloc() : super(ShareInitial()) {
    on<ShareFileEvent>(_onShareFile);
  }

  Future<void> _onShareFile(
      ShareFileEvent event, Emitter<ShareState> emit) async {
    emit(ShareLoading());

    try {
      await FoldersRepository().shareFileWithUsers(
        fileId: event.fileId,
        emails: event.emails,
        permission: event.permission,
        notify: event.notify,
        message: event.message,
      );
      emit(ShareSuccess());
    } catch (e) {
      emit(ShareFailure(e.toString()));
    }
  }
}
