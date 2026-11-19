import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Polices embarquées et fichier de leur licence (SIL Open Font License).
const _fontLicenses = {
  'DM Sans': 'assets/fonts/DMSans-OFL.txt',
  'Inter': 'assets/fonts/Inter-OFL.txt',
};

/// Ajoute les licences des polices à la page « Licences » de l'application :
/// l'OFL demande que son texte accompagne les polices distribuées.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: font, value: asset) in _fontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString(asset));
    }
  });
}
