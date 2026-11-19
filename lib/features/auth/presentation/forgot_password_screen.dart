import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_providers.dart';
import 'auth_fields.dart';

/// Deux étapes sur le même écran : demander un code, puis le saisir avec le
/// nouveau mot de passe.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  bool _isCodeRequested = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    final isRequested = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .requestPasswordReset(_email.text);
    if (isRequested && mounted) setState(() => _isCodeRequested = true);
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;
    // En cas de succès, l'utilisateur est connecté et la navigation suit.
    ref
        .read(forgotPasswordControllerProvider.notifier)
        .resetPassword(
          email: _email.text,
          code: _code.text,
          newPassword: _newPassword.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(forgotPasswordControllerProvider);
    final error = action.error;

    return FormPage(
      title: l10n.forgotTitle,
      children: [
        Text(
          _isCodeRequested
              ? l10n.forgotCodeSent(_email.text.trim())
              : l10n.forgotInstructions,
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isCodeRequested)
                EmailField(controller: _email)
              else ...[
                ConfirmationCodeField(controller: _code),
                const SizedBox(height: AppSpacing.lg),
                PasswordField(
                  controller: _newPassword,
                  label: l10n.authNewPasswordLabel,
                  isNewPassword: true,
                  onSubmitted: _resetPassword,
                ),
              ],
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ErrorMessage(failureMessage(l10n, error)),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: _isCodeRequested
              ? l10n.forgotResetAction
              : l10n.forgotSendCode,
          isLoading: action.isLoading,
          onPressed: _isCodeRequested ? _resetPassword : _requestCode,
        ),
      ],
    );
  }
}
