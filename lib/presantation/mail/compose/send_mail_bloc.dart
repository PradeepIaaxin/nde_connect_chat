import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'send_mail_event.dart';
import 'send_mail_state.dart';
import 'package:nde_email/presantation/mail/compose/api_service.dart';

class SendMailBloc extends Bloc<SendMailEvent, SendMailState> {
  final ApiService apiService;

  SendMailBloc({required this.apiService}) : super(SendMailInitial()) {
    on<SendMailRequest>(_onSendMail);
  }

  Future<void> _onSendMail(
      SendMailRequest event, Emitter<SendMailState> emit) async {
    emit(MailSending());

    try {
      String? draftMailboxId = await MailboxStorage.getDraftsMailboxId();
      if (draftMailboxId == null || draftMailboxId.isEmpty) {
        emit(MailSendError("Drafts mailbox ID is missing"));
        return;
      }

      log("Using Drafts Mailbox ID: $draftMailboxId");

      bool success = await apiService.sendEmail(
        fromEmail: event.fromEmail,
        to: event.to,
        ccEmail: event.cc,
        bccEmail: event.bcc,
        subject: event.subject,
        body: event.body,
      );

      if (success) {
        emit(MailSent());
      } else {
        emit(MailSendError("Failed to send email."));
      }
    } catch (e) {
      emit(MailSendError("Error: ${e.toString()}"));
    }
  }
}
