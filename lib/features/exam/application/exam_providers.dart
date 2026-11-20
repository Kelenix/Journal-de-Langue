import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../billing/application/billing_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../data/supabase_exam_repository.dart';
import '../domain/exam.dart';
import '../domain/exam_repository.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => SupabaseExamRepository(ref.watch(supabaseClientProvider)),
);

/// Simulations de l'utilisateur connecté, la plus récente d'abord.
final examsProvider = FutureProvider.autoDispose<List<Exam>>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return const [];
  return ref.watch(examRepositoryProvider).list();
}, retry: (retryCount, error) => null);

/// Lancement et remise d'une simulation (US-20).
class ExamController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ExamRepository get _exams => ref.read(examRepositoryProvider);

  Future<bool> start({
    required LearningLanguage language,
    required ExamLevel level,
    required String uiLocale,
  }) => _run(
    () => _exams.start(language: language, level: level, uiLocale: uiLocale),
    // Un Pack Examinateur vient d'être utilisé.
    alsoReloadWallet: true,
  );

  Future<bool> submit({required String examId, required String answer}) =>
      _run(() => _exams.submit(examId: examId, answer: answer));

  Future<bool> _run(
    Future<Exam> Function() action, {
    bool alsoReloadWallet = false,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!ref.mounted) return !result.hasError;

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return false;
    }
    ref.invalidate(examsProvider);
    if (alsoReloadWallet) ref.invalidate(walletProvider);
    state = const AsyncData(null);
    return true;
  }
}

final examControllerProvider =
    NotifierProvider.autoDispose<ExamController, AsyncValue<void>>(
      ExamController.new,
    );
