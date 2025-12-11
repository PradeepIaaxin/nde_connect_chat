import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:video_player/video_player.dart';
import 'CustomAppBar_Widget.dart';
import 'buttombarWigate.dart';

class VideoMessageScreen extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final String lastSendTime;

  const VideoMessageScreen({
    Key? key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.lastSendTime,
  }) : super(key: key);

  @override
  _VideoMessageScreenState createState() => _VideoMessageScreenState();
}

class _VideoMessageScreenState extends State<VideoMessageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(lastSendTime: widget.lastSendTime),
      body: Center(
        child: VideoMessageWidget(
          videoUrl: widget.videoUrl,
          thumbnailUrl: widget.thumbnailUrl,
          lastSendTime: widget.lastSendTime,
        ),
      ),
      bottomNavigationBar: BottomBarWidget(
        onReplyPressed: () {
          Messenger.alert(msg: 'Reply feature tapped');
        },
        onEmojiPressed: () {
          Messenger.alert(msg: 'Emoji picker opened');
        },
      ),
    );
  }
}

class VideoMessageWidget extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;

  const VideoMessageWidget({
    Key? key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required lastSendTime,
  }) : super(key: key);

  @override
  _VideoMessageWidgetState createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isInitialized) {
      setState(() {
        if (_controller.value.isPlaying) {
          _controller.pause();
          _isPlaying = false;
        } else {
          _controller.play();
          _isPlaying = true;
        }
      });
    }
  }

  void _openFullScreen() {
    if (_controller.value.isInitialized) {
      MyRouter.push(
        screen: FullScreenVideoPlayer(videoUrl: widget.videoUrl),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFullScreen,
      child: Container(
        width: 250,
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isLoading)
              Image.network(
                widget.thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else if (_controller.value.isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: VideoPlayer(_controller),
              ),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white),
            if (!_isLoading && !_isPlaying)
              IconButton(
                icon:
                    const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                onPressed: _togglePlayPause,
              ),
          ],
        ),
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _isPlaying = true;
        });
      }).catchError((error) {
        log("Error loading video: $error");
      });
  }



  

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isInitialized) {
      setState(() {
        if (_controller.value.isPlaying) {
          _controller.pause();
          _isPlaying = false;
        } else {
          _controller.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_controller.value.isInitialized) VideoPlayer(_controller),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: _togglePlayPause,
            ),
          ),
        ],
      ),
    );
  }
}
