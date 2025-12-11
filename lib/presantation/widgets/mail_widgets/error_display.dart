import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final ErrorType type;
  final double imageSize;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.type = ErrorType.Somethingwrong,
    this.imageSize = 200,
  });

  String get _imagePath {
    switch (type) {
      case ErrorType.emptymailbox:
        return 'assets/images/empty_mailbox.png';
      case ErrorType.noInternet:
        return 'assets/images/network_error.png';
      case ErrorType.Somethingwrong:
        return 'assets/images/somthingwrong.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _imagePath,
            height: imageSize,
            width: imageSize,
            fit: BoxFit.contain,
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum ErrorType {
  Somethingwrong,
  emptymailbox,
  noInternet,
}
