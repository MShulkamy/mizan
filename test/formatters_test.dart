import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('formats currency with the correct symbol', () {
      expect(Formatters.currency(1250, 'EGP'), contains('EGP'));
      expect(Formatters.currency(1250, 'USD'), contains('\$'));
      expect(Formatters.currency(1250.5, 'EUR'), contains('1,250.50'));
    });

    test('compact numbers collapse large values', () {
      expect(Formatters.compactNumber(1500), '1.5K');
      expect(Formatters.compactNumber(1250000), contains('M'));
    });

    test('percent rounds to whole numbers', () {
      expect(Formatters.percent(0.644), '64%');
      expect(Formatters.percent(0), '0%');
    });

    test('exposes a stable currency list', () {
      expect(Formatters.currencies, contains('EGP'));
      expect(Formatters.currencies, contains('USD'));
    });
  });
}
