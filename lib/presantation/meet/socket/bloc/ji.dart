// // lib/meeting_state_logic.dart

// import 'dart:async';
// import 'dart:developer' as developer;
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:nde_email/utils/imports/common_imports.dart';

// // --- State Definitions (using ValueNotifier) ---

// enum ConnectionStatus {
//   connecting,
//   authenticated,
//   loadingDevice,
//   deviceLoaded,
//   joiningRoom,
//   roomJoined,
//   mediaStarted,
//   connected,
//   disconnected,
//   error,
// }

// class StreamInfo {
//   final String producerId;
//   final String socketId;
//   String? peerName;
//   RTCVideoRenderer? renderer;
//   MediaStream? stream;
//   Consumer? consumer;

//   StreamInfo({
//     required this.producerId,
//     required this.socketId,
//     this.peerName,
//     this.renderer,
//     this.stream,
//     this.consumer,
//   });
// }

// class MeetingState {
//   final ValueNotifier<ConnectionStatus> statusNotifier =
//       ValueNotifier(ConnectionStatus.connecting);
//   final ValueNotifier<String> statusMessageNotifier =
//       ValueNotifier('Connecting...');
//   final ValueNotifier<String?> localUserIdNotifier = ValueNotifier(null);
//   final ValueNotifier<MediaStream?> localStreamNotifier = ValueNotifier(null);
//   final ValueNotifier<RTCVideoRenderer> localRendererNotifier =
//       ValueNotifier(RTCVideoRenderer());
//   final ValueNotifier<bool> micEnabledNotifier = ValueNotifier(true);
//   final ValueNotifier<bool> videoEnabledNotifier = ValueNotifier(true);
//   final ValueNotifier<bool> isFrontCameraNotifier = ValueNotifier(true);
//   final ValueNotifier<bool> speakerOnNotifier = ValueNotifier(false);
//   final ValueNotifier<bool> bluetoothRequestedNotifier = ValueNotifier(false);
//   final ValueNotifier<Map<String, dynamic>> peersNotifier = ValueNotifier({});
//   final ValueNotifier<Map<String, StreamInfo>> remoteStreamsNotifier =
//       ValueNotifier({});

//   void dispose() {
//     statusNotifier.dispose();
//     statusMessageNotifier.dispose();
//     localUserIdNotifier.dispose();
//     localStreamNotifier.dispose();
//     localRendererNotifier.dispose();
//     micEnabledNotifier.dispose();
//     videoEnabledNotifier.dispose();
//     isFrontCameraNotifier.dispose();
//     speakerOnNotifier.dispose();
//     bluetoothRequestedNotifier.dispose();
//     peersNotifier.dispose();
//     remoteStreamsNotifier.dispose();
//   }
// }

// // --- Logic Class ---

// class MeetingLogic {
//   final String _roomId;
//   final MeetingState _state;
//   final Function(String message) _showError;
//   IO.Socket? _socket;
//   Device? _mediasoupDevice;
//   Transport? _producerTransport;
//   Transport? _consumerTransport;
//   Producer? _audioProducer;
//   Producer? _videoProducer;
//   String? _token;

//   final List<Map<String, String>> _pendingProducers = [];
//   final Set<String> _consumingOrConsumed = {};
//   final Set<String> _localProducerIds = {};
//   bool _producing = false;

//   MeetingLogic(this._roomId, this._state, this._showError) {
//     _initMeeting();
//   }

//   void _updateStatus(ConnectionStatus status, String message) {
//     _state.statusNotifier.value = status;
//     _state.statusMessageNotifier.value = message;
//   }

//   Future<void> _initMeeting() async {
//     _updateStatus(ConnectionStatus.connecting, 'Connecting...');
//     final statuses = await [Permission.camera, Permission.microphone].request();
//     if (statuses[Permission.camera]?.isGranted == true &&
//         statuses[Permission.microphone]?.isGranted == true) {
//       await _initializeVideoCall();
//     } else {
//       _showError('Camera and Microphone permissions are required.');
//     }
//   }

//   Future<void> _initializeVideoCall() async {
//     try {
//       await _loadUserData();
//       if (_token != null && _state.localUserIdNotifier.value != null) {
//         await _startMediaCapture();
//         await _connectSocket();
//       } else {
//         _showError('Failed to load user data');
//       }
//     } catch (e, st) {
//       _log('Error initializing video call: $e\n$st');
//       _showError('Failed to initialize video call: $e');
//       _updateStatus(ConnectionStatus.error, 'Error: ${e.toString()}');
//     }
//   }

//   Future<void> _loadUserData() async {
//     _token = await UserPreferences.getAccessToken();
//     _state.localUserIdNotifier.value = await UserPreferences.getUserId();
//   }

//   Future<void> _startMediaCapture() async {
//     try {
//       final constraints = {
//         'audio': true,
//         'video': {'facingMode': 'user'}
//       };
//       final stream = await navigator.mediaDevices.getUserMedia(constraints);
//       final localRenderer = RTCVideoRenderer();
//       await localRenderer.initialize();
//       localRenderer.srcObject = stream;

//       _state.localStreamNotifier.value = stream;
//       _state.localRendererNotifier.value = localRenderer;
//       _updateStatus(ConnectionStatus.mediaStarted, 'Media started.');
//       _log('✅ Media stream obtained.');
//     } catch (e) {
//       _log('❌ Error accessing media devices: $e');
//       _showError('Failed to access camera/microphone: $e');
//       rethrow;
//     }
//   }

//   Future<void> _connectSocket() async {
//     try {
//       _socket = IO.io(
//         'https://api.nowdigitaleasy.com/meet',
//         IO.OptionBuilder()
//             .setTransports(['websocket'])
//             .setPath('/meet/socket.io')
//             .setQuery({'token': '$_token'})
//             .enableAutoConnect()
//             .enableReconnection()
//             .build(),
//       );
//       _setupSocketListeners();
//       _socket!.connect();
//     } catch (e) {
//       _log('Error creating socket connection: $e');
//       _showError('Failed to create socket connection: $e');
//       _updateStatus(ConnectionStatus.error, 'Socket error: $e');
//     }
//   }

//   void _setupSocketListeners() {
//     _socket!.onConnect((_) {
//       _log('✅ Socket connected successfully');
//       _socket!.emit('authenticate',
//           {'id': _state.localUserIdNotifier.value, 'token': 'Bearer $_token'});
//     });

//     _socket!.on('authenticated', (_) async {
//       _log('-- Socket authenticated');
//       _updateStatus(ConnectionStatus.authenticated, 'Authenticated.');
//       await _initializeMediasoupDevice();
//     });

//     _socket!.onDisconnect((reason) {
//       _log('❌ Socket disconnected: $reason');
//       _updateStatus(ConnectionStatus.disconnected, 'Disconnected: $reason');
//     });

//     _socket!.on('newProducer', (data) {
//       if (data is Map &&
//           data['producerID'] != null &&
//           data['socketID'] != null) {
//         _enqueueOrConsume(
//             data['producerID'].toString(), data['socketID'].toString());
//       }
//     });

//     _socket!.on('producerClosed', (data) {
//       final producerId = data is String ? data : data?['producerID'];
//       if (producerId != null) _removeConsumer(producerId.toString());
//     });

//     _socket!.on('newPeer', (data) {
//       if (data is Map && data['socketID'] != null) {
//         _addOrUpdatePeer(data);
//       }
//     });

//     _socket!.on('leave', (data) {
//       if (data != null && data['socketID'] != null) {
//         _removePeer(data['socketID']);
//       }
//     });
//   }

//   void _addOrUpdatePeer(dynamic data) {
//     final newPeers = Map<String, dynamic>.from(_state.peersNotifier.value);
//     final socketId = data['socketID'].toString();
//     final user = data['user'] ?? {};
//     final fullName =
//         '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
//     newPeers[socketId] = {'userID': data['userID'], 'name': fullName};
//     _state.peersNotifier.value = newPeers;
//   }

//   void _removePeer(String socketId) {
//     final newPeers = Map<String, dynamic>.from(_state.peersNotifier.value);
//     newPeers.remove(socketId);
//     _state.peersNotifier.value = newPeers;

//     final remoteStreams =
//         Map<String, StreamInfo>.from(_state.remoteStreamsNotifier.value);
//     remoteStreams.removeWhere((key, value) => value.socketId == socketId);
//     _state.remoteStreamsNotifier.value = remoteStreams;
//   }

//   dynamic _normalizeAck(dynamic resp) {
//     if (resp is List && resp.isNotEmpty) return resp.first;
//     return resp;
//   }

//   Future<void> _initializeMediasoupDevice() async {
//     if (_mediasoupDevice != null && _mediasoupDevice!.loaded) return;
//     _updateStatus(ConnectionStatus.loadingDevice, 'Loading device...');
//     try {
//       final rtpCaps = _normalizeAck(
//           await _socket!.emitWithAckAsync('getRouterRtpCapabilities', {}));
//       if (rtpCaps == null || rtpCaps is! Map) {
//         throw Exception('Failed to get router capabilities');
//       }
//       _mediasoupDevice = Device();
//       await _mediasoupDevice!.load(
//           routerRtpCapabilities:
//               RtpCapabilities.fromMap(Map<String, dynamic>.from(rtpCaps)));
//       _updateStatus(ConnectionStatus.deviceLoaded, 'Device loaded.');
//       await _joinRoom();
//     } catch (e, st) {
//       _log('❌ Error initializing Mediasoup device: $e\n$st');
//       _showError('Failed to initialize media device: $e');
//       _updateStatus(ConnectionStatus.error, 'Device error: $e');
//     }
//   }

//   Future<void> _joinRoom() async {
//     _updateStatus(ConnectionStatus.joiningRoom, 'Joining room...');
//     try {
//       final response = _normalizeAck(
//           await _socket!.emitWithAckAsync('join', {'roomID': _roomId}));
//       if (response == null || response is! Map) {
//         throw Exception('Failed to join room');
//       }
//       final peers = response['peers'] as Map? ?? {};
//       final producers = response['producers'] as List? ?? [];
//       final newPeers = Map<String, dynamic>.from(_state.peersNotifier.value);
//       peers.forEach((socketId, peerData) {
//         final user = peerData['user'] ?? {};
//         final fullName =
//             '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
//         newPeers[socketId] = {'userID': peerData['userID'], 'name': fullName};
//       });
//       _state.peersNotifier.value = newPeers;
//       _updateStatus(ConnectionStatus.roomJoined, 'Room joined.');
//       for (var producer in producers) {
//         final producerId = producer['producerID']?.toString();
//         final socketId = producer['socketID']?.toString();
//         if (producerId != null && socketId != null) {
//           _enqueueOrConsume(producerId, socketId);
//         }
//       }
//       await _createTransports();
//     } catch (e) {
//       _log('❌ Error joining room: $e');
//       _showError('Failed to join room: $e');
//       _updateStatus(ConnectionStatus.error, 'Join room error: $e');
//     }
//   }

//   // New callback to handle incoming Producer objects
//   void _handleNewProducer(Producer producer) {
//     _log(
//         '⚙️ Received new producer via callback: ${producer.id}, Kind: ${producer.kind}');
//     _localProducerIds.add(producer.id);
//     if (producer.kind == 'audio') {
//       _audioProducer = producer;
//     } else if (producer.kind == 'video') {
//       _videoProducer = producer;
//     }
//   }

//   Future<void> _createTransports() async {
//     if (_mediasoupDevice == null) {
//       _log('Mediasoup device not loaded when trying to create transports.');
//       return;
//     }

//     if (_producerTransport == null) {
//       final rawProd =
//           await _socket!.emitWithAckAsync('createProducerTransport', {});
//       final producerParams = _normalizeAck(rawProd);
//       _log('Producer Transport Params received: $producerParams'); // ADDED LOG
//       _producerTransport = _mediasoupDevice!.createSendTransportFromMap(
//         Map<String, dynamic>.from(producerParams),
//         producerCallback: _handleNewProducer,
//       );
//       _setupProducerTransportListeners();
//     }
//     if (_consumerTransport == null) {
//       final rawCons =
//           await _socket!.emitWithAckAsync('createConsumerTransport', {});
//       final consumerParams = _normalizeAck(rawCons);
//       _log('Consumer Transport Params received: $consumerParams'); // ADDED LOG
//       _consumerTransport = _mediasoupDevice!.createRecvTransportFromMap(
//           Map<String, dynamic>.from(consumerParams));
//       _setupConsumerTransportListeners();
//     }
//     _log('✅ Transports created.');
//   }

//   void _setupProducerTransportListeners() {
//     _producerTransport!.on('connect', (data) async {
//       _log('🟡 Producer transport: Attempting to connect...');
//       final dtlsParameters = data['dtlsParameters'].toMap();
//       try {
//         await _socket!
//             .emitWithAckAsync('connectProducerTransport', dtlsParameters);
//         _log('🟢 Producer transport: connectProducerTransport ack received.');
//         data['callback']
//             ?.call(); // Important: Call the transport's internal callback on success
//       } catch (error) {
//         _log(
//             '🔴 Producer transport: connectProducerTransport failed: ${error.toString()}');
//         _showError('Producer transport connection failed: ${error.toString()}');
//         data['errback']?.call(
//             error); // Important: Call the transport's internal errback on failure
//       }
//     });
//     _producerTransport!.on('produce', (data, ackCallback) async {
//       final raw = await _socket!.emitWithAckAsync('produce', {
//         'kind': data['kind'],
//         'rtpParameters': data['rtpParameters'].toMap(),
//         'roomID': _roomId,
//         'isScreen': data['appData']?['isScreen'] ?? false,
//       });
//       final response = _normalizeAck(raw);
//       if (response != null && response['id'] != null) {
//         ackCallback({'id': response['id']});
//       } else {
//         // Log the error response from the server if available
//         _log(
//             '🔴 Producer transport: produce signaling failed. Server response: $response');
//         ackCallback({'error': response?['error'] ?? 'produce_failed'});
//         _showError(
//             'Failed to produce media: ${response?['error'] ?? 'Unknown error'}');
//       }
//     });
//     _producerTransport!.on('connectionstatechange', (state) async {
//       _log('🔵 Producer transport state changed to: $state');
//       if (state == 'connected' && !_producing) {
//         _produceMedia();
//         _updateStatus(ConnectionStatus.connected, 'Connected.');
//       } else if (state == 'failed') {
//         _log('🔴 Producer transport connection failed, attempting to close...');
//         _producerTransport!.close();
//         _showError('Producer transport connection failed.');
//         _updateStatus(ConnectionStatus.error, 'Producer transport failed.');
//       }
//     });
//     _producerTransport!.on('close', () {
//       _log('Producer transport closed.');
//     });
//   }

//   void _setupConsumerTransportListeners() {
//     _consumerTransport!.on('connect', (data) async {
//       _log('🟡 Consumer transport: Attempting to connect...');
//       final dtlsParameters = data['dtlsParameters'].toMap();
//       try {
//         await _socket!
//             .emitWithAckAsync('connectConsumerTransport', dtlsParameters);
//         _log('🟢 Consumer transport: connectConsumerTransport ack received.');
//         data['callback']?.call();
//       } catch (error) {
//         _log(
//             '🔴 Consumer transport: connectConsumerTransport failed: ${error.toString()}');
//         _showError('Consumer transport connection failed: ${error.toString()}');
//         data['errback']?.call(error);
//       }
//     });
//     _consumerTransport!.on('connectionstatechange', (state) {
//       _log('🔵 Consumer transport state changed to: $state');
//       if (state == 'connected') {
//         _log('✅ Consumer transport connected. Processing pending producers...');
//         _consumePendingProducers();
//       } else if (state == 'failed') {
//         _log('🔴 Consumer transport connection failed, attempting to close...');
//         _consumerTransport!.close();
//         _showError('Consumer transport connection failed.');
//       }
//     });
//     _consumerTransport!.on('track', (track, consumer) async {
//       _log('Received new track: ${track.kind}, Consumer ID: ${consumer.id}');
//       _addRemoteConsumer(consumer);
//     });
//     _consumerTransport!.on('close', () {
//       _log('Consumer transport closed.');
//     });
//   }

//   void _produceMedia() {
//     if (_producing ||
//         _state.localStreamNotifier.value == null ||
//         _producerTransport == null) {
//       _log(
//           'Skipping _produceMedia: already producing, no local stream, or no producer transport.');
//       return;
//     }
//     final audioTrack =
//         _state.localStreamNotifier.value!.getAudioTracks().firstOrNull;
//     final videoTrack =
//         _state.localStreamNotifier.value!.getVideoTracks().firstOrNull;

//     if (audioTrack != null) {
//       _producerTransport!.produce(
//         track: audioTrack,
//         stream: _state.localStreamNotifier.value!,
//         source: 'mic',
//         appData: {'mediaType': 'audio'},
//       );
//       _log('Attempting to produce audio...');
//     }

//     if (videoTrack != null) {
//       _producerTransport!.produce(
//         track: videoTrack,
//         stream: _state.localStreamNotifier.value!,
//         source: 'camera',
//         appData: {'mediaType': 'video'},
//       );
//       _log('Attempting to produce video...');
//     }
//     _producing = true;
//   }

//   Future<void> _addRemoteConsumer(Consumer consumer) async {
//     final producerId = consumer.producerId;
//     if (_localProducerIds.contains(producerId)) {
//       _log('Skipping remote consumer for local producer ID: $producerId');
//       return;
//     }
//     if (_consumingOrConsumed.contains(producerId)) {
//       _log(
//           'Skipping remote consumer for already consuming/consumed producer ID: $producerId');
//       return;
//     }
//     _consumingOrConsumed.add(producerId);

//     final remoteRenderer = RTCVideoRenderer();
//     await remoteRenderer.initialize();
//     final remoteStream =
//         await createLocalMediaStream(math.Random().nextInt(1000000).toString());
//     remoteStream.addTrack(consumer.track);
//     remoteRenderer.srcObject = remoteStream;
//     final peerName =
//         _state.peersNotifier.value[consumer.peerId]?['name'] ?? 'Participant';
//     final streamInfo = StreamInfo(
//       producerId: producerId,
//       socketId: consumer.peerId ?? '',
//       peerName: peerName,
//       renderer: remoteRenderer,
//       stream: remoteStream,
//       consumer: consumer,
//     );
//     final newRemoteStreams =
//         Map<String, StreamInfo>.from(_state.remoteStreamsNotifier.value);
//     newRemoteStreams[producerId] = streamInfo;
//     _state.remoteStreamsNotifier.value = newRemoteStreams;
//     await _socket!.emitWithAckAsync('resume', {'producerID': producerId});
//     _log('Resumed consumer for producer ID: $producerId');
//   }

//   void _enqueueOrConsume(String producerId, String socketId) {
//     if (_consumingOrConsumed.contains(producerId) ||
//         _localProducerIds.contains(producerId)) {
//       _log(
//           'Skipping enqueue/consume for producer ID: $producerId (already handled).');
//       return;
//     }
//     if (_consumerTransport == null) {
//       _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
//       _log(
//           'Enqueuing producer ID: $producerId (consumer transport not ready).');
//       return;
//     }
//     _consume(producerId, socketId);
//   }

//   Future<void> _consumePendingProducers() async {
//     if (_consumerTransport == null) return;
//     final pending = List<Map<String, String>>.from(_pendingProducers);
//     _pendingProducers.clear();
//     for (final item in pending) {
//       final pid = item['producerId'];
//       final sid = item['socketId'];
//       if (pid != null && sid != null) {
//         await _consume(pid, sid);
//       }
//     }
//   }

//   Future<void> _consume(String producerId, String socketId) async {
//     if (_mediasoupDevice == null ||
//         !_mediasoupDevice!.loaded ||
//         _consumerTransport == null ||
//         _consumingOrConsumed.contains(producerId)) {
//       if (_consumerTransport == null) {
//         _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
//       }
//       return;
//     }
//     _consumingOrConsumed.add(producerId);
//     try {
//       final consumerParams =
//           _normalizeAck(await _socket!.emitWithAckAsync('consume', {
//         'socketID': socketId,
//         'producerID': producerId,
//         'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
//         'roomID': _roomId,
//       }));
//       final p = Map<String, dynamic>.from(consumerParams);
//       _consumerTransport!.consume(
//         id: p['id'],
//         producerId: p['producerId'],
//         peerId: socketId,
//         kind: p['kind'] == 'audio'
//             ? RTCRtpMediaType.RTCRtpMediaTypeAudio
//             : RTCRtpMediaType.RTCRtpMediaTypeVideo,
//         rtpParameters: RtpParameters.fromMap(p['rtpParameters']),
//         appData: {'producerId': producerId},
//       );
//     } catch (e, st) {
//       _log('❌ Error in consume process: $e\n$st');
//       _consumingOrConsumed.remove(producerId);
//       _showError('Failed to consume media: $e');
//     }
//   }

//   void _removeConsumer(String producerId) {
//     final streamInfo = _state.remoteStreamsNotifier.value[producerId];
//     if (streamInfo == null) return;
//     final newRemoteStreams =
//         Map<String, StreamInfo>.from(_state.remoteStreamsNotifier.value);
//     newRemoteStreams.remove(producerId);
//     _state.remoteStreamsNotifier.value = newRemoteStreams;
//     _consumingOrConsumed.remove(producerId);
//     try {
//       streamInfo.consumer?.close();
//       streamInfo.renderer?.dispose();
//       streamInfo.stream?.dispose();
//     } catch (_) {}
//   }

//   void toggleMic() {
//     final newMicState = !_state.micEnabledNotifier.value;
//     _state.micEnabledNotifier.value = newMicState;
//     if (_audioProducer != null) {
//       if (newMicState) {
//         _audioProducer!.resume();
//       } else {
//         _audioProducer!.pause();
//       }
//     }
//     _socket?.emit(newMicState ? 'micon' : 'micOff',
//         {'userId': _state.localUserIdNotifier.value});
//   }

//   void toggleVideo() {
//     final newVideoState = !_state.videoEnabledNotifier.value;
//     _state.videoEnabledNotifier.value = newVideoState;
//     if (_videoProducer != null) {
//       if (newVideoState) {
//         _videoProducer!.resume();
//       } else {
//         _videoProducer!.pause();
//       }
//     }
//     _socket?.emit(newVideoState ? 'videoon' : 'videooff',
//         {'userId': _state.localUserIdNotifier.value});
//   }

//   Future<void> switchCamera() async {
//     final localStream = _state.localStreamNotifier.value;
//     if (localStream == null || localStream.getVideoTracks().isEmpty) return;
//     try {
//       await localStream.getVideoTracks().first.switchCamera();
//       _state.isFrontCameraNotifier.value = !_state.isFrontCameraNotifier.value;
//     } catch (e) {
//       _log('❌ Failed to switch camera: $e');
//       _showError('Failed to switch camera: $e');
//     }
//   }

//   void toggleSpeaker() {
//     final newSpeakerState = !_state.speakerOnNotifier.value;
//     Helper.setSpeakerphoneOn(newSpeakerState);
//     _state.speakerOnNotifier.value = newSpeakerState;
//     _state.bluetoothRequestedNotifier.value = false;
//   }

//   Future<void> hangUp() async {
//     _log('☎ Hanging up...');
//     if (_socket?.connected == true) {
//       _socket!.emit('leave', {'roomID': _roomId});
//     }
//     await _cleanupResources();
//   }

//   Future<void> _cleanupResources() async {
//     _log('🧹 Starting resource cleanup...');
//     _audioProducer?.close();
//     _videoProducer?.close();
//     _producerTransport?.close();
//     _consumerTransport?.close();
//     _socket?.disconnect();
//     _state.localRendererNotifier.value.dispose();
//     _state.localStreamNotifier.value?.dispose();
//     for (var info in _state.remoteStreamsNotifier.value.values) {
//       info.consumer?.close();
//       info.renderer?.dispose();
//       info.stream?.dispose();
//     }
//     _localProducerIds.clear();
//     _consumingOrConsumed.clear();
//     _pendingProducers.clear();
//   }

//   void _log(String message) => developer.log('[MeetingLogic] $message');
// }

// lib/meeting_state_logic.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nde_email/utils/imports/common_imports.dart';

enum ConnectionStatus {
  connecting,
  authenticated,
  loadingDevice,
  deviceLoaded,
  joiningRoom,
  roomJoined,
  mediaStarted,
  connected,
  disconnected,
  error,
}

class StreamInfo {
  final String producerId;
  final String socketId;
  String? peerName;
  RTCVideoRenderer? renderer;
  MediaStream? stream;
  Consumer? consumer;

  StreamInfo({
    required this.producerId,
    required this.socketId,
    this.peerName,
    this.renderer,
    this.stream,
    this.consumer,
  });
}

class MeetingState {
  final ValueNotifier<ConnectionStatus> statusNotifier =
      ValueNotifier(ConnectionStatus.connecting);
  final ValueNotifier<String> statusMessageNotifier =
      ValueNotifier('Connecting...');
  final ValueNotifier<String?> localUserIdNotifier = ValueNotifier(null);
  final ValueNotifier<MediaStream?> localStreamNotifier = ValueNotifier(null);
  final ValueNotifier<RTCVideoRenderer> localRendererNotifier =
      ValueNotifier(RTCVideoRenderer());
  final ValueNotifier<bool> micEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<bool> videoEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<bool> isFrontCameraNotifier = ValueNotifier(true);
  final ValueNotifier<bool> speakerOnNotifier = ValueNotifier(false);
  final ValueNotifier<bool> bluetoothRequestedNotifier = ValueNotifier(false);
  final ValueNotifier<Map<String, dynamic>> peersNotifier = ValueNotifier({});
  final ValueNotifier<Map<String, StreamInfo>> remoteStreamsNotifier =
      ValueNotifier({});

  void dispose() {
    statusNotifier.dispose();
    statusMessageNotifier.dispose();
    localUserIdNotifier.dispose();
    localStreamNotifier.dispose();
    localRendererNotifier.dispose();
    micEnabledNotifier.dispose();
    videoEnabledNotifier.dispose();
    isFrontCameraNotifier.dispose();
    speakerOnNotifier.dispose();
    bluetoothRequestedNotifier.dispose();
    peersNotifier.dispose();
    remoteStreamsNotifier.dispose();
  }
}

// --- Logic Class ---

class MeetingLogic {
  final String _roomId;
  final MeetingState _state;
  final Function(String message) _showError;
  IO.Socket? _socket;
  Device? _mediasoupDevice;
  Transport? _producerTransport;
  Transport? _consumerTransport;
  Producer? _audioProducer;
  Producer? _videoProducer;
  String? _token;

  final List<Map<String, String>> _pendingProducers = [];
  final Set<String> _consumingOrConsumed = {};
  final Set<String> _localProducerIds = {};
  bool _producing = false;

  MeetingLogic(this._roomId, this._state, this._showError) {
    _initMeeting();
  }

  void _updateStatus(ConnectionStatus status, String message) {
    _state.statusNotifier.value = status;
    _state.statusMessageNotifier.value = message;
  }

  Future<void> _initMeeting() async {
    _updateStatus(ConnectionStatus.connecting, 'Connecting...');
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera]?.isGranted == true &&
        statuses[Permission.microphone]?.isGranted == true) {
      await _initializeVideoCall();
    } else {
      _showError('Camera and Microphone permissions are required.');
    }
  }

  Future<void> _initializeVideoCall() async {
    try {
      await _loadUserData();
      if (_token != null && _state.localUserIdNotifier.value != null) {
        await _startMediaCapture();
        await _connectSocket();
      } else {
        _showError('Failed to load user data');
      }
    } catch (e, st) {
      _log('Error initializing video call: $e\n$st');
      _showError('Failed to initialize video call: $e');
      _updateStatus(ConnectionStatus.error, 'Error: ${e.toString()}');
    }
  }

  Future<void> _loadUserData() async {
    _token = await UserPreferences.getAccessToken();
    _state.localUserIdNotifier.value = await UserPreferences.getUserId();
  }

  Future<void> _startMediaCapture() async {
    try {
      final constraints = {
        'audio': true,
        'video': {'facingMode': 'user'}
      };
      final stream = await navigator.mediaDevices.getUserMedia(constraints);
      final localRenderer = RTCVideoRenderer();
      await localRenderer.initialize();
      localRenderer.srcObject = stream;

      _state.localStreamNotifier.value = stream;
      _state.localRendererNotifier.value = localRenderer;
      _updateStatus(ConnectionStatus.mediaStarted, 'Media started.');
      _log('✅ Media stream obtained.');
    } catch (e) {
      _log('❌ Error accessing media devices: $e');
      _showError('Failed to access camera/microphone: $e');
      rethrow;
    }
  }

  Future<void> _connectSocket() async {
    try {
      _socket = IO.io(
        'https://api.nowdigitaleasy.com/meet',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/meet/socket.io')
            .setQuery({'token': '$_token'})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );
      _setupSocketListeners();
      _socket!.connect();
    } catch (e) {
      _log('Error creating socket connection: $e');
      _showError('Failed to create socket connection: $e');
      _updateStatus(ConnectionStatus.error, 'Socket error: $e');
    }
  }

  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _log('✅ Socket connected successfully');
      _socket!.emit('authenticate',
          {'id': _state.localUserIdNotifier.value, 'token': 'Bearer $_token'});
    });

    _socket!.on('authenticated', (_) async {
      _log('-- Socket authenticated');
      _updateStatus(ConnectionStatus.authenticated, 'Authenticated.');
      await _initializeMediasoupDevice();
    });

    _socket!.onDisconnect((reason) {
      _log('❌ Socket disconnected: $reason');
      _updateStatus(ConnectionStatus.disconnected, 'Disconnected: $reason');
    });

    _socket!.on('newProducer', (data) {
      if (data is Map &&
          data['producerID'] != null &&
          data['socketID'] != null) {
        _enqueueOrConsume(
            data['producerID'].toString(), data['socketID'].toString());
      }
    });

    _socket!.on('producerClosed', (data) {
      final producerId = data is String ? data : data?['producerID'];
      if (producerId != null) _removeConsumer(producerId.toString());
    });

    _socket!.on('newPeer', (data) {
      if (data is Map && data['socketID'] != null) {
        _addOrUpdatePeer(data);
      }
    });

    _socket!.on('leave', (data) {
      if (data != null && data['socketID'] != null) {
        _removePeer(data['socketID']);
      }
    });
  }

  var sockettid;
  void _addOrUpdatePeer(dynamic data) {
    final newPeers = Map<String, dynamic>.from(_state.peersNotifier.value);
    final sockettid = data['socketID'].toString();
    final user = data['user'] ?? {};
    final fullName =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    newPeers[sockettid] = {'userID': data['userID'], 'name': fullName};
    _state.peersNotifier.value = newPeers;
  }

  void _removePeer(String socketId) {
    final newPeers = Map<String, dynamic>.from(_state.peersNotifier.value);
    newPeers.remove(socketId);
    _state.peersNotifier.value = newPeers;

    final remoteStreams =
        Map<String, StreamInfo>.from(_state.remoteStreamsNotifier.value);
    remoteStreams.removeWhere((key, value) => value.socketId == socketId);
    _state.remoteStreamsNotifier.value = remoteStreams;
  }

  dynamic _normalizeAck(dynamic resp) {
    if (resp is List && resp.isNotEmpty) return resp.first;
    return resp;
  }

  Future<void> _initializeMediasoupDevice() async {
    if (_mediasoupDevice != null && _mediasoupDevice!.loaded) return;
    _updateStatus(ConnectionStatus.loadingDevice, 'Loading device...');
    try {
      final rtpCaps = _normalizeAck(
          await _socket!.emitWithAckAsync('getRouterRtpCapabilities', {}));
      if (rtpCaps == null || rtpCaps is! Map) {
        throw Exception('Failed to get router capabilities');
      }
      _mediasoupDevice = Device();
      await _mediasoupDevice!.load(
          routerRtpCapabilities:
              RtpCapabilities.fromMap(Map<String, dynamic>.from(rtpCaps)));
      _updateStatus(ConnectionStatus.deviceLoaded, 'Device loaded.');
      await _joinRoom();
    } catch (e, st) {
      _log('❌ Error initializing Mediasoup device: $e\n$st');
      _showError('Failed to initialize media device: $e');
      _updateStatus(ConnectionStatus.error, 'Device error: $e');
    }
  }

  Future<void> _joinRoom() async {
    _updateStatus(ConnectionStatus.joiningRoom, 'Joining room...');
    try {
      final response = _normalizeAck(
          await _socket!.emitWithAckAsync('join', {'roomID': _roomId}));
      if (response == null || response is! Map) {
        throw Exception('Failed to join room');
      }
      final peers = response['peers'] as Map? ?? {};
      final producers = response['producers'] as List? ?? [];
      final newPeers = Map<String, dynamic>.from(_state.peersNotifier.value);
      peers.forEach((socketId, peerData) {
        final user = peerData['user'] ?? {};
        final fullName =
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
        newPeers[socketId] = {'userID': peerData['userID'], 'name': fullName};
      });
      _state.peersNotifier.value = newPeers;
      _updateStatus(ConnectionStatus.roomJoined, 'Room joined.');
      for (var producer in producers) {
        final producerId = producer['producerID']?.toString();
        final socketId = producer['socketID']?.toString();
        if (producerId != null && socketId != null) {
          _enqueueOrConsume(producerId, socketId);
        }
      }
      await _createTransports();
    } catch (e) {
      _log('❌ Error joining room: $e');
      _showError('Failed to join room: $e');
      _updateStatus(ConnectionStatus.error, 'Join room error: $e');
    }
  }

  // New callback to handle incoming Producer objects
  void _handleNewProducer(Producer producer) {
    _log(
        '⚙️ Received new producer via callback: ${producer.id}, Kind: ${producer.kind}');
    _localProducerIds.add(producer.id);
    if (producer.kind == 'audio') {
      _audioProducer = producer;
    } else if (producer.kind == 'video') {
      _videoProducer = producer;
    }
  }

  Future<void> _createTransports() async {
    if (_mediasoupDevice == null || !_mediasoupDevice!.loaded) return;

    // --- Producer Transport ---
    if (_producerTransport == null) {
      final rawProd =
          await _socket!.emitWithAckAsync('createProducerTransport', {
        'forceTcp': false,
        'roomID': _roomId,
        'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
      });

      final producerParams = _normalizeAck(rawProd);
      _log('Producer Transport Params: $producerParams');

      _producerTransport = _mediasoupDevice!.createSendTransportFromMap(
        Map<String, dynamic>.from(producerParams),
        producerCallback: _handleNewProducer,
      );

      _producerTransport!.on('connect', (data) async {
        final dtlsParams = {'dtlsParameters': data['dtlsParameters'].toMap()};
        try {
          await _socket!.emitWithAckAsync('connectProducerTransport',
              {...dtlsParams, 'transportId': _producerTransport!.id});
          data['callback']?.call();
        } catch (e) {
          data['errback']?.call(e);
          _showError('Producer transport connect failed: $e');
        }
      });

      _producerTransport!.on('produce', (data, ackCallback) async {
        try {
          final result = await _socket!.emitWithAckAsync('produce', {
            'transportId': _producerTransport!.id,
            'kind': data['kind'],
            'rtpParameters': data['rtpParameters'].toMap(),
            'roomID': _roomId,
            'isScreen': data['appData']?['isScreen'] ?? false,
          });
          ackCallback({'id': result['id']});
        } catch (e) {
          ackCallback({'error': e.toString()});
        }
      });
    }

    // --- Consumer Transport ---
    if (_consumerTransport == null) {
      final rawCons =
          await _socket!.emitWithAckAsync('createConsumerTransport', {
        'forceTcp': false,
        'roomID': _roomId,
        'socketID': sockettid.toString(),
      });

      final consumerParams = _normalizeAck(rawCons);
      _log('Consumer Transport Params: $consumerParams');

      _consumerTransport = _mediasoupDevice!.createRecvTransportFromMap(
          Map<String, dynamic>.from(consumerParams));

      _consumerTransport!.on('connect', (data) async {
        final dtlsParams = {'dtlsParameters': data['dtlsParameters'].toMap()};
        try {
          await _socket!.emitWithAckAsync('connectConsumerTransport',
              {...dtlsParams, 'transportId': _consumerTransport!.id});
          data['callback']?.call();
        } catch (e) {
          data['errback']?.call(e);
          _showError('Consumer transport connect failed: $e');
        }
      });
    }

    _log('✅ Transports created successfully');
  }

  Future<void> _consume(String producerId, String socketId) async {
    if (_consumerTransport == null || !_mediasoupDevice!.loaded) {
      _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
      return;
    }

    final consumerParams =
        _normalizeAck(await _socket!.emitWithAckAsync('consume', {
      'producerId': producerId,
      'socketID': socketId,
      'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
      'transportId': _consumerTransport!.id,
      'roomID': _roomId,
    }));

    _consumerTransport!.consume(
      id: consumerParams['id'],
      producerId: consumerParams['producerId'],
      peerId: socketId,
      kind: consumerParams['kind'] == 'audio'
          ? RTCRtpMediaType.RTCRtpMediaTypeAudio
          : RTCRtpMediaType.RTCRtpMediaTypeVideo,
      rtpParameters: RtpParameters.fromMap(consumerParams['rtpParameters']),
      appData: {'producerId': producerId},
    );
  }

  void _setupConsumerTransportListeners() {
    _consumerTransport!.on('connect', (data) async {
      _log('🟡 Consumer transport: Attempting to connect...');
      final dtlsParameters = data['dtlsParameters'].toMap();
      try {
        await _socket!
            .emitWithAckAsync('connectConsumerTransport', dtlsParameters);
        _log('🟢 Consumer transport: connectConsumerTransport ack received.');
        data['callback']?.call();
      } catch (error) {
        _log(
            '🔴 Consumer transport: connectConsumerTransport failed: ${error.toString()}');
        _showError('Consumer transport connection failed: ${error.toString()}');
        data['errback']?.call(error);
      }
    });
    _consumerTransport!.on('connectionstatechange', (state) {
      _log('🔵 Consumer transport state changed to: $state');
      if (state == 'connected') {
        _log('✅ Consumer transport connected. Processing pending producers...');
        _consumePendingProducers();
      } else if (state == 'failed') {
        _log('🔴 Consumer transport connection failed, attempting to close...');
        _consumerTransport!.close();
        _showError('Consumer transport connection failed.');
      }
    });
    _consumerTransport!.on('track', (track, consumer) async {
      _log('Received new track: ${track.kind}, Consumer ID: ${consumer.id}');
      _addRemoteConsumer(consumer);
    });
    _consumerTransport!.on('close', () {
      _log('Consumer transport closed.');
    });
  }

  void _produceMedia() {
    if (_producing ||
        _state.localStreamNotifier.value == null ||
        _producerTransport == null) {
      _log(
          'Skipping _produceMedia: already producing, no local stream, or no producer transport.');
      return;
    }
    final audioTrack =
        _state.localStreamNotifier.value!.getAudioTracks().firstOrNull;
    final videoTrack =
        _state.localStreamNotifier.value!.getVideoTracks().firstOrNull;

    if (audioTrack != null) {
      _producerTransport!.produce(
        track: audioTrack,
        stream: _state.localStreamNotifier.value!,
        source: 'mic',
        appData: {'mediaType': 'audio'},
      );
      _log('Attempting to produce audio...');
    }

    if (videoTrack != null) {
      _producerTransport!.produce(
        track: videoTrack,
        stream: _state.localStreamNotifier.value!,
        source: 'camera',
        appData: {'mediaType': 'video'},
      );
      _log('Attempting to produce video...');
    }
    _producing = true;
  }

  Future<void> _addRemoteConsumer(Consumer consumer) async {
    final producerId = consumer.producerId;
    if (_localProducerIds.contains(producerId)) {
      _log('Skipping remote consumer for local producer ID: $producerId');
      return;
    }
    if (_consumingOrConsumed.contains(producerId)) {
      _log(
          'Skipping remote consumer for already consuming/consumed producer ID: $producerId');
      return;
    }
    _consumingOrConsumed.add(producerId);

    final remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();
    final remoteStream =
        await createLocalMediaStream(math.Random().nextInt(1000000).toString());
    remoteStream.addTrack(consumer.track);
    remoteRenderer.srcObject = remoteStream;
    final peerName =
        _state.peersNotifier.value[consumer.peerId]?['name'] ?? 'Participant';
    final streamInfo = StreamInfo(
      producerId: producerId,
      socketId: consumer.peerId ?? '',
      peerName: peerName,
      renderer: remoteRenderer,
      stream: remoteStream,
      consumer: consumer,
    );
    final newRemoteStreams =
        Map<String, StreamInfo>.from(_state.remoteStreamsNotifier.value);
    newRemoteStreams[producerId] = streamInfo;
    _state.remoteStreamsNotifier.value = newRemoteStreams;
    await _socket!.emitWithAckAsync('resume', {'producerID': producerId});
    _log('Resumed consumer for producer ID: $producerId');
  }

  void _enqueueOrConsume(String producerId, String socketId) {
    if (_consumingOrConsumed.contains(producerId) ||
        _localProducerIds.contains(producerId)) {
      _log(
          'Skipping enqueue/consume for producer ID: $producerId (already handled).');
      return;
    }
    if (_consumerTransport == null) {
      _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
      _log(
          'Enqueuing producer ID: $producerId (consumer transport not ready).');
      return;
    }
    _consume(producerId, socketId);
  }

  Future<void> _consumePendingProducers() async {
    if (_consumerTransport == null) return;
    final pending = List<Map<String, String>>.from(_pendingProducers);
    _pendingProducers.clear();
    for (final item in pending) {
      final pid = item['producerId'];
      final sid = item['socketId'];
      if (pid != null && sid != null) {
        await _consume(pid, sid);
      }
    }
  }

  void _removeConsumer(String producerId) {
    final streamInfo = _state.remoteStreamsNotifier.value[producerId];
    if (streamInfo == null) return;
    final newRemoteStreams =
        Map<String, StreamInfo>.from(_state.remoteStreamsNotifier.value);
    newRemoteStreams.remove(producerId);
    _state.remoteStreamsNotifier.value = newRemoteStreams;
    _consumingOrConsumed.remove(producerId);
    try {
      streamInfo.consumer?.close();
      streamInfo.renderer?.dispose();
      streamInfo.stream?.dispose();
    } catch (_) {}
  }

  void toggleMic() {
    final newMicState = !_state.micEnabledNotifier.value;
    _state.micEnabledNotifier.value = newMicState;
    if (_audioProducer != null) {
      if (newMicState) {
        _audioProducer!.resume();
      } else {
        _audioProducer!.pause();
      }
    }
    _socket?.emit(newMicState ? 'micon' : 'micOff',
        {'userId': _state.localUserIdNotifier.value});
  }

  void toggleVideo() {
    final newVideoState = !_state.videoEnabledNotifier.value;
    _state.videoEnabledNotifier.value = newVideoState;
    if (_videoProducer != null) {
      if (newVideoState) {
        _videoProducer!.resume();
      } else {
        _videoProducer!.pause();
      }
    }
    _socket?.emit(newVideoState ? 'videoon' : 'videooff',
        {'userId': _state.localUserIdNotifier.value});
  }

  Future<void> switchCamera() async {
    final localStream = _state.localStreamNotifier.value;
    if (localStream == null || localStream.getVideoTracks().isEmpty) return;
    try {
      await localStream.getVideoTracks().first.switchCamera();
      _state.isFrontCameraNotifier.value = !_state.isFrontCameraNotifier.value;
    } catch (e) {
      _log('❌ Failed to switch camera: $e');
      _showError('Failed to switch camera: $e');
    }
  }

  void toggleSpeaker() {
    final newSpeakerState = !_state.speakerOnNotifier.value;
    Helper.setSpeakerphoneOn(newSpeakerState);
    _state.speakerOnNotifier.value = newSpeakerState;
    _state.bluetoothRequestedNotifier.value = false;
  }

  Future<void> hangUp() async {
    _log('☎ Hanging up...');
    if (_socket?.connected == true) {
      _socket!.emit('leave', {'roomID': _roomId});
    }
    await _cleanupResources();
  }

  Future<void> _cleanupResources() async {
    _log('🧹 Starting resource cleanup...');
    _audioProducer?.close();
    _videoProducer?.close();
    _producerTransport?.close();
    _consumerTransport?.close();
    _socket?.disconnect();
    _state.localRendererNotifier.value.dispose();
    _state.localStreamNotifier.value?.dispose();
    for (var info in _state.remoteStreamsNotifier.value.values) {
      info.consumer?.close();
      info.renderer?.dispose();
      info.stream?.dispose();
    }
    _localProducerIds.clear();
    _consumingOrConsumed.clear();
    _pendingProducers.clear();
  }

  void _log(String message) => developer.log('[MeetingLogic] $message');
}
