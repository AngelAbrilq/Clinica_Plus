import 'package:intl/intl.dart';

/// Formatos de fecha/hora en español de Colombia (DRY: un solo lugar).
abstract final class DateFormatters {
  static const String _locale = 'es_CO';

  static final DateFormat _weekdayShort = DateFormat('EEE', _locale);
  static final DateFormat _monthShort = DateFormat('MMM', _locale);
  static final DateFormat _longDate = DateFormat("EEEE d 'de' MMMM", _locale);
  static final DateFormat _time = DateFormat('h:mm a', _locale);

  /// "lun"
  static String weekdayShort(DateTime date) => _weekdayShort.format(date).replaceAll('.', '');

  /// "nov"
  static String monthShort(DateTime date) => _monthShort.format(date).replaceAll('.', '');

  /// "Lunes 2 de noviembre"
  static String longDate(DateTime date) => _capitalize(_longDate.format(date));

  /// "8:00 a. m."
  static String time(DateTime date) => _time.format(date);

  /// "8:00 a. m. – 8:30 a. m."
  static String timeRange(DateTime start, DateTime end) => '${time(start)} – ${time(end)}';

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
