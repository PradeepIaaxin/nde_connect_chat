import 'package:equatable/equatable.dart';

abstract class FatchnameState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Initial State
class FatchnameInitial extends FatchnameState  {}

// Loading State
class FatchnameLoading extends FatchnameState  {}

// Success State
class FatchnameSuccess extends FatchnameState  {
  final String message;
  FatchnameSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Error State


class FatchnameError extends FatchnameState {
  final String message;
  FatchnameError(this.message);

  @override
  List<Object?> get props => [message];
}


// State for sender email
class FatchnameEmailLoaded extends FatchnameState  {
  final String email;
 FatchnameEmailLoaded(this.email);

  @override
  List<Object?> get props => [email];
}
 