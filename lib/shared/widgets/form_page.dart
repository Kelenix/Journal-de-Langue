import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Mise en page commune des écrans de formulaire : titre, contenu défilant
/// (le clavier ne masque rien), largeur bornée sur grand écran.
class FormPage extends StatelessWidget {
  const FormPage({required this.title, required this.children, super.key});

  static const _maxContentWidth = 480.0;

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
