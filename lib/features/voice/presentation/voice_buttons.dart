import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../languages/domain/learning_language.dart';
import '../application/voice_providers.dart';
import '../domain/voice_service.dart';

/// Dicte le journal : le texte reconnu s'ajoute à la fin de [controller]
/// (US-15). Masqué une fois établi que l'appareil ne reconnaît pas la langue.
class DictationButton extends ConsumerStatefulWidget {
  const DictationButton({
    required this.controller,
    required this.language,
    required this.maxCharacters,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final LearningLanguage language;
  final int maxCharacters;
  final bool enabled;

  @override
  ConsumerState<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends ConsumerState<DictationButton> {
  // Gardé hors de `ref` : il sert encore pendant la fermeture de l'écran.
  late final VoiceService _voice = ref.read(voiceServiceProvider);
  bool _isListening = false;
  bool _isUnavailable = false;

  /// Texte présent avant la dictée, auquel s'ajoute ce qui est reconnu.
  String _textBefore = '';

  @override
  void dispose() {
    if (_isListening) _voice.stopDictation();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.controller.text.trimRight();
    _textBefore = existing.isEmpty ? '' : '$existing ';

    final outcome = await _voice.startDictation(
      language: widget.language,
      onText: _insert,
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!mounted) return;

    switch (outcome) {
      case DictationStart.started:
        setState(() => _isListening = true);
      case DictationStart.permissionDenied:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.voicePermissionDenied)),
        );
      case DictationStart.unavailable:
        setState(() => _isUnavailable = true);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.voiceDictationUnavailable)),
        );
    }
  }

  void _insert(String recognized) {
    if (!mounted) return;
    var text = '$_textBefore$recognized';
    if (text.length > widget.maxCharacters) {
      text = text.substring(0, widget.maxCharacters);
    }
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _stop() async {
    await _voice.stopDictation();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnavailable) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return IconButton(
      tooltip: _isListening ? l10n.voiceStopDictation : l10n.voiceDictate,
      isSelected: _isListening,
      icon: const Icon(Icons.mic_none),
      selectedIcon: const Icon(Icons.stop_circle_outlined),
      onPressed: !widget.enabled
          ? null
          : _isListening
          ? _stop
          : _start,
    );
  }
}

/// Lit [text] à voix haute en [language] (US-15). Masqué si l'appareil ne
/// sait pas lire la langue.
class ListenButton extends ConsumerStatefulWidget {
  const ListenButton({required this.text, required this.language, super.key});

  final String text;
  final LearningLanguage language;

  @override
  ConsumerState<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends ConsumerState<ListenButton> {
  late final VoiceService _voice = ref.read(voiceServiceProvider);
  bool _isSpeaking = false;

  @override
  void dispose() {
    if (_isSpeaking) _voice.stopSpeaking();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isSpeaking) {
      await _voice.stopSpeaking();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _voice.speak(widget.text, widget.language);
    if (mounted) setState(() => _isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final canSpeak =
        ref.watch(canSpeakProvider(widget.language)).value ?? false;
    if (!canSpeak) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return IconButton(
      tooltip: _isSpeaking ? l10n.voiceStopListening : l10n.voiceListen,
      isSelected: _isSpeaking,
      icon: const Icon(Icons.volume_up_outlined),
      selectedIcon: const Icon(Icons.stop_circle_outlined),
      onPressed: _toggle,
    );
  }
}
