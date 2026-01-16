import 'package:flutter/material.dart';

/// Receipt Snap Color Palette
/// Fintech Modern Design - Inspired by Revolut/Wise
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6C5CE7);         // Purple accent
  static const Color primaryLight = Color(0xFF9D8DF1);    // Light purple
  static const Color primaryDark = Color(0xFF5849C2);     // Dark purple
  
  // Secondary/Accent
  static const Color accent = Color(0xFF00D09C);          // Teal green (success/positive)
  static const Color accentLight = Color(0xFF4FFFCE);     // Light teal

  // Background Colors
  static const Color background = Color(0xFF0D0D12);      // Deep black
  static const Color surface = Color(0xFF16161D);         // Card surface
  static const Color cardBackground = Color(0xFF16161D);  // Card background (alias for surface)
  static const Color surfaceElevated = Color(0xFF1E1E28);// Elevated cards
  static const Color surfaceHighlight = Color(0xFF252532);// Highlighted surface

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);     // Pure white
  static const Color textSecondary = Color(0xFF8B8B9A);   // Muted gray
  static const Color textTertiary = Color(0xFF5C5C6B);    // Faded gray
  static const Color textInverse = Color(0xFF0D0D12);     // For light backgrounds

  // Border & Divider
  static const Color border = Color(0xFF2A2A38);
  static const Color borderLight = Color(0xFF3A3A48);
  static const Color divider = Color(0xFF1F1F2A);

  // Status Colors
  static const Color success = Color(0xFF00D09C);         // Teal green
  static const Color successLight = Color(0xFF00D09C);
  static const Color warning = Color(0xFFFFB547);         // Warm amber
  static const Color warningLight = Color(0xFFFFD080);
  static const Color error = Color(0xFFFF6B6B);           // Soft red
  static const Color errorLight = Color(0xFFFF9999);
  static const Color info = Color(0xFF54A0FF);            // Blue

  // Urgency Colors (for renewal badges)
  static const Color urgencyHigh = Color(0xFFFF6B6B);     // 1-3 days (red)
  static const Color urgencyMedium = Color(0xFFFFB547);   // 4-7 days (amber)
  static const Color urgencyLow = Color(0xFF00D09C);      // 8+ days (teal)
  static const Color urgencyNone = Color(0xFF5C5C6B);     // Inactive

  // Category Colors (for subscription icons)
  static const Color categoryEntertainment = Color(0xFFE84393);
  static const Color categoryMusic = Color(0xFF1DB954);
  static const Color categorySoftware = Color(0xFF54A0FF);
  static const Color categoryGaming = Color(0xFF9B59B6);
  static const Color categoryHealth = Color(0xFF00D09C);
  static const Color categoryNews = Color(0xFFFF6B6B);
  static const Color categoryCloud = Color(0xFF74B9FF);
  static const Color categoryOther = Color(0xFF6C5CE7);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF9D8DF1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D09C), Color(0xFF4FFFCE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E28), Color(0xFF16161D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00D09C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass effect colors
  static Color glassBackground = Colors.white.withOpacity(0.05);
  static Color glassBorder = Colors.white.withOpacity(0.1);

  // Get urgency color based on days until renewal
  static Color getUrgencyColor(int daysUntil) {
    if (daysUntil <= 3) return urgencyHigh;
    if (daysUntil <= 7) return urgencyMedium;
    return urgencyLow;
  }

  // Get category color by name
  static Color getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'entertainment':
      case 'streaming':
        return categoryEntertainment;
      case 'music':
        return categoryMusic;
      case 'software':
      case 'productivity':
        return categorySoftware;
      case 'gaming':
        return categoryGaming;
      case 'health':
      case 'fitness':
        return categoryHealth;
      case 'news':
      case 'media':
        return categoryNews;
      case 'cloud':
      case 'storage':
        return categoryCloud;
      default:
        return categoryOther;
    }
  }
}
