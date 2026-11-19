/// Compte de l'utilisateur. Toute méthode échoue avec une `Failure`.
abstract interface class AuthRepository {
  /// Identifiant de l'utilisateur connecté, `null` sinon. Émet l'état courant
  /// puis chaque changement.
  Stream<String?> watchUserId();

  /// Crée le compte et envoie un code de confirmation par e-mail.
  Future<void> signUp({required String email, required String password});

  /// Valide le code reçu ; l'utilisateur est alors connecté.
  Future<void> confirmSignUp({required String email, required String code});

  Future<void> resendSignUpCode(String email);

  Future<void> signIn({required String email, required String password});

  /// Envoie un code de réinitialisation si un compte existe pour [email].
  Future<void> requestPasswordReset(String email);

  /// Valide le code et enregistre le nouveau mot de passe ; l'utilisateur est
  /// alors connecté.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> signOut();

  /// Supprime le compte et toutes ses données, puis déconnecte.
  Future<void> deleteAccount();
}
