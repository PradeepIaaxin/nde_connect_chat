import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/folder_bloc/create_folder_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_event.dart';
import 'package:nde_email/presantation/drive/common/create_dialogue.dart';
import 'package:nde_email/presantation/drive/view/uploadtodrive.dart';
import 'package:nde_email/utils/url/url_launcher.dart';

void displayBottomSheet(BuildContext context, String? fileid) {
  Future<void> _pickFiles(BuildContext context) async {
    Navigator.pop(context);

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      List<PlatformFile> selectedFiles = result.files;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UploadToDriveScreen(
            selectedFiles: selectedFiles,
            parentId: fileid,
          ),
        ),
      );
    }
  }

  Future<void> newContainer() async {
    Navigator.pop(context);
    final result = await showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<CreateFolderBloc>(),
        child: NewBoxDialog(parentId: fileid),
      ),
    );

    if (result == true) {
      context.read<InsideBloc>().add(InFetchStarredFolders(filedId: fileid!));
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 15),
              ),

              // Grid menu
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.9,
                children: [
                  _buildOptionItem(
                    icon: Icons.folder_outlined,
                    label: 'Folder',
                    iconColor: Colors.grey[700],
                    backgroundColor: Colors.grey[100],
                    onTap: newContainer,
                  ),
                  _buildOptionItem(
                    icon: Icons.upload_outlined,
                    label: 'Upload',
                    iconColor: Colors.grey[700],
                    backgroundColor: Colors.grey[100],
                    onTap: () => _pickFiles(context),
                  ),
                  _buildOptionItem(
                    icon: Icons.camera_alt_outlined,
                    label: 'Scan',
                    iconColor: Colors.grey[700],
                    backgroundColor: Colors.grey[100],
                    onTap: () {},
                  ),
                  _buildOptionItem(
                    icon: Icons.article,
                    label: 'Google Docs',
                    iconColor: Colors.blue[700],
                    backgroundColor: Colors.blue[50],
                    onTap: () {
                      UrlLauncherHelper.launchURL(
                        context,
                        'https://play.google.com/store/apps/details?id=com.google.android.apps.docs.editors.docs&hl=en_IN',
                      );
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.add_chart,
                    label: 'Google Sheets',
                    iconColor: Colors.green[700],
                    backgroundColor: Colors.green[50],
                    onTap: () {
                      UrlLauncherHelper.launchURL(
                        context,
                        'https://play.google.com/store/apps/details?id=com.google.android.apps.docs.editors.sheets&hl=en_IN',
                      );
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.slideshow,
                    label: 'Google Slides',
                    iconColor: Colors.orange[700],
                    backgroundColor: Colors.orange[50],
                    onTap: () {
                      UrlLauncherHelper.launchURL(
                        context,
                        'https://play.google.com/store/apps/details?id=com.google.android.apps.docs.editors.slides&hl=en_IN',
                      );
                    },
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

Widget _buildOptionItem({
  required IconData icon,
  required String label,
  required Color? iconColor,
  required Color? backgroundColor,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
