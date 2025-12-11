import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'websocket_event.dart';
import 'websocket_state.dart';
import 'package:nde_email/domain/sockets/mail_socket/socket.dart';
import 'package:nde_email/presantation/mail/socket/websocket_model.dart';
import 'dart:convert';
import 'package:nde_email/domain/sockets/mail_socket/nottification.dart';

class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final WebSocketService socketService;
  final List<NotificationModel> notifications = [];

  WebSocketBloc(this.socketService) : super(WebSocketInitial()) {
    on<ConnectWebSocket>((event, emit) async {
      await socketService.connect();
      emit(WebSocketConnected());

      // Add a delay before listening to avoid race conditions
      Future.delayed(Duration(seconds: 1), () {
        socketService.messages.listen((message) {
          add(ReceiveMessage(message));
        });
      });
    });

    Future<void> _handleNotification(
      Map<String, dynamic> data,
      Emitter emit,
    ) async {
      final newNotification = NotificationModel.fromJson(data);
      notifications.add(newNotification);

      String senderName = newNotification.fromName ?? "Unknown";
      String senderEmail = newNotification.fromAddress ?? "Unknown";

      await NotificationService.showNotification(
        title: '📧 $senderName',
        body: 'Email: $senderEmail\n${newNotification.message}',
      );

      emit(WebSocketMessageReceived(List.from(notifications)));
    }

    on<ReceiveMessage>((event, emit) async {
      try {
        final decoded = jsonDecode(event.message);

        if (decoded is List && decoded.isNotEmpty) {
          // If the message is a LIST, take first element
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              await _handleNotification(item, emit);
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          // If the message is a MAP (normal case)
          await _handleNotification(decoded, emit);
        } else {
          log("Unknown message format: $decoded");
        }
      } catch (e) {
        log("  Error parsing message: $e");
      }
    });
  }

  @override
  Future<void> close() {
    socketService.dispose();
    return super.close();
  }
}
