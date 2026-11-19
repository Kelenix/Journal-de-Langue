import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/auth/data/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `127.0.0.1` sur l'hôte ; `host.docker.internal` depuis le conteneur Flutter.
final _host = Platform.environment['SUPABASE_TEST_HOST'] ?? '127.0.0.1';

/// Boîte de réception locale des e-mails (`[local_smtp]` de supabase/config.toml).
const _mailboxPort = 55324;
const testPassword = 'motdepasse-initial';

/// Client du Supabase local décrit par `env/dev.json`.
SupabaseClient createTestClient() {
  final config =
      jsonDecode(File('env/dev.json').readAsStringSync())
          as Map<String, dynamic>;
  final url = Uri.parse(config['SUPABASE_URL'] as String);
  return SupabaseClient(
    url.replace(host: _host).toString(),
    config['SUPABASE_PUBLISHABLE_KEY'] as String,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    ),
  );
}

String newTestEmail() =>
    'test-${DateTime.now().microsecondsSinceEpoch}@example.test';

/// Crée un compte confirmé et le laisse connecté sur [client].
Future<void> signUpConfirmed(SupabaseClient client, String email) async {
  final auth = SupabaseAuthRepository(client);
  await auth.signUp(email: email, password: testPassword);
  await auth.confirmSignUp(
    email: email,
    code: await latestEmailCode(email, emailCount: 1),
  );
}

/// Supprime le compte connecté, s'il y en a un, et libère le client.
Future<void> deleteAccountAndDispose(SupabaseClient client) async {
  if (client.auth.currentUser != null) {
    await SupabaseAuthRepository(client).deleteAccount();
  }
  await client.dispose();
}

/// Code à 6 chiffres du dernier e-mail reçu par [email], une fois que
/// [emailCount] e-mails lui sont parvenus.
Future<String> latestEmailCode(String email, {required int emailCount}) async {
  const attempts = 20;
  const pause = Duration(milliseconds: 250);

  for (var attempt = 0; attempt < attempts; attempt++) {
    final search = await _mailbox('/api/v1/search', {'query': 'to:$email'});
    final messages = search['messages'] as List<dynamic>;
    if (messages.length >= emailCount) {
      final latest = messages.first as Map<String, dynamic>;
      final message = await _mailbox('/api/v1/message/${latest['ID']}');
      final code = RegExp(r'\b\d{6}\b').firstMatch(message['Text'] as String);
      if (code != null) return code.group(0)!;
    }
    await Future<void>.delayed(pause);
  }
  fail('Aucun e-mail avec un code reçu pour $email.');
}

Future<Map<String, dynamic>> _mailbox(
  String path, [
  Map<String, String>? query,
]) async {
  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(
      Uri.http('$_host:$_mailboxPort', path, query),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    httpClient.close();
  }
}

/// Secret défini dans supabase/functions/.env.test.
const _webhookSecret = 'secret-de-test-du-webhook';

/// Envoie [body] à la fonction `revenuecat-webhook`, comme le ferait RevenueCat.
Future<({int status, Object? body})> postWebhook(
  Map<String, Object?> body, {
  String? secret = _webhookSecret,
}) async {
  final httpClient = HttpClient();
  try {
    final request = await httpClient.postUrl(
      Uri.parse('http://$_host:55321/functions/v1/revenuecat-webhook'),
    );
    request.headers.contentType = ContentType.json;
    if (secret != null) request.headers.set('Authorization', secret);
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return (status: response.statusCode, body: jsonDecode(text) as Object?);
  } finally {
    httpClient.close();
  }
}

/// Donne un abonnement Premium mensuel à l'utilisateur connecté sur [client].
Future<void> activatePremium(SupabaseClient client) async {
  final userId = client.auth.currentUser!.id;
  final now = DateTime.now();
  final response = await postWebhook({
    'api_version': '1.0',
    'event': {
      'id': 'test-${now.microsecondsSinceEpoch}',
      'type': 'INITIAL_PURCHASE',
      'app_user_id': userId,
      'product_id': 'premium_monthly',
      'period_type': 'NORMAL',
      'event_timestamp_ms': now.millisecondsSinceEpoch,
      'expiration_at_ms': now
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
    },
  });
  if (response.status != HttpStatus.ok) {
    fail('Abonnement de test non appliqué : ${response.body}');
  }
}
