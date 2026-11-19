import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base des contrôleurs d'écran : expose le chargement et l'erreur d'une
/// action déclenchée par l'utilisateur.
abstract class ActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Retourne `true` si [action] a réussi.
  @protected
  Future<bool> run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    // L'écran a pu être fermé pendant l'action (redirection après connexion).
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
