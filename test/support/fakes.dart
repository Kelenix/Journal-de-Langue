import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/ads/domain/ad_status.dart';
import 'package:journal_de_langue/features/ads/domain/ads_service.dart';
import 'package:journal_de_langue/features/auth/domain/auth_repository.dart';
import 'package:journal_de_langue/features/billing/domain/billing_repository.dart';
import 'package:journal_de_langue/features/billing/domain/offer.dart';
import 'package:journal_de_langue/features/billing/domain/one_time_product.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/billing/domain/wallet.dart';
import 'package:journal_de_langue/features/exam/domain/exam.dart';
import 'package:journal_de_langue/features/exam/domain/exam_repository.dart';
import 'package:journal_de_langue/features/exercises/domain/exercise.dart';
import 'package:journal_de_langue/features/exercises/domain/exercise_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_draft_store.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/journal/domain/journal_repository.dart';
import 'package:journal_de_langue/features/languages/domain/language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/reports/domain/content_report_repository.dart';
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
  String? get currentEmail => _userId == null ? null : 'learner@example.test';

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
  FakeJournalRepository({this.vocabulary, this.subscriptions, this.wallet});

  static const _freeDailyCorrections = 1;
  static const _premiumDailyCorrections = 30;

  /// Reçoit le vocabulaire des journaux corrigés, comme le fait le serveur.
  final FakeVocabularyRepository? vocabulary;

  /// Source de l'offre de l'utilisateur ; sans elle, l'offre est gratuite.
  final FakeSubscriptionRepository? subscriptions;

  /// Crédits achetés, utilisés une fois le quota du jour épuisé.
  final FakeWalletRepository? wallet;

  /// Corrections offertes par des vidéos, utilisées après les crédits.
  int rewardCorrections = 0;

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

  /// Le serveur passe au jour suivant : quota du jour neuf.
  void startNewDay() {
    _entryOfDay = null;
    _correctionsToday = 0;
  }

  /// Journaux corrigés, du plus récent au plus ancien.
  List<JournalEntry> get savedEntries =>
      _entries.values.toList()
        ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

  /// Pages d'historique demandées.
  final historyPages = <({int offset, int limit})>[];

  /// Fait échouer le chargement des pages suivantes de l'historique.
  Failure? nextPageFailure;

  @override
  Future<List<JournalEntry>> historyPage({
    required int offset,
    required int limit,
  }) async {
    final failure = offset == 0 ? loadFailure : nextPageFailure;
    if (failure != null) throw failure;
    historyPages.add((offset: offset, limit: limit));
    return savedEntries.skip(offset).take(limit).toList();
  }

  @override
  Future<List<JournalEntry>> entriesSince(
    LearningLanguage language, {
    DateTime? firstDay,
  }) async {
    final failure = loadFailure;
    if (failure != null) throw failure;
    return [
      for (final entry in savedEntries)
        if (entry.language == language &&
            (firstDay == null || !entry.entryDate.isBefore(firstDay)))
          entry,
    ];
  }

  @override
  Future<HistoryOverview> historyOverview() async => HistoryOverview(
    historyDays: subscriptions?.activePlan == null ? 4 : null,
    lockedEntries: subscriptions?.activePlan == null ? lockedEntries : 0,
    correctedEntries: _entries.length + lockedEntries,
  );

  int get _planCorrectionsLeft =>
      ((subscriptions?.activePlan == null
                  ? _freeDailyCorrections
                  : _premiumDailyCorrections) -
              _correctionsToday)
          .clamp(0, 30);

  @override
  Future<JournalAllowance> allowance(DateTime day) async {
    final failure = loadFailure;
    if (failure != null) throw failure;
    final plan = subscriptions?.activePlan;
    return JournalAllowance(
      plan: plan,
      maxSentences: plan == null ? 7 : 40,
      maxCharacters: plan == null ? 1000 : 6000,
      correctionsLeft: _planCorrectionsLeft,
      credits: wallet?.wallet.correctionCredits ?? 0,
      rewardCorrections: rewardCorrections,
    );
  }

  @override
  Future<String?> entryIdOfDay(DateTime day) async => _entryOfDay?.id;

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
    // Quota du jour épuisé : un crédit acheté prend le relais.
    final usesCredit = _planCorrectionsLeft == 0;
    if (usesCredit) {
      if ((wallet?.wallet.correctionCredits ?? 0) > 0) {
        wallet!.spendCredit();
      } else {
        rewardCorrections--;
      }
    }
    seedCorrectedToday(entry);
    if (usesCredit) _correctionsToday--;
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
  FakeBillingRepository(this.subscriptions, [this.wallet]);

  /// Prix affichés pour les produits vendus à l'unité.
  static String priceOf(OneTimeProduct product) => switch (product) {
    OneTimeProduct.corrections10 => r'$1.99',
    OneTimeProduct.corrections50 => r'$5.99',
    OneTimeProduct.examPack => r'$7.99',
    OneTimeProduct.removeAds => r'$2.99',
    _ => r'$2.49',
  };

  /// Reçoit les achats à l'unité, comme le serveur après la notification.
  final FakeWalletRepository? wallet;
  final boughtProducts = <OneTimeProduct>[];

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

  /// Achats à l'unité déjà faits avec le compte du store, retrouvés eux aussi
  /// par la restauration.
  final restorableProducts = <OneTimeProduct>[];

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
  Future<List<ProductOffer>> products() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return [
      for (final product in OneTimeProduct.values.reversed)
        ProductOffer(product: product, priceLabel: priceOf(product)),
    ];
  }

  @override
  Future<PurchaseOutcome> buy(OneTimeProduct product) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    if (cancelsPurchase) return PurchaseOutcome.cancelledByUser;

    boughtProducts.add(product);
    if (!neverConfirms) wallet?.grant(product);
    return PurchaseOutcome.completed;
  }

  @override
  Future<void> restore() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    final plan = restorablePlan;
    if (plan != null) _activate(plan, inTrial: false);
    for (final product in restorableProducts) {
      wallet?.grant(product);
    }
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

  /// Exercices offerts par des vidéos.
  int bonus = 0;

  int get _left => (_isPremium ? 20 : 3) + bonus - answers.length;

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

    final entries = journal.savedEntries;
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

    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = [
      for (var offset = 0; offset < today.weekday; offset++)
        if (days.contains(monday.add(Duration(days: offset))))
          monday.add(Duration(days: offset)),
    ];

    final inLanguage = entries.where((entry) => entry.language == language);
    final isPremium = subscriptions?.activePlan != null;
    if (!isPremium) {
      return LearningStats(
        isPremium: false,
        streakDays: streak,
        journals: inLanguage.length,
        weekDays: weekDays,
      );
    }

    final counts = <ErrorCategory, int>{};
    for (final item in inLanguage.expand((entry) => entry.items)) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    final words = inLanguage.expand((entry) => entry.vocabulary).toList();
    final weeks = <DateTime, int>{};
    for (final entry in inLanguage) {
      final date = entry.entryDate;
      final monday = DateTime(
        date.year,
        date.month,
        date.day - date.weekday + 1,
      );
      weeks[monday] = (weeks[monday] ?? 0) + 1;
    }
    return LearningStats(
      isPremium: true,
      streakDays: streak,
      journals: inLanguage.length,
      weekDays: weekDays,
      wordsLearned: words.where((word) => word.learnedAt != null).length,
      wordsTotal: words.length,
      mistakesByCategory: [
        for (final MapEntry(:key, :value) in counts.entries)
          CategoryCount(category: key, count: value),
      ]..sort((a, b) => b.count.compareTo(a.count)),
      weeklyJournals: [
        for (final MapEntry(:key, :value) in weeks.entries)
          WeeklyJournals(weekStart: key, journals: value),
      ]..sort((a, b) => a.weekStart.compareTo(b.weekStart)),
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

/// Achats à l'unité en mémoire, tels que le serveur les connaît.
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository([this.wallet = const Wallet()]);

  Wallet wallet;

  /// Fait échouer la lecture des achats.
  Failure? failure;

  @override
  Future<Wallet> current() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return wallet;
  }

  /// Ce que la notification d'achat apporterait.
  void grant(OneTimeProduct product) {
    final language = product.passLanguage;
    wallet = switch (product) {
      OneTimeProduct.corrections10 => wallet.copyWith(
        correctionCredits: wallet.correctionCredits + 10,
      ),
      OneTimeProduct.corrections50 => wallet.copyWith(
        correctionCredits: wallet.correctionCredits + 50,
      ),
      OneTimeProduct.examPack => wallet.copyWith(
        examCredits: wallet.examCredits + 1,
      ),
      OneTimeProduct.removeAds => wallet.copyWith(adsRemoved: true),
      _ => wallet.copyWith(
        languagePasses: [
          ...wallet.languagePasses,
          LanguagePass(language: language!, expiresAt: DateTime(2026, 12, 19)),
        ],
      ),
    };
  }

  void spendCredit() =>
      wallet = wallet.copyWith(correctionCredits: wallet.correctionCredits - 1);
}

/// Sujet d'examen d'exemple.
const sampleExamPrompt = ExamPrompt(
  title: 'A letter to a friend',
  task: 'Write to a friend about your last holiday.',
  minWords: 120,
  maxWords: 180,
);

/// Correction renforcée d'exemple.
const sampleExamResult = ExamResult(
  score: 14,
  levelEstimate: 'B1',
  summary: 'Clear and well organised.',
  criteria: [
    CriterionScore(
      criterion: ExamCriterion.task,
      score: 4,
      comment: 'Complete.',
    ),
    CriterionScore(
      criterion: ExamCriterion.coherence,
      score: 4,
      comment: 'Well linked.',
    ),
    CriterionScore(
      criterion: ExamCriterion.vocabulary,
      score: 3,
      comment: 'Some repetition.',
    ),
    CriterionScore(
      criterion: ExamCriterion.grammar,
      score: 3,
      comment: 'Check past tenses.',
    ),
  ],
  correctedText: 'I went to Rome.',
  items: [
    CorrectionItem(
      original: 'goed',
      corrected: 'went',
      category: ErrorCategory.conjugation,
      explanation: '"Go" is irregular.',
    ),
  ],
  revisionPlan: [
    RevisionStep(
      title: 'Irregular verbs',
      details: 'Learn the 50 most common.',
    ),
    RevisionStep(title: 'Linking words', details: 'Vary "and" and "then".'),
  ],
);

/// Simulations en mémoire, avec les règles du serveur : un Pack Examinateur
/// par simulation, une seule simulation en cours à la fois.
class FakeExamRepository implements ExamRepository {
  FakeExamRepository(this.wallet);

  final FakeWalletRepository wallet;
  final exams = <Exam>[];
  final drafts = <String>[];

  /// Fait échouer le lancement d'une simulation.
  Failure? startFailure;

  @override
  Future<List<Exam>> list() async => [...exams.reversed];

  @override
  Future<Exam> start({
    required LearningLanguage language,
    required ExamLevel level,
    required String uiLocale,
  }) async {
    final failure = startFailure;
    if (failure != null) throw failure;
    final open = exams
        .where((exam) => exam.status != ExamStatus.graded)
        .firstOrNull;
    if (open != null) return open;
    if (wallet.wallet.examCredits == 0) throw const NoExamCreditFailure();

    wallet.wallet = wallet.wallet.copyWith(
      examCredits: wallet.wallet.examCredits - 1,
    );
    final exam = Exam(
      id: 'exam-${exams.length + 1}',
      language: language,
      level: level,
      status: ExamStatus.inProgress,
      createdAt: DateTime(2026, 11, 19),
      prompt: sampleExamPrompt,
    );
    exams.add(exam);
    return exam;
  }

  @override
  Future<void> saveDraft({
    required String examId,
    required String answer,
  }) async {
    drafts.add(answer);
    _replace(examId, (exam) => exam.copyWith(answer: answer));
  }

  @override
  Future<Exam> submit({required String examId, required String answer}) async =>
      _replace(
        examId,
        (exam) => exam.copyWith(
          answer: answer,
          status: ExamStatus.graded,
          result: sampleExamResult,
          gradedAt: DateTime(2026, 11, 19),
        ),
      );

  Exam _replace(String examId, Exam Function(Exam) change) {
    final index = exams.indexWhere((exam) => exam.id == examId);
    return exams[index] = change(exams[index]);
  }
}

/// Publicités et récompenses telles que le serveur les connaît.
class FakeAdsRepository implements AdsRepository {
  FakeAdsRepository([this.adStatus = const AdStatus()]);

  /// Utilisateur gratuit, inscrit depuis plus de 14 jours, sans récompense
  /// obtenue aujourd'hui.
  static const eligible = AdStatus(
    adsEnabled: true,
    correctionRewardAvailable: true,
    exercisesRewardAvailable: true,
  );

  AdStatus adStatus;

  @override
  Future<AdStatus> status() async => adStatus;
}

/// SDK publicitaire simulé : la bannière est une boîte reconnaissable, la vidéo
/// « vue en entier » prévient le serveur par [onEarned] comme le ferait AdMob.
class FakeAdsService implements AdsService {
  static const bannerKey = Key('fake-banner');

  /// Consentement donné (ou non requis).
  bool canRequestAds = true;
  bool privacyOptionsRequired = false;
  int privacyOptionsShown = 0;
  int interstitialsShown = 0;
  RewardedOutcome rewardedOutcome = RewardedOutcome.earned;

  /// Ce que le serveur fait quand AdMob confirme la récompense.
  void Function(AdRewardKind kind)? onEarned;
  final rewardedFor = <({String userId, AdRewardKind kind})>[];

  @override
  Future<bool> prepare() async => canRequestAds;

  @override
  Future<bool> isPrivacyOptionsRequired() async => privacyOptionsRequired;

  @override
  Future<void> showPrivacyOptions() async => privacyOptionsShown++;

  @override
  Widget banner() => const SizedBox(key: bannerKey, height: 50);

  @override
  Future<bool> showInterstitial() async {
    interstitialsShown++;
    return true;
  }

  @override
  Future<RewardedOutcome> showRewarded({
    required String userId,
    required AdRewardKind kind,
  }) async {
    rewardedFor.add((userId: userId, kind: kind));
    if (rewardedOutcome == RewardedOutcome.earned) onEarned?.call(kind);
    return rewardedOutcome;
  }
}

/// Signalements reçus par le serveur.
class FakeContentReportRepository implements ContentReportRepository {
  final reports =
      <({ReportedContent content, String targetId, String? comment})>[];

  /// Fait échouer l'envoi.
  Failure? failure;

  @override
  Future<void> report(
    ReportedContent content,
    String targetId, {
    String? comment,
  }) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    reports.add((content: content, targetId: targetId, comment: comment));
  }
}
