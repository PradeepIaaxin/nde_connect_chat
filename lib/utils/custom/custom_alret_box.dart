import 'package:flutter/material.dart';

class CustomConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
    String confirmText = "Confirm",
    String cancelText = "Cancel",
    Color confirmColor = Colors.red,

    
    Color iconColor = Colors.red,
    IconData icon = Icons.help_outline,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black87,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;

        return PopScope(
          canPop: !isLoading,
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Dialog(
                backgroundColor: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 36, color: iconColor),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          // Cancel button
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  isLoading ? null : () => Navigator.pop(ctx, false),
                              child: Text(cancelText),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // CONFIRM button with loading
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);

                                      try {
                                        await onConfirm();
                                      } catch (e) {
                                        debugPrint("Error in onConfirm(): $e");
                                      }

                                      if (ctx.mounted) {
                                        Navigator.pop(ctx, true);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      confirmText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
