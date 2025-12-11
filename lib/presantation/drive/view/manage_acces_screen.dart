import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/manage_access/manage_access_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/manage_access/manage_event.dart';
import 'package:nde_email/presantation/drive/Bloc/manage_access/manage_state.dart';
import 'package:nde_email/presantation/drive/model/send/send_model.dart'
    show UserDetails;
import 'package:shimmer/shimmer.dart';

class ManageAccessScreenUI extends StatelessWidget {
  final String fileId;

  const ManageAccessScreenUI({super.key, required this.fileId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManageAccessBloc()..add(FetchShareDetailsEvent(fileId)),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Manage access'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.link),
            const SizedBox(width: 12),
          ],
        ),
        body: BlocBuilder<ManageAccessBloc, ManageAccessState>(
          builder: (context, state) {
            if (state is ManageAccessLoaded) {
              final data = state.shareDetails;
              final owner = data.owner;
              final users = data.users ?? [];
              final sharePermission = data.sharePermission ?? "restricted";

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("People with access",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (owner != null)
                    _buildPersonTile(
                      name: "${owner.firstName} ${owner.lastName}",
                      email: owner.email ?? "",
                      role: "Owner",
                      imageUrl: owner.profilePic,
                      bgColor: const Color.fromARGB(255, 10, 10, 10),
                    ),
                  const SizedBox(height: 10),
                  ...users.map((user) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildPersonTile(
                        name:
                            "${user.firstName ?? 'Unknown'} ${user.lastName ?? 'name'}"
                                .trim(),
                        email: user.email ?? "",
                        role: _mapPermissionToRole(user),
                        imageUrl: (user.profilePic?.isNotEmpty ?? false)
                            ? user.profilePic
                            : null,
                        initial: (user.firstName?.isNotEmpty ?? false)
                            ? user.firstName![0].toUpperCase()
                            : '',
                        bgColor: _getColorForRole(user),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 30),
                  const Text("General access",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock),
                    title: Text(
                      _getGeneralAccessTitle(sharePermission),
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      _getGeneralAccessSubtitle(sharePermission),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text("Change",
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                ],
              );
            } else if (state is ManageAccessError) {
              return Center(child: Text("Error: ${state.message}"));
            } else {
              return _buildShimmerLoadingUI();
            }
          },
        ),
      ),
    );
  }

  /// ✅ Shimmer Loading UI
  Widget _buildShimmerLoadingUI() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(width: 150, height: 20),
              const SizedBox(height: 16),
              ...List.generate(3, (index) => _shimmerPersonTile()),
              const SizedBox(height: 30),
              _shimmerBox(width: 150, height: 20),
              const SizedBox(height: 16),
              _shimmerBox(width: double.infinity, height: 60),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ Shimmer placeholder for person tile
  Widget _shimmerPersonTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 120, height: 14),
                const SizedBox(height: 4),
                _shimmerBox(width: 180, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _shimmerBox(width: 50, height: 14),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// ✅ Person Tile UI
  Widget _buildPersonTile({
    required String name,
    required String email,
    required String role,
    String? imageUrl,
    String? initial,
    required Color bgColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: imageUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
          : CircleAvatar(
              backgroundColor: bgColor,
              child: Text(
                initial ?? (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
      title: Text(name, style: const TextStyle(color: Colors.black)),
      subtitle: Text(email, style: const TextStyle(color: Colors.black87)),
      trailing: Text(role, style: const TextStyle(color: Colors.blue)),
    );
  }

  String _mapPermissionToRole(UserDetails user) {
    switch (user.permission) {
      case 1:
        return "Viewer";
      case 2:
        return "Editor";
      default:
        return "Unknown";
    }
  }

  Color _getColorForRole(UserDetails user) {
    switch (user.permission) {
      case 1:
        return Colors.deepOrange;
      case 2:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _getGeneralAccessTitle(String value) {
    switch (value.toLowerCase()) {
      case "restricted":
        return "Restricted";
      case "public":
        return "Public (Anyone with the link)";
      default:
        return "Restricted";
    }
  }

  String _getGeneralAccessSubtitle(String value) {
    switch (value.toLowerCase()) {
      case "restricted":
        return "Only people added can open with the link";
      case "public":
        return "Anyone on the internet with the link can view";
      default:
        return "Only people added can open with the link";
    }
  }
}
