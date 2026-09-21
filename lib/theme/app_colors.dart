import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Legacy Dark Theme (Stays as-is for Admin/Vendor/Rider)
  static const Color background = Color(0xFF232733);
  static const Color secondaryBackground = Color(0xFF2C3142);
  static const Color surface = Color(0xFF31384B);
  static const Color elevatedSurface = Color(0xFF383F55);
  static const Color bottomNav = Color(0xFF2A2F40);
  static const Color dialog = Color(0xFF30384A);

  static const Color primary = Color(0xFFC9A27E); // Warm Beige
  static const Color accent = Color(0xFFC9A27E);
  static const Color secondaryAccent = Color(0xFFD6B08A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC5CBD8);
  static const Color textHint = Color(0xFF98A2B3);
  static const Color textDisabled = Color(0xFF6B7280);
  
  static const Color border = Color(0xFF434B61);
  static const Color divider = Color(0x6641485A);

  // Status Colors
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // Premium Light Theme
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSecondaryBackground = Color(0xFFF1F5F9);
  static const Color lightPrimary = Color(0xFF0EA5E9); // Primary Blue
  static const Color lightSecondaryAccent = Color(0xFF38BDF8); // Secondary Blue
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextHint = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightSuccess = Color(0xFF22C55E);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightError = Color(0xFFEF4444);

  // Premium Dark Theme (Deep Navy Slate - For Customer Module)
  static const Color premiumDarkBackground = Color(0xFF0B1120);
  static const Color premiumDarkSecondaryBackground = Color(0xFF111827);
  static const Color premiumDarkSurface = Color(0xFF1E293B);
  static const Color premiumDarkElevatedSurface = Color(0xFF263548);
  static const Color premiumDarkPrimary = Color(0xFF38BDF8); // Electric Blue
  static const Color premiumDarkTextPrimary = Color(0xFFF8FAFC);
  static const Color premiumDarkTextSecondary = Color(0xFF94A3B8);
  static const Color premiumDarkDivider = Color(0xFF334155);
  static const Color premiumDarkError = Color(0xFFF87171);
  static const Color premiumDarkSuccess = Color(0xFF22C55E);
  static const Color premiumDarkWarning = Color(0xFFFBBF24);
  static const Color premiumDarkInfo = Color(0xFF38BDF8);

  // Backward Compatibility / Aliases for Help Center
  static const Color supportDarkBackground = premiumDarkBackground;
  static const Color supportDarkSecondaryBackground = premiumDarkSecondaryBackground;
  static const Color supportDarkSurface = premiumDarkSurface;
  static const Color supportDarkElevatedSurface = premiumDarkElevatedSurface;
  static const Color supportDarkPrimary = premiumDarkPrimary;
  static const Color supportDarkTextPrimary = premiumDarkTextPrimary;
  static const Color supportDarkTextSecondary = premiumDarkTextSecondary;
  static const Color supportDarkDivider = premiumDarkDivider;
  static const Color supportDarkError = Color(0xFFF87171);

  // Role colors (For dashboards)
  static const Color admin = primary;
  static const Color vendor = secondaryAccent;
  static const Color customer = primary;
  static const Color rider = secondaryAccent;

  static Color forRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'super_admin':
        return admin;
      case 'vendor':
        return vendor;
      case 'rider':
        return rider;
      case 'customer':
        return customer;
      default:
        return primary;
    }
  }

  static LinearGradient gradientForRole(String role, {bool isLight = false}) {
    if (!isLight) {
      Color c = primary;
      if (role == 'vendor' || role == 'rider') c = secondaryAccent;
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c, Color.lerp(c, Colors.black, 0.15)!],
      );
    } else {
      Color c = lightPrimary;
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c, Color.lerp(c, Colors.white, 0.2)!],
      );
    }
  }
}
