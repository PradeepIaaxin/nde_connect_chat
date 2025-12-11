import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/compose/api_service.dart';
import 'save_draft_state.dart';
import 'save_dratf_event.dart';





class DraftBloc extends Bloc<DraftEvent, DraftState> {
  final ApiService apiService;
  int? lastDraftId; 

  DraftBloc({required this.apiService}) : super(DraftInitial()) {
    on<SaveDraftEvent>(_saveDraft);
  }

  Future<void> _saveDraft(SaveDraftEvent event, Emitter<DraftState> emit) async {
    emit(DraftSaving());
    try {
      
      if (lastDraftId != null) {
        event.draftData["replacePrevious"] = {
          "mailbox": event.mailboxId,
          "id": lastDraftId.toString(),
        };
      }

      int? draftId = await apiService.saveDraft(event.mailboxId, event.draftData);

      if (draftId != null) {
        lastDraftId = draftId; 
        emit(DraftSaved());
      } else {
        emit(DraftError("Failed to save draft"));
      }
    } catch (e) {
      emit(DraftError(e.toString()));
    }
  }
}