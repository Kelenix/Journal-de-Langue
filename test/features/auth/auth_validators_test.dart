import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/auth/domain/auth_validators.dart';

void main() {
  test('isValidEmail accepte une adresse usuelle, espaces autour compris', () {
    expect(isValidEmail('lea@example.com'), isTrue);
    expect(isValidEmail('  lea.martin+test@mail.example.fr '), isTrue);
  });

  test('isValidEmail refuse les adresses incomplètes', () {
    for (final value in [
      '',
      'lea',
      'lea@',
      '@example.com',
      'lea@example',
      'a b@c.d',
    ]) {
      expect(isValidEmail(value), isFalse, reason: value);
    }
  });

  test('isValidPassword exige 8 caractères', () {
    expect(isValidPassword('1234567'), isFalse);
    expect(isValidPassword('12345678'), isTrue);
  });

  test('isValidConfirmationCode exige exactement 6 chiffres', () {
    expect(isValidConfirmationCode('123456'), isTrue);
    expect(isValidConfirmationCode(' 123456 '), isTrue);
    for (final value in ['', '12345', '1234567', '12345a']) {
      expect(isValidConfirmationCode(value), isFalse, reason: value);
    }
  });
}
