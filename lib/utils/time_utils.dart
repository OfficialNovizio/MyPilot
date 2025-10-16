
import 'package:intl/intl.dart';

String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String hhmm(DateTime d) => DateFormat('HH:mm').format(d);
String monthDay(DateTime d) => DateFormat('MMM d').format(d);
String formatShort(DateTime d) => DateFormat('MMM d').format(d);
DateTime atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime startOfWeek(DateTime d, bool monday) {
  final wd = d.weekday; // 1 Mon..7 Sun
  final diff = monday ? (wd - DateTime.monday) : (wd % 7);
  final res = DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  return DateTime(res.year, res.month, res.day);
}
DateTime addDays(DateTime d, int n) => d.add(Duration(days: n));
int minutesBetween(String startHHMM, String endHHMM) {
  final sh = int.parse(startHHMM.substring(0, 2));
  final sm = int.parse(startHHMM.substring(3, 5));
  final eh = int.parse(endHHMM.substring(0, 2));
  final em = int.parse(endHHMM.substring(3, 5));
  var start = sh * 60 + sm;
  var end = eh * 60 + em;
  if (end < start) end += 24 * 60;
  return end - start;
}
