import 'package:equatable/equatable.dart';

abstract class WebSocketEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ConnectWebSocket extends WebSocketEvent {}

class DisconnectWebSocket extends WebSocketEvent {}

class ReceiveMessage extends WebSocketEvent {
  final String message;

  ReceiveMessage(this.message);

  @override
  List<Object> get props => [message];
}
