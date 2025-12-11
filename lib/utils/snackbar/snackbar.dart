import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nde_email/utils/spacer/spacer.dart';

class Messenger {
  static final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static alertError(String msg) => alert(msg: msg, color: Colors.black);
  static alertSuccess(String msg) => alert(msg: msg, color: Colors.green);

  static alert({required String msg, Color? color}) {
    if (msg.trim().isEmpty) return;
    log(msg);

    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        showCloseIcon: true,
        closeIconColor: Colors.white,
        duration: const Duration(milliseconds: 3500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: const RoundedRectangleBorder(),
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  static pop(BuildContext context) {
    showModalBottomSheet<void>(
      constraints: const BoxConstraints.expand(),
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.blue[100],
          child: ListView.builder(
            itemCount: 25,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text('Item $index'));
            },
          ),
        );
      },
    );
  }

  static alertWithSvgImage({
    required String msg,
    double width = 250,
  }) {
    if (msg.trim().isEmpty) return;
    log(msg);

    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.zero,
        content: SizedBox(
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(2),
                child: SvgPicture.asset(
                  'assets/images/login_logo.svg',
                  width: 30,
                  height: 30,
                ),
              ),
              vSpace8,
              Flexible(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
