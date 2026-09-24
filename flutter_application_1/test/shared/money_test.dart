import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMoneyToCents', () {
    test('interpreta formato brasileiro com vírgula', () {
      expect(parseMoneyToCents('1.234,56'), 123456);
      expect(parseMoneyToCents('10,5'), 1050);
      expect(parseMoneyToCents('10,00'), 1000);
    });

    test('interpreta valores simples e com ponto decimal', () {
      expect(parseMoneyToCents('10'), 1000);
      expect(parseMoneyToCents('10.50'), 1050);
    });

    test('interpreta separadores de milhar sem vírgula', () {
      expect(parseMoneyToCents('1.234'), 123400);
      expect(parseMoneyToCents('1.234.567'), 123456700);
    });

    test('ignora símbolos e espaços', () {
      expect(parseMoneyToCents(r'R$ 50,00'), 5000);
      expect(parseMoneyToCents('  7,25  '), 725);
    });

    test('suporta valores negativos', () {
      expect(parseMoneyToCents('-5,00'), -500);
    });

    test('retorna null para entradas inválidas ou vazias', () {
      expect(parseMoneyToCents(''), isNull);
      expect(parseMoneyToCents('   '), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents('10,505'), isNull);
      expect(parseMoneyToCents('1,2,3'), isNull);
    });
  });

  group('formatMoneyCents', () {
    test('formata em reais com duas casas', () {
      final result = formatMoneyCents(123456);
      expect(result, contains(r'R$'));
      expect(result, contains('1.234,56'));
    });

    test('formata valores negativos', () {
      final result = formatMoneyCents(-25);
      expect(result, contains('-'));
      expect(result, contains('0,25'));
    });

    test('formata zero', () {
      final result = formatMoneyCents(0);
      expect(result, contains('0,00'));
    });
  });

  group('formatDate', () {
    test('formata com dois dígitos', () {
      expect(formatDate(DateTime(2026, 9, 24)), '24/09/2026');
      expect(formatDate(DateTime(2026, 3, 5)), '05/03/2026');
    });
  });
}
