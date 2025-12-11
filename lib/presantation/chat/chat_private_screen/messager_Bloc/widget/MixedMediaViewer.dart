import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../../utils/reusbale/common_import.dart';
import '../../../../widgets/chat_widgets/Common/grouped_media_viewer.dart';
import 'VideoPlayerScreen.dart';


class MixedMediaViewer extends StatefulWidget {
  final List<GroupMediaItem> items;
  final int initialIndex;

  const MixedMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<MixedMediaViewer> createState() => _MixedMediaViewerState();
}

class _MixedMediaViewerState extends State<MixedMediaViewer> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_index + 1} / ${widget.items.length}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final item = widget.items[i];
          if (item.isVideo) {
            final isNetwork = item.mediaUrl.startsWith('http');
            // Simple full-screen player; you can customise this
            return Center(
              child: VideoPlayerScreen(
                path: item.mediaUrl,
                isNetwork: isNetwork,
                isVideo: true,
              ),
            );
          } else {
            return PhotoView(
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              imageProvider: item.mediaUrl.startsWith('http')
                  ? CachedNetworkImageProvider(item.mediaUrl)
                  : FileImage(File(item.mediaUrl)) as ImageProvider,
            );
          }
        },
      ),
    );
  }
}
