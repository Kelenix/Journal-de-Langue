import '../../languages/domain/learning_language.dart';

/// Issue d'une demande de dictée.
enum DictationStart {
  started,

  /// L'utilisateur a refusé le micro : l'app reste utilisable au clavier.
  permissionDenied,

  /// Pas de reconnaissance vocale pour cette langue sur l'appareil.
  unavailable,

  /// L'écoute n'a pas pu démarrer (micro occupé par un appel…) : la dictée
  /// reste proposée.
  failed,
}

/// Dictée et lecture à voix haute par les services vocaux du système, sans
/// coût ni envoi à nos serveurs (ADR-005).
abstract interface class VoiceService {
  /// Démarre la dictée en [language]. [onText] reçoit le texte reconnu depuis
  /// le début de la dictée, au fil de la parole ; [onDone] est appelé quand
  /// l'écoute s'arrête. Le micro n'est demandé qu'au premier appel.
  Future<DictationStart> startDictation({
    required LearningLanguage language,
    required void Function(String text) onText,
    required void Function() onDone,
  });

  Future<void> stopDictation();

  /// Vrai si l'appareil sait lire [language] à voix haute.
  Future<bool> canSpeak(LearningLanguage language);

  /// Lit [text] en [language] ; se termine à la fin de la lecture.
  Future<void> speak(String text, LearningLanguage language);

  Future<void> stopSpeaking();
}
