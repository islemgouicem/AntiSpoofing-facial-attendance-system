import 'package:flutter/material.dart';

/// Curated colour palette for the attendance application.
class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────────
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);
  static const accent = Color(0xFF8B5CF6);

  // ── Semantic ─────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFF43F5E);
  static const info = Color(0xFF3B82F6);

  // ── Dark surfaces ────────────────────────────────────────
  static const darkBg = Color(0xFF09090F);
  static const darkSurface = Color(0xFF111118);
  static const darkCard = Color(0xFF16161F);
  static const darkCardHover = Color(0xFF1E1E2A);
  static const darkBorder = Color(0xFF232334);
  static const darkText = Color(0xFFF0F0F5);
  static const darkTextSecondary = Color(0xFF9090A8);
  static const darkTextTertiary = Color(0xFF5A5A72);

  // ── Light surfaces ───────────────────────────────────────
  static const lightBg = Color(0xFFF8F9FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardHover = Color(0xFFF3F4F6);
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightText = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextTertiary = Color(0xFF9CA3AF);

  // ── Gradients ────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Sidebar ──────────────────────────────────────────────
  static const darkSidebar = Color(0xFF0D0D14);
  static const lightSidebar = Color(0xFFFFFFFF);
}
