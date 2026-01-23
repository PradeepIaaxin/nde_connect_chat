import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/domain/sockets/mail_socket/nottification.dart';
import 'package:nde_email/domain/sockets/mail_socket/socket.dart';
import 'package:nde_email/presantation/mail/socket/websocket_model.dart';

import 'websocket_event.dart';
import 'websocket_state.dart';

class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final WebSocketService socketService;
  final List<NotificationModel> notifications = [];

  WebSocketBloc(this.socketService) : super(WebSocketInitial()) {

    /// 🔌 CONNECT SOCKET
    on<ConnectWebSocket>((event, emit) async {
      log("🟢 Bloc: ConnectWebSocket triggered");

      await socketService.connect();

      log("✅ Bloc: Socket connect() called");
      emit(WebSocketConnected());

      // Delay to avoid race condition
      Future.delayed(const Duration(seconds: 1), () {
        log("👂 Bloc: Listening to socket messages");

        socketService.messages.listen((message) {
          log("📩 Bloc: RAW message received → $message");
          add(ReceiveMessage(message));
        });
      });
    });

    /// 🔔 HANDLE NOTIFICATION
    Future<void> handleNotification(
      Map<String, dynamic> data,
      Emitter<WebSocketState> emit,
    ) async {
      log("📦 Bloc: Handling notification JSON → $data");

      final newNotification = NotificationModel.fromJson(data);
      notifications.add(newNotification);

      log("👤 From Name: ${newNotification.fromName}");
      log("📧 From Email: ${newNotification.fromAddress}");
      log("💬 Message: ${newNotification.message}");
      log("📊 Total notifications: ${notifications.length}");

      String senderName = newNotification.fromName;
      String senderEmail = newNotification.fromAddress;

      await NotificationService.showNotification(
        title: '📧 $senderName',
        body: 'Email: $senderEmail\n${newNotification.message}',
      );

      emit(WebSocketMessageReceived(List.from(notifications)));
      log("📤 Bloc: WebSocketMessageReceived emitted");
    }

    /// 📥 RECEIVE MESSAGE
    on<ReceiveMessage>((event, emit) async {
      try {
        log("🧩 Bloc: Decoding message");

        final decoded = jsonDecode(event.message);
        log("🔍 Decoded type: ${decoded.runtimeType}");

        if (decoded is List && decoded.isNotEmpty) {
          log("📚 Bloc: Message is LIST (${decoded.length} items)");

          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              await handleNotification(item, emit);
            } else {
              log("⚠️ Bloc: List item not Map → $item");
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          log("🗂 Bloc: Message is MAP");
          await handleNotification(decoded, emit);
        } else {
          log("❓ Bloc: Unknown message format → $decoded");
        }
      } catch (e, stack) {
        log("❌ Bloc: Error parsing message → $e");
        log("📌 StackTrace → $stack");
      }
    });
  }

  @override
  Future<void> close() {
    log("🔴 Bloc: Closing WebSocketBloc");
    socketService.dispose();
    return super.close();
  }
}
