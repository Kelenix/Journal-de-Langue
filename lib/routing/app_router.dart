import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/home/presentation/startup_screen.dart';
import '../features/journal/presentation/correction_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/languages/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/stats/presentation/progress_screen.dart';
import '../features/vocabulary/presentation/review_screen.dart';
import 'app_routes.dart';
import 'session_gate.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // go_router réévalue la redirection à chaque changement d'état de session.
  final gate = ValueNotifier(ref.read(sessionGateProvider));
  ref.listen(sessionGateProvider, (_, next) => gate.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.journal,
    refreshListenable: gate,
    redirect: (context, state) =>
        AppRoutes.redirectFor(gate.value, state.matchedLocation),
    routes: [
      _route(AppRoutes.startup, const StartupScreen()),
      _route(AppRoutes.signIn, const SignInScreen()),
      _route(AppRoutes.signUp, const SignUpScreen()),
      _route(AppRoutes.forgotPassword, const ForgotPasswordScreen()),
      _route(AppRoutes.onboarding, const OnboardingScreen()),
      GoRoute(
        path: AppRoutes.verifyEmail,
        // L'e-mail à confirmer est transmis par l'écran précédent.
        redirect: (context, state) =>
            state.extra is String ? null : AppRoutes.signIn,
        builder: (context, state) =>
            VerifyEmailScreen(email: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.correction,
        builder: (context, state) => CorrectionScreen(
          entryId: state.pathParameters[AppRoutes.correctionEntryId]!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          _branch(AppRoutes.journal, const JournalScreen()),
          _branch(AppRoutes.history, const HistoryScreen()),
          _branch(AppRoutes.review, const ReviewScreen()),
          _branch(AppRoutes.progress, const ProgressScreen()),
          _branch(AppRoutes.profile, const ProfileScreen()),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});

GoRoute _route(String path, Widget screen) =>
    GoRoute(path: path, builder: (context, state) => screen);

StatefulShellBranch _branch(String path, Widget screen) =>
    StatefulShellBranch(routes: [_route(path, screen)]);
