/// Configuration publique injectée à la compilation
/// (`--dart-define-from-file=env/<env>.json`). Aucun secret ici.
class AppConfig {
  const AppConfig._({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromEnvironment() => AppConfig.validated(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  );

  /// Échoue tôt et clairement plutôt que de démarrer avec une configuration vide.
  factory AppConfig.validated({
    required String supabaseUrl,
    required String supabasePublishableKey,
  }) {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('SUPABASE_URL absent ou invalide. $_howToFix');
    }
    if (supabasePublishableKey.isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY absent. $_howToFix');
    }
    return AppConfig._(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
    );
  }

  static const _howToFix =
      'Lance l\'app avec --dart-define-from-file=env/dev.json (voir README).';

  final String supabaseUrl;
  final String supabasePublishableKey;
}
