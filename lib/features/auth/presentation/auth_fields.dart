import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/auth_validators.dart';

class EmailField extends StatelessWidget {
  const EmailField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: l10n.authEmailLabel),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      validator: (value) =>
          isValidEmail(value ?? '') ? null : l10n.authEmailInvalid,
    );
  }
}

class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    required this.isNewPassword,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  /// `true` pour un mot de passe à créer (règle de longueur, enregistrement
  /// proposé par le gestionnaire de mots de passe).
  final bool isNewPassword;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: true,
      textInputAction: TextInputAction.done,
      autofillHints: [
        isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onFieldSubmitted: (_) => onSubmitted?.call(),
      validator: (value) {
        final password = value ?? '';
        // À la connexion, seule l'absence de saisie est signalée : la règle
        // de longueur a pu changer depuis la création du compte.
        final isAcceptable = isNewPassword
            ? isValidPassword(password)
            : password.isNotEmpty;
        return isAcceptable ? null : l10n.authPasswordTooShort;
      },
    );
  }
}

class ConfirmationCodeField extends StatelessWidget {
  const ConfirmationCodeField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: l10n.verifyCodeLabel),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(confirmationCodeLength),
      ],
      validator: (value) =>
          isValidConfirmationCode(value ?? '') ? null : l10n.authCodeInvalid,
    );
  }
}
