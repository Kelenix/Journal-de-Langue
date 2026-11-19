import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../languages/domain/learning_language.dart';
import '../data/system_voice_service.dart';
import '../domain/voice_service.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = SystemVoiceService();
  ref.onDispose(service.dispose);
  return service;
});

/// Vrai si l'appareil sait lire cette langue à voix haute.
final canSpeakProvider = FutureProvider.autoDispose
    .family<bool, LearningLanguage>(
      (ref, language) => ref.watch(voiceServiceProvider).canSpeak(language),
    );
