import 'package:intl/intl.dart';

/// Number, currency and date formatting helpers.
class Formatters {
  Formatters._();

  static final Map<String, NumberFormat> _currencyCache = {};

  /// Formats [value] using the currency's symbol, e.g. `EGP 1,250` or `1,250 ج.م`.
  static String currency(double value, String currencyCode, {bool compact = false}) {
    final symbol = currencySymbol(currencyCode);
    final pattern = compact ? '#,##0.#' : '#,##0.00';
    final format = _currencyCache.putIfAbsent(
      '$currencyCode|$pattern',
      () => NumberFormat(pattern),
    );
    final formatted = format.format(value);
    return symbol.isEmpty ? formatted : '$formatted $symbol';
  }

  /// Compact form for headline figures, e.g. `12.5K`.
  static String compactNumber(double value) {
    return NumberFormat.compact().format(value);
  }

  static const Map<String, String> _symbols = <String, String>{
    'EGP': 'EGP',
    'USD': '\$',
    'EUR': '€',
    'SAR': 'SAR',
    'AED': 'AED',
    'GBP': '£',
  };

  static String currencySymbol(String code) => _symbols[code] ?? code;

  static const List<String> currencies = <String>[
    'EGP',
    'USD',
    'EUR',
    'SAR',
    'AED',
    'GBP',
  ];

  /// Short month label such as `Sep`.
  static String monthShort(DateTime date) => DateFormat.MMM().format(date);

  /// Full month and year such as `September 2026`.
  static String monthYear(DateTime date) => DateFormat.yMMMM().format(date);

  /// Day + short month such as `12 Sep`.
  static String dayMonth(DateTime date) => DateFormat('d MMM').format(date);

  /// Day of week, e.g. `Monday`.
  static String weekday(DateTime date) => DateFormat.EEEE().format(date);

  /// Percentage with no decimals, e.g. `64%`.
  static String percent(double fraction) =>
      '${(fraction * 100).round()}%';
}
