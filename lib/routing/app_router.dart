import 'package:attendx/features/analytics/screens/analytics_screen.dart';
import 'package:attendx/features/auth/screens/forgot_password_screen.dart';
import 'package:attendx/features/auth/screens/login_screen.dart';
import 'package:attendx/features/auth/screens/onboarding_screen.dart';
import 'package:attendx/features/auth/screens/register_screen.dart';
import 'package:attendx/features/auth/screens/splash_screen.dart';
import 'package:attendx/features/calculator/screens/calculator_screen.dart';
import 'package:attendx/features/profile/screens/settings_screen.dart';
import 'package:attendx/features/subjects/screens/add_edit_subject_screen.dart';
import 'package:attendx/features/subjects/screens/subject_detail_screen.dart';
import 'package:attendx/features/subjects/screens/subjects_list_screen.dart';
import 'package:attendx/features/timetable/screens/add_edit_timetable_screen.dart';
import 'package:attendx/models/subject_model.dart';
import 'package:attendx/models/timetable_model.dart';
import 'package:attendx/providers/auth_provider.dart';
import 'package:attendx/widgets/root_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // isAuthenticatedProvider already falls back to a synchronous
  // client.auth.currentSession check (restored instantly from local
  // storage by Supabase.initialize(), no network needed) whenever the
  // authStateChanges stream hasn't emitted its first event yet. Watching
  // authStateProvider directly here — and treating "no data yet" as
  // "unknown, stay on splash" — was the bug: if the stream's first event
  // is ever delayed (slow/paused Supabase project, flaky network, etc.)
  // the app would sit on the splash screen forever instead of routing
  // based on the session Supabase already knows about.
  final isAuthed = ref.watch(isAuthenticatedProvider);
  // Still watch the stream so the router rebuilds on sign-in/sign-out.
  ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loggingIn = [
        '/login',
        '/register',
        '/forgot-password',
        '/onboarding',
        '/splash',
      ].contains(state.matchedLocation);

      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn && state.matchedLocation != '/onboarding') {
        return '/home';
      }
      if (!isAuthed && state.matchedLocation == '/splash') return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Shell containing the bottom navigation for the five main tabs.
      GoRoute(path: '/home', builder: (_, __) => const RootShell(initialIndex: 0)),
      GoRoute(path: '/attendance', builder: (_, __) => const RootShell(initialIndex: 1)),
      GoRoute(path: '/timetable', builder: (_, __) => const RootShell(initialIndex: 2)),
      GoRoute(path: '/history', builder: (_, __) => const RootShell(initialIndex: 3)),
      GoRoute(path: '/profile', builder: (_, __) => const RootShell(initialIndex: 4)),

      GoRoute(
        path: '/calculator',
        builder: (_, __) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (_, __) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/subjects',
        builder: (_, __) => const SubjectsListScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/subject/add',
        builder: (_, __) => const AddEditSubjectScreen(),
      ),
      GoRoute(
        path: '/subject/edit',
        builder: (context, state) =>
            AddEditSubjectScreen(subject: state.extra as SubjectModel?),
      ),
      GoRoute(
        path: '/subject/detail',
        builder: (context, state) =>
            SubjectDetailScreen(subject: state.extra as SubjectModel),
      ),
      GoRoute(
        path: '/timetable/add',
        builder: (_, __) => const AddEditTimetableScreen(),
      ),
      GoRoute(
        path: '/timetable/edit',
        builder: (context, state) =>
            AddEditTimetableScreen(entry: state.extra as TimetableModel?),
      ),
    ],
  );
});
