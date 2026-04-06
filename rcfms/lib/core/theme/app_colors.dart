import 'package:flutter/material.dart';

/// RCFMS Design System - Color Palette
///
/// Inspired by Linear, Stripe, and Apple's Human Interface Guidelines.
/// Clean, accessible, and typography-driven.
class AppColors {
  AppColors._();

  // ============================================================================
  // FOUNDATION - Neutral Grays (Slate Scale)
  // ============================================================================

  /// Background - Light airy slate
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF111827); // Gray 900

  /// Surface - Pure white for cards
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937); // Gray 800

  /// Subtle backgrounds for hover/selected states
  static const Color surfaceHover = Color(0xFFF1F3F5);
  static const Color surfaceHoverDark = Color(0xFF374151); // Gray 700

  static const Color surfacePressed = Color(0xFFE9ECEF);
  static const Color surfacePressedDark = Color(0xFF4B5563); // Gray 600

  /// Borders - Subtle, not boxy
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF1F3F5);
  static const Color borderDark = Color(0xFF374151); // Gray 700

  static const Color borderFocus = Color(0xFFD1D5DB);
  static const Color borderFocusDark = Color(0xFF9CA3AF); // Gray 400

  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF374151); // Gray 700

  // ============================================================================
  // TEXT COLORS - Dark Charcoal Scale (No Pure Black)
  // ============================================================================

  /// Primary text - Dark charcoal
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFF9FAFB); // Gray 50

  /// Secondary text - Muted gray
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // Gray 300

  /// Tertiary/placeholder text
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280); // Gray 500

  /// Disabled text
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textDisabledDark = Color(0xFF4B5563); // Gray 600

  /// Inverse text (on dark backgrounds)
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textInverseDark =
      Color(0xFF1A1A1A); // Dark text on light inverse backgrounds

  // ============================================================================
  // PRIMARY BRAND COLOR - Teal (Calming, Trustworthy)
  // ============================================================================

  /// Primary teal - Main action color
  static const Color primary = Color(0xFF0891B2);
  static const Color primaryLight = Color(0xFF22D3EE);
  static const Color primaryDark = Color(0xFF0E7490);

  /// Primary with opacity for backgrounds
  static Color primarySurface = const Color(0xFF0891B2).withOpacity(0.08);
  static Color primarySurfaceDark = const Color(0xFF22D3EE)
      .withOpacity(0.15); // Lighter for dark mode visibility

  static Color primaryBorder = const Color(0xFF0891B2).withOpacity(0.2);

  // ============================================================================
  // ACCENT COLOR - Warm Coral (Friendly, Caring)
  // ============================================================================

  static const Color accent = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFB923C);
  static const Color accentDark = Color(0xFFEA580C);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Success - Soft green
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFF10B981);
  static Color successSurface = const Color(0xFF059669).withOpacity(0.08);

  /// Warning - Warm amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static Color warningSurface = const Color(0xFFF59E0B).withOpacity(0.08);

  /// Error - Soft red
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFEF4444);
  static Color errorSurface = const Color(0xFFDC2626).withOpacity(0.08);

  /// Info - Soft blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static Color infoSurface = const Color(0xFF3B82F6).withOpacity(0.08);

  // ============================================================================
  // SERVICE UNIT COLORS (Muted, Professional)
  // ============================================================================

  /// Social Service - Warm purple
  static const Color unitSocial = Color(0xFF7C3AED);
  static Color unitSocialSurface = const Color(0xFF7C3AED).withOpacity(0.08);

  /// Medical Service - Soft teal
  static const Color unitMedical = Color(0xFF0891B2);
  static Color unitMedicalSurface = const Color(0xFF0891B2).withOpacity(0.08);

  /// Psychological Service - Calm indigo
  static const Color unitPsych = Color(0xFF4F46E5);
  static Color unitPsychSurface = const Color(0xFF4F46E5).withOpacity(0.08);

  /// Rehabilitation Service - Fresh green
  static const Color unitRehab = Color(0xFF059669);
  static Color unitRehabSurface = const Color(0xFF059669).withOpacity(0.08);

  /// Home Life Service - Warm orange
  static const Color unitHomelife = Color(0xFFF97316);
  static Color unitHomelifeSurface = const Color(0xFFF97316).withOpacity(0.08);

  /// Nutrition Service - Fresh Lime/Green
  static const Color unitNutrition = Color(0xFF84CC16); // Lime 500
  static Color unitNutritionSurface = const Color(0xFF84CC16).withOpacity(0.08);

  // ============================================================================
  // STATUS COLORS (Form Workflow)
  // ============================================================================

  static const Color statusDraft = Color(0xFF6B7280);
  static const Color statusSubmitted = Color(0xFF3B82F6);
  static const Color statusPendingReview = Color(0xFFF59E0B);
  static const Color statusApproved = Color(0xFF059669);
  static const Color statusReturned = Color(0xFFDC2626);

  // ============================================================================
  // ADDITIONAL ALIASES
  // ============================================================================

  /// Secondary color - alias for accent
  static const Color secondary = accent;

  /// Text on primary backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text hint color
  static const Color textHint = textTertiary;

  /// Get service unit color by name
  static Color getServiceUnitColor(String unit) {
    switch (unit.toLowerCase()) {
      case 'social':
      case 'socialservice':
        return unitSocial;
      case 'medical':
      case 'medicalservice':
        return unitMedical;
      case 'psych':
      case 'psychological':
      case 'psychologicalservice':
        return unitPsych;
      case 'rehab':
      case 'rehabilitation':
      case 'rehabilitationservice':
        return unitRehab;
      case 'homelife':
      case 'home_life':
      case 'homelifeservice':
        return unitHomelife;
      case 'nutrition':
      case 'dietetics':
      case 'nutritionservice':
        return unitNutrition;
      default:
        return primary;
    }
  }

  // ============================================================================
  // SPECIAL COLORS
  // ============================================================================

  /// Overlay for modals/drawers
  static Color overlay = Colors.black.withOpacity(0.4);

  /// Shimmer loading colors
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);

  /// Shadow color
  static Color shadow = Colors.black.withOpacity(0.08);
  static Color shadowLight = Colors.black.withOpacity(0.04);
}
