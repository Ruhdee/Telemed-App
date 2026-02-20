import 'package:flutter/material.dart';

/// Color palette matching the React app's CSS variables in `globals.css`.
///
/// The React app uses a premium gold/glass design system with warm backgrounds.
class AppColors {
  AppColors._();

  // ── Gold Palette ──────────────────────────────────────────────
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color goldDark = Color(0xFFAA8C2C);

  // ── Bronze ────────────────────────────────────────────────────
  static const Color bronze = Color(0xFFCD7F32);
  static const Color bronzeLight = Color(0xFFE6BE8A);

  // ── Background ────────────────────────────────────────────────
  static const Color bgWarm = Color(0xFFFDFBF7);
  static const Color bgWhite = Colors.white;

  // ── Glassmorphism ─────────────────────────────────────────────
  static const Color glassBg = Color(0xB3FFFFFF); // rgba(255,255,255,0.7)
  static const Color glassBorder = Color(0x80FFFFFF); // rgba(255,255,255,0.5)
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x121F2687), // rgba(31,38,135,0.07)
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ── Semantic Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Risk Tier Colors ──────────────────────────────────────────
  static const Color riskHigh = Color(0xFFEF4444);
  static const Color riskMedium = Color(0xFFF59E0B);
  static const Color riskLow = Color(0xFF22C55E);

  // ── Gold Gradient ─────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldPrimary, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldTextGradient = LinearGradient(
    colors: [goldDark, goldPrimary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
