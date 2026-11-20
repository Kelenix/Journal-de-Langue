import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../shared/application/action_controller.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

/// Identifiant de l'utilisateur connecté, `null` s'il ne l'est pas.
final currentUserIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).watchUserId(),
);

/// E-mail du compte connecté, relu à chaque changement de compte.
final currentEmailProvider = Provider<String?>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(authRepositoryProvider).currentEmail;
});

/// Actions de compte d'un écran. Chaque écran a sa propre instance pour ne pas
/// partager chargement et erreurs.
class AuthController extends ActionController {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<bool> signIn({required String email, required String password}) =>
      run(() => _repository.signIn(email: email.trim(), password: password));

  Future<bool> signUp({required String email, required String password}) =>
      run(() => _repository.signUp(email: email.trim(), password: password));

  Future<bool> confirmSignUp({required String email, required String code}) =>
      run(() => _repository.confirmSignUp(email: email, code: code.trim()));

  Future<bool> resendSignUpCode(String email) =>
      run(() => _repository.resendSignUpCode(email));

  Future<bool> requestPasswordReset(String email) =>
      run(() => _repository.requestPasswordReset(email.trim()));

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => run(
    () => _repository.resetPassword(
      email: email.trim(),
      code: code.trim(),
      newPassword: newPassword,
    ),
  );

  Future<bool> signOut() => run(_repository.signOut);

  Future<bool> deleteAccount() => run(_repository.deleteAccount);
}

typedef _AuthControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>;

_AuthControllerProvider _authController() =>
    NotifierProvider.autoDispose<AuthController, AsyncValue<void>>(
      AuthController.new,
    );

final signInControllerProvider = _authController();
final signUpControllerProvider = _authController();
final verifyEmailControllerProvider = _authController();
final forgotPasswordControllerProvider = _authController();
final accountControllerProvider = _authController();
