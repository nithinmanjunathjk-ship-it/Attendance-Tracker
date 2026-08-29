import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/providers/attendance_provider.dart';
import 'package:attendx/providers/theme_provider.dart';
import 'package:attendx/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Loads SUPABASE_URL / SUPABASE_ANON_KEY from the bundled .env file.
    // See .env.example — copy it to .env and fill in your project values.
    await dotenv.load(fileName: '.env');
    await SupabaseService.initialize();
  } catch (error) {
    // A misconfigured .env (missing/empty keys, wrong URL, etc.) used to
    // crash the app before it could draw a single frame, which just looks
    // like "the app won't open" with no clue why. Show the actual reason
    // on screen instead.
    runApp(_StartupErrorApp(error: error));
    return;
  }

  runApp(const ProviderScope(child: AttendXApp()));
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'AttendX failed to start',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text('$error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AttendXApp extends ConsumerWidget {
  const AttendXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Kick off the offline-sync listener for the lifetime of the app.
    ref.watch(syncStatusProvider);

    return MaterialApp.router(
      title: 'AttendX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
