import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/utils/const/consts.dart';

class GroupedImagesWidget extends StatelessWidget {
  final List<String> images;
  final Function(int index)? onImageTap;

  const GroupedImagesWidget({
    super.key,
    required this.images,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildLayout(context),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    int count = images.length;

    if (count == 1) {
      return _buildSingleImage(context, 0);
    } else if (count == 2) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(width: 3, color: senderColor),
        ),
        child: Row(
          children: [
            Expanded(child: _buildSingleImage(context, 0, height: 150)),
            const SizedBox(width: 0),
            Expanded(child: _buildSingleImage(context, 1, height: 150)),
          ],
        ),
      );
    } else if (count == 3) {
      return Container(
        child: Column(
          children: [
            _buildSingleImage(context, 0, height: 120, width: double.infinity),
            const SizedBox(height: 0),
            Row(
              children: [
                Expanded(child: _buildSingleImage(context, 1, height: 100)),
                const SizedBox(width: 0),
                Expanded(child: _buildSingleImage(context, 2, height: 100)),
              ],
            ),
          ],
        ),
      );
    } else {
      // 4 or more images - 2x2 grid with overflow count
      return Container(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSingleImage(context, 0, height: 100)),
                const SizedBox(width: 0),
                Expanded(child: _buildSingleImage(context, 1, height: 100)),
              ],
            ),
            const SizedBox(height: 0),
            Row(
              children: [
                Expanded(child: _buildSingleImage(context, 2, height: 100)),
                const SizedBox(width: 0),
                Expanded(
                  child: count > 4
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildSingleImage(context, 3, height: 100),
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Text(
                                    "+${count - 4}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildSingleImage(context, 3, height: 100),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSingleImage(BuildContext context, int index,
      {double? height, double? width}) {
    final imagePath = images[index];
    final isLocal =
        imagePath.startsWith('/') || imagePath.startsWith('file://');

    return GestureDetector(
      onTap: () => onImageTap?.call(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 5, color: senderColor),
        ),
        height: height,
        width: width,
        child: isLocal
            ? Image.file(
                File(imagePath.replaceFirst('file://', '')),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}