import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/fileSize.dart';
import 'package:nde_email/presantation/drive/view/recent_screen.dart';
import 'package:nde_email/presantation/drive/view/storage_screen.dart';
import 'package:nde_email/presantation/drive/view/trash_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';

class StorageItem {
  final String type;
  final double size;

  const StorageItem({required this.type, required this.size});
}

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  FileStorageResponse? storageData;
  final double totalCapacity = 5 * 1024 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<FileStorageResponse> fetchFileStats() async {
    final String? accessToken = await UserPreferences.getAccessToken();
    final String? defaultWorkspace =
        await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      throw Exception(
          'Missing authentication credentials. Please log in again.');
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace,
      'Content-Type': 'application/json',
    };

    try {
      final response = await Dio().get(
        'https://api.nowdigitaleasy.com/drive/v1/files',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data.containsKey("data")
            ? FileStorageResponse.fromJson(data["data"])
            : FileStorageResponse.fromJson(data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Failed to load file stats: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch file stats: ${e.message}');
    } catch (e) {
      throw Exception(
          'An unknown error occurred while fetching file stats: $e');
    }
  }

  Future<void> _loadStorageStats() async {
    try {
      final data = await fetchFileStats();
      if (mounted) {
        setState(() {
          storageData = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading storage stats: $e');
    }
  }

  Color getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'images':
        return Colors.orange;
      case 'audios':
        return Colors.blue;
      case 'documents':
        return Colors.green;
      case 'videos':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final double usedBytes = storageData?.totelsize?.size?.toDouble() ?? 0;
    final double usagePercent = usedBytes / totalCapacity;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double iconSize = screenWidth * 0.05;

    List<StorageItem> items = storageData?.filesize?.map((fileSize) {
          return StorageItem(
            type: fileSize.type,
            size: fileSize.size?.toDouble() ?? 0,
          );
        }).toList() ??
        [];

    return Drawer(
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _DrawerHeader(),
              const Divider(),
              _buildDrawerItems(iconSize),
              _buildAdditionalItems(iconSize),
              if (storageData != null) ...[
                _StorageInfoSection(
                  usedBytes: usedBytes,
                  usagePercent: usagePercent,
                  totalCapacity: totalCapacity,
                  items: items,
                  formatFileSize: formatFileSize,
                  getColorByType: getColorByType,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItems(double iconSize) {
    return Column(
      children: [
        _drawerItem(
          icon: Icons.access_time,
          title: "Recent",
          iconSize: iconSize,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const RecentScreen()));
          },
        ),
        _drawerItem(
            icon: Icons.upload_file,
            title: "Uploads",
            iconSize: iconSize,
            onTap: () {}),
        _drawerItem(
            icon: Icons.offline_pin,
            title: "Offline",
            iconSize: iconSize,
            onTap: () {}),
        _drawerItem(
          icon: Icons.delete,
          title: "Trash",
          iconSize: iconSize,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const TrashScreen()));
          },
        ),
        _drawerItem(
            icon: Icons.report_problem,
            title: "Spam",
            iconSize: iconSize,
            onTap: () {}),
      ],
    );
  }

  Widget _buildAdditionalItems(double iconSize) {
    return Column(
      children: [
        _drawerItem(
            icon: Icons.backup,
            title: "Backups",
            iconSize: iconSize,
            onTap: () {}),
        _drawerItem(
            icon: Icons.settings,
            title: "Settings",
            iconSize: iconSize,
            onTap: () {}),
        _drawerItem(
            icon: Icons.help,
            title: "Help & feedback",
            iconSize: iconSize,
            onTap: () {}),
        _drawerItem(
          icon: Icons.cloud,
          title: "Storage",
          iconSize: iconSize,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const StorageScreen()));
          },
        ),
      ],
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700, size: iconSize),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 30, bottom: 10),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: 'Nde', style: TextStyle(color: chatColor)),
                const TextSpan(
                  text: " Drive",
                  style: TextStyle(fontSize: 20, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageInfoSection extends StatelessWidget {
  const _StorageInfoSection({
    required this.usedBytes,
    required this.usagePercent,
    required this.totalCapacity,
    required this.items,
    required this.formatFileSize,
    required this.getColorByType,
  });

  final double usedBytes;
  final double usagePercent;
  final double totalCapacity;
  final List<StorageItem> items;
  final String Function(int bytes) formatFileSize;
  final Color Function(String type) getColorByType;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const StorageScreen()));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StorageBar(
                items: items,
                usedBytes: usedBytes,
                getColorByType: getColorByType),
            const SizedBox(height: 12),
            Text(
              "${formatFileSize(usedBytes.toInt())} of ${formatFileSize(totalCapacity.toInt())} used (${(usagePercent * 100).toStringAsFixed(1)}%)",
              style:
                  const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),

            // Wrap(
            //   spacing: 10,
            //   runSpacing: 8,
            //   children: items.map((item) {
            //     return _StorageLegendItem(
            //       item: item,
            //       formatFileSize: formatFileSize,
            //       getColorByType: getColorByType,
            //     );
            //   }).toList(),
            // ),
          ],
        ),
      ),
    );
  }
}

class _StorageBar extends StatelessWidget {
  const _StorageBar(
      {required this.items,
      required this.usedBytes,
      required this.getColorByType});

  final List<StorageItem> items;
  final double usedBytes;
  final Color Function(String type) getColorByType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          return Row(
            children: items.map((item) {
              final width = totalWidth * (item.size / max(usedBytes, 1));
              return Container(width: width, color: getColorByType(item.type));
            }).toList(),
          );
        },
      ),
    );
  }
}

class _StorageLegendItem extends StatelessWidget {
  const _StorageLegendItem({
    required this.item,
    required this.formatFileSize,
    required this.getColorByType,
  });

  final StorageItem item;
  final String Function(int bytes) formatFileSize;
  final Color Function(String type) getColorByType;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: getColorByType(item.type), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('${item.type} (${formatFileSize(item.size.toInt())})',
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
