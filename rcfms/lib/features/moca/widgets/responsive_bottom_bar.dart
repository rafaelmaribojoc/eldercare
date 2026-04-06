import 'package:flutter/material.dart';

import '../constants/moca_colors.dart';

/// Responsive bottom bar for assessment screens
/// Handles small screens by stacking elements vertically
class ResponsiveBottomBar extends StatelessWidget {
  final String scoreText;
  final Color scoreColor;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final String continueText;
  final bool isLoading;

  const ResponsiveBottomBar({
    super.key,
    required this.scoreText,
    required this.scoreColor,
    this.subtitle,
    this.onBack,
    required this.onContinue,
    this.continueText = 'Continue',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isSmallScreen
            ? _buildCompactLayout(context)
            : _buildNormalLayout(context),
      ),
    );
  }

  Widget _buildNormalLayout(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  scoreText,
                  style: TextStyle(
                    fontFamily: MocaColors.fontFamily,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    fontSize: 13,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: MocaColors.fontFamily,
                    fontSize: 11,
                    color: MocaColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (onBack != null) ...[
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                'Back',
                style: TextStyle(fontFamily: MocaColors.fontFamily),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: isLoading ? null : onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: scoreColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    continueText,
                    style: TextStyle(fontFamily: MocaColors.fontFamily),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Score and subtitle row
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                scoreText,
                style: TextStyle(
                  fontFamily: MocaColors.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: MocaColors.fontFamily,
                    fontSize: 10,
                    color: MocaColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Buttons row - using Wrap for responsiveness
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onBack != null)
              SizedBox(
                width: onBack != null ? 100 : double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: MocaColors.fontFamily,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 120,
              height: 40,
              child: ElevatedButton(
                onPressed: isLoading ? null : onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scoreColor,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        continueText,
                        style: TextStyle(
                          fontFamily: MocaColors.fontFamily,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
