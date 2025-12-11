import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MeetSocket {
  IO.Socket? _socket;
  bool _isConnected = false;

  Future<void> connect({
    required String token,
    required String userId,
  }) async {
    if (_isConnected) return;

    _socket = IO.io(
      'https://api.nowdigitaleasy.com/meet',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/meet/socket.io')
          .setQuery({
            'token': token,
            'userId': userId,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _socket!.emit('authenticate', {'token': token, 'userId': userId});
      log("✅ Socket connected: ${_socket!.id}");
    });

    _socket!.on('authenticated', (_) {
      _socket!.emit('join', {'roomID': _socket!.id});
    });

    _socket!.onDisconnect((_) => _isConnected = false);
    _socket!.onConnectError((err) => print('Socket error: $err'));
    _socket!.onError((err) => print('Socket error: $err'));

    _socket!.connect();
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  Future<dynamic> emitWithAck(String event, dynamic data) async {
    return _socket!.emitWithAck(event, data);
  }

  void emit(String event, dynamic data) {
    if (_isConnected) {
      _socket?.emit(event, data);
    }
  }

  void off(String event, Function(dynamic)? callback) {
    _socket?.off(event, callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
  }
}
