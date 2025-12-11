import 'package:equatable/equatable.dart';

abstract class SocketState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SocketInitial extends SocketState {}

class SocketConnecting extends SocketState {}

class SocketConnected extends SocketState {}

class SocketDisconnected extends SocketState {}

class SocketError extends SocketState {
  final String message;
  SocketError(this.message);

  @override
  List<Object?> get props => [message];
}

class SocketStatusUpdated extends SocketState {
  final bool isOnline;
  SocketStatusUpdated(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}