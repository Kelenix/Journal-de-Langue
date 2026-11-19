import 'package:flutter/material.dart';

import '../domain/text_highlight.dart';

/// Texte dont certains fragments sont mis en évidence par [highlightStyle]
/// (fautes barrées, corrections soulignées).
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    required this.text,
    required this.fragments,
    required this.highlightStyle,
    super.key,
  });

  final String text;
  final List<String> fragments;
  final TextStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final segment in highlightFragments(text, fragments))
            TextSpan(
              text: segment.text,
              style: segment.isHighlighted ? highlightStyle : null,
            ),
        ],
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
