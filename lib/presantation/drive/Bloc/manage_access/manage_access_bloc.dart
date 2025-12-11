// manage_access_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/manage_access/manage_event.dart';
import 'package:nde_email/presantation/drive/Bloc/manage_access/manage_state.dart';

import 'package:nde_email/presantation/drive/data/common_repo.dart';

class ManageAccessBloc extends Bloc<ManageAccessEvent, ManageAccessState> {
  ManageAccessBloc() : super(ManageAccessInitial()) {
    on<FetchShareDetailsEvent>((event, emit) async {
      try {
        final details = await FoldersRepository().getShareDetails(event.fileId);
        emit(ManageAccessLoaded(details));
      } catch (e) {
        emit(ManageAccessError(e.toString()));
      }
    });
  }
}
