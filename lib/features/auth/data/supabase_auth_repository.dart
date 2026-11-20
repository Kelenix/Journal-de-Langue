import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  Stream<String?> watchUserId() => _userIdEvents().distinct();

  Stream<String?> _userIdEvents() async* {
    yield _auth.currentUser?.id;
    // Une coupure réseau pendant le renouvellement du jeton arrive comme une
    // erreur du flux, rejouée à chaque nouvel abonnement : la session reste
    // valable et le renouvellement est retenté. Une session perdue arrive, elle,
    // comme une déconnexion.
    yield* _auth.onAuthStateChange
        .map((state) => state.session?.user.id)
        .handleError((Object _) {});
  }

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Future<void> signUp({required String email, required String password}) =>
      guardFailures(() => _auth.signUp(email: email, password: password));

  @override
  Future<void> confirmSignUp({required String email, required String code}) =>
      guardFailures(
        () => _auth.verifyOTP(email: email, token: code, type: OtpType.signup),
      );

  @override
  Future<void> resendSignUpCode(String email) =>
      guardFailures(() => _auth.resend(type: OtpType.signup, email: email));

  @override
  Future<void> signIn({required String email, required String password}) =>
      guardFailures(
        () => _auth.signInWithPassword(email: email, password: password),
      );

  @override
  Future<void> requestPasswordReset(String email) =>
      guardFailures(() => _auth.resetPasswordForEmail(email));

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => guardFailures(() async {
    await _auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      // Reprendre son mot de passe actuel n'est pas une erreur pour
      // l'utilisateur : il est connecté avec le mot de passe saisi.
      if (error.code != 'same_password') rethrow;
    }
  });

  @override
  Future<void> signOut() => guardFailures(_auth.signOut);

  @override
  Future<void> deleteAccount() => guardFailures(() async {
    await _client.rpc<void>('delete_account');
    // Le compte n'existe plus côté serveur : seule la session locale reste à
    // effacer. Elle l'est avant l'appel au serveur, dont l'échec (réseau) ne
    // change plus rien : la suppression a réussi.
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } on Exception {
      // Session locale déjà retirée.
    }
  });
}
