import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/widget/grp_create_screen.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:share_plus/share_plus.dart';

class ViewImage extends StatefulWidget {
  final String username;
  final String imageurl;
  final String? grpname;
  final String heroTag;
  final bool isGroup;
  final String? grpId;
  final String? conversionalId;

  const ViewImage({
    super.key,
    required this.imageurl,
    required this.username,
    this.grpname,
    required this.heroTag,
    this.isGroup = false,
    this.grpId, this.conversionalId,
  });

  @override
  State<ViewImage> createState() => _ViewImageState();
}

class _ViewImageState extends State<ViewImage>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _bgOpacity = 1;
  bool _showAppBar = true;

  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.imageurl.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(widget.imageurl), context);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
      _showAppBar = true;
    } else {
      final position = _doubleTapDetails!.localPosition;
      _controller.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
      _showAppBar = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.username.isNotEmpty
        ? widget.username
        : (widget.grpname?.isNotEmpty == true ? widget.grpname! : '');

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha:_bgOpacity),
      body: Stack(
        children: [
          /// ================= IMAGE VIEW =================
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (d) => _doubleTapDetails = d,
            onDoubleTap: _handleDoubleTap,
            onVerticalDragUpdate: (details) {
              _dragOffset += details.delta.dy;
              _bgOpacity = (1 - (_dragOffset.abs() / 400)).clamp(0.0, 1.0);
              setState(() {});
            },
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;

              // WhatsApp velocity dismiss
              if (_dragOffset.abs() > 180 || velocity.abs() > 800) {
                Navigator.pop(context);
              } else {
                _dragOffset = 0;
                _bgOpacity = 1;
                setState(() {});
              }
            },
            child: Center(
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: RepaintBoundary(
                  child: Hero(
                    tag: widget.heroTag,
                    child: InteractiveViewer(
                      transformationController: _controller,
                      panEnabled: true,
                      minScale: 1,
                      maxScale: 4,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      onInteractionStart: (_) {
                        setState(() => _showAppBar = false);
                      },
                      onInteractionEnd: (_) {
                        setState(() => _showAppBar = true);
                      },
                      child: widget.imageurl.isEmpty
                          ? const Text(
                              "No Profile photo",
                              style: TextStyle(color: Colors.white),
                            )
                          : CachedNetworkImage(
                              imageUrl: widget.imageurl,
                              fit: BoxFit.contain,
                              memCacheWidth: 1440,
                              fadeInDuration: const Duration(milliseconds: 120),
                              placeholder: (c, _) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.error,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// ================= TOP BAR (AUTO HIDE) =================
          if (_showAppBar)
            SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _bgOpacity,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.black.withValues(alpha:0.35),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child:
                            const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.isGroup) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            MyRouter.push(
                              screen: GroupNameEditScreen(
                                initialValue: widget.username,
                                keyToEdit: "group_name",
                                groupId: widget.grpId ?? "",
                                groupImage: widget.imageurl,
                                  convoId: widget.conversionalId
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            if (widget.imageurl.isNotEmpty) {
                              Share.share(widget.imageurl);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
