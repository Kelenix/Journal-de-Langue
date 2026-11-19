import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/languages/application/language_providers.dart';

/// Où l'utilisateur en est dans son parcours d'entrée ; pilote la navigation.
enum SessionGate { loading, failed, signedOut, needsLanguage, ready }

final sessionGateProvider = Provider<SessionGate>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (!userId.hasValue) {
    return userId.hasError ? SessionGate.failed : SessionGate.loading;
  }
  if (userId.value == null) return SessionGate.signedOut;

  final languages = ref.watch(activeLanguagesProvider);
  // Pendant un rafraîchissement (après un choix de langue) la valeur
  // précédente reste valable ; après un changement d'utilisateur, non.
  if (languages.isLoading && !languages.isRefreshing) {
    return SessionGate.loading;
  }
  if (languages.hasError) return SessionGate.failed;
  return languages.requireValue.isEmpty
      ? SessionGate.needsLanguage
      : SessionGate.ready;
});
