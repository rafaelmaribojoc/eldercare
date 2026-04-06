import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/error_handler.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
    IconData? icon,
  }) {
    // Clear existing snackbars first to avoid queue buildup
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Default icons
    final displayIcon = icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline);
    final bgColor = isError ? AppColors.error : AppColors.success;
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(displayIcon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      elevation: 4,
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Specialized method for formatting errors and showing a snackbar
  static void showError(
    BuildContext context, {
    required dynamic error,
    String? fallbackMessage,
  }) {
    final bool isNetwork = ErrorHandler.isNetworkError(error);
    
    // Format error using centralized ErrorHandler
    String displayMessage = ErrorHandler.getUserFriendlyMessage(error);
    
    if (displayMessage.toLowerCase().contains('unknown error') && fallbackMessage != null) {
      displayMessage = fallbackMessage;
    }

    show(
      context,
      message: displayMessage,
      isError: true,
      icon: isNetwork ? Icons.wifi_off : Icons.error_outline,
      // Longer duration to give user time to read the network error message
      duration: isNetwork ? const Duration(seconds: 5) : const Duration(seconds: 4),
    );
  }
}
