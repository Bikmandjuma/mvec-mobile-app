import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API base URL used by the app.
///
/// Resolution order (highest priority first):
/// 1. `--dart-define=API_BASE_URL=...` — wins so a build can target a
///    different host (e.g. `10.0.2.2` for the Android emulator) without
///    editing `.env`.
/// 2. `API_BASE_URL` from `.env` (loaded at startup via `dotenv.load()`).
/// 3. a localhost fallback for development.
String get kApiBaseUrl {
  // A compile-time define must beat the checked-in `.env`, otherwise
  // `flutter run --dart-define=API_BASE_URL=...` is silently ignored.
  const defined = String.fromEnvironment('API_BASE_URL');
  if (defined.trim().isNotEmpty) return defined.trim();

  try {
    final envUrl = dotenv.maybeGet('API_BASE_URL');
    if (envUrl != null && envUrl.trim().isNotEmpty) return envUrl.trim();
  } catch (_) {
    // dotenv is not loaded (e.g. tests) — fall back to the default below.
  }
  return 'http://localhost:4000/api';
}

/// Demo mode — lets the app be presented with no backend running.
///
/// When enabled, `AuthController.login` accepts any password locally and skips
/// the network round-trip, so the auth gate opens onto the mock marketplace
/// and the admin console (whose pages fall back to empty/placeholder states).
///
/// Opt in per-run with `--dart-define=DEMO_MODE=true`. Default is off, so
/// release builds always talk to the real backend.
const bool kDemoMode = bool.fromEnvironment(
  'DEMO_MODE',
  defaultValue: false,
);

const String kAdminEmail = String.fromEnvironment(
  'ADMIN_EMAIL',
  defaultValue: 'admin@gmail.com',
);

const String kAdminPassword = String.fromEnvironment(
  'ADMIN_PASSWORD',
  defaultValue: 'admin!',
);