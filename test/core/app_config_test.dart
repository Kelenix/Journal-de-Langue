import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/config/app_config.dart';

void main() {
  group('AppConfig.validated', () {
    test('accepte une URL et une clé valides', () {
      final config = AppConfig.validated(
        supabaseUrl: 'http://10.0.2.2:55321',
        supabasePublishableKey: 'anon',
      );

      expect(config.supabaseUrl, 'http://10.0.2.2:55321');
      expect(config.supabasePublishableKey, 'anon');
    });

    test('refuse une URL absente', () {
      expect(
        () => AppConfig.validated(
          supabaseUrl: '',
          supabasePublishableKey: 'anon',
        ),
        throwsStateError,
      );
    });

    test('refuse une URL sans schéma', () {
      expect(
        () => AppConfig.validated(
          supabaseUrl: 'localhost:54321',
          supabasePublishableKey: 'anon',
        ),
        throwsStateError,
      );
    });

    test('refuse une clé absente', () {
      expect(
        () => AppConfig.validated(
          supabaseUrl: 'http://10.0.2.2:55321',
          supabasePublishableKey: '',
        ),
        throwsStateError,
      );
    });
  });
}
