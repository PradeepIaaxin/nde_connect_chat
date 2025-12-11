import 'package:equatable/equatable.dart';

abstract class SocketEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 🔌 Connect after login
class ConnectSocketEvent extends SocketEvent {}

/// 🔌 Disconnect on logout
class DisconnectSocketEvent extends SocketEvent {}

/// 🔄 Reconnect if connection lost
class ReconnectSocketEvent extends SocketEvent {}

/// 📡 Toggle Online Status Update
class SocketStatusChangedEvent extends SocketEvent {
  final bool isOnline;
  SocketStatusChangedEvent(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}