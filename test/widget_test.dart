import 'package:crave_delivery1/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators', () {
    test('validateRequired rejects empty values', () {
      expect(
        AuthValidators.validateRequired('', 'Restaurant name'),
        'Please enter your Restaurant name',
      );
    });

    test('validateRequired accepts filled values', () {
      expect(AuthValidators.validateRequired('Lahore Grill', 'City'), isNull);
    });

    test('validatePhone accepts valid phone numbers', () {
      expect(AuthValidators.validatePhone('+92 300 1234567'), isNull);
    });

    test('validatePhone rejects short values', () {
      expect(AuthValidators.validatePhone('123'), 'Enter a valid phone number');
    });
  });
}
