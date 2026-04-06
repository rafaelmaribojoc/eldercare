import 'package:flutter/material.dart';
import '../utils/interaction_utils.dart';
import '../theme/app_colors.dart';

/// A unified button component for RCFMS that handles rapid-tap prevention
/// and optional loading states.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  final double? width;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.width,
    this.backgroundColor,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  final _throttler =
      AppThrottler(throttleDuration: const Duration(milliseconds: 600));

  void _handlePress() {
    if (widget.onPressed == null || widget.isLoading) return;

    _throttler.run(() {
      widget.onPressed!();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isPrimary ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(widget.label),
      ],
    );

    if (widget.isPrimary) {
      return SizedBox(
        width: widget.width,
        child: ElevatedButton(
          onPressed: widget.onPressed == null || widget.isLoading
              ? null
              : _handlePress,
          style: widget.backgroundColor != null
              ? ElevatedButton.styleFrom(
                  backgroundColor: widget.backgroundColor)
              : null,
          child: content,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      child: OutlinedButton(
        onPressed:
            widget.onPressed == null || widget.isLoading ? null : _handlePress,
        child: content,
      ),
    );
  }
}

/// A throttled IconButton to prevent multiple clicks causing crashes/multiple dialogs.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  final _throttler =
      AppThrottler(throttleDuration: const Duration(milliseconds: 600));

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(widget.icon),
      color: widget.color,
      tooltip: widget.tooltip,
      onPressed: widget.onPressed == null
          ? null
          : () => _throttler.run(widget.onPressed!),
    );
  }
}
