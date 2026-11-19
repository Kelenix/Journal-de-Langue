import 'dart:convert';
import 'dart:io';

/// Faux serveur de l'API Anthropic, joint par la fonction `correct-entry` quand
/// elle tourne avec `supabase/functions/.env.test`.
class FakeClaude {
  /// Port attendu par `ANTHROPIC_BASE_URL` dans `.env.test`.
  static const port = 55399;

  late final HttpServer _server;

  /// Corps JSON que le « modèle » renvoie comme réponse structurée.
  Map<String, Object?> correction = const {};
  String stopReason = 'end_turn';

  /// Code HTTP renvoyé ; autre que 200 pour simuler une panne de l'API.
  int statusCode = HttpStatus.ok;

  /// Corps des requêtes reçues, dans l'ordre.
  final requests = <Map<String, dynamic>>[];

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server.listen(_respond);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _respond(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    requests.add(jsonDecode(body) as Map<String, dynamic>);

    final payload = statusCode == HttpStatus.ok
        ? {
            'id': 'msg_test',
            'type': 'message',
            'role': 'assistant',
            'model': 'claude-haiku-5-5',
            'content': [
              {'type': 'text', 'text': jsonEncode(correction)},
            ],
            'stop_reason': stopReason,
            'stop_sequence': null,
            'usage': {'input_tokens': 321, 'output_tokens': 123},
          }
        : {
            'type': 'error',
            'error': {'type': 'api_error', 'message': 'panne simulée'},
          };

    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(payload));
    await request.response.close();
  }
}
