import 'package:flutter/material.dart';
import 'package:nde_email/utils/reusbale/mime.type.dart';
import 'package:nde_email/utils/spacer/spacer.dart';

class BottomSheetOption {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? mimetype;
  final String? foldertype;

  BottomSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.mimetype,
    this.foldertype,
  });
}

void showReusableBottomSheet(
    BuildContext context, List<BottomSheetOption> options,
    {String? title, String? mimetype, String? foldertype}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (context) {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              vSpace18,
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 5),
                  child: Row(
                    children: [
                      buildIcon(
                        type: foldertype,
                        mimeType: mimetype,
                      ),
                      const SizedBox(width: 8), // hSpace8
                      Expanded(
                        // <- This prevents overflow
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              title != null ? Divider(thickness: 1) : voidBox,
              // Build list tiles with conditional dividers
              ...List.generate(options.length, (index) {
                final option = options[index];
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(option.icon),
                      title: Text(option.title),
                      onTap: () {
                        Navigator.pop(context);
                        option.onTap();
                      },
                    ),
                    // Add a divider after 2nd item and at the end of the list
                    if (index == 2 || index == options.length - 8)
                      const Divider(
                        thickness: 1,
                        indent: 60,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
