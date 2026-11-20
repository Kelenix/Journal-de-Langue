import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_providers.dart';
import 'auth_fields.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // En cas de succès, la navigation suit l'état de session.
    ref
        .read(signInControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(signInControllerProvider);
    final error = action.error;

    return FormPage(
      title: l10n.authSignInTitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmailField(controller: _email),
                const SizedBox(height: AppSpacing.lg),
                PasswordField(
                  controller: _password,
                  label: l10n.authPasswordLabel,
                  isNewPassword: false,
                  onSubmitted: _submit,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ErrorMessage(failureMessage(l10n, error)),
          if (error is EmailNotConfirmedFailure)
            TextButton(
              onPressed: () => context.push(
                AppRoutes.verifyEmail,
                extra: _email.text.trim(),
              ),
              child: Text(l10n.verifyEnterCode),
            ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.authSignInAction,
          isLoading: action.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.push(AppRoutes.forgotPassword),
          child: Text(l10n.authForgotPassword),
        ),
        TextButton(
          // Remplace la connexion : le retour ramène à l'accueil.
          onPressed: () => context.pushReplacement(AppRoutes.signUp),
          child: Text(l10n.authNoAccount, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
