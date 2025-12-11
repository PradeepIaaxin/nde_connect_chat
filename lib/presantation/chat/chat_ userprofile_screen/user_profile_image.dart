import 'package:flutter/material.dart';

class ViewImage extends StatelessWidget {
  final String username;
  final String imageurl;
  final String? grpname;

  const ViewImage({
    super.key,
    required this.imageurl,
    required this.username,
    this.grpname,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName = username.isNotEmpty
        ? username
        : (grpname?.isNotEmpty == true ? grpname! : '');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        shadowColor: Colors.grey.shade700,
        elevation: 2,
        title: Text(
          displayName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: double.infinity,
          height: 450,
          child: imageurl.isEmpty
              ? const Center(
                  child: Text(
                    "No Profile photo",
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                )
              : Image.network(
                  imageurl,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.fitHeight,
                ),
        ),
      ),
    );
  }
}
