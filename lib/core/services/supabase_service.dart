import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase client lifecycle.
///
/// Call [SupabaseService.initialize] once in `main()` before running the
/// app. After that, use [SupabaseService.client] anywhere to access the
/// Supabase client (auth, database, realtime, storage).
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    final url = _sanitizeUrl(dotenv.env['SUPABASE_URL'] ?? '');
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL / SUPABASE_ANON_KEY.\n\n'
        'If you are running this from source: copy .env.example to .env '
        'and fill in your project credentials.\n\n'
        'If this is a CI-built APK: add SUPABASE_URL and SUPABASE_ANON_KEY '
        'as repository secrets under GitHub → Settings → Secrets and '
        'variables → Actions, then re-run the workflow.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey, // ignore: deprecated_member_use
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 5,
      ),
    );
  }

  /// Accepts the bare project URL Supabase expects, but tolerates common
  /// copy-paste mistakes like an appended `/rest/v1` (the REST endpoint
  /// path, not the project URL) or a trailing slash.
  static String _sanitizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    url = url.replaceFirst(RegExp(r'/rest/v1/?$'), '');
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => client.auth.currentUser?.id;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
