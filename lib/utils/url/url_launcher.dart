import 'package:nde_email/utils/reusbale/common_import.dart';

class UrlLauncherHelper {
  static Future<void> launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Messenger.alert(msg: "Could not launch URL");
    }
  }
}
