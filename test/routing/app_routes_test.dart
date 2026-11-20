import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/legal/domain/legal_document.dart';
import 'package:journal_de_langue/routing/app_routes.dart';
import 'package:journal_de_langue/routing/session_gate.dart';

void main() {
  group('AppRoutes.redirectFor', () {
    test('pendant le chargement ou après un échec, tout mène au démarrage', () {
      for (final gate in [SessionGate.loading, SessionGate.failed]) {
        expect(
          AppRoutes.redirectFor(gate, AppRoutes.journal),
          AppRoutes.startup,
        );
        expect(AppRoutes.redirectFor(gate, AppRoutes.startup), isNull);
      }
    });

    test('déconnecté : l\'accueil, les routes de compte et les textes légaux '
        'sont accessibles ; le reste mène à l\'accueil', () {
      const gate = SessionGate.signedOut;

      expect(AppRoutes.redirectFor(gate, AppRoutes.journal), AppRoutes.welcome);
      expect(AppRoutes.redirectFor(gate, AppRoutes.profile), AppRoutes.welcome);
      expect(
        AppRoutes.redirectFor(gate, AppRoutes.onboarding),
        AppRoutes.welcome,
      );
      for (final route in [
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.verifyEmail,
        AppRoutes.forgotPassword,
        for (final document in LegalDocument.values)
          AppRoutes.legalOf(document),
      ]) {
        expect(AppRoutes.redirectFor(gate, route), isNull);
      }
    });

    test('connecté sans langue : le choix de la langue est imposé', () {
      const gate = SessionGate.needsLanguage;

      expect(
        AppRoutes.redirectFor(gate, AppRoutes.journal),
        AppRoutes.onboarding,
      );
      expect(
        AppRoutes.redirectFor(gate, AppRoutes.signIn),
        AppRoutes.onboarding,
      );
      expect(AppRoutes.redirectFor(gate, AppRoutes.onboarding), isNull);
    });

    test('prêt : les routes d\'entrée renvoient au journal', () {
      const gate = SessionGate.ready;

      for (final route in [
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.verifyEmail,
        AppRoutes.forgotPassword,
        AppRoutes.startup,
        AppRoutes.onboarding,
      ]) {
        expect(AppRoutes.redirectFor(gate, route), AppRoutes.journal);
      }
      expect(AppRoutes.redirectFor(gate, AppRoutes.history), isNull);
      expect(AppRoutes.redirectFor(gate, AppRoutes.journal), isNull);
    });
  });
}
