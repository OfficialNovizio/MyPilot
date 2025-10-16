
import 'time_utils.dart';

class ShiftDraft {
  String date; // YYYY-MM-DD
  String start; // HH:mm
  String end;   // HH:mm
  String jobId;
  int breakMin;
  ShiftDraft({required this.date, required this.start, required this.end, required this.jobId, this.breakMin = 0});
}

final _dow = {
  'mon': 1,'monday':1,'tue':2,'tues':2,'tuesday':2,'wed':3,'wednesday':3,
  'thu':4,'thur':4,'thurs':4,'thursday':4,'fri':5,'friday':5,'sat':6,'saturday':6,'sun':7,'sunday':7,
};
final _mon = {
  'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,
  'jul':7,'aug':8,'sep':9,'sept':9,'oct':10,'nov':11,'dec':12
};

String _pad2(int n) => n < 10 ? '0$n' : '$n';

String _parseTime(String h, String? m, String? ampm) {
  int hh = int.tryParse(h) ?? 0;
  int mm = int.tryParse(m ?? '0') ?? 0;
  final a = (ampm ?? '').toLowerCase();
  final is12h = a.contains('a') || a.contains('p') || a.contains('am') || a.contains('pm');
  if (is12h) {
    if (a.startsWith('p') && hh < 12) hh += 12;
    if (a.startsWith('a') && hh == 12) hh = 0;
  }
  return '${_pad2(hh)}:${_pad2(mm)}';
}

final _range12 = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*([ap]m?|[AP]M?)?\s*[-–to]+\s*(\d{1,2})(?::(\d{2}))?\s*([ap]m?|[AP]M?)?');
final _range24 = RegExp(r'(\d{1,2}):(\d{2})\s*[-–to]+\s*(\d{1,2}):(\d{2})');

List<ShiftDraft> parseShiftsText(String text, {required DateTime anchorMonth, required String defaultJobId}) {
  final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final drafts = <ShiftDraft>[];

  DateTime? current;
  int anchorYear = anchorMonth.year;
  int anchorMonthNum = anchorMonth.month;

  for (final raw in lines) {
    final line = raw.replaceAll('\u00A0', ' ').toLowerCase();

    final m1 = RegExp(r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*)\s+(\d{1,2})').firstMatch(line);
    if (m1 != null) {
      final mname = m1.group(1)!.substring(0,3);
      final day = int.parse(m1.group(2)!);
      final m = _mon[mname] ?? anchorMonthNum;
      current = DateTime(anchorYear, m, day);
    }

    final m2 = RegExp(r'(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?').firstMatch(line);
    if (m2 != null) {
      final m = int.parse(m2.group(1)!);
      final d = int.parse(m2.group(2)!);
      final y = m2.group(3) != null ? int.parse(m2.group(3)!) : anchorYear;
      current = DateTime(y < 100 ? 2000 + y : y, m, d);
    }

    final m3 = RegExp(r'((?:mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun)[a-z]*)(?:\s+(\d{1,2}))?').firstMatch(line);
    if (m3 != null) {
      final dow = _dow[m3.group(1)!]!;
      if (m3.group(2) != null) {
        final d = int.parse(m3.group(2)!);
        current = DateTime(anchorYear, anchorMonthNum, d);
      } else {
        DateTime probe = DateTime(anchorYear, anchorMonthNum, 1);
        while (probe.weekday != dow) { probe = probe.add(const Duration(days: 1)); }
        final lastDay = DateTime(anchorYear, anchorMonthNum + 1, 0).day;
        if (probe.day <= lastDay) current = probe;
      }
    }

    if (current != null) {
      final matches = _range12.allMatches(line).toList();
      if (matches.isEmpty) {
        final m = _range24.firstMatch(line);
        if (m != null) {
          final s = '{_pad2(int.parse(m.group(1)!))}:{_pad2(int.parse(m.group(2)!))}';
          final e = '{_pad2(int.parse(m.group(3)!))}:{_pad2(int.parse(m.group(4)!))}';
          drafts.add(ShiftDraft(date: ymd(current), start: s, end: e, jobId: defaultJobId));
          continue;
        }
      }
      for (final m in matches) {
        final s = _parseTime(m.group(1)!, m.group(2), m.group(3));
        final e = _parseTime(m.group(4)!, m.group(5), m.group(6));
        drafts.add(ShiftDraft(date: ymd(current), start: s, end: e, jobId: defaultJobId));
      }
    }
  }
  return drafts;
}
