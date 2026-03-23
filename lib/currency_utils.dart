import 'package:intl/intl.dart';

final NumberFormat _euroFormat = NumberFormat.currency(
  locale: 'es_ES',
  symbol: '€',
  decimalDigits: 2,
);

String formatEuro(num value) => _euroFormat.format(value);
