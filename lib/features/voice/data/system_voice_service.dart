import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../languages/domain/learning_language.dart';
import '../domain/voice_service.dart';

/// Reconnaissance et synthèse vocales du système (Android, iOS).
class SystemVoiceService implements VoiceService {
  static const _pauseBeforeStop = Duration(seconds: 5);
  static const _maxDictation = Duration(minutes: 2);
  static const _localesTimeout = Duration(seconds: 2);

  final _speech = SpeechToText();
  final _tts = FlutterTts();

  void Function(String text)? _onText;
  void Function()? _onDone;

  static String _languageTag(LearningLanguage language) => switch (language) {
    LearningLanguage.english => 'en-US',
    LearningLanguage.spanish => 'es-ES',
    LearningLanguage.german => 'de-DE',
    LearningLanguage.french => 'fr-FR',
  };

  @override
  Future<DictationStart> startDictation({
    required LearningLanguage language,
    required void Function(String text) onText,
    required void Function() onDone,
  }) async {
    try {
      // Les écouteurs ne sont retenus qu'à la première initialisation : ils
      // relaient vers la dictée en cours.
      final isReady = await _speech.initialize(
        onStatus: _onStatus,
        onError: (_) => _finish(),
      );
      if (!isReady) {
        return await _speech.hasPermission
            ? DictationStart.unavailable
            : DictationStart.permissionDenied;
      }

      // Android 13 et plus : la liste peut ne jamais arriver, ou ne contenir
      // que les langues téléchargées pour l'écoute hors ligne, alors que
      // l'écoute en ligne connaît la langue. Sinon : la variante attendue.
      final locales = await _speech.locales().timeout(
        _localesTimeout,
        onTimeout: () => const [],
      );
      final localeId = _bestLocale(locales, language) ?? _languageTag(language);

      _onText = onText;
      _onDone = onDone;
      await _speech.listen(
        onResult: (result) => _onText?.call(result.recognizedWords),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          autoPunctuation: true,
          pauseFor: _pauseBeforeStop,
          listenFor: _maxDictation,
        ),
      );
      return DictationStart.started;
    } on ListenFailedException catch (error, stackTrace) {
      developer.log(
        'Écoute impossible',
        name: 'voice',
        error: error,
        stackTrace: stackTrace,
      );
      return DictationStart.failed;
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        'Dictée indisponible',
        name: 'voice',
        error: error,
        stackTrace: stackTrace,
      );
      return DictationStart.unavailable;
    }
  }

  /// La variante attendue de [language] si l'appareil l'a, sinon une autre
  /// variante de la même langue (en-GB pour l'anglais, es-MX pour l'espagnol…).
  static String? _bestLocale(
    List<LocaleName> locales,
    LearningLanguage language,
  ) {
    String normalized(LocaleName locale) =>
        locale.localeId.replaceAll('_', '-').toLowerCase();
    final expected = _languageTag(language).toLowerCase();
    final sameLanguage = locales.where(
      (locale) =>
          normalized(locale) == language.code ||
          normalized(locale).startsWith('${language.code}-'),
    );
    return (sameLanguage
                .where((locale) => normalized(locale) == expected)
                .firstOrNull ??
            sameLanguage.firstOrNull)
        ?.localeId;
  }

  void _onStatus(String status) {
    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      _finish();
    }
  }

  void _finish() {
    final onDone = _onDone;
    _onDone = null;
    onDone?.call();
  }

  @override
  Future<void> stopDictation() => _speech.stop();

  @override
  Future<bool> canSpeak(LearningLanguage language) async {
    try {
      final isAvailable = await _tts.isLanguageAvailable(
        _languageTag(language),
      );
      return isAvailable == true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> speak(String text, LearningLanguage language) async {
    try {
      // Un seul moteur pour tous les boutons : la lecture en cours s'arrête
      // (et rend la main à son bouton) avant la suivante.
      await _tts.stop();
      await _tts.setLanguage(_languageTag(language));
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(text);
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        'Lecture impossible',
        name: 'voice',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    _onText = null;
    _onDone = null;
    await _speech.cancel();
    await _tts.stop();
  }
}
