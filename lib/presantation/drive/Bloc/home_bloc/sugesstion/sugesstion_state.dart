import 'package:nde_email/presantation/drive/model/home/suggestion/suggestion_model.dart';

abstract class SuggestionsState {}

class SuggestionsInitial extends SuggestionsState {}

class SuggestionsLoading extends SuggestionsState {}

class SuggestionsLoaded extends SuggestionsState {
  final List<FileModel> suggestions;
  final bool hasMore;
  final String? errorMessage;

  SuggestionsLoaded(this.suggestions, this.hasMore, this.errorMessage);
}

class SuggestionsError extends SuggestionsState {
  final String message;

  SuggestionsError(this.message);
}
