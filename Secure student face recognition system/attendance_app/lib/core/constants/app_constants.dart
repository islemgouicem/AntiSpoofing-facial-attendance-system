/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // ── AI Engine ────────────────────────────────────────────
  static const String aiBaseUrl = 'http://127.0.0.1:8000';
  static const Duration aiHealthPoll = Duration(milliseconds: 500);
  static const Duration aiStartupTimeout = Duration(seconds: 30);
  static const int aiHealthMaxRetries = 120; // Wait up to 60 seconds (120 * 500ms)

  // ── Recognition ──────────────────────────────────────────
  static const Duration recognitionInterval = Duration(milliseconds: 500);
  static const double recognitionThreshold = 0.4;

  // ── Camera ───────────────────────────────────────────────
  static const Duration frameInterval = Duration(milliseconds: 50);

  // ── Database ─────────────────────────────────────────────
  static const String dbName = 'face_attend.db';
  static const int dbVersion = 3;

  // ── UI ───────────────────────────────────────────────────
  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 72;
  static const Duration animDuration = Duration(milliseconds: 250);
  static const Duration pageFadeDuration = Duration(milliseconds: 180);
}
