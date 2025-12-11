import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class EmailChanged extends LoginEvent {
  final String email;

  const EmailChanged({required this.email});

  @override
  List<Object> get props => [email];
}

class PasswordChanged extends LoginEvent {
  final String password;

  const PasswordChanged({required this.password});

  @override
  List<Object> get props => [password];
}

class LoginApi extends LoginEvent {
  final String email;
  final String password;

  const LoginApi({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LoginLoggedOut extends LoginEvent {
  const LoginLoggedOut();
}

class ClearLoginError extends LoginEvent {
  const ClearLoginError();

  @override
  List<Object> get props => [];
}

class LoginStatusReset extends LoginEvent {}

class LoginRefresh extends LoginEvent {}


class EmailSubmit extends LoginEvent {
  final String email;
  EmailSubmit({required this.email});
}