import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/legal_document.dart';

/// Texte légal demandé, dans la langue de l'interface (code de langue).
typedef LegalTextRequest = (LegalDocument, String);

final legalTextProvider = FutureProvider.autoDispose
    .family<List<LegalBlock>, LegalTextRequest>((ref, request) async {
      final (document, languageCode) = request;
      return parseLegalText(
        await rootBundle.loadString(document.assetPath(languageCode)),
      );
    }, retry: (retryCount, error) => null);
