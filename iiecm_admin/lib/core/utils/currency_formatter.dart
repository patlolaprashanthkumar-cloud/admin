import 'package:intl/intl.dart';

/// Formatter for Indian Rupee (INR) transactions across IIECM Admin
class CurrencyFormatter {
  static final NumberFormat _inrStandard = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats amount into Indian Rupee style, e.g. ₹25,000 or ₹25,000.50
  static String format(num amount, {bool showDecimals = false}) {
    return showDecimals ? _inrDecimal.format(amount) : _inrStandard.format(amount);
  }
}

