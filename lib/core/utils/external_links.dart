import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Identifiant de l'application Android (android/app/build.gradle.kts).
const _androidPackageName = 'com.journaldelangue.journal_de_langue';

/// Ouvre une adresse dans l'application du système. Remplacé dans les tests.
final urlOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Page du store où l'utilisateur gère ou annule ses abonnements.
Uri get subscriptionManagementUrl => defaultTargetPlatform == TargetPlatform.iOS
    ? Uri.https('apps.apple.com', '/account/subscriptions')
    : Uri.https('play.google.com', '/store/account/subscriptions', {
        'package': _androidPackageName,
      });
