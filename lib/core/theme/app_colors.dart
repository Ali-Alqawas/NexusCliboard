import 'package:flutter/material.dart';

/// NexusClip - نظام الألوان
/// Cyber-Luxury Color System
///
/// فلسفة التصميم: "Cyber-Luxury"
/// Design Philosophy: "Cyber-Luxury"
///
/// هذا النظام يوفر ألوان متناسقة وأنيقة
/// This system provides consistent and elegant colors
class AppColors {
  // منع إنشاء نسخ من الكلاس
  // Prevent instantiation
  AppColors._();

  // =====================================================
  // الألوان الأساسية / Primary Colors
  // =====================================================

  /// الخلفية الأساسية - Deep Navy مع شفافية 85%
  /// Primary Background - Deep Navy with 85% opacity
  static const Color background = Color(0xFF001E28);
  static const Color backgroundTransparent = Color(0xD9001E28);

  /// العناصر التفاعلية - Golden Bronze
  /// Interactive Elements - Golden Bronze
  static const Color primary = Color(0xFFB48C69);
  static const Color primaryLight = Color(0xFFD4A574);
  static const Color primaryDark = Color(0xFF8A6B4E);

  /// النصوص - Soft Cream
  /// Text - Soft Cream
  static const Color textPrimary = Color(0xFFE5CDAF);
  static const Color textSecondary = Color(0xFFDCB98C);
  static const Color textTertiary = Color(0xFFAA9A7C);

  /// العناصر الثانوية
  /// Secondary Elements
  static const Color secondary = Color(0xFFDCB98C);

  /// التنبيهات - Electric Amber
  /// Alerts - Electric Amber
  static const Color accent = Color(0xFFFFB300);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);

  // =====================================================
  // ألوان الأقسام / Category Colors
  // =====================================================

  /// Live Stream - أزرق سماوي
  static const Color categoryLive = Color(0xFF00BCD4);

  /// Code Snippets - أخضر المطورين
  static const Color categoryCode = Color(0xFF8BC34A);

  /// Secure Vault - أحمر آمن
  static const Color categorySecure = Color(0xFFE91E63);

  /// Templates - بنفسجي إبداعي
  static const Color categoryTemplates = Color(0xFF9C27B0);

  /// Links - أزرق الروابط
  static const Color categoryLinks = Color(0xFF2196F3);

  // =====================================================
  // ألوان السطوح / Surface Colors
  // =====================================================

  /// سطح البطاقات
  /// Card Surface
  static const Color cardBackground = Color(0xFF002A38);
  static const Color cardBackgroundLight = Color(0xFF003648);

  /// حدود العناصر
  /// Element Borders
  static const Color border = Color(0xFF3D5A68);
  static const Color borderLight = Color(0xFF4A6B7A);

  /// التمويه / Overlay
  static const Color overlay = Color(0x80001E28);
  static const Color overlayLight = Color(0x40001E28);

  // =====================================================
  // التدرجات / Gradients
  // =====================================================

  /// التدرج الرئيسي
  /// Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// تدرج الخلفية
  /// Background Gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF002A38), background],
  );

  /// تدرج البطاقات
  /// Card Gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardBackgroundLight, cardBackground],
  );

  /// تدرج الـ Glassmorphism
  /// Glassmorphism Gradient
  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.1),
      Colors.white.withValues(alpha: 0.05),
    ],
  );

  // =====================================================
  // وظائف مساعدة / Helper Functions
  // =====================================================

  /// الحصول على لون الفئة بناءً على النوع
  /// Get category color based on type
  static Color getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'link':
      case 'url':
        return categoryLinks;
      case 'code':
      case 'snippet':
        return categoryCode;
      case 'password':
      case 'secure':
        return categorySecure;
      case 'template':
      case 'quick':
        return categoryTemplates;
      case 'live':
      case 'stream':
        return categoryLive;
      default:
        return primary;
    }
  }

  /// الحصول على لون مع شفافية
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
