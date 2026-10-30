import 'package:intl/intl.dart';

/// Formatter for dates and timestamps across IIECM Admin
class AppDateFormatter {
  static final DateFormat _displayDate = DateFormat('dd MMM yyyy');
  static final DateFormat _displayDateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  static String formatDate(DateTime dateTime) => _displayDate.format(dateTime);
  static String formatDateTime(DateTime dateTime) => _displayDateTime.format(dateTime);
  static String formatShortDate(DateTime dateTime) => _shortDate.format(dateTime);
  static String formatMonthYear(DateTime dateTime) => _monthYear.format(dateTime);
}

