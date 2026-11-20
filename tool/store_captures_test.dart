// Captures des écrans pour les fiches des stores, en français et en anglais,
// rendues par l'app elle-même avec des données d'exemple (abonné Premium).
//
// Lancer, depuis la racine du projet :
//   flutter test tool/store_captures_test.dart --update-goldens
//   python tool/generate_store_visuals.py
//
// Écrit docs/store/captures/<langue>/<numéro>-<écran>.png : 1080 × 2400, sans
// barres du système. Hors de test/ : ne fait pas partie de la suite de tests.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/exam/domain/exam.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/stats/domain/learning_stats.dart';
import 'package:journal_de_langue/features/vocabulary/domain/vocabulary_item.dart';
import 'package:journal_de_langue/l10n/app_localizations.dart';

import '../test/support/fakes.dart';
import '../test/support/pump_app.dart';

void main() {
  testWidgets('captures en français', (tester) => _capture(tester, _french));
  testWidgets('captures en anglais', (tester) => _capture(tester, _english));
}

/// Contenu d'exemple pour une langue d'interface.
typedef _Sample = ({
  String folder,
  Locale locale,

  /// La première est la langue du journal.
  List<LearningLanguage> languages,
  String draft,
  JournalEntry corrected,
  List<VocabularyItem> words,
  Exam exam,
});

Future<void> _capture(WidgetTester tester, _Sample sample) async {
  await tester.runAsync(_loadFonts);
  tester.platformDispatcher.localesTestValue = [sample.locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  // Les vraies ombres, que les tests remplacent par des aplats, dès le
  // premier rendu : la première capture les montre aussi.
  debugDisableShadows = false;
  try {
    await _captureScreens(tester, sample);
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _captureScreens(WidgetTester tester, _Sample sample) async {
  final subscriptions = FakeSubscriptionRepository(
    Subscription(
      plan: SubscriptionPlan.annual,
      expiresAt: FakeSubscriptionRepository.farFuture,
    ),
  );
  final wallet = FakeWalletRepository();
  final language = sample.languages.first;
  await pumpApp(
    tester,
    auth: FakeAuthRepository(userId: FakeAuthRepository.signedInUserId),
    languages: FakeLanguageRepository(sample.languages, subscriptions),
    subscriptions: subscriptions,
    wallet: wallet,
    journal: FakeJournalRepository(subscriptions: subscriptions, wallet: wallet)
      ..seedPast(sample.corrected),
    vocabulary: FakeVocabularyRepository(sample.words),
    drafts: InMemoryJournalDraftStore()
      ..drafts[(FakeAuthRepository.signedInUserId, language)] = sample.draft,
    stats: _CuratedStats(),
    exams: FakeExamRepository(wallet)..exams.add(sample.exam),
  );
  final l10n = lookupAppLocalizations(sample.locale);

  Future<void> shot(String name) async {
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/store/captures/${sample.folder}/$name.png'),
    );
  }

  Future<void> openTab(IconData icon) => tapOn(tester, find.byIcon(icon));

  await shot('1-journal');

  await openTab(Icons.schedule_outlined);
  await tapOn(tester, find.text(sample.corrected.originalText));
  await shot('2-correction');
  // Bouton retour par son type : son libellé suit la langue.
  await tapOn(tester, find.byType(BackButton));

  await openTab(Icons.copy_outlined);
  await shot('3-review');

  await openTab(Icons.bar_chart_rounded);
  await shot('4-progress');

  await openTab(Icons.copy_outlined);
  await tapOn(tester, find.text(l10n.examTitle));
  await tapOn(tester, find.text(l10n.examScore(sample.exam.result!.score)));
  await shot('5-exam');
}

/// Polices de l'app (DM Sans, Inter, icônes), chargées pour un rendu fidèle.
Future<void> _loadFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Progrès d'un abonné régulier : 12 jours de suite, 4 à 7 journaux par semaine.
class _CuratedStats extends FakeStatsRepository {
  _CuratedStats() : super(journal: FakeJournalRepository());

  @override
  Future<LearningStats> get({
    required LearningLanguage language,
    required DateTime day,
  }) async => LearningStats(
    isPremium: true,
    streakDays: 12,
    journals: 40,
    weekDays: [
      DateTime(2026, 11, 16),
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 18),
    ],
    wordsLearned: 18,
    wordsTotal: 48,
    mistakesByCategory: const [
      CategoryCount(category: ErrorCategory.conjugation, count: 18),
      CategoryCount(category: ErrorCategory.spelling, count: 11),
      CategoryCount(category: ErrorCategory.vocabulary, count: 7),
      CategoryCount(category: ErrorCategory.grammar, count: 5),
    ],
    weeklyJournals: [
      for (final (index, journals) in const [3, 5, 4, 6, 7, 5, 6, 4].indexed)
        WeeklyJournals(
          weekStart: DateTime(2026, 9, 28 + 7 * index),
          journals: journals,
        ),
    ],
  );
}

// ── Interface en français : on apprend l'anglais ─────────────────────────────

final _Sample _french = (
  folder: 'fr',
  locale: const Locale('fr'),
  languages: const [LearningLanguage.english, LearningLanguage.spanish],
  draft:
      'Today I visited my grandmother. We has cooked an apple pie together '
      'and she tell me stories about her childhood.',
  corrected: JournalEntry(
    id: 'market',
    language: LearningLanguage.english,
    entryDate: DateTime(2026, 11, 18),
    originalText:
        'Yesterday I go to the market with my sister. We buyed fresh bread '
        'and I has forgot my wallet at home!',
    correctedText:
        'Yesterday I went to the market with my sister. We bought fresh bread '
        'and I had forgotten my wallet at home!',
    level: CorrectionLevel.advanced,
    items: const [
      CorrectionItem(
        original: 'go',
        corrected: 'went',
        category: ErrorCategory.conjugation,
        explanation:
            'Avec « yesterday », l\'action est terminée : le verbe se met au '
            'prétérit.',
      ),
      CorrectionItem(
        original: 'buyed',
        corrected: 'bought',
        category: ErrorCategory.conjugation,
        explanation: '« Buy » est irrégulier : son prétérit est « bought ».',
      ),
      CorrectionItem(
        original: 'has forgot',
        corrected: 'had forgotten',
        category: ErrorCategory.grammar,
        explanation:
            'Pour une action antérieure à une autre action passée, on emploie '
            'le plus-que-parfait.',
      ),
    ],
    vocabulary: const [
      VocabularyItem(
        id: 'v-market',
        term: 'market',
        translation: 'marché',
        example: 'I go to the market on Saturdays.',
      ),
      VocabularyItem(
        id: 'v-bread',
        term: 'fresh bread',
        translation: 'pain frais',
        example: 'We bought fresh bread.',
      ),
      VocabularyItem(
        id: 'v-wallet',
        term: 'wallet',
        translation: 'portefeuille',
        example: 'I forgot my wallet at home.',
      ),
    ],
  ),
  words: [
    const VocabularyItem(
      id: 'w-childhood',
      term: 'childhood',
      translation: 'enfance',
      example: 'She tells me stories about her childhood.',
    ),
    const VocabularyItem(
      id: 'w-pie',
      term: 'apple pie',
      translation: 'tarte aux pommes',
      example: 'We cooked an apple pie together.',
    ),
    const VocabularyItem(
      id: 'w-market',
      term: 'market',
      translation: 'marché',
      example: 'I go to the market on Saturdays.',
    ),
    VocabularyItem(
      id: 'w-wallet',
      term: 'wallet',
      translation: 'portefeuille',
      example: 'I forgot my wallet at home.',
      learnedAt: DateTime(2026, 11, 18),
    ),
  ],
  exam: Exam(
    id: 'exam-1',
    language: LearningLanguage.english,
    level: ExamLevel.b1,
    status: ExamStatus.graded,
    createdAt: DateTime(2026, 11, 17),
    gradedAt: DateTime(2026, 11, 17),
    prompt: const ExamPrompt(
      title: 'A letter to a friend',
      task:
          'Write to a friend about your last holiday: where you went, what you '
          'did and what you enjoyed most.',
      minWords: 120,
      maxWords: 150,
    ),
    answer:
        'Dear Tom, last summer I go to Portugal with my family. We stayed in a '
        'small house near the sea.',
    result: const ExamResult(
      score: 15,
      levelEstimate: 'B1',
      summary:
          'Une lettre claire et bien organisée. Quelques erreurs de temps à '
          'revoir pour viser le B2.',
      criteria: [
        CriterionScore(
          criterion: ExamCriterion.task,
          score: 4,
          comment: 'Tous les points du sujet sont traités.',
        ),
        CriterionScore(
          criterion: ExamCriterion.coherence,
          score: 4,
          comment: 'Les paragraphes s\'enchaînent avec de bons connecteurs.',
        ),
        CriterionScore(
          criterion: ExamCriterion.vocabulary,
          score: 3,
          comment: 'Vocabulaire juste mais répétitif : varie les adjectifs.',
        ),
        CriterionScore(
          criterion: ExamCriterion.grammar,
          score: 4,
          comment: 'Bonne maîtrise ; deux erreurs de prétérit.',
        ),
      ],
      correctedText:
          'Dear Tom, last summer I went to Portugal with my family. We stayed '
          'in a small house near the sea.',
      items: [
        CorrectionItem(
          original: 'go',
          corrected: 'went',
          category: ErrorCategory.conjugation,
          explanation: 'Action terminée dans le passé : prétérit.',
        ),
      ],
      revisionPlan: [
        RevisionStep(
          title: 'Revoir le prétérit des verbes irréguliers',
          details: 'Go, buy, forget : apprends leurs formes passées.',
        ),
        RevisionStep(
          title: 'Enrichir tes descriptions',
          details: 'Apprends cinq adjectifs pour décrire un lieu.',
        ),
      ],
    ),
  ),
);

// ── Interface en anglais : on apprend l'espagnol ─────────────────────────────

final _Sample _english = (
  folder: 'en',
  locale: const Locale('en'),
  languages: const [LearningLanguage.spanish, LearningLanguage.french],
  draft:
      'Hoy yo visitar a mi abuela. Cocinamos un tarta de manzana juntas y ella '
      'me cuenta historias de su infancia.',
  corrected: JournalEntry(
    id: 'mercado',
    language: LearningLanguage.spanish,
    entryDate: DateTime(2026, 11, 18),
    originalText:
        'Ayer yo voy al mercado con mi hermana. Compramos la pan fresco y '
        'olvidé mi cartera en la casa.',
    correctedText:
        'Ayer fui al mercado con mi hermana. Compramos pan fresco y olvidé mi '
        'cartera en casa.',
    level: CorrectionLevel.advanced,
    items: const [
      CorrectionItem(
        original: 'yo voy',
        corrected: 'fui',
        category: ErrorCategory.conjugation,
        explanation:
            'With « ayer », the action is finished: use the preterite. The '
            'subject pronoun is usually left out.',
      ),
      CorrectionItem(
        original: 'la pan',
        corrected: 'pan',
        category: ErrorCategory.grammar,
        explanation: '« Pan » is masculine, and no article is needed here.',
      ),
      CorrectionItem(
        original: 'en la casa',
        corrected: 'en casa',
        category: ErrorCategory.phrasing,
        explanation: '« En casa » means « at home », without the article.',
      ),
    ],
    vocabulary: const [
      VocabularyItem(
        id: 'v-mercado',
        term: 'mercado',
        translation: 'market',
        example: 'Voy al mercado los sábados.',
      ),
      VocabularyItem(
        id: 'v-pan',
        term: 'pan fresco',
        translation: 'fresh bread',
        example: 'Compramos pan fresco.',
      ),
      VocabularyItem(
        id: 'v-cartera',
        term: 'cartera',
        translation: 'wallet',
        example: 'Olvidé mi cartera en casa.',
      ),
    ],
  ),
  words: [
    const VocabularyItem(
      id: 'w-infancia',
      term: 'infancia',
      translation: 'childhood',
      example: 'Me cuenta historias de su infancia.',
    ),
    const VocabularyItem(
      id: 'w-tarta',
      term: 'tarta de manzana',
      translation: 'apple pie',
      example: 'Cocinamos una tarta de manzana.',
    ),
    const VocabularyItem(
      id: 'w-mercado',
      term: 'mercado',
      translation: 'market',
      example: 'Voy al mercado los sábados.',
    ),
    VocabularyItem(
      id: 'w-cartera',
      term: 'cartera',
      translation: 'wallet',
      example: 'Olvidé mi cartera en casa.',
      learnedAt: DateTime(2026, 11, 18),
    ),
  ],
  exam: Exam(
    id: 'exam-1',
    language: LearningLanguage.spanish,
    level: ExamLevel.b1,
    status: ExamStatus.graded,
    createdAt: DateTime(2026, 11, 17),
    gradedAt: DateTime(2026, 11, 17),
    prompt: const ExamPrompt(
      title: 'Una carta a un amigo',
      task:
          'Escribe a un amigo sobre tus últimas vacaciones: adónde fuiste, qué '
          'hiciste y qué te gustó más.',
      minWords: 120,
      maxWords: 150,
    ),
    answer:
        'Querido Tomás: el verano pasado yo voy a Portugal con mi familia. '
        'Nos quedamos en una casa pequeña cerca del mar.',
    result: const ExamResult(
      score: 15,
      levelEstimate: 'B1',
      summary:
          'A clear, well-organised letter. A few tense errors to review to aim '
          'for B2.',
      criteria: [
        CriterionScore(
          criterion: ExamCriterion.task,
          score: 4,
          comment: 'Every point of the task is covered.',
        ),
        CriterionScore(
          criterion: ExamCriterion.coherence,
          score: 4,
          comment: 'Paragraphs flow well with good linking words.',
        ),
        CriterionScore(
          criterion: ExamCriterion.vocabulary,
          score: 3,
          comment: 'Accurate but repetitive vocabulary: vary your adjectives.',
        ),
        CriterionScore(
          criterion: ExamCriterion.grammar,
          score: 4,
          comment: 'Good control; two preterite errors.',
        ),
      ],
      correctedText:
          'Querido Tomás: el verano pasado fui a Portugal con mi familia. Nos '
          'quedamos en una casa pequeña cerca del mar.',
      items: [
        CorrectionItem(
          original: 'yo voy',
          corrected: 'fui',
          category: ErrorCategory.conjugation,
          explanation: 'Finished action in the past: preterite.',
        ),
      ],
      revisionPlan: [
        RevisionStep(
          title: 'Review irregular preterites',
          details: 'Ir, comprar, olvidar: learn their past forms.',
        ),
        RevisionStep(
          title: 'Enrich your descriptions',
          details: 'Learn five adjectives to describe a place.',
        ),
      ],
    ),
  ),
);
