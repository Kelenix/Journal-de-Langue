// Publicités et récompenses contre le Supabase local. Prérequis : voir
// correction_backend_test.dart (la fonction admob-reward lit ses clés de vérification sur
// le faux serveur lancé ici).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/ads/data/supabase_ads_repository.dart';
import 'package:journal_de_langue/features/ads/domain/ad_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';
import 'support/fake_claude.dart';

/// `127.0.0.1` sur l'hôte ; `host.docker.internal` depuis le conteneur Flutter.
final _host = Platform.environment['SUPABASE_TEST_HOST'] ?? '127.0.0.1';

/// Appelle la fonction admob-reward comme le ferait AdMob.
Future<({int status, Object? body})> _rewardCallback(String query) async {
  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(
      Uri.parse('http://$_host:55321/functions/v1/admob-reward?$query'),
    );
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return (status: response.statusCode, body: jsonDecode(text) as Object?);
  } finally {
    httpClient.close();
  }
}

void main() {
  final fakeServer = FakeClaude();
  late SupabaseClient client;

  setUpAll(fakeServer.start);
  tearDownAll(fakeServer.stop);

  setUp(() async {
    client = createTestClient();
    await signUpConfirmed(client, newTestEmail());
  });

  tearDown(() => deleteAccountAndDispose(client));

  test('un nouvel inscrit ne voit aucune publicité pendant 14 jours', () async {
    expect(
      await SupabaseAdsRepository(client).status(),
      const AdStatus(
        correctionRewardAvailable: true,
        exercisesRewardAvailable: true,
      ),
    );
  });

  test('un rappel AdMob mal signé n\'accorde rien', () async {
    final userId = client.auth.currentUser!.id;
    final response = await _rewardCallback(
      'ad_network=1&ad_unit=1&custom_data=correction&reward_amount=1'
      '&reward_item=correction&timestamp=1&transaction_id=forged'
      '&user_id=$userId&signature=MEUCIQ&key_id=1',
    );

    expect(response.status, HttpStatus.unauthorized);
    expect(response.body, {'error': 'invalid_signature'});
    expect((await SupabaseAdsRepository(client).status()).rewardCorrections, 0);
  });

  test('la requête de vérification de la console AdMob est acceptée sans '
      'effet', () async {
    final response = await _rewardCallback('');

    expect(response.status, HttpStatus.ok);
    expect(response.body, {'status': 'ignored'});
  });
}
