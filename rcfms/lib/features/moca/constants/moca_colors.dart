import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// MoCA-P specific colors for assessment sections
/// Uses Poppins font family from ElderCare assets
class MocaColors {
  MocaColors._();

  // Font family for MoCA module
  static const String fontFamily = 'Poppins';

  // Primary MoCA Colors - Using app branding colors (Teal)
  static const Color primary = AppColors.primary; // Teal - main app brand color
  static const Color primaryLight = Color(0xFFE0F7FA);
  static const Color primaryDark = AppColors.primaryDark;

  // Section Colors for Assessment
  static const Color visuospatialColor = Color(0xFF7E57C2);
  static const Color namingColor = Color(0xFF26A69A);
  static const Color memoryColor = Color(0xFFEF5350);
  static const Color attentionColor = Color(0xFFFFB74D);
  static const Color languageColor = Color(0xFF42A5F5);
  static const Color abstractionColor = Color(0xFF8D6E63);
  static const Color recallColor = Color(0xFFEC407A);
  static const Color orientationColor = Color(0xFF66BB6A);

  // Score Colors
  static const Color scoreNormal = Color(0xFF4CAF50);
  static const Color scoreAtRisk = Color(0xFFFFC107);
  static const Color scoreImpaired = Color(0xFFE53935);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // Gradient - Using app branding teal colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0891B2), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
