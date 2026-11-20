import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Action principale d'un écran. Inactive et animée pendant [isLoading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
    super.key,
  });

  static const _spinnerSize = 20.0;
  static const _iconSize = 20.0;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Icône après le libellé (une flèche pour avancer).
  final IconData? trailingIcon;

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
          : trailingIcon == null
          ? Text(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(label)),
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, size: _iconSize),
              ],
            ),
    );
  }
}
