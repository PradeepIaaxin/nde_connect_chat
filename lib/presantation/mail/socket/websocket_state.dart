import 'package:equatable/equatable.dart';

import 'package:nde_email/presantation/mail/socket/websocket_model.dart';

abstract class WebSocketState extends Equatable {
  const WebSocketState();

  @override
  List<Object> get props => [];
}

class WebSocketInitial extends WebSocketState {}

class WebSocketConnected extends WebSocketState {}

class WebSocketMessageReceived extends WebSocketState {
  final List<NotificationModel> notifications;

  const WebSocketMessageReceived(this.notifications);

  @override
  List<Object> get props => [notifications];
}
