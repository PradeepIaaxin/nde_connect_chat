import 'package:equatable/equatable.dart';


enum LoginStatus { initial, loading, success, failure, errorScreen, backendErrorScreen,networkErrorScreen ,failureSnackbar,hasSubmitted,loggedOut}


 class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.message = '',
    this.status = LoginStatus.initial,
    this.hasSubmitted = false,
   
  });

  final String email;
  final String password;
  final String message;
  final LoginStatus status;
   final bool hasSubmitted;
  

  LoginState copyWith({
    String? email,
    String? password,
    String? message,
    LoginStatus? status,
     bool? hasSubmitted,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      message: message ?? this.message,
      status: status ?? this.status,
        hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    );
  }

  @override
  List<Object> get props => [email, password, message, status];
}
