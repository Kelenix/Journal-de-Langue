import 'dart:async';
import 'dart:math';

import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/auth/domain/auth_repository.dart';
import 'package:journal_de_langue/features/billing/domain/billing_repository.dart';
import 'package:journal_de_langue/features/billing/domain/offer.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/exercises/domain/exercise.dart';
import 'package:journal_de_langue/features/exercises/domain/exercise_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_draft_store.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/journal/domain/journal_repository.dart';
import 'package:journal_de_langue/features/languages/domain/language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/stats/domain/learning_stats.dart';
import 'package:journal_de_langue/features/stats/domain/stats_repository.dart';
import 'package:journal_de_langue/features/voice/domain/voice_service.dart';
import 'package:journal_de_langue/features/vocabulary/domain/vocabulary_item.dart';
import 'package:journal_de_langue/features/vocabulary/domain/vocabulary_repository.dart';

/// Compte en mémoire. [failure], s'il est défini, fait échouer chaque appel.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({String? userId}) : _userId = userId;

  static const signedInUserId = 'user-1';

  final _changes = StreamController<String?>.broadcast();
  final calls = <String>[];
  String? _userId;
  Failure? failure;

  void _setUser(String? userId) {
    _userId = userId;
    _changes.add(userId);
  }

  Future<void> _record(String call, {String? thenUserId, bool signs = false}) {
    calls.add(call);
    final failure = this.failure;
    if (failure != null) return Future.error(failure);
    if (signs) _setUser(thenUserId);
    return Future.value();
  }

  @override
  Stream<String?> watchUserId() async* {
    yield _userId;
    yield* _changes.stream;
  }

  @override
  Future<void> signUp({required String email, required String password}) =>
      _record('signUp $email');

  @override
  Future<void> confirmSignUp({required String email, required String code}) =>
      _record(
        'confirmSignUp $email $code',
        thenUserId: signedInUserId,
        signs: true,
      );

  @override
  Future<void> resendSignUpCode(String email) =>
      _record('resendSignUpCode $email');

  @override
  Future<void> signIn({required String email, required String password}) =>
      _record('signIn $email', thenUserId: signedInUserId, signs: true);

  @override
  Future<void> requestPasswordReset(String email) =>
      _record('requestPasswordReset $email');

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _record(
    'resetPassword $email $code',
    thenUserId: signedInUserId,
    signs: true,
  );

  @override
  Future<void> signOut() => _record('signOut', signs: true);

  @override
  Future<void> deleteAccount() => _record('deleteAccount', signs: true);
}

/// Langues en mémoire, la langue en cours d'abord, avec les règles du
/// serveur : une langue en gratuit, 3 en Premium mensuel ou hebdomadaire, 4 en
/// annuel.
class FakeLanguageRepository implements LanguageRepository {
  FakeLanguageRepository([
    List<LearningLanguage> active = const [],
    this.subscriptions,
  ]) : _active = [...active];

  /// Source de l'offre de l'utilisateur ; sans elle, l'offre est gratuite.
  final FakeSubscriptionRepository? subscriptions;

  final List<LearningLanguage> _active;
  Failure? failure;

  int get _maxLanguages => switch (subscriptions?.activePlan) {
    null => 1,
    SubscriptionPlan.annual => 4,
    SubscriptionPlan.monthly || SubscriptionPlan.weekly => 3,
  };

  @override
  Future<List<LearningLanguage>> activeLanguages() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return List.unmodifiable(_active.take(_maxLanguages));
  }

  @override
  Future<void> activate(LearningLanguage language) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    if (_maxLanguages == 1) {
      _active.clear();
    } else if (!_active.contains(language) && _active.length >= _maxLanguages) {
      throw const LanguageLimitFailure();
    }
    _active
      ..remove(language)
      ..insert(0, language);
  }

  @override
  Future<void> deactivate(LearningLanguage language) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    _active.remove(language);
  }
}

/// Mot à réviser d'exemple.
const sampleWord = VocabularyItem(
  id: 'word-1',
  term: 'a cat',
  translation: 'un chat',
  example: 'The cat is sleeping.',
);

/// Journal corrigé d'exemple : une faute, « has » → « have », et un mot à
/// réviser.
JournalEntry sampleEntry({
  String id = 'entry-1',
  String originalText = 'I has a cat.',
  DateTime? entryDate,
  CorrectionLevel level = CorrectionLevel.basic,
}) => JournalEntry(
  id: id,
  language: LearningLanguage.english,
  entryDate: entryDate ?? DateTime(2026, 11, 19),
  originalText: originalText,
  correctedText: 'I have a cat.',
  level: level,
  items: const [
    CorrectionItem(
      original: 'has',
      corrected: 'have',
      category: ErrorCategory.conjugation,
      explanation: 'With "I", use "have".',
    ),
  ],
  vocabulary: const [sampleWord],
);

/// Journaux en mémoire, avec la règle gratuite : une correction par jour.
class FakeJournalRepository implements JournalRepository {
  FakeJournalRepository({this.vocabulary, this.subscriptions});

  static const _freeDailyCorrections = 1;
  static const _premiumDailyCorrections = 30;

  /// Reçoit le vocabulaire des journaux corrigés, comme le fait le serveur.
  final FakeVocabularyRepository? vocabulary;

  /// Source de l'offre de l'utilisateur ; sans elle, l'offre est gratuite.
  final FakeSubscriptionRepository? subscriptions;

  final submissions = <({String text, String idempotencyKey})>[];
  final _entries = <String, JournalEntry>{};
  JournalEntry? _entryOfDay;
  int _correctionsToday = 0;

  /// Journaux plus anciens que ce que l'offre permet de relire.
  int lockedEntries = 0;

  /// Fait échouer le chargement de la situation du jour et de l'historique.
  Failure? loadFailure;

  /// Fait échouer l'envoi d'un journal.
  Failure? submitFailure;

  /// Reformulation rendue aux abonnés.
  static const sampleRewrite = SentenceRewrite(
    polite: 'I am the owner of a cat.',
    casual: 'Got a cat.',
    professional: 'I have one cat in my care.',
  );

  final rewrites = <({String entryId, String sentence})>[];

  /// Fait échouer les reformulations.
  Failure? rewriteFailure;

  /// Place un journal déjà corrigé aujourd'hui.
  void seedCorrectedToday(JournalEntry entry) {
    seedPast(entry);
    _entryOfDay = entry;
    _correctionsToday++;
  }

  /// Place un journal corrigé un jour précédent.
  void seedPast(JournalEntry entry) => _entries[entry.id] = entry;

  @override
  Future<List<JournalEntry>> recentEntries() async {
    final failure = loadFailure;
    if (failure != null) throw failure;
    return _entries.values.toList()
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
  }

  @override
  Future<HistoryOverview> historyOverview() async =>
      subscriptions?.activePlan == null
      ? HistoryOverview(historyDays: 4, lockedEntries: lockedEntries)
      : const HistoryOverview(historyDays: null, lockedEntries: 0);

  @override
  Future<JournalAllowance> allowance(DateTime day) async {
    final failure = loadFailure;
    if (failure != null) throw failure;
    final plan = subscriptions?.activePlan;
    final dailyCorrections = plan == null
        ? _freeDailyCorrections
        : _premiumDailyCorrections;
    return JournalAllowance(
      plan: plan,
      maxSentences: plan == null ? 7 : 40,
      maxCharacters: plan == null ? 1000 : 6000,
      correctionsLeft: (dailyCorrections - _correctionsToday).clamp(0, 30),
    );
  }

  @override
  Future<JournalEntry?> entryOfDay(DateTime day) async => _entryOfDay;

  @override
  Future<JournalEntry> entry(String id) async => _entries[id]!;

  @override
  Future<SentenceRewrite> rewrite({
    required String entryId,
    required String sentence,
  }) async {
    rewrites.add((entryId: entryId, sentence: sentence));
    final failure = rewriteFailure;
    if (failure != null) throw failure;
    if (subscriptions?.activePlan == null) {
      throw const PremiumRequiredFailure();
    }
    return sampleRewrite;
  }

  @override
  Future<JournalEntry> submit({
    required String text,
    required LearningLanguage language,
    required String uiLocale,
    required DateTime day,
    required String idempotencyKey,
  }) async {
    submissions.add((text: text, idempotencyKey: idempotencyKey));
    final failure = submitFailure;
    if (failure != null) throw failure;

    final entry = sampleEntry(
      id: 'entry-${submissions.length}',
      originalText: text,
      level: subscriptions?.activePlan == null
          ? CorrectionLevel.basic
          : CorrectionLevel.advanced,
    );
    seedCorrectedToday(entry);
    vocabulary?.items.insertAll(0, entry.vocabulary);
    return entry;
  }
}

/// Vocabulaire en mémoire.
class FakeVocabularyRepository implements VocabularyRepository {
  FakeVocabularyRepository([List<VocabularyItem> items = const []])
    : items = [...items];

  final List<VocabularyItem> items;
  Failure? failure;

  @override
  Future<List<VocabularyItem>> list(LearningLanguage language) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return List.unmodifiable(items);
  }

  @override
  Future<void> setLearned(String itemId, {required bool isLearned}) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    final index = items.indexWhere((item) => item.id == itemId);
    items[index] = items[index].copyWith(
      learnedAt: isLearned ? DateTime(2026, 11, 19) : null,
    );
  }
}

class InMemoryJournalDraftStore implements JournalDraftStore {
  final drafts = <(String, LearningLanguage), String>{};

  @override
  Future<String> load(String userId, LearningLanguage language) async =>
      drafts[(userId, language)] ?? '';

  @override
  Future<void> save(
    String userId,
    LearningLanguage language,
    String text,
  ) async => drafts[(userId, language)] = text;

  @override
  Future<void> clearAll() async => drafts.clear();
}

/// Abonnement en mémoire, tel que le serveur le connaît.
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository([this.subscription]);

  /// Échéance lointaine par rapport à l'horloge des tests.
  static final farFuture = DateTime(2027, 11, 19);

  Subscription? subscription;

  /// Abonnement qui n'apparaît qu'après ce nombre de lectures, comme une
  /// notification d'achat arrivée en retard.
  Subscription? delayed;
  int readsBeforeDelayed = 0;

  SubscriptionPlan? get activePlan => subscription?.plan;

  @override
  Future<Subscription?> current() async {
    if (delayed != null && readsBeforeDelayed-- <= 0) {
      subscription = delayed;
      delayed = null;
    }
    return subscription;
  }
}

/// Store en mémoire : un achat réussi active l'abonnement côté « serveur ».
class FakeBillingRepository implements BillingRepository {
  FakeBillingRepository(this.subscriptions);

  static const annual = Offer(
    plan: SubscriptionPlan.annual,
    priceLabel: r'$29.99',
    price: 29.99,
    currencyCode: 'USD',
    trialDays: 3,
  );
  static const monthly = Offer(
    plan: SubscriptionPlan.monthly,
    priceLabel: r'$4.99',
    price: 4.99,
    currencyCode: 'USD',
    trialDays: 3,
  );
  static const weekly = Offer(
    plan: SubscriptionPlan.weekly,
    priceLabel: r'$2.99',
    price: 2.99,
    currencyCode: 'USD',
  );

  final FakeSubscriptionRepository subscriptions;
  final purchases = <SubscriptionPlan>[];

  /// Fait échouer le chargement des offres, l'achat et la restauration.
  Failure? failure;

  /// L'utilisateur referme la fenêtre de paiement du store.
  bool cancelsPurchase = false;

  /// La notification d'achat n'atteint jamais le serveur.
  bool neverConfirms = false;

  /// Achat déjà fait avec le compte du store, à retrouver par la restauration.
  SubscriptionPlan? restorablePlan;

  // Dans le désordre : l'app doit les présenter annuel, mensuel, hebdomadaire.
  @override
  Future<List<Offer>> offers() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return const [weekly, annual, monthly];
  }

  @override
  Future<PurchaseOutcome> purchase(Offer offer) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    if (cancelsPurchase) return PurchaseOutcome.cancelledByUser;

    purchases.add(offer.plan);
    if (!neverConfirms) _activate(offer.plan, inTrial: offer.trialDays != null);
    return PurchaseOutcome.completed;
  }

  @override
  Future<void> restore() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    final plan = restorablePlan;
    if (plan != null) _activate(plan, inTrial: false);
  }

  void _activate(SubscriptionPlan plan, {required bool inTrial}) =>
      subscriptions.subscription = Subscription(
        plan: plan,
        expiresAt: FakeSubscriptionRepository.farFuture,
        inTrial: inTrial,
      );
}

/// Exercices en mémoire, avec les limites du serveur : 3 par jour en gratuit,
/// 20 en Premium, servis par lots de 3 ou 5.
class FakeExerciseRepository implements ExerciseRepository {
  FakeExerciseRepository({this.subscriptions});

  /// Position de la bonne réponse de chaque exercice.
  static const rightChoice = 1;
  static const explanation = 'With "I", use "have".';

  /// Source de l'offre de l'utilisateur ; sans elle, l'offre est gratuite.
  final FakeSubscriptionRepository? subscriptions;

  final answers = <({String exerciseId, int choice})>[];

  /// Nombre de lots demandés au serveur.
  int batchesServed = 0;

  /// Fait échouer le chargement d'un lot.
  Failure? loadFailure;

  /// Fait échouer l'envoi d'une réponse.
  Failure? answerFailure;

  bool get _isPremium => subscriptions?.activePlan != null;

  int get _left => (_isPremium ? 20 : 3) - answers.length;

  @override
  Future<ExerciseBatch> next({
    required LearningLanguage language,
    required String uiLocale,
    required DateTime day,
  }) async {
    final failure = loadFailure;
    if (failure != null) throw failure;
    if (_left <= 0) return ExerciseBatch.limitReached(isPremium: _isPremium);

    batchesServed++;
    return ExerciseBatch.available(
      category: ErrorCategory.conjugation,
      isPersonalized: _isPremium,
      left: _left,
      exercises: [
        for (var index = 0; index < min(_left, _isPremium ? 5 : 3); index++)
          Exercise(
            id: 'exercise-${answers.length + index}',
            question: 'I ___ a cat. (${answers.length + index + 1})',
            options: const ['has', 'have', 'having', 'haves'],
          ),
      ],
    );
  }

  @override
  Future<ExerciseFeedback> answer({
    required String exerciseId,
    required int choice,
    required DateTime day,
  }) async {
    final failure = answerFailure;
    if (failure != null) throw failure;
    answers.add((exerciseId: exerciseId, choice: choice));
    return ExerciseFeedback(
      isCorrect: choice == rightChoice,
      answerIndex: rightChoice,
      explanation: explanation,
      left: _left,
    );
  }
}

/// Statistiques en mémoire, déduites des journaux corrigés : série comptée
/// jusqu'à aujourd'hui ou hier, détails réservés à Premium.
class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository({required this.journal, this.subscriptions});

  final FakeJournalRepository journal;

  /// Source de l'offre de l'utilisateur ; sans elle, l'offre est gratuite.
  final FakeSubscriptionRepository? subscriptions;

  /// Fait échouer le chargement.
  Failure? failure;

  @override
  Future<LearningStats> get({
    required LearningLanguage language,
    required DateTime day,
  }) async {
    final failure = this.failure;
    if (failure != null) throw failure;

    final entries = await journal.recentEntries();
    final days = {
      for (final entry in entries)
        DateTime(
          entry.entryDate.year,
          entry.entryDate.month,
          entry.entryDate.day,
        ),
    };
    final today = DateTime(day.year, day.month, day.day);
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final inLanguage = entries.where((entry) => entry.language == language);
    final isPremium = subscriptions?.activePlan != null;
    if (!isPremium) {
      return LearningStats(
        isPremium: false,
        streakDays: streak,
        journals: inLanguage.length,
      );
    }

    final counts = <ErrorCategory, int>{};
    for (final item in inLanguage.expand((entry) => entry.items)) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    final words = inLanguage.expand((entry) => entry.vocabulary).toList();
    return LearningStats(
      isPremium: true,
      streakDays: streak,
      journals: inLanguage.length,
      wordsLearned: words.where((word) => word.learnedAt != null).length,
      wordsTotal: words.length,
      mistakesByCategory: [
        for (final MapEntry(:key, :value) in counts.entries)
          CategoryCount(category: key, count: value),
      ]..sort((a, b) => b.count.compareTo(a.count)),
      weeklyMistakeRate: [
        if (inLanguage.isNotEmpty)
          WeeklyMistakeRate(
            weekStart: DateTime(2026, 11, 16),
            mistakesPerSentence: 0.5,
          ),
      ],
    );
  }
}

/// Services vocaux simulés : la dictée « entend » [dictatedText].
class FakeVoiceService implements VoiceService {
  /// Issue des demandes de dictée.
  DictationStart dictation = DictationStart.started;

  /// Ce que l'utilisateur dit.
  String dictatedText = 'I has a dog.';

  /// Langues que l'appareil sait lire.
  Set<LearningLanguage> speakable = LearningLanguage.values.toSet();

  final spoken = <(String, LearningLanguage)>[];
  void Function()? _onDone;

  @override
  Future<DictationStart> startDictation({
    required LearningLanguage language,
    required void Function(String text) onText,
    required void Function() onDone,
  }) async {
    if (dictation != DictationStart.started) return dictation;
    _onDone = onDone;
    // Texte partiel puis complet, comme la reconnaissance du système.
    onText(dictatedText.split(' ').first);
    onText(dictatedText);
    return dictation;
  }

  @override
  Future<void> stopDictation() async {
    _onDone?.call();
    _onDone = null;
  }

  @override
  Future<bool> canSpeak(LearningLanguage language) async =>
      speakable.contains(language);

  @override
  Future<void> speak(String text, LearningLanguage language) async =>
      spoken.add((text, language));

  @override
  Future<void> stopSpeaking() async {}
}
