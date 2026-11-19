import 'package:flutter/material.dart';

/// Action principale d'un écran. Inactive et animée pendant [isLoading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  static const _spinnerSize = 20.0;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox.square(
              dimension: _spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: label,
              ),
            )
          : Text(label),
    );
  }
}
