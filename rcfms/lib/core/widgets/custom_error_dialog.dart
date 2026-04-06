import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/error_handler.dart';

class CustomErrorDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? technicalDetails;
  final bool isNetworkError;

  const CustomErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.technicalDetails,
    this.isNetworkError = false,
  });

  /// Helper method to show the dialog easily
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    dynamic error,
  }) {
    final bool isNetwork = ErrorHandler.isNetworkError(error ?? message);
    final String finalMessage = isNetwork 
        ? ErrorHandler.getUserFriendlyMessage(error ?? message)
        : message;
    final String finalTitle = isNetwork && title.toLowerCase().contains('failed') 
        ? 'No Internet Connection' 
        : title;

    showDialog(
      context: context,
      builder: (context) => CustomErrorDialog(
        title: finalTitle,
        message: finalMessage,
        technicalDetails: error?.toString().replaceAll('Exception: ', ''),
        isNetworkError: isNetwork,
      ),
    );
  }

  @override
  State<CustomErrorDialog> createState() => _CustomErrorDialogState();
}

class _CustomErrorDialogState extends State<CustomErrorDialog> {
  @override
  Widget build(BuildContext context) {
    // Check if dark mode for specific styling adjustments
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.8, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header with curve
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.errorSurface.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Icon(
                  widget.isNetworkError ? Icons.wifi_off_rounded : Icons.error_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
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
