import 'package:equatable/equatable.dart';

abstract class EmailSuggestionsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchEmailSuggestions extends EmailSuggestionsEvent {
  final String query;

  FetchEmailSuggestions(this.query);

  @override
  List<Object?> get props => [query];
}
