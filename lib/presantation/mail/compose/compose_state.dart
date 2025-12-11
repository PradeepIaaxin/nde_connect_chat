import 'package:equatable/equatable.dart';

abstract class ComposeState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Initial State
class ComposeInitial extends ComposeState {}

// Loading State
class ComposeLoading extends ComposeState {}

// Success State
class ComposeSuccess extends ComposeState {
  final String message;
  ComposeSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Error State
class ComposeError extends ComposeState {
  final String message;
  ComposeError(this.message);

  @override
  List<Object?> get props => [message];
}

// State for sender email
class SenderEmailLoaded extends ComposeState {
  final String email;
  SenderEmailLoaded(this.email);

  @override
  List<Object?> get props => [email];
}
 