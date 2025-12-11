import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/fileinfo/fileinfo_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/fileinfo/fileinfo_event.dart';
import 'package:nde_email/presantation/drive/Bloc/fileinfo/fileinfor_state.dart';
import 'package:nde_email/presantation/drive/model/folderinfo_model.dart';
import 'package:nde_email/utils/datetime/dateFormatter.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:shimmer/shimmer.dart';

class FileDetailScreen extends StatefulWidget {
  final String fileID;
  const FileDetailScreen({super.key, required this.fileID});

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showTitle = true);
    });
  }

  void _loadFolders() {
    context
        .read<InfoDetailsBloc>()
        .add(FetchInfoDetails(fileID: widget.fileID));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfoDetailsBloc, FileDetailState>(
      builder: (context, state) {
        String titleText = "Loading...";

        if (state is InfoDetailsLoaded &&
            state.infoResponse.isNotEmpty &&
            _showTitle) {
          titleText = state.infoResponse.first.name;
        } else if (state is InfoDetailsError) {
          titleText = "Error loading file";
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              titleText,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(FileDetailState state) {
    if (state is InfoDetailsLoading || !_showTitle) {
      return _buildShimmerLoading();
    } else if (state is InfoDetailsError) {
      return Center(child: Text("Error: ${state.message}"));
    } else if (state is InfoDetailsLoaded && state.infoResponse.isNotEmpty) {
      final INfoModelItem file = state.infoResponse.first;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File Preview
            Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildMimeIcon(file)),
            const SizedBox(height: 20),

            // File Info
            _infoTile("Type", file.mimetype),
            _infoTile("Size", "${(file.size / 1024).toStringAsFixed(2)} KB"),
            _infoTile(
                "Storage Used", "${(file.size / 1024).toStringAsFixed(2)} KB"),
            _infoTile(
                "Created", DateTimeUtils.formatMessageTime(file.createdAt)),
            _infoTile(
                "Modified", DateTimeUtils.formatMessageTime(file.updatedAt)),

            const Divider(height: 32, color: Colors.black),
            const Text("Who has access", style: TextStyle(color: Colors.black)),
            const SizedBox(height: 12),

            // Access Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: file.owner.profilePic.isEmpty
                      ? ColorUtil.getColorFromAlphabet(file.owner.name)
                      : Colors.transparent,
                  child: file.owner.profilePic.isEmpty
                      ? Text(file.owner.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold))
                      : ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: file.owner.profilePic,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.error),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.lock_outline, color: Colors.black),
                const SizedBox(width: 8),
                Text(file.permission ? "Has permission" : "Restricted",
                    style: const TextStyle(color: Colors.black)),
              ],
            ),

            const Divider(height: 32, color: Colors.black),
            const Text("Activity", style: TextStyle(color: Colors.black)),
            const SizedBox(height: 12),

            // Activity Info
            _activityTile(file.owner.name, "Created this file",
                file.createdAt.toLocal().toString()),
            _activityTile(file.owner.name, "Last modified this file",
                file.updatedAt.toLocal().toString()),
          ],
        ),
      );
    } else {
      return const Center(child: Text("No data available"));
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer for File Preview
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Shimmer for File Info
            _shimmerInfoTile(),
            _shimmerInfoTile(),
            _shimmerInfoTile(),
            _shimmerInfoTile(),
            _shimmerInfoTile(),

            const Divider(height: 32, color: Colors.transparent),
            Container(height: 16, width: 120, color: Colors.white),
            const SizedBox(height: 12),

            // Shimmer for Access Info
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Container(height: 16, width: 24, color: Colors.white),
                const SizedBox(width: 8),
                Container(height: 16, width: 100, color: Colors.white),
              ],
            ),

            const Divider(height: 32, color: Colors.transparent),
            Container(height: 16, width: 80, color: Colors.white),
            const SizedBox(height: 12),

            // Shimmer for Activity Info
            _shimmerActivityTile(),
            _shimmerActivityTile(),
          ],
        ),
      ),
    );
  }
}

// Reusable Shimmer widgets
Widget _shimmerInfoTile() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(height: 16, width: 80, color: Colors.white),
        const SizedBox(width: 20),
        Expanded(
          child: Container(height: 16, color: Colors.white),
        ),
      ],
    ),
  );
}

Widget _shimmerActivityTile() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 32, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Container(height: 16, width: 60, color: Colors.white),
      ],
    ),
  );
}

// Your existing widgets, unchanged
Widget _infoTile(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black))),
        Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black45))),
      ],
    ),
  );
}

Widget _activityTile(String actor, String action, String date) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        CircleAvatar(
            radius: 16,
            backgroundColor: ColorUtil.getColorFromAlphabet(actor),
            child: Text(actor[0].toUpperCase(),
                style: const TextStyle(color: Colors.white))),
        const SizedBox(width: 8), // Replaced hSpace8 with SizedBox
        Expanded(
          child: Text("$actor\n$action",
              style: const TextStyle(color: Colors.black, height: 1.3)),
        ),
        Text(DateFormatter.formatToReadableDate(date.toString()),
            style: const TextStyle(color: Colors.black45)),
      ],
    ),
  );
}

Widget _buildMimeIcon(INfoModelItem folder) {
  final type = folder.type.toLowerCase();
  final mimeType = folder.mimetype.toLowerCase().trim();

  if (type == 'folder') {
    return Image.asset(
      "assets/images/folder.png",
      fit: BoxFit.cover,
      color: Colors.amber,
    );
  }

  if (mimeType.contains('msword') ||
      mimeType.contains('officedocument.word') ||
      mimeType.contains('ndocx')) {
    return Image.asset('assets/images/word.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
    return Image.asset('assets/images/sheets.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('presentation') ||
      mimeType.contains('powerpoint') ||
      mimeType.contains('slides')) {
    return Image.asset('assets/images/sheets.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('pdf')) {
    return Image.asset('assets/images/pdf.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('image') ||
      mimeType.contains('png') ||
      mimeType.contains('jpg') ||
      mimeType.contains('jpeg')) {
    return Image.asset('assets/images/image.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('video')) {
    return Image.asset('assets/images/video.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('audio')) {
    return Image.asset('assets/images/headphones.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('text') || mimeType.contains('plain')) {
    return Image.asset('assets/images/text.png', fit: BoxFit.cover);
  }

  if (mimeType.contains('zip') ||
      mimeType.contains('rar') ||
      mimeType.contains('compressed') ||
      mimeType.contains('octet-stream')) {
    return Image.asset('assets/images/zip.png', fit: BoxFit.cover);
  }

  // Fallback icon for unrecognized types
  return Image.asset('assets/images/image.png', fit: BoxFit.cover);
}
