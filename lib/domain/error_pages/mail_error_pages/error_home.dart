import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class ErrorScreenWithRefresh extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRefresh;

  const ErrorScreenWithRefresh({
    super.key,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/backenderror.jpg",
                width: 240,
                height: 240,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.loading,
                  foregroundColor: AppColors.bg,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
