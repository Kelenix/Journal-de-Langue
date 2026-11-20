import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../languages/domain/learning_language.dart';
import '../data/system_voice_service.dart';
import '../domain/voice_service.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = SystemVoiceService();
  ref.onDispose(service.dispose);
  return service;
});

/// Bouton « Écouter » dont le texte est lu en ce moment : un seul moteur de
/// lecture pour toute l'app, donc un seul bouton actif à la fois.
class SpeakingButtonNotifier extends Notifier<Object?> {
  @override
  Object? build() => null;

  bool isActive(Object button) => state == button;

  void start(Object button) => state = button;

  void stop(Object button) {
    if (state == button) state = null;
  }
}

final speakingButtonProvider =
    NotifierProvider<SpeakingButtonNotifier, Object?>(
      SpeakingButtonNotifier.new,
    );

/// Vrai si l'appareil sait lire cette langue à voix haute.
final canSpeakProvider = FutureProvider.autoDispose
    .family<bool, LearningLanguage>(
      (ref, language) => ref.watch(voiceServiceProvider).canSpeak(language),
    );
