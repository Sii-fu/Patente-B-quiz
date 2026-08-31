import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats a course access expiry date as e.g. "Oct 24, 2026", localized to the
/// app's current locale. Shared by the admin user list and the access gates.
String formatExpiryDate(BuildContext context, DateTime date) {
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat('MMM d, yyyy', localeName).format(date.toLocal());
}

/// Adds [months] calendar months to [date]. Using `Duration(days: 30 * n)`
/// drifts, so build the date from its components instead — DateTime normalises
/// an overflowing month (e.g. month 15 becomes March of the next year) and an
/// overflowing day (e.g. Jan 31 + 1 month becomes Mar 2/3).
DateTime addMonths(DateTime date, int months) {
  return DateTime(
    date.year,
    date.month + months,
    date.day,
    date.hour,
    date.minute,
    date.second,
  );
}
