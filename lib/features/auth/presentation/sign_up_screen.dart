import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_providers.dart';
import 'auth_fields.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    final isCodeSent = await ref
        .read(signUpControllerProvider.notifier)
        .signUp(email: email, password: _password.text);
    if (isCodeSent && mounted) {
      await context.push(AppRoutes.verifyEmail, extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(signUpControllerProvider);
    final error = action.error;

    return FormPage(
      title: l10n.authSignUpTitle,
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
                  isNewPassword: true,
                  onSubmitted: _submit,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ErrorMessage(failureMessage(l10n, error)),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.authSignUpAction,
          isLoading: action.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go(AppRoutes.signIn),
          child: Text(l10n.authHaveAccount),
        ),
      ],
    );
  }
}
