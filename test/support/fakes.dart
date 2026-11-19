import 'dart:async';

import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/auth/domain/auth_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_draft_store.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/journal/domain/journal_repository.dart';
import 'package:journal_de_langue/features/languages/domain/language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

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

/// Journal corrigé d'exemple : une faute, « has » → « have ».
JournalEntry sampleEntry({
  String id = 'entry-1',
  String originalText = 'I has a cat.',
}) => JournalEntry(
  id: id,
  language: LearningLanguage.english,
  entryDate: DateTime(2026, 11, 19),
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
);

/// Journaux en mémoire, avec la règle gratuite : une correction par jour.
class FakeJournalRepository implements JournalRepository {
  final submissions = <({String text, String idempotencyKey})>[];
  final _entries = <String, JournalEntry>{};
  JournalEntry? _entryOfDay;
  int correctionsLeft = 1;

  /// Fait échouer le chargement de la situation du jour.
  Failure? loadFailure;

  /// Fait échouer l'envoi d'un journal.
  Failure? submitFailure;

  /// Place un journal déjà corrigé aujourd'hui.
  void seedCorrectedToday(JournalEntry entry) {
    _entries[entry.id] = entry;
    _entryOfDay = entry;
    correctionsLeft = 0;
  }

  @override
  Future<JournalAllowance> allowance(DateTime day) async {
    final failure = loadFailure;
    if (failure != null) throw failure;
    return JournalAllowance(
      maxSentences: 7,
      maxCharacters: 1000,
      correctionsLeft: correctionsLeft,
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
    return entry;
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
