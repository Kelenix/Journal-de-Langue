/// Règles de saisie du compte, identiques à celles du serveur
/// (`supabase/config.toml` : mot de passe et longueur du code).
const minPasswordLength = 8;
const confirmationCodeLength = 6;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _codePattern = RegExp('^\\d{$confirmationCodeLength}\$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

bool isValidPassword(String value) => value.length >= minPasswordLength;

bool isValidConfirmationCode(String value) =>
    _codePattern.hasMatch(value.trim());
