import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/Socket/socket_bloc/socket_states.dart';
import 'socket_event.dart';

import '../../Socket/Socket_Service.dart';

class SocketBloc extends Bloc<SocketEvent, SocketState> {
  final SocketService socketService;

  SocketBloc(this.socketService) : super(SocketInitial()) {
    /// 🔌 Connect
    on<ConnectSocketEvent>((event, emit) async {
      emit(SocketConnecting());
      try {
        await socketService.ensureConnected();
        emit(SocketConnected());
      } catch (e) {
        emit(SocketError(e.toString()));
      }
    });

    /// 🔌 Disconnect
    on<DisconnectSocketEvent>((event, emit) async {
      socketService.disconnect();
      emit(SocketDisconnected());
    });

    /// 🔄 Reconnect manually
    on<ReconnectSocketEvent>((event, emit) async {
      emit(SocketConnecting());
      try {
        await socketService.ensureConnected();
        emit(SocketConnected());
      } catch (e) {
        emit(SocketError(e.toString()));
      }
    });

    /// 📡 Online Status Update
    socketService.onlineStatusStream.listen((isOnline) {
      add(SocketStatusChangedEvent(isOnline));
    });

    on<SocketStatusChangedEvent>((event, emit) {
      emit(SocketStatusUpdated(event.isOnline));
    });
  }
}
