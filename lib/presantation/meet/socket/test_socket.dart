import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class VideoCallPage extends StatefulWidget {
  final String roomId;
  const VideoCallPage({super.key, required this.roomId});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class StreamInfo {
  final String producerId;
  final String socketId;
  String? peerName;
  RTCVideoRenderer? renderer;
  MediaStream? stream;
  MediaStreamTrack? audioTrack;
  Consumer? consumer;

  StreamInfo({
    required this.producerId,
    required this.socketId,
    this.peerName,
    this.renderer,
    this.stream,
    this.audioTrack,
    this.consumer,
  });
}

class _VideoCallPageState extends State<VideoCallPage> {
  IO.Socket? socket;

  MediaStream? localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  Device? _mediasoupDevice;
  Transport? _producerTransport;
  Transport? _consumerTransport;

  bool _isInitializingDevice = false;
  bool _isConnecting = false;
  bool _socketConnected = false;
  bool _isAuthenticated = false;
  bool _deviceLoaded = false;
  bool _roomJoined = false;
  bool _mediaStarted = false;
  bool _isJoiningRoom = false;
  bool _isInitializing = false;

  String? token;
  String? userId;

  final Map<String, StreamInfo> _remoteStreams = {};
  final Map<String, dynamic> _peers = {};

  final List<Map<String, String>> _pendingProducers = [];
  final Set<String> _consumingOrConsumed = {};
  final Set<String> _localProducerIds = {};

  bool _micEnabled = true;
  bool _videoEnabled = true;
  bool _speakerOn = false;
  bool _bluetoothRequested = false;
  bool _isFrontCamera = true;
  bool _producing = false;

  @override
  void initState() {
    super.initState();
    _debugEventFlow('initState');
    _initMeeting();
  }

  void _debugEventFlow(String event, [dynamic data]) {
    _log('🛠 Event: $event, Data: $data');
  }

  Future<void> _initMeeting() async {
    if (_isInitializing) {
      _log('Already initializing, skipping');
      return;
    }
    _isInitializing = true;
    _debugEventFlow('initMeeting');

    final statuses = await [Permission.camera, Permission.microphone].request();
    final camStatus = statuses[Permission.camera];
    final micStatus = statuses[Permission.microphone];

    if (camStatus == PermissionStatus.granted &&
        micStatus == PermissionStatus.granted) {
      await _initializeVideoCall();
    } else if (camStatus == PermissionStatus.permanentlyDenied ||
        micStatus == PermissionStatus.permanentlyDenied) {
      _log('Permissions permanently denied, opening app settings');
      await openAppSettings();
      if (mounted) Navigator.of(context).pop();
    } else {
      _log('Permissions denied, exiting');
      if (mounted) Navigator.of(context).pop();
    }
    _isInitializing = false;
  }

  Future<void> _initializeVideoCall() async {
    _debugEventFlow('initializeVideoCall');
    try {
      await _loadUserData();
      _log('Token: $token, UserID: $userId');
      if (token != null && userId != null) {
        await _startMediaCapture();
        await _initializeRenderer();
        await _connectSocket();
      } else {
        _log('User data not loaded. Token or UserId is null');
        _showError('Failed to load user data');
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      _log('Error initializing video call: $e');
      _showError('Failed to initialize video call: $e');
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _loadUserData() async {
    _debugEventFlow('loadUserData');
    try {
      final fetchedUserId = await UserPreferences.getUserId();
      final fetchedToken = await UserPreferences.getAccessToken();
      _log('Loaded token: $fetchedToken, userId: $fetchedUserId');
      if (mounted) {
        setState(() {
          userId = fetchedUserId;
          token = fetchedToken;
        });
      }
    } catch (e) {
      _log('Error loading user data: $e');
      rethrow;
    }
  }

  Future<void> _startMediaCapture() async {
    if (_mediaStarted) {
      _log('Media already started, skipping');
      return;
    }
    _debugEventFlow('startMediaCapture');
    try {
      _log('🎬 Starting media (audio+video) with front camera preferred');
      final constraints = {
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 30}
        }
      };

      final stream = await navigator.mediaDevices.getUserMedia(constraints);
      _log(
          '✅ Media stream obtained | id=${stream.id}, tracks=${stream.getTracks().length}');
      if (mounted) {
        setState(() {
          localStream = stream;
          _mediaStarted = true;
        });
      }
      await _applyAudioRoute();
    } catch (e, st) {
      _log('❌ Error accessing media devices: $e\n$st');
      _showError(
          'Failed to access camera/microphone. Please check permissions.');
      if (mounted) Navigator.of(context).pop();
      rethrow;
    }
  }

  Future<void> _initializeRenderer() async {
    _debugEventFlow('initializeRenderer');
    try {
      _log('Initializing local renderer for room: ${widget.roomId}');
      await _localRenderer.initialize();
      _localRenderer.srcObject = localStream;
      _log('Local renderer initialized successfully');
    } catch (e) {
      _log('Error initializing local renderer: $e');
      rethrow;
    }
  }

  Future<void> _connectSocket() async {
    if (_isConnecting || _socketConnected) {
      _log('Socket already connecting or connected, skipping');
      return;
    }
    _debugEventFlow('connectSocket');

    setState(() => _isConnecting = true);

    try {
      socket = IO.io(
        'https://api.nowdigitaleasy.com/meet',
        IO.OptionBuilder()
            .setPath('/meet/socket.io')
            .setQuery({'token': '$token'})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(3)
            .setReconnectionDelay(2000)
            .setTimeout(20000)
            .build(),
      );

      _setupSocketListeners();
      socket!.connect();
    } catch (e) {
      _log('Error creating socket connection: $e');
      if (mounted) setState(() => _isConnecting = false);
      _showError('Failed to create socket connection: $e');
    }
  }

  void _setupSocketListeners() {
    if (socket == null) return;
    socket!.clearListeners();
    _debugEventFlow('setupSocketListeners');

    socket!.onConnect((_) {
      _debugEventFlow('onConnect');
      _log('✅ Socket connected successfully');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _socketConnected = true;
        });
      }
      socket!.emit('authenticate', {'id': userId, 'token': 'Bearer $token'});
    });

    socket!.on('authenticated', (_) async {
      _debugEventFlow('authenticated');
      _log('✅ Socket authenticated successfully');
      if (mounted) setState(() => _isAuthenticated = true);

      await _joinRoom();
      //await _initializeMediasoupDevice();
    });

    socket!.onDisconnect((reason) {
      _debugEventFlow('onDisconnect', reason);
      _log('❌ Socket disconnected: $reason');
      if (mounted) {
        setState(() {
          _socketConnected = false;
          _isAuthenticated = false;
          _isConnecting = false;
          _deviceLoaded = false;
          _roomJoined = false;
        });
      }
    });

    socket!.onConnectError((error) {
      _debugEventFlow('onConnectError', error);
      _log('❌ Socket connection error: $error');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _socketConnected = false;
        });
      }
    });

    socket!.onError((error) {
      _debugEventFlow('onError', error);
      _log('❌ Socket error: $error');
      _showError('Socket error: $error');
    });

    socket!.on('connect_timeout', (_) {
      _debugEventFlow('connect_timeout');
      _log('⏰ Socket connection timeout');
      _showError('Connection timeout');
    });

    socket!.on('reconnect',
        (attemptNumber) => _debugEventFlow('reconnect', attemptNumber));
    socket!.on('reconnect_error',
        (error) => _debugEventFlow('reconnect_error', error));
    socket!.on('reconnect_failed', (_) => _debugEventFlow('reconnect_failed'));

    socket!.on('newProducer', (data) {
      _debugEventFlow('newProducer', data);
      if (data is Map &&
          data['producerID'] != null &&
          data['socketID'] != null) {
        final producerId = data['producerID'].toString();
        final socketId = data['socketID'].toString();
        _log("📡 New producer detected: $producerId from socket: $socketId");
        _enqueueOrConsume(producerId, socketId);
      } else {
        _log('❌ Invalid newProducer payload: $data');
      }
    });

    socket!.on('remove', (data) {
      _debugEventFlow('remove', data);
      if (data != null && data['producerID'] != null) {
        _removeConsumer(data['producerID'].toString());
      }
    });

    socket!.on('newPeer', (data) {
      _debugEventFlow('newPeer', data);
      _addOrUpdatePeer(data);
    });

    socket!.on('leave', (data) {
      _debugEventFlow('leave', data);
      if (data != null && data['socketID'] != null) {
        final socketId = data['socketID'];
        _removePeer(socketId);
      }
    });

    socket!.on('micOff', (data) => _debugEventFlow('micOff', data));
    socket!.on('micOn', (data) => _debugEventFlow('micOn', data));
    socket!.on('videoOff', (data) => _debugEventFlow('videoOff', data));
    socket!.on('videoOn', (data) => _debugEventFlow('videoOn', data));

    socket!.on('callCut', (data) {
      _debugEventFlow('callCut', data);
      _log('☎ Call ended by user: $data');
      _hangUp();
    });
  }

  void _addOrUpdatePeer(dynamic data) {
    _debugEventFlow('addOrUpdatePeer', data);
    if (data is Map && data['socketID'] != null) {
      final socketId = data['socketID'].toString();
      final uid = data['userID']?.toString() ?? '';
      final Map<String, dynamic> userData =
          (data['user'] is Map) ? Map<String, dynamic>.from(data['user']) : {};
      final firstName = userData['first_name']?.toString() ?? '';
      final lastName = userData['last_name']?.toString() ?? '';
      final fullName = '$firstName $lastName'.trim();
      if (mounted) {
        setState(() {
          _peers[socketId] = {'userID': uid, 'name': fullName};
        });
      }
    }
  }

  void _removePeer(String socketId) {
    _debugEventFlow('removePeer', socketId);
    if (mounted) {
      setState(() {
        _peers.remove(socketId);
        _remoteStreams.entries
            .where((e) => e.value.socketId == socketId)
            .map((e) => e.key)
            .toList()
            .forEach(_removeConsumer);
      });
    }
  }

  Future<void> _initializeMediasoupDevice2() async {
    _debugEventFlow('initializeMediasoupDevice');
    if (!_socketConnected || !_isAuthenticated) {
      _log(
          '❌ Cannot initialize device: socket not connected or not authenticated');
      return;
    }
    if (_isInitializingDevice || _deviceLoaded) {
      _log('Device initialization already in progress or completed');
      return;
    }

    setState(() => _isInitializingDevice = true);

    try {
      _log('🔧 Initializing MediaSoup device...');
      final rtpCaps =
          await socket!.emitWithAckAsync('getRouterRtpCapabilities', {});
      _log('Router RTP capabilities response: $rtpCaps');
      if (rtpCaps == null || rtpCaps is! Map || (rtpCaps['error'] != null)) {
        _log('❌ Failed to get router capabilities: $rtpCaps');
        _showError('Failed to get router capabilities');
        if (mounted) setState(() => _isInitializingDevice = false);
        return;
      }

      try {
        _mediasoupDevice = Device();
        await _mediasoupDevice!.load(
            routerRtpCapabilities:
                RtpCapabilities.fromMap(Map<String, dynamic>.from(rtpCaps)));
        _log('✅ MediaSoup device loaded successfully');
        if (mounted) {
          setState(() {
            _deviceLoaded = true;
            _isInitializingDevice = false;
          });
        }
        // await _joinRoom();
      } catch (e) {
        _log('❌ Error loading MediaSoup device: $e');
        _showError('Failed to initialize media device: $e');
        if (mounted) setState(() => _isInitializingDevice = false);
      }
    } catch (e) {
      _log('❌ Error initializing MediaSoup device: $e');
      _showError('Failed to initialize media device: $e');
      if (mounted) setState(() => _isInitializingDevice = false);
    }
  }

  Future<void> _initializeMediasoupDevice() async {
    _debugEventFlow('initializeMediasoupDevice');
    if (!_socketConnected || !_isAuthenticated) {
      _log(
          '❌ Cannot initialize device: socket not connected or not authenticated');
      return;
    }
    if (_isInitializingDevice || _deviceLoaded) {
      _log('Device initialization already in progress or completed');
      return;
    }

    setState(() => _isInitializingDevice = true);

    try {
      _log('🔧 Initializing MediaSoup device...');
      final rtpCaps =
          await socket!.emitWithAckAsync('getRouterRtpCapabilities', {});
      _log('Router RTP capabilities response: $rtpCaps');
      if (rtpCaps == null || rtpCaps is! Map || (rtpCaps['error'] != null)) {
        _log('❌ Failed to get router capabilities: $rtpCaps');
        _showError('Failed to get router capabilities');
        if (mounted) setState(() => _isInitializingDevice = false);
        return;
      }

      try {
        _mediasoupDevice = Device();
        await _mediasoupDevice!.load(
            routerRtpCapabilities:
                RtpCapabilities.fromMap(Map<String, dynamic>.from(rtpCaps)));
        _log('✅ MediaSoup device loaded successfully');
        if (mounted) {
          setState(() {
            _deviceLoaded = true;
            _isInitializingDevice = false;
          });
        }
        await _joinRoom();
      } catch (e) {
        _log('❌ Error loading MediaSoup device: $e');
        _showError('Failed to initialize media device: $e');
        if (mounted) setState(() => _isInitializingDevice = false);
      }
    } catch (e) {
      _log('❌ Error initializing MediaSoup device: $e');
      _showError('Failed to initialize media device: $e');
      if (mounted) setState(() => _isInitializingDevice = false);
    }
  }

  Future<void> _joinRoom() async {
    _debugEventFlow('joinRoom');
    // if (!_deviceLoaded ||
    //     _mediasoupDevice == null ||
    //     !_mediasoupDevice!.loaded ||
    //     _isJoiningRoom) {
    //   _log('❌ Cannot join room: MediaSoup device not ready or already joining');
    //   return;
    // }

    setState(() => _isJoiningRoom = true);
    _log('🚪 Joining room: ${widget.roomId}');

    try {
      final response =
          await socket!.emitWithAckAsync('join', {'roomID': widget.roomId});
      _log('Join room response: $response');
      await _initializeMediasoupDevice2();

      if (response == null || response is! Map || (response['error'] != null)) {
        _log('❌ Failed to join room: $response');
        _showError('Failed to join room');
        if (mounted) setState(() => _isJoiningRoom = false);
        return;
      }

      try {
        final peers = response['peers'] as Map? ?? {};
        if (mounted) {
          setState(() {
            peers.forEach((socketId, peerData) {
              final user = peerData['user'] ?? {};
              _peers[socketId] = {
                'userID': peerData['userID'],
                'name': '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                    .trim(),
              };
            });
            _roomJoined = true;
            _isJoiningRoom = false;
          });
        }

        final producers = response['producers'] as List? ?? [];
        for (var producer in producers) {
          final socketID = producer['socketID']?.toString() ?? '';
          final producerId = producer['producerID']?.toString() ?? '';
          if (producerId.isNotEmpty && socketID.isNotEmpty) {
            _enqueueOrConsume(producerId, socketID);
          }
        }
        _log(
            '✅ Room joined. Peers: ${_peers.length}, Producers: ${producers.length}');
        await _createTransports();
      } catch (e) {
        _log('❌ Error processing join response: $e');
        _showError('Failed to process room data: $e');
        if (mounted) setState(() => _isJoiningRoom = false);
      }
    } catch (e) {
      _log('❌ Error joining room: $e');
      _showError('Failed to join room: $e');
      if (mounted) setState(() => _isJoiningRoom = false);
    }
  }

  Future<void> _createTransports() async {
    _debugEventFlow('createTransports');

    // ✅ Pre-check conditions
    if (!_roomJoined || socket == null || !_mediaStarted) {
      _log(
          '❌ Cannot create transports: Room not joined, media not started, or socket is null.');
      return;
    }

    try {
      // ✅ Create Consumer Transport if not created
      if (_consumerTransport == null) {
        _log('🚚 Creating Consumer Transport...');
        final consumerResponse = await socket!.emitWithAckAsync(
          'createConsumerTransport',
          {},
        );

        _log('✅ Consumer Transport Params: $consumerResponse');

        if (consumerResponse['error'] != null) {
          final errorMsg = consumerResponse['error'].toString();
          _log('❌ Failed to create Consumer Transport: $errorMsg');
          _showError('Failed to create consumer transport: $errorMsg');
          return;
        }

        await _createConsumerTransport(
          Map<String, dynamic>.from(consumerResponse),
        );
      }

      // ✅ Create Producer Transport if not created
      if (_producerTransport == null) {
        _log('🚚 Creating Producer Transport...');
        final producerResponse = await socket!.emitWithAckAsync(
          'createProducerTransport',
          {
            "forceTcp": false,
            "rtpCapabilities": _mediasoupDevice!.rtpCapabilities.toMap(),
            'roomID': widget.roomId,
          },
        );

        _log('✅ Producer Transport Params: $producerResponse');

        if (producerResponse['error'] != null) {
          final errorMsg = producerResponse['error'].toString();
          _log('❌ Failed to create Producer Transport: $errorMsg');
          _showError('Failed to create producer transport: $errorMsg');
          return;
        }

        await _createProducerTransport(
          Map<String, dynamic>.from(producerResponse),
        );
      }

      _log('✅ Transports successfully created.');
    } catch (e, stackTrace) {
      _log('❌ Exception while creating transports: $e');
      _log('📄 Stack Trace: $stackTrace'); // Optional for debugging
      _showError('Failed to create media transports: $e');
    }
  }

  Future<void> _createProducerTransport(Map<String, dynamic> params) async {
    _debugEventFlow('createProducerTransport', params);

    // ✅ Validate device and existing transport
    if (_mediasoupDevice == null || !_mediasoupDevice!.loaded) {
      _log(
          '❌ Cannot create producer transport: MediaSoup device is not loaded.');
      return;
    }
    if (_producerTransport != null) {
      _log('⚠ Producer transport already exists. Skipping creation.');
      return;
    }

    try {
      _log('🏭 Initializing Producer Transport with params: $params');

      // ✅ Create transport
      _producerTransport = _mediasoupDevice!.createSendTransportFromMap(params);
      _log('✅ Producer transport instance created successfully.');

      // ✅ Handle 'connect' event
      _producerTransport!.on('connect', (data) async {
        _debugEventFlow('producerTransport_connect', data);
        _log(
            '🔗 Producer transport connect event received. Connecting to server...');

        try {
          await socket!.emitWithAckAsync('connectProducerTransport', {
            'dtlsParameters': data['dtlsParameters'].toMap(),
          });
          _log('✅ Producer transport connected to server.');
          _produceMedia();
        } catch (e) {
          _log('❌ Error connecting Producer Transport: $e');
        }
      });

      // ✅ Handle 'produce' event
      _producerTransport!.on('produce', (data, accept) async {
        _debugEventFlow('producerTransport_produce', data);
        final kind = data['kind'];
        _log('📤 Produce event received for kind=$kind. Sending to server...');

        try {
          final response = await socket!.emitWithAckAsync('produce', {
            'kind': kind,
            'rtpParameters': data['rtpParameters'].toMap(),
            'isScreen': data['appData']?['mediaType'] == 'screen',
            'roomID': widget.roomId,
          });

          if (response != null && response is Map && response['id'] != null) {
            final producerId = response['id'].toString();
            _log('✅ Producer created successfully. ID=$producerId');
            _localProducerIds.add(producerId);
            accept({'id': producerId});
          } else {
            _log('❌ Failed to create producer on server. Response: $response');
            accept({'error': 'produce_failed'});
          }
        } catch (e) {
          _log('❌ Exception during produce event: $e');
          accept({'error': 'produce_failed'});
        }
      });

      // ✅ Handle connection state changes
      _producerTransport!.on('connectionstatechange', (state) async {
        _debugEventFlow('producerTransport_connectionstatechange', state);
        _log('🔄 Producer transport state changed: $state');

        if (!mounted) return;

        if (state == 'connected' && !_producing) {
          _log(
              '✅ Producer transport is connected. Starting media production...');
          _produceMedia();
          setState(() => _producing = true);
        } else if (state == 'failed') {
          _log('❌ Producer transport failed. Closing...');
          _producerTransport?.close();
          setState(() => _producing = false);
        }
      });
    } catch (e, stackTrace) {
      _log('❌ Error creating producer transport: $e');
      _log('📄 Stack trace: $stackTrace');
      _showError('Failed to create producer transport: $e');
    }
  }

  // Future<void> _createProducerTransport(Map<String, dynamic> params) async {
  //   _debugEventFlow('createProducerTransport', params);
  //   if (_mediasoupDevice == null || !_mediasoupDevice!.loaded) {
  //     _log('❌ MediaSoup device not loaded');
  //     return;
  //   }
  //   if (_producerTransport != null) {
  //     _log('Producer transport already exists.');
  //     return;
  //   }

  //   try {
  //     _log('🏭 Creating producer transport...$params');
  //     _producerTransport = _mediasoupDevice!.createSendTransportFromMap(params);

  //     _producerTransport!.on('connect', (data) async {
  //       _debugEventFlow('producerTransport_connect', data);
  //       _log(
  //           '🔗 Producer transport connect event received. Attempting to connect...');
  //       try {
  //         await socket!.emitWithAckAsync('connectProducerTransport', {
  //           'dtlsParameters': data['dtlsParameters'].toMap(),
  //         });
  //         _log('✅ Producer transport connected to server.');
  //         _produceMedia();
  //       } catch (e) {
  //         _log('❌ Error during connectProducerTransport: $e');
  //       }
  //     });

  //     _producerTransport!.on('produce', (data, accept) async {
  //       _debugEventFlow('producerTransport_produce', data);
  //       _log('📤 produce event kind=${data['kind']}. Sending to server...');
  //       try {
  //         final response = await socket!.emitWithAckAsync('produce', {
  //           'kind': data['kind'],
  //           'rtpParameters': data['rtpParameters'].toMap(),
  //           'isScreen':
  //               (data['appData']?['mediaType'] == 'screen') ? true : false,
  //           'roomID': widget.roomId,
  //         });
  //         if (response != null && response is Map && response['id'] != null) {
  //           final pid = response['id'].toString();
  //           _log('✅ Producer created id=$pid');
  //           _localProducerIds.add(pid);
  //           accept({'id': pid});
  //         } else {
  //           _log('❌ Producer creation failed: $response');
  //           accept({'error': 'produce_failed'});
  //         }
  //       } catch (e) {
  //         _log('❌ Error emitting produce to server: $e');
  //         accept({'error': 'produce_failed'});
  //       }
  //     });

  //     _producerTransport!.on('connectionstatechange', (state) async {
  //       _debugEventFlow('producerTransport_connectionstatechange', state);
  //       _log('🔄 Producer transport state: $state');
  //       if (mounted) {
  //         if (state == 'connected' && !_producing) {
  //           _log(
  //               '✅ Producer transport is connected. Starting to produce media...');
  //           _produceMedia();
  //           setState(() => _producing = true);
  //         } else if (state == 'failed') {
  //           _log('❌ Producer transport failed. Closing...');
  //           _producerTransport?.close();
  //           setState(() => _producing = false);
  //         }
  //       }
  //     });
  //     _log('✅ Producer transport created.');
  //   } catch (e, stack) {
  //     _log('❌ Error creating producer transport: $e\n$stack');
  //     _showError('Failed to create producer transport: $e');
  //   }
  // }

  void _produceMedia() {
    _debugEventFlow('produceMedia');
    if (_producerTransport == null || _producerTransport!.closed) {
      _log('Producer transport not available or closed');
      return;
    }
    if (localStream == null) {
      _log('Local stream not available');
      return;
    }
    if (_producing) {
      _log('Already producing media. Skipping.');
      return;
    }

    final audioTracks = localStream!.getAudioTracks();
    final videoTracks = localStream!.getVideoTracks();

    if (audioTracks.isNotEmpty && _micEnabled) {
      final audioTrack = audioTracks.first;
      try {
        _producerTransport!.produce(
          track: audioTrack,
          stream: localStream!,
          source: 'mic',
          appData: {'mediaType': 'audio'},
        );
        _log('✅ Audio produce() called');
      } on Exception catch (e) {
        _log('❌ Audio produce() failed: $e');
      }
    }

    if (videoTracks.isNotEmpty && _videoEnabled) {
      final videoTrack = videoTracks.first;
      try {
        _producerTransport!.produce(
          track: videoTrack,
          encodings: [
            RtpEncodingParameters(
                rid: 'r0', maxBitrate: 100000, scalabilityMode: 'S1T3'),
            RtpEncodingParameters(
                rid: 'r1', maxBitrate: 300000, scalabilityMode: 'S1T3'),
            RtpEncodingParameters(
                rid: 'r2', maxBitrate: 900000, scalabilityMode: 'S1T3'),
          ],
          stream: localStream!,
          source: 'camera',
          appData: {'mediaType': 'video'},
        );
        _log('✅ Video produce() called');
      } on Exception catch (e) {
        _log('❌ Video produce() failed: $e');
      }
    }
    if (mounted) setState(() => _producing = true);
  }

  Future<void> _createConsumerTransport(Map<String, dynamic> params) async {
    _debugEventFlow('createConsumerTransport', params);
    if (_mediasoupDevice == null || !_mediasoupDevice!.loaded) {
      _log('❌ Cannot create consumer transport: device not loaded');
      return;
    }

    if (_consumerTransport != null) {
      _log('Consumer transport already exists.');
      _consumePendingProducers();
      return;
    }

    try {
      _log('🏭 Creating consumer transport with params: $params');
      _consumerTransport = _mediasoupDevice!.createRecvTransportFromMap(params);

      _consumerTransport!.on('connect', (data) async {
        _debugEventFlow('consumerTransport_connect', data);
        _log(
            '🔗 Consumer transport connect event received. Attempting to connect...');
        if (data != null && data['dtlsParameters'] != null) {
          await socket!.emitWithAckAsync('connectConsumerTransport', {
            'dtlsParameters': data['dtlsParameters'].toMap(),
          });
          _log('✅ Consumer transport connected to server.');
        } else {
          _log('⚠ No dtlsParameters in consumer connect event');
        }
      });

      _consumerTransport!.on('connectionstatechange', (state) {
        _debugEventFlow('consumerTransport_connectionstatechange', state);
        _log('🔄 Consumer transport state: $state');
        if (state == 'connected') _consumePendingProducers();
        if (state == 'failed') {
          _log('❌ Consumer transport failed');
        }
      });

      _log('✅ Consumer transport created successfully');
      _consumePendingProducers();
    } catch (e, st) {
      _log('❌ Error creating consumer transport: $e\n$st');
      _showError('Failed to create consumer transport: $e');
    }
  }

  Future<void> _consume(String producerId, String socketId) async {
    _debugEventFlow(
        'consume', {'producerId': producerId, 'socketId': socketId});
    if (_mediasoupDevice == null || !_mediasoupDevice!.loaded) {
      _log('❌ MediaSoup device not ready for consuming');
      _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
      return;
    }

    if (_consumerTransport == null) {
      _log('❌ Consumer transport not ready');
      _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
      return;
    }

    if (_consumingOrConsumed.contains(producerId)) {
      _log('↩ Already consuming/consumed $producerId');
      return;
    }

    _consumingOrConsumed.add(producerId);
    _log('🍽 Consuming producer: $producerId from socket: $socketId');

    try {
      final consumerParams = await socket!.emitWithAckAsync('consume', {
        'socketID': socketId,
        'producerID': producerId,
        'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
        'roomID': widget.roomId,
      });
      _log('📦 Consumer params: $consumerParams');

      if (consumerParams == null || consumerParams is! Map) {
        _log('❌ Invalid response from server: $consumerParams');
        _consumingOrConsumed.remove(producerId);
        return;
      }

      final p = Map<String, dynamic>.from(consumerParams);

      for (final key in ['id', 'producerId', 'kind', 'rtpParameters']) {
        if (!p.containsKey(key) || p[key] == null) {
          _log('❌ Missing required key: $key in response: $p');
          _consumingOrConsumed.remove(producerId);
          return;
        }
      }

      _log(
          '✅ Consumer params validated: ID=${p['id']}, Producer=${p['producerId']}, Kind=${p['kind']}');

      // Use a Completer to handle the async consumer creation
      final completer = Completer<Consumer>();

      _consumerTransport!.consume(
          id: p['id'],
          producerId: p['producerId'],
          peerId: socketId,
          kind: p['kind'] == 'audio'
              ? RTCRtpMediaType.RTCRtpMediaTypeAudio
              : RTCRtpMediaType.RTCRtpMediaTypeVideo,
          rtpParameters: RtpParameters.fromMap(p['rtpParameters']),
          appData: {'producerId': producerId, ...(p['appData'] ?? {})},
          accept: (consumerData) {
            _log('✅ Consumer data received via accept callback: $consumerData');
            // Check if consumerData is already a Consumer or needs conversion
            if (consumerData is Consumer) {
              completer.complete(consumerData);
            } else if (consumerData is Map) {
              _log(
                  '⚠ Consumer data is a Map, handling may need package-specific logic: $consumerData');

              completer.completeError(
                  Exception('Consumer data is a Map, not a Consumer object'));
            } else {
              _log(
                  '❌ Unexpected consumer data type: ${consumerData.runtimeType}');
              completer
                  .completeError(Exception('Unexpected consumer data type'));
            }
          });

      final consumer = await completer.future;
      await _addRemoteConsumerWithParams(producerId, socketId, p, consumer);
      _consumingOrConsumed.remove(producerId);
    } catch (e, st) {
      _log('❌ Error in consume process: $e\n$st');
      _consumingOrConsumed.remove(producerId);
    }
  }

  // Future<void> _consume(String producerId, String socketId) async {
  //   _debugEventFlow(
  //       'consume', {'producerId': producerId, 'socketId': socketId});
  //   if (_mediasoupDevice == null || !_mediasoupDevice!.loaded) {
  //     _log('❌ MediaSoup device not ready for consuming');
  //     _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
  //     return;
  //   }

  //   if (_consumerTransport == null) {
  //     _log('❌ Consumer transport not ready');
  //     _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
  //     return;
  //   }

  //   if (_consumingOrConsumed.contains(producerId)) {
  //     _log('↩ Already consuming/consumed $producerId');
  //     return;
  //   }

  //   _consumingOrConsumed.add(producerId);
  //   _log('🍽 Consuming producer: $producerId from socket: $socketId');

  //   try {
  //     final consumerParams = await socket!.emitWithAckAsync('consume', {
  //       'socketID': socketId,
  //       'producerID': producerId,
  //       'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
  //       'roomID': widget.roomId,
  //     });
  //     _log('📦 Consumer params: $consumerParams');

  //     if (consumerParams == null || consumerParams is! Map) {
  //       _log('❌ Invalid response from server: $consumerParams');
  //       _consumingOrConsumed.remove(producerId);
  //       return;
  //     }

  //     final p = Map<String, dynamic>.from(consumerParams);

  //     for (final key in ['id', 'producerId', 'kind', 'rtpParameters']) {
  //       if (!p.containsKey(key) || p[key] == null) {
  //         _log('❌ Missing required key: $key in response: $p');
  //         _consumingOrConsumed.remove(producerId);
  //         return;
  //       }
  //     }

  //     _log(
  //         '✅ Consumer params validated: ID=${p['id']}, Producer=${p['producerId']}, Kind=${p['kind']}');

  //     final consumer = await _consumerTransport!.consume(
  //       id: p['id'],
  //       producerId: p['producerId'],
  //       peerId: socketId,
  //       kind: p['kind'] == 'audio'
  //           ? RTCRtpMediaType.RTCRtpMediaTypeAudio
  //           : RTCRtpMediaType.RTCRtpMediaTypeVideo,
  //       rtpParameters: RtpParameters.fromMap(p['rtpParameters']),
  //       appData: {'producerId': producerId, ...(p['appData'] ?? {})},
  //     );

  //     await _addRemoteConsumerWithParams(producerId, socketId, p, consumer);
  //     _consumingOrConsumed.remove(producerId);
  //   } catch (e, st) {
  //     _log('❌ Error in consume process: $e\n$st');
  //     _consumingOrConsumed.remove(producerId);
  //   }
  // }

  Future<void> _addRemoteConsumerWithParams(String producerId, String socketId,
      Map<String, dynamic> params, Consumer consumer) async {
    _debugEventFlow('addRemoteConsumerWithParams',
        {'producerId': producerId, 'socketId': socketId});
    String? peerSocketId;
    for (final peerEntry in _peers.entries) {
      if (peerEntry.value['userID'] == params['appData']?['userID']) {
        peerSocketId = peerEntry.key;
        break;
      }
    }

    if (_remoteStreams.containsKey(producerId)) {
      final streamInfo = _remoteStreams[producerId]!;
      streamInfo.consumer?.close();
      streamInfo.consumer = consumer;
      if (!streamInfo.stream!.getTracks().contains(consumer.track)) {
        streamInfo.stream!.addTrack(consumer.track);
      }
      if (consumer.kind == RTCRtpMediaType.RTCRtpMediaTypeVideo &&
          streamInfo.renderer != null) {
        streamInfo.renderer!.srcObject = streamInfo.stream;
      }
      _log('✅ Updated consumer for existing stream: $producerId');
    } else {
      final remoteRenderer = RTCVideoRenderer();
      await remoteRenderer.initialize();

      final remoteStream = await createLocalMediaStream(
          math.Random().nextInt(1000000).toString());
      remoteStream.addTrack(consumer.track);

      _log(
          '✅ Consumer created for producer: $producerId, kind: ${params['kind']}');

      if (!mounted) return;

      if (params['kind'] == 'video') {
        remoteRenderer.srcObject = remoteStream;
      }

      setState(() {
        _remoteStreams[producerId] = StreamInfo(
          producerId: producerId,
          socketId: peerSocketId ?? socketId,
          renderer: params['kind'] == 'video' ? remoteRenderer : null,
          stream: remoteStream,
          audioTrack: params['kind'] == 'audio' ? consumer.track : null,
          consumer: consumer,
        );
      });
    }

    await socket!.emitWithAckAsync('resume', {'producerID': producerId},
        ack: (data) {
      _log('✅ Resume acknowledged: $data');
    });
  }

  void _enqueueOrConsume(String producerId, String socketId) {
    _debugEventFlow(
        'enqueueOrConsume', {'producerId': producerId, 'socketId': socketId});
    if (_consumingOrConsumed.contains(producerId) ||
        _localProducerIds.contains(producerId)) {
      _log(
          '↩ Already consuming/consumed or is a local producer $producerId, skipping');
      return;
    }

    if (_consumerTransport == null) {
      _log('⏳ Queueing producer $producerId until consumer transport is ready');
      _pendingProducers.add({'producerId': producerId, 'socketId': socketId});
      return;
    }

    _consume(producerId, socketId);
  }

  void _consumePendingProducers() {
    _debugEventFlow('consumePendingProducers');
    if (_consumerTransport == null) return;
    if (_pendingProducers.isEmpty) return;

    _log('▶ Consuming ${_pendingProducers.length} pending producers');
    final pending = List<Map<String, String>>.from(_pendingProducers);
    _pendingProducers.clear();
    for (final item in pending) {
      final pid = item['producerId'];
      final sid = item['socketId'];
      if (pid != null && sid != null) {
        _consume(pid, sid);
      }
    }
  }

  void _removeConsumer(String producerId) {
    _debugEventFlow('removeConsumer', producerId);
    _log('🗑 Removing consumer for producer: $producerId');

    final streamInfo = _remoteStreams.remove(producerId);
    _consumingOrConsumed.remove(producerId);

    streamInfo?.consumer?.close();
    streamInfo?.renderer?.dispose();
    streamInfo?.stream?.dispose();

    if (mounted) setState(() {});
  }

  void _toggleMic() {
    _debugEventFlow('toggleMic');
    if (localStream == null || !_mediaStarted) return;
    final audioTrack = localStream!.getAudioTracks().isNotEmpty
        ? localStream!.getAudioTracks().first
        : null;
    if (audioTrack == null) return;
    setState(() {
      _micEnabled = !_micEnabled;
      audioTrack.enabled = _micEnabled;
    });
    socket?.emit(_micEnabled ? 'micOn' : 'micOff', {'userId': userId});
    _log('🎤 Microphone ${_micEnabled ? 'enabled' : 'disabled'}');
  }

  void _toggleVideo() {
    _debugEventFlow('toggleVideo');
    if (localStream == null || !_mediaStarted) return;
    final videoTrack = localStream!.getVideoTracks().isNotEmpty
        ? localStream!.getVideoTracks().first
        : null;
    if (videoTrack == null) return;
    setState(() {
      _videoEnabled = !_videoEnabled;
      videoTrack.enabled = _videoEnabled;
    });
    socket?.emit(_videoEnabled ? 'videoOn' : 'videoOff', {'userId': userId});
    _log('📹 Video ${_videoEnabled ? 'enabled' : 'disabled'}');
  }

  Future<void> _switchCamera() async {
    _debugEventFlow('switchCamera');
    try {
      if (localStream == null || localStream!.getVideoTracks().isEmpty) {
        _log('❌ Cannot switch camera: no video track available');
        _showError('Failed to switch camera: No video track found.');
        return;
      }
      final videoTracks = localStream!.getVideoTracks();
      await videoTracks.first.switchCamera();
      _isFrontCamera = !_isFrontCamera;
      setState(() {});
      _log('🔁 switchCamera called (isFront=$_isFrontCamera)');
    } catch (e) {
      _log('❌ Failed to switch camera: $e');
      _showError('Failed to switch camera');
    }
  }

  Future<void> _applyAudioRoute() async {
    _debugEventFlow('applyAudioRoute');
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
      _log(
          '🔊 Audio route applied -> speaker: $_speakerOn (bluetoothRequested: $_bluetoothRequested)');
    } catch (e) {
      _log('❌ Error applying audio route: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    _debugEventFlow('toggleSpeaker');
    _speakerOn = !_speakerOn;
    if (_speakerOn) _bluetoothRequested = false;
    await _applyAudioRoute();
    setState(() {});
  }

  Future<void> _requestBluetoothRouting() async {
    _debugEventFlow('requestBluetoothRouting');
    _bluetoothRequested = !_bluetoothRequested;
    if (_bluetoothRequested) {
      _speakerOn = false;
      _showError(
          'Bluetooth routing requires platform implementation (not implemented here).');
    }
    await _applyAudioRoute();
    setState(() {});
  }

  Future<void> _hangUp() async {
    _debugEventFlow('hangUp');
    try {
      _log('☎ Hanging up...');
      if (socket?.connected == true) {
        socket!.emit('leave', {'roomID': widget.roomId});
      }
      await _cleanupResources();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _log('❌ Error during hangup: $e');
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _cleanupResources() async {
    _debugEventFlow('cleanupResources');
    _log('🧹 Starting resource cleanup...');
    try {
      for (var track in localStream?.getTracks() ?? []) {
        try {
          track.stop();
        } catch (e) {
          _log('Error stopping track: $e');
        }
      }

      _localRenderer.srcObject = null;
      await _localRenderer.dispose();
      await localStream?.dispose();

      for (var pid in _localProducerIds) {
        try {
          await socket?.emitWithAckAsync(
              'remove', {'producerID': pid, 'roomID': widget.roomId});
        } catch (e) {
          _log('Error removing producer $pid: $e');
        }
      }
      _localProducerIds.clear();

      try {
        _producerTransport?.close();
      } catch (e) {
        _log('Error closing producer transport: $e');
      }
      _producerTransport = null;

      try {
        _consumerTransport?.close();
      } catch (e) {
        _log('Error closing consumer transport: $e');
      }
      _consumerTransport = null;

      for (var info in _remoteStreams.values) {
        try {
          info.consumer?.close();
          await info.renderer?.dispose();
          await info.stream?.dispose();
        } catch (e) {
          _log('Error disposing remote stream ${info.producerId}: $e');
        }
      }
      _remoteStreams.clear();
      _peers.clear();
      _pendingProducers.clear();
      _consumingOrConsumed.clear();

      try {
        socket?.disconnect();
        socket?.dispose();
      } catch (e) {
        _log('Error disconnecting socket: $e');
      }
      socket = null;

      _log('✅ Resource cleanup complete.');
    } catch (e) {
      _log('❌ Cleanup error: $e');
    }
  }

  void _showError(String message) {
    _debugEventFlow('showError', message);
    _log('⚠ Error: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar()),
      ),
    );
  }

  String _getPeerUserIdByProducerId(String producerId) {
    for (final streamInfo in _remoteStreams.values) {
      if (streamInfo.producerId == producerId) {
        final peer = _peers[streamInfo.socketId];
        return peer?['userID']?.toString() ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

  String _getPeerName(String producerId) {
    final streamInfo = _remoteStreams[producerId];
    if (streamInfo?.socketId != null &&
        _peers.containsKey(streamInfo!.socketId)) {
      return _peers[streamInfo.socketId]['name']?.toString() ?? 'Participant';
    }
    return 'Participant';
  }

  String _getConnectionStatus() {
    if (_isConnecting) return 'Connecting...';
    if (!_socketConnected) return 'Disconnected';
    if (!_isAuthenticated) return 'Authenticating...';
    if (_isInitializingDevice) return 'Loading device...';
    if (_isJoiningRoom) return 'Joining room...';
    if (!_deviceLoaded) return 'Device not loaded';
    if (!_roomJoined) return 'Joining room...';
    if (!_mediaStarted) return 'Starting media...';
    return 'Connected';
  }

  Color _getConnectionStatusColor() {
    if (_socketConnected &&
        _isAuthenticated &&
        _deviceLoaded &&
        _roomJoined &&
        _mediaStarted) {
      return Colors.green;
    } else if (_isConnecting || _isInitializingDevice || _isJoiningRoom) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  void dispose() {
    _debugEventFlow('dispose');
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _debugEventFlow('build');
    final remoteVideoStreams =
        _remoteStreams.values.where((info) => info.renderer != null).toList();
    _log('Building video grid with ${remoteVideoStreams.length} streams');

    return Scaffold(
      appBar: AppBar(
        title: Text('Meet - ${widget.roomId}'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _getConnectionStatusColor(),
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(_getConnectionStatus(),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (_isConnecting || _isInitializingDevice || _isJoiningRoom)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Participants (${_peers.length + 1})'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You (${userId ?? 'Unknown'})',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._peers.entries
                          .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('${e.value['name']} (${e.key})')))
                          .toList(),
                      const SizedBox(height: 8),
                      Text('Status: ${_getConnectionStatus()}',
                          style: TextStyle(
                              fontSize: 12,
                              color: _getConnectionStatusColor())),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'))
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueGrey.shade900, Colors.black]),
        ),
        child: Stack(
          children: [
            if (remoteVideoStreams.isNotEmpty)
              _buildVideoGrid(remoteVideoStreams)
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isConnecting ||
                        !_socketConnected ||
                        !_isAuthenticated ||
                        _isInitializingDevice ||
                        !_roomJoined) ...[
                      const CircularProgressIndicator(color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(_getConnectionStatus(),
                          style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 8),
                      Text('Room: ${widget.roomId}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ] else ...[
                      const Icon(Icons.people, size: 50, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text('Waiting for participants...',
                          style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 8),
                      Text('Room: ${widget.roomId}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            if (_mediaStarted) _buildLocalVideoPreview(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FloatingActionButton(
                  heroTag: 'mic',
                  onPressed: _mediaStarted ? _toggleMic : null,
                  backgroundColor:
                      _micEnabled && _mediaStarted ? Colors.blue : Colors.grey,
                  child: Icon(_micEnabled ? Icons.mic : Icons.mic_off)),
              FloatingActionButton(
                  heroTag: 'hangup',
                  onPressed: () {}, //_hangUp,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end)),
              FloatingActionButton(
                  heroTag: 'video',
                  onPressed: _mediaStarted ? _toggleVideo : null,
                  backgroundColor: _videoEnabled && _mediaStarted
                      ? Colors.blue
                      : Colors.grey,
                  child: Icon(
                      _videoEnabled ? Icons.videocam : Icons.videocam_off)),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FloatingActionButton.extended(
                  heroTag: 'switchCam',
                  onPressed: _mediaStarted &&
                          localStream != null &&
                          localStream!.getVideoTracks().isNotEmpty
                      ? _switchCamera
                      : null,
                  backgroundColor: Colors.blueGrey.shade700,
                  icon: const Icon(Icons.cameraswitch),
                  label: const Text('Camera')),
              FloatingActionButton.extended(
                  heroTag: 'speaker',
                  onPressed: _mediaStarted ? _toggleSpeaker : null,
                  backgroundColor: _speakerOn ? Colors.blue : Colors.grey,
                  icon: const Icon(Icons.volume_up),
                  label: Text(_speakerOn ? 'Speaker' : 'Earpiece')),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid(List<StreamInfo> remoteVideoStreams) {
    _debugEventFlow('buildVideoGrid', remoteVideoStreams.length);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: remoteVideoStreams.length == 1 ? 1 : 2,
        childAspectRatio: remoteVideoStreams.length == 1 ? 1 : 1.3,
      ),
      itemCount: remoteVideoStreams.length,
      itemBuilder: (context, index) {
        final streamInfo = remoteVideoStreams[index];
        final peerName = _getPeerName(streamInfo.producerId);
        return _buildVideoTile(streamInfo.renderer!, peerName, false);
      },
    );
  }

  Widget _buildVideoTile(RTCVideoRenderer renderer, String name, bool isLocal) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black45,
              child: RTCVideoView(
                renderer,
                filterQuality: FilterQuality.high,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
            if (isLocal)
              Positioned.fill(
                child: Container(
                  color: _videoEnabled ? Colors.transparent : Colors.black,
                  child: _videoEnabled
                      ? null
                      : const Center(
                          child: Icon(Icons.videocam_off,
                              color: Colors.white, size: 40)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVideoPreview() {
    return Positioned(
      bottom: 160,
      right: 16,
      width: 140,
      height: 186,
      child: _buildVideoTile(_localRenderer, 'You', true),
    );
  }

  void _log(String message) => developer.log('[$runtimeType] $message');
}
