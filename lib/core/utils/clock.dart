import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Heure courante de l'appareil. Remplacée dans les tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
