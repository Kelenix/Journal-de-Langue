import 'dart:async';

import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/auth/domain/auth_repository.dart';
import 'package:journal_de_langue/features/billing/domain/billing_repository.dart';
import 'package:journal_de_langue/features/billing/domain/offer.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/journal/domain/journal_draft_store.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/journal/domain/journal_repository.dart';
import 'package:journal_de_langue/features/languages/domain/language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
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

/// Langues en mémoire, avec la règle gratuite : une seule langue active.
class FakeLanguageRepository implements LanguageRepository {
  FakeLanguageRepository([List<LearningLanguage> active = const []])
    : _active = [...active];

  List<LearningLanguage> _active;
  Failure? failure;

  @override
  Future<List<LearningLanguage>> activeLanguages() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return List.unmodifiable(_active);
  }

  @override
  Future<void> activate(LearningLanguage language) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    _active = [language];
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
}) => JournalEntry(
  id: id,
  language: LearningLanguage.english,
  entryDate: entryDate ?? DateTime(2026, 11, 19),
  originalText: originalText,
  correctedText: 'I have a cat.',
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
