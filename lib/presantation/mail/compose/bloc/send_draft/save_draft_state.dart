  import 'package:equatable/equatable.dart';

  abstract class DraftState extends Equatable {
    @override
    List<Object?> get props => [];
  }

  class DraftInitial extends DraftState {}

  class DraftSaving extends DraftState {}

  class DraftSaved extends DraftState {}

  class DraftError extends DraftState {
    final String message;
    DraftError(this.message);

    @override
    List<Object?> get props => [message];
  }
