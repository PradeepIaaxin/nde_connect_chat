import 'package:flutter_bloc/flutter_bloc.dart';
import 'email_suggestions_event.dart';
import 'email_suggestions_state.dart';
import 'email_suggestions_api.dart';
import 'email_suggestions_model.dart';


class EmailSuggestionsBloc extends Bloc<EmailSuggestionsEvent, EmailSuggestionsState> {
  final MailRepository repository;

  EmailSuggestionsBloc(this.repository) : super(EmailSuggestionsInitial()) {
    on<FetchEmailSuggestions>((event, emit) async {
      emit(EmailSuggestionsLoading());
      try {
        final List<User> suggestions = await repository.fetchEmailSuggestions(event.query);
        emit(EmailSuggestionsLoaded(suggestions));
      } catch (e) {
        emit(EmailSuggestionsError('Failed to load suggestions'));
      }
    });
  }
}
