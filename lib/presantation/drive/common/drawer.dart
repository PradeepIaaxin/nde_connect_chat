import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/file_size.dart';
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
  int _selectedIndex = -1;
  String? userName;

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();

    if (mounted) {
      setState(() {
        userName = name ?? "Unknown User";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
    _loadUserData();
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
    final double usedBytes = storageData?.totelsize.size.toDouble() ?? 0;
    final double usagePercent = usedBytes / totalCapacity;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double iconSize = screenWidth * 0.05;

    List<StorageItem> items = storageData?.filesize.map((fileSize) {
          return StorageItem(
            type: fileSize.type,
            size: fileSize.size.toDouble(),
          );
        }).toList() ??
        [];

    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerHeader(
                  userName: userName ?? "Unknown User",
                ),
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
      ),
    );
  }

  Widget _buildDrawerItems(double iconSize) {
    return Column(
      children: [
        _drawerItem(
          index: 0,
          icon: Icons.access_time,
          title: "Recent",
          iconSize: iconSize,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecentScreen(),
              ),
            );
          },
        ),
        _drawerItem(
          index: 1,
          icon: Icons.upload_file_outlined,
          title: "Uploads",
          iconSize: iconSize,
          onTap: () {},
        ),
        _drawerItem(
          index: 2,
          icon: Icons.offline_pin_outlined,
          title: "Offline",
          iconSize: iconSize,
          onTap: () {},
        ),
        _drawerItem(
          index: 3,
          icon: Icons.delete_outline,
          title: "Trash",
          iconSize: iconSize,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrashScreen(),
              ),
            );
          },
        ),
        _drawerItem(
          index: 4,
          icon: Icons.report_problem_outlined,
          title: "Spam",
          iconSize: iconSize,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAdditionalItems(double iconSize) {
    return Column(
      children: [
        _drawerItem(
          index: 5,
          icon: Icons.backup_outlined,
          title: "Backups",
          iconSize: iconSize,
          onTap: () {},
        ),
        _drawerItem(
          index: 6,
          icon: Icons.settings_outlined,
          title: "Settings",
          iconSize: iconSize,
          onTap: () {},
        ),
        _drawerItem(
          index: 7,
          icon: Icons.help_outline_outlined,
          title: "Help & feedback",
          iconSize: iconSize,
          onTap: () {},
        ),
        _drawerItem(
          index: 8,
          icon: Icons.cloud_outlined,
          title: "Storage",
          iconSize: iconSize,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StorageScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _drawerItem({
    required int index,
    required IconData icon,
    required String title,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.iconActive.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            size: iconSize,
            color: isSelected ? AppColors.iconActive : Colors.grey.shade700,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.iconActive : Colors.black87,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });

            onTap();
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String userName;

  const _DrawerHeader({
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 👉 Name + App
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: "Nde ",
                            style: TextStyle(color: chatColor),
                          ),
                          const TextSpan(
                            text: "Drive",
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 👉 Bottom divider
        const Divider(height: 1, thickness: 1),
      ],
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
              "${formatFileSize(usedBytes.toInt())} of "
              "${formatFileSize(totalCapacity.toInt())} used "
              "(${_formatPercent(usagePercent)})",
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
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

String _formatPercent(double value) {
  final percent = value * 100;

  if (percent == 0) return "0%";

  if (percent < 0.1) {
    return "${percent.toStringAsFixed(2)}%";
  }

  return "${percent.toStringAsFixed(1)}%";
}

// ignore: unused_element
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
