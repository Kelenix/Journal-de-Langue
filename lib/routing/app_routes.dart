import 'session_gate.dart';

abstract final class AppRoutes {
  static const journal = '/';
  static const history = '/history';
  static const review = '/review';
  static const progress = '/progress';
  static const profile = '/profile';

  static const startup = '/startup';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';

  static const correctionEntryId = 'entryId';
  static const correction = '/correction/:$correctionEntryId';

  static String correctionOf(String entryId) => '/correction/$entryId';

  static const _signedOutRoutes = {signIn, signUp, verifyEmail, forgotPassword};
  static const _entryRoutes = {..._signedOutRoutes, startup, onboarding};

  /// Route imposée par [gate] quand l'utilisateur est sur [location], ou
  /// `null` s'il peut y rester.
  static String? redirectFor(SessionGate gate, String location) {
    switch (gate) {
      case SessionGate.loading:
      case SessionGate.failed:
        return location == startup ? null : startup;
      case SessionGate.signedOut:
        return _signedOutRoutes.contains(location) ? null : signIn;
      case SessionGate.needsLanguage:
        return location == onboarding ? null : onboarding;
      case SessionGate.ready:
        return _entryRoutes.contains(location) ? journal : null;
    }
  }
}
