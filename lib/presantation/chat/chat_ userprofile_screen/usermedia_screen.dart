import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_bloc.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_event.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/bloc/profile_screen_state.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/data/view_deatilsrepo.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/doc_links_model.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/MixedMediaViewer.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_viewer.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class UsermediaScreen extends StatefulWidget {
  const UsermediaScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  final String userId;
  final String username;

  @override
  State<UsermediaScreen> createState() => _UsermediaScreenState();
}

class _UsermediaScreenState extends State<UsermediaScreen>
    with SingleTickerProviderStateMixin {
  final mediaRepository = MediaRepository();
  late TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    debugPrint("Current user ID : ${widget.userId}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.iconActive,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          dividerColor: Colors.transparent,
          labelColor: AppColors.iconDefault,
          tabs: const [
            Tab(
              text: "Media",
            ),
            Tab(text: "Docs"),
            Tab(text: "Links"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BlocProvider(
            create: (_) => MediaBloc(mediaRepository)
              ..add(FetchMedia(userId: widget.userId, type: 'media')),
            child: MediaTab(userId: widget.userId, username: widget.username),
          ),
          BlocProvider(
            create: (_) => MediaBloc(mediaRepository)
              ..add(FetchMedia(userId: widget.userId, type: 'doc')),
            child: const DocsTab(),
          ),
          BlocProvider(
            create: (_) => MediaBloc(mediaRepository)
              ..add(FetchMedia(userId: widget.userId, type: 'link')),
            child: const LinksTab(),
          ),
        ],
      ),
    );
  }
}

class MediaTab extends StatelessWidget {
  final String userId;
  final String username;
  MediaTab({super.key, required this.userId, required this.username});

  /// 🔥 THUMBNAIL FUTURE CACHE (VERY IMPORTANT)
  final Map<String, Future<File?>> _thumbFutureCache = {};

  Future<File?> _getThumb(String url) {
    return _thumbFutureCache.putIfAbsent(
      url,
      () => VideoThumbUtil.generateFromUrl(url),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  bool _isVideo(MediaItem item) {
    return item.meta?.mimeType?.startsWith('video') == true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading) {
          return _buildSkeletonGrid();
        }

        if (state is MediaLoaded) {
          final items = state.items;
          if (items.isEmpty) {
            return const Center(child: Text("No media found"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final isVideo = _isVideo(item);
              final url = item.originalUrl ?? '';

              return GestureDetector(
                onTap: () {
                  MyRouter.push(
                    screen: MixedMediaViewer(
                      items: items.map((item) {
                        return GroupMediaItem(
                          previewUrl:
                              item.thumbnailImageUrl ?? item.originalUrl ?? '',
                          mediaUrl: item.originalUrl ?? '',
                          isVideo: _isVideo(item),
                          senderName: item.sender.firstName,
                          senderId: item.sender.id,
                          time: item.createdAt,
                        );
                      }).toList(),
                      initialIndex: index,
                      conversionalId: userId,
                      fullName: username,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      /// 🖼 BASE IMAGE (ONLY ONCE)
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),

                      /// 🎥 VIDEO OVERLAY
                      if (isVideo)
                        Stack(
                          fit: StackFit.expand,
                          children: [
                            /// 🎞 THUMB (CACHED)
                            FutureBuilder<File?>(
                              future: _getThumb(url),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.file(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                            /// DARK OVERLAY
                            Container(color: Colors.black26),

                            /// ▶️ PLAY ICON
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        if (state is MediaError) {
          return const Center(child: Text("Error loading media"));
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ------------------ DOCS TAB ------------------

class DocsTab extends StatelessWidget {
  const DocsTab({super.key});

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return "Unknown size";
    final kb = bytes / 1024;
    final mb = kb / 1024;
    return mb < 1
        ? "${kb.toStringAsFixed(1)} KB"
        : "${mb.toStringAsFixed(1)} MB";
  }

  String _getDisplayFileName(MediaItem item) {
    return item.meta?.fileName ??
        item.meta?.originalFilename ??
        (item.originalUrl != null
            ? Uri.parse(item.originalUrl!).pathSegments.last
            : "Unknown.pdf");
  }

  void _OpenFilex(
      BuildContext context, String urlOrPath, String? fileType) async {
    // 1. If it's a local file, just open it
    if (!urlOrPath.startsWith('http')) {
      await OpenFilex.open(urlOrPath);
      Messenger.alertError("Could not open local file.");

      return;
    }

    // 2. It's a URL - Check if we already have it downloaded
    try {
      final String packageName = "com.nowdigitaleasy.NDEconnect";
      final String baseDir =
          "/storage/emulated/0/Android/media/$packageName/NowDigitalEasy/Media";

      final Directory directory = Directory(baseDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Extract filename
      final String fileName = urlOrPath.split('/').last.split('?').first;
      String safeFileName = fileName.isEmpty
          ? 'document_${DateTime.now().millisecondsSinceEpoch}'
          : fileName;

      // Check for extension
      String extension = p.extension(safeFileName);
      if (extension.isEmpty) {
        if (fileType != null) {
          final lowerType = fileType.toLowerCase();
          if (lowerType.contains('pdf')) {
            extension = '.pdf';
          } else if (lowerType.contains('word') ||
              lowerType.contains('doc') ||
              lowerType.contains('msword')) {
            extension = '.docx';
          } else if (lowerType.contains('excel') ||
              lowerType.contains('sheet') ||
              lowerType.contains('spreadsheet')) {
            extension = '.xlsx';
          } else if (lowerType.contains('presentation') ||
              lowerType.contains('powerpoint')) {
            extension = '.pptx';
          } else if (lowerType.contains('image')) {
            extension = '.jpg';
          } else if (lowerType.contains('video')) {
            extension = '.mp4';
          } else if (lowerType.contains('text') ||
              lowerType.contains('plain')) {
            extension = '.txt';
          } else if (lowerType.contains('csv')) {
            extension = '.csv';
          } else if (lowerType.contains('zip')) {
            extension = '.zip';
          } else if (lowerType.contains('rar')) {
            extension = '.rar';
          } else if (lowerType.contains('json')) {
            extension = '.json';
          } else if (lowerType.contains('xml')) extension = '.xml';
        }

        // Fallback checks on filename/url matching common patterns if no type or type didn't match
        if (extension.isEmpty) {
          final lowerName = safeFileName.toLowerCase();
          if (lowerName.contains('pdf')) {
            extension = '.pdf';
          } else if (lowerName.contains('doc')) {
            extension = '.docx';
          } else if (lowerName.contains('xls')) {
            extension = '.xlsx';
          } else if (lowerName.contains('ppt')) {
            extension = '.pptx';
          }
        }

        if (extension.isNotEmpty) {
          safeFileName += extension;
        }
      }

      final String finalPath = p.join(baseDir, safeFileName);
      final File targetFile = File(finalPath);

      if (await targetFile.exists()) {
        // Open existing
        final result = await OpenFilex.open(finalPath);
        if (result.type != ResultType.done) {
          Messenger.alertError("Could not open file.");
        }
        return;
      }

      // 3. Not downloaded - Request Permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        final status2 = await Permission.manageExternalStorage.request();
        if (!status.isGranted && !status2.isGranted) {
          // handled quietly used in other files
        }
      }

      // 4. Download
      Messenger.alertSuccess('Downloading document...');
      await Dio().download(urlOrPath, finalPath);
      Messenger.alertSuccess('Saved to NowDigitalEasy/Media');

      // 5. Open
      final result = await OpenFilex.open(finalPath);
      if (result.type != ResultType.done) {
        Messenger.alertError('Could not open downloaded file.');
      }
    } catch (e) {
      Messenger.alertError('Failed to open file');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading) {
          return _buildSkeletonList();
        } else if (state is MediaLoaded) {
          // ✅ Filter only file/document items
          final docs = state.items.where((item) {
            final type = item.messageType.toLowerCase();
            final contentType = item.contentType?.toLowerCase() ?? '';
            return type == 'file' ||
                contentType.contains('pdf') ||
                contentType.contains('doc') ||
                contentType.contains('xls') ||
                contentType.contains('application');
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("No documents found"));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(indent: 70, endIndent: 10),
            itemBuilder: (context, index) {
              final item = docs[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file,
                    color: Colors.blue, size: 32),
                title: Text(
                  _getDisplayFileName(item),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  "${_formatSize(item.meta?.size)} • ${item.createdAt ?? ''}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  if (item.originalUrl != null) {
                    _OpenFilex(context, item.originalUrl!, item.meta?.mimeType);
                  } else {
                    log("No URL available for this document");
                    Messenger.alertError("Document URL not found");
                  }
                },
              );
            },
          );
        } else if (state is MediaError) {
          return const Center(child: Text("Error loading documents"));
        } else {
          return const Center(child: Text("No data found"));
        }
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: 5,
      separatorBuilder: (_, __) => const Divider(indent: 70, endIndent: 10),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: Container(width: 40, height: 40, color: Colors.white),
            title: Container(height: 16, color: Colors.white),
            subtitle: Container(height: 14, width: 100, color: Colors.white),
          ),
        );
      },
    );
  }
}

// ------------------ LINKS TAB ------------------

class LinksTab extends StatelessWidget {
  const LinksTab({super.key});

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: 5,
      separatorBuilder: (_, __) => const Divider(indent: 70, endIndent: 10),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: Container(width: 40, height: 40, color: Colors.white),
            title: Container(height: 16, color: Colors.white),
            subtitle: Container(height: 14, width: 150, color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading) {
          return _buildSkeletonList();
        } else if (state is MediaLoaded) {
          if (state.items.isEmpty) {
            return const Center(child: Text("No links found"));
          }

          final links = <String>[];
          for (var item in state.items) {
            links.addAll(item.fullLinks.cast<String>());
            links.addAll(item.bareLinks.cast<String>());
            links.addAll(item.emailLinks.cast<String>());
            if (item.originalUrl != null &&
                item.originalUrl!.startsWith("http")) {
              links.add(item.originalUrl!);
            }
          }

          final uniqueLinks = links.toSet().toList();

          if (uniqueLinks.isEmpty) {
            return const Center(child: Text("No valid links found"));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: uniqueLinks.length,
            separatorBuilder: (_, __) =>
                const Divider(indent: 70, endIndent: 10),
            itemBuilder: (context, index) {
              final link = uniqueLinks[index];
              return ListTile(
                leading: const Icon(Icons.link, color: Colors.green),
                title: Text(
                  link,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text("Tap to open"),
                onTap: () {
                  launchUrl(Uri.parse(link),
                      mode: LaunchMode.externalApplication);
                },
              );
            },
          );
        } else if (state is MediaError) {
          return const Center(child: Text("Error loading links"));
        } else {
          return const Center(child: Text("No data found"));
        }
      },
    );
  }
}
