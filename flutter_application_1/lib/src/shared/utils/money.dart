import 'package:intl/intl.dart';

const defaultCurrencyCode = 'BRL';
const defaultLocale = 'pt_BR';

String formatMoneyCents(
  int cents, {
  String currencyCode = defaultCurrencyCode,
  String locale = defaultLocale,
}) {
  final formatter = NumberFormat.currency(
    locale: locale,
    symbol: currencySymbol(currencyCode),
    decimalDigits: 2,
  );
  return formatter.format(cents / 100).replaceAll('\u00A0', ' ');
}

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatCentsAsInput(int cents) {
  final whole = (cents ~/ 100).toString();
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return '$whole,$fraction';
}

const monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String monthName(int month) => monthNames[month - 1];

String currencySymbol(String code) => switch (code) {
  'BRL' => r'R$',
  'USD' => r'$',
  'EUR' => '€',
  _ => '$code ',
};

int? parseMoneyToCents(String input) {
  var text = input.replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (text.isEmpty) {
    return null;
  }

  if (text.contains(',')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(text)) {
    text = text.replaceAll('.', '');
  }

  final match = RegExp(r'^-?(\d+)(?:\.(\d{0,2}))?$').firstMatch(text);
  if (match == null) {
    return null;
  }

  final whole = int.parse(match.group(1)!);
  final fractionText = match.group(2) ?? '';
  final fraction = fractionText.isEmpty
      ? 0
      : int.parse(fractionText.padRight(2, '0'));
  final sign = text.startsWith('-') ? -1 : 1;

  return sign * (whole * 100 + fraction);
}
