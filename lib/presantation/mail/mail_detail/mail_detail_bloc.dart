
import 'package:bloc/bloc.dart';
import 'mail_detail_event.dart';
import 'mail_detail_state.dart';
import 'mail_detail_api.dart';



class MailDetailBloc extends Bloc<MailDetailEvent, MailDetailState> {
  final fatchdetailmailapi apiService;

  MailDetailBloc({required this.apiService}) : super(MailDetailInitial()) {
    on<FetchMailDetailEvent>((event, emit) async {
      emit(MailDetailLoading());

      try {
        final mailDetail = await apiService.fetchMailDetail(event.mailboxId, event.messageId);
        emit(MailDetailLoaded(mailDetail));
      } catch (e) {
        emit(MailDetailError("${e.toString()}"));
      }
    });
  }
}