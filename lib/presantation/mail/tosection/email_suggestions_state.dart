import 'package:equatable/equatable.dart';
import 'email_suggestions_model.dart';









abstract class EmailSuggestionsState extends Equatable {
  @override
  List<Object> get props => [];
}

class EmailSuggestionsInitial extends EmailSuggestionsState {}

class EmailSuggestionsLoading extends EmailSuggestionsState {}

class EmailSuggestionsLoaded extends EmailSuggestionsState {
  final List<User> suggestions;

  EmailSuggestionsLoaded(this.suggestions);

  @override
  List<Object> get props => [suggestions];
}

class EmailSuggestionsError extends EmailSuggestionsState {
  final String message;

  EmailSuggestionsError(this.message);

  @override
  List<Object> get props => [message];
}