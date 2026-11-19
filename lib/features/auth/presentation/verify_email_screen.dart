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

/// Saisie du code reçu par e-mail après l'inscription.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // En cas de succès, la navigation suit l'état de session.
    ref
        .read(verifyEmailControllerProvider.notifier)
        .confirmSignUp(email: widget.email, code: _code.text);
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isSent = await ref
        .read(verifyEmailControllerProvider.notifier)
        .resendSignUpCode(widget.email);
    if (isSent) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.verifyResent)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(verifyEmailControllerProvider);
    final error = action.error;

    return FormPage(
      title: l10n.verifyTitle,
      children: [
        Text(l10n.verifyInstructions(widget.email)),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: ConfirmationCodeField(controller: _code),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ErrorMessage(failureMessage(l10n, error)),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.verifyAction,
          isLoading: action.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: action.isLoading ? null : _resend,
          child: Text(l10n.verifyResend),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.signIn),
          child: Text(l10n.authHaveAccount),
        ),
      ],
    );
  }
}
