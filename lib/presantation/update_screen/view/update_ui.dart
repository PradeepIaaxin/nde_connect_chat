import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../utils/snackbar/snackbar.dart';
import 'package:flutter/material.dart';

class UpdateScreen extends StatelessWidget {
  final bool isUpdate;
  final String? appUpdateUrl;
  const UpdateScreen({super.key, required this.isUpdate,  this.appUpdateUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.cardColor;
    final textTheme = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colorScheme,
      body: Center(
        child: Padding(
          padding:  EdgeInsets.all(18),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(
              isUpdate ? "assets/images/update.png" : "assets/images/maintenance.png",
              width: MediaQuery.of(context).size.height*0.4,
              height: MediaQuery.of(context).size.height*0.4,
            ),
            SizedBox(height: MediaQuery.of(context).size.height*0.01),
            Text(
              isUpdate ? "Update" : "We are under maintenance",
              style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.023, color: textTheme),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height*0.01),

            Text(
              isUpdate ? "Your app is deprecated" :"We will right back again",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isUpdate ? MediaQuery.of(context).size.height*0.04 : 0),
            isUpdate? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
              ),
                onPressed: () async {
                  // String? appUrl = 'https://google.com';
                  // if(Platform.isAndroid) {
                  //   appUrl = appUpdateUrl;
                  // }else if(Platform.isIOS) {
                  //   appUrl = appUpdateUrl;
                  // }
                  if(await canLaunchUrlString(appUpdateUrl!)) {
                    launchUrlString(appUpdateUrl!);
                  }
                  else {
                    Messenger.alert(msg: '${'can_not_launch$appUpdateUrl'} ');
                  }
                },
            child: Text("Update Now",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 16),)): const SizedBox()

          ]),
        ),
      ),
    );
  }
}
