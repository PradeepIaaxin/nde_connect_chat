// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:nde_email/data/respiratory.dart';
// import 'package:nde_email/presantation/meet/web_rtc/web_rtc_service.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'package:nde_email/presantation/meet/socket/meet_socket.dart';

// class MeetScreen extends StatefulWidget {
//   const MeetScreen({
//     super.key,
//   });

//   @override
//   State<MeetScreen> createState() => _MeetScreenState();
// }

// class _MeetScreenState extends State<MeetScreen> {
//   final MeetSocket _meetSocket = MeetSocket();
//   final MediasoupService _mediasoup = MediasoupService();

//   bool _permissionsGranted = false;
//   bool _micEnabled = true;
//   bool _videoEnabled = true;
//   bool _isConnected = false;

//   String? token;
//   String? userId;
//   String? userName;
//   String? profilePicUrl;
//   String? gmail;

//   Future<void> _loadUserData() async {
//     final fetchedUserId = await UserPreferences.getUserId();
//     final fetchedToken = await UserPreferences.getAccessToken();

//     final fetchedPicUrl = await UserPreferences.getProfilePicKey();
//     final fetchedGmail = await UserPreferences.getEmail();

//     if (mounted) {
//       setState(() {
//         userId = fetchedUserId;
//         token = fetchedToken;

//         profilePicUrl = fetchedPicUrl;
//         gmail = fetchedGmail;
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _initMeeting();
//   }

//   Future<void> _initMeeting() async {
//     final camStatus = await Permission.camera.request();
//     final micStatus = await Permission.microphone.request();

//     if (camStatus.isGranted && micStatus.isGranted) {
//       setState(() => _permissionsGranted = true);

//       // Initialize socket connection
//       await _meetSocket.connect(
//         token: token ?? "",
//         userId: userId ?? "",
//       );

//       // Initialize mediasoup
//       await _mediasoup.initialize(
//         socket: _meetSocket,
//         onRemoteStreamAdded: _handleRemoteStreamAdded,
//         onRemoteStreamRemoved: _handleRemoteStreamRemoved,
//       );

//       setState(() => _isConnected = true);
//     }
//   }

//   void _handleRemoteStreamAdded(String peerId, MediaStream stream) {
//     setState(() {});
//   }

//   void _handleRemoteStreamRemoved(String peerId) {
//     setState(() {});
//   }

//   void _toggleMic() {
//     setState(() => _micEnabled = !_micEnabled);
//     _mediasoup.toggleMic(_micEnabled);
//     _meetSocket.emit(_micEnabled ? 'micOn' : 'micOff', {});
//   }

//   void _toggleVideo() {
//     setState(() => _videoEnabled = !_videoEnabled);
//     _mediasoup.toggleCamera(_videoEnabled);
//     _meetSocket.emit(_videoEnabled ? 'videoOn' : 'videoOff', {});
//   }

//   void _hangUp() {
//     _mediasoup.dispose();
//     _meetSocket.disconnect();
//     Navigator.pop(context);
//   }

//   @override
//   void dispose() {
//     _hangUp();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: _permissionsGranted
//           ? Stack(
//               children: [
//                 _buildMainVideo(),

//                 // Local preview
//                 Positioned(
//                   right: 20,
//                   top: 40,
//                   width: 120,
//                   height: 160,
//                   child: RTCVideoView(
//                     _mediasoup.localRenderer,
//                     mirror: true,
//                     objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                   ),
//                 ),

//                 // Controls
//                 Positioned(
//                   bottom: 40,
//                   left: 0,
//                   right: 0,
//                   child: _buildControls(),
//                 ),
//               ],
//             )
//           : const Center(
//               child: Text(
//                 "Please allow Camera & Microphone permissions",
//                 style: TextStyle(fontSize: 16, color: Colors.white),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//     );
//   }

//   Widget _buildMainVideo() {
//     if (_mediasoup.remoteStreams.isEmpty) {
//       return const Center(
//         child: Text(
//           "Waiting for participants...",
//           style: TextStyle(color: Colors.white, fontSize: 18),
//         ),
//       );
//     }

//     // Display the first remote stream as main video
//     final firstStream = _mediasoup.remoteStreams.values.first;
//     return RTCVideoView(
//       _mediasoup.getRemoteRenderer(firstStream.id)!,
//       objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//     );
//   }

//   Widget _buildControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         IconButton(
//           iconSize: 36,
//           style: IconButton.styleFrom(backgroundColor: Colors.white24),
//           icon: Icon(
//             _micEnabled ? Icons.mic : Icons.mic_off,
//             color: _micEnabled ? Colors.white : Colors.red,
//           ),
//           onPressed: _toggleMic,
//         ),
//         const SizedBox(width: 20),
//         IconButton(
//           iconSize: 36,
//           style: IconButton.styleFrom(backgroundColor: Colors.white24),
//           icon: Icon(
//             _videoEnabled ? Icons.videocam : Icons.videocam_off,
//             color: _videoEnabled ? Colors.white : Colors.red,
//           ),
//           onPressed: _toggleVideo,
//         ),
//         const SizedBox(width: 20),
//         IconButton(
//           iconSize: 40,
//           style: IconButton.styleFrom(backgroundColor: Colors.red),
//           icon: const Icon(Icons.call_end, color: Colors.white),
//           onPressed: _hangUp,
//         ),
//       ],
//     );
//   }
// }
