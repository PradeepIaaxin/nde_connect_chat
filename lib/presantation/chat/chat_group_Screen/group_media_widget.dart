// import 'dart:io';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:nde_email/presantation/chat/chat_group_Screen/group_media_viewer.dart';

// class GroupedImagesWidget extends StatelessWidget {
//   final List<String> images;
//   final Function(int index)? onImageTap;

//   const GroupedImagesWidget({
//     Key? key,
//     required this.images,
//     this.onImageTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (images.isEmpty) return const SizedBox.shrink();

//     return Container(
//       constraints: const BoxConstraints(maxWidth: 260),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: _buildLayout(context),
//       ),
//     );
//   }

//   Widget _buildLayout(BuildContext context) {
//     int count = images.length;

//     if (count == 1) {
//       return _buildSingleImage(context, 0, height: 250, width: double.infinity);
//     } else if (count == 2) {
//       return Row(
//         children: [
//           Expanded(child: _buildSingleImage(context, 0, height: 120)),
//           const SizedBox(width: 2),
//           Expanded(child: _buildSingleImage(context, 1, height: 120)),
//         ],
//       );
//     } else if (count == 3) {
//       return Column(
//         children: [
//           _buildSingleImage(context, 0, height: 120, width: double.infinity),
//           const SizedBox(height: 2),
//           Row(
//             children: [
//               Expanded(child: _buildSingleImage(context, 1, height: 100)),
//               const SizedBox(width: 2),
//               Expanded(child: _buildSingleImage(context, 2, height: 100)),
//             ],
//           ),
//         ],
//       );
//     } else {
//       return Column(
//         children: [
//           Row(
//             children: [
//               Expanded(child: _buildSingleImage(context, 0, height: 100)),
//               const SizedBox(width: 2),
//               Expanded(child: _buildSingleImage(context, 1, height: 100)),
//             ],
//           ),
//           const SizedBox(height: 2),
//           Row(
//             children: [
//               Expanded(child: _buildSingleImage(context, 2, height: 100)),
//               const SizedBox(width: 2),
//               Expanded(
//                 child: count > 4
//                     ? Stack(
//                         children: [
//                           _buildSingleImage(context, 3, height: 100),
//                           Positioned.fill(
//                             child: Container(
//                               color: Colors.black54,
//                               child: Center(
//                                 child: Text(
//                                   "+${count - 3}",
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )
//                     : _buildSingleImage(context, 3, height: 100),
//               ),
//             ],
//           ),
//         ],
//       );
//     }
//   }

//   Widget _buildSingleImage(BuildContext context, int index,
//       {double? height, double? width}) {
//     final imagePath = images[index];
//     final isLocal =
//         !imagePath.startsWith('http') && !imagePath.startsWith('https');

//     return GestureDetector(
//       onTap: () {
//         if (onImageTap != null) {
//           onImageTap!(index);
//         } else {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => GroupedMediaViewer(
//                 mediaUrls: images,
//                 initialIndex: index,
//               ),
//             ),
//           );
//         }
//       },
//       child: SizedBox(
//         height: height,
//         width: width,
//         child: isLocal
//             ? Image.file(
//                 File(imagePath.replaceFirst('file://', '')),
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   color: Colors.grey[300],
//                   child: const Icon(Icons.broken_image, color: Colors.grey),
//                 ),
//               )
//             : CachedNetworkImage(
//                 imageUrl: imagePath,
//                 fit: BoxFit.cover,
//                 placeholder: (context, url) => Container(
//                   color: Colors.grey[300],
//                   child: const Center(child: CircularProgressIndicator()),
//                 ),
//                 errorWidget: (context, url, error) => Container(
//                   color: Colors.grey[300],
//                   child: const Icon(Icons.error),
//                 ),
//               ),
//       ),
//     );
//   }
// }