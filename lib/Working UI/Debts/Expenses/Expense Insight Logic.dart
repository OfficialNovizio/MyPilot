// insights_cashflow_paycycles_deck.dart
//
// ✅ Single-file drop-in refactor:
// - Calendar markers (PayMarker) stay for UI (optional)
// - Insights are computed PAYCHEQUE → PAYCHEQUE using YOUR model:
//     PayCell -> PayJobLine (periodStart/periodEnd/payTotal/hoursTotal)
// - Only paydays that lie inside the focused month are included
//
// You asked "whole code at once" → here it is.
//
// NOTE (brutal truth):
// Your previous "marker windows" approach can look correct on the calendar but still compute wrong totals,
// because it doesn't enforce job-specific pay periods. This file fixes that.
// You MUST ensure your shift hours field mapping in _shiftHours() matches your actual model.
//
// ------------------------------------------------------------

import 'dart:math';
import 'package:flutter/material.dart';

import '../../../models/Expense Model.dart';
import '../../Account/Account Getx.dart';

// ------------------------------------------------------------
// YOUR MODELS (as provided)
// ------------------------------------------------------------

// ------------------------------------------------------------
// DATE HELPERS
// ------------------------------------------------------------

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);
DateTime _monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);

String _md(DateTime d) => "${d.month}/${d.day}";
String _rangeLabel(DateTime a, DateTime b) => "${_md(a)}–${_md(b)}";

String _yyyymmdd(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return "$y$m$dd";
}

int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

DateTime _nextMonthlyDueFrom(DateTime anchor, int dueDay) {
  final a = _day(anchor);
  int clampDay(int yy, int mm, int d) => d.clamp(1, _daysInMonth(yy, mm));

  final dThis = DateTime(a.year, a.month, clampDay(a.year, a.month, dueDay));
  if (!dThis.isBefore(a)) return dThis;

  final nm = DateTime(a.year, a.month + 1, 1);
  return DateTime(nm.year, nm.month, clampDay(nm.year, nm.month, dueDay));
}

bool _inWindow(DateTime d, DateTime start, DateTime end) {
  final dd = _day(d);
  return !dd.isBefore(_day(start)) && !dd.isAfter(_day(end));
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is String) return DateTime.tryParse(v);
  return null;
}

// ------------------------------------------------------------
// PAY FREQUENCY → STEP DAYS
// ------------------------------------------------------------

int _stepDays(String? freq) {
  final s = (freq ?? "").toLowerCase().trim();
  if (s.contains("bi") && s.contains("week")) return 14;
  if (s.contains("fortnight")) return 14;
  if (s.contains("week")) return 7;
  if (s.contains("semi") && s.contains("month")) return 15;
  if (s.contains("month")) return 30; // only for markers; pay cycles still use step as period length
  return 0;
}

// ------------------------------------------------------------
// COLOR PARSER (HEX STRING)
// ------------------------------------------------------------

Color _parseColor(String? hex) {
  final raw = (hex ?? "").replaceAll("#", "").trim();
  if (raw.isEmpty) return const Color(0xFF111111);
  final v = int.tryParse(raw.length == 6 ? "FF$raw" : raw, radix: 16);
  if (v == null) return const Color(0xFF111111);
  return Color(v);
}

int? _jobId(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

// ------------------------------------------------------------
// SHIFT FIELD ADAPTERS (YOU MUST VERIFY THESE)
// ------------------------------------------------------------

double _shiftIncome(dynamic sh) {
  final v = sh?.income ?? sh?.pay ?? sh?.amount;
  return (v is num) ? v.toDouble() : 0.0;
}

double _shiftHours(dynamic sh) {
  // 🔧 IMPORTANT: change this to your real field name if needed
  // Common possibilities: hours, totalHours, shiftHours, durationHours, workingHours
  final v = sh?.hours ?? sh?.totalHours ?? sh?.shiftHours ?? sh?.durationHours ?? sh?.workingHours ?? sh?.workHours;
  return (v is num) ? v.toDouble() : 0.0;
}

// ------------------------------------------------------------
// 1) CALENDAR MARKERS (optional, but your calendar uses this)
// Month-only version (since you want only markers inside month)
// ------------------------------------------------------------

Map<DateTime, List<PayMarker>> computePayMarkersMonthOnly({
  required DateTime focusedDay,
  required List<dynamic> jobs, // List<JobData>
}) {
  final monthStart = _day(_monthStart(focusedDay));
  final monthEnd = _day(_monthEnd(focusedDay));

  final out = <DateTime, List<PayMarker>>{};

  for (final j in jobs) {
    final DateTime? last = j.lastPayChequeDate;
    if (last == null) continue;

    DateTime d = _day(last);
    final step = _stepDays(j.payFrequency);
    if (step <= 0) continue;

    final color = _parseColor(j.jobColor);
    final name = (j.jobName ?? 'Job').toString();
    final int jobId = _jobId(j.id) ?? -1;
    if (jobId < 0) continue;

    // jump forward until monthStart
    if (d.isBefore(monthStart)) {
      final diff = monthStart.difference(d).inDays;
      final jumps = (diff / step).ceil();
      d = d.add(Duration(days: jumps * step));
    }

    for (; !d.isAfter(monthEnd); d = d.add(Duration(days: step))) {
      final key = _day(d);
      (out[key] ??= <PayMarker>[]).add(PayMarker(jobId: jobId, jobName: name, color: color));
    }
  }

  return out;
}

// ------------------------------------------------------------
// 2) PAYCYCLES: Map<payDate, PayCell> using YOUR model
// - only paydays inside month
// - each payDate may have multiple jobs (lines)
// - each line has periodStart/periodEnd inclusive
// ------------------------------------------------------------

class _Agg {
  double pay = 0;
  double hours = 0;
}

Map<DateTime, Map<int, _Agg>> _indexShiftsByDayJob(dynamic shiftModel) {
  final out = <DateTime, Map<int, _Agg>>{};
  if (shiftModel == null) return out;

  final months = shiftModel.data;
  if (months == null) return out;

  for (final m in months) {
    final dates = m.dates ?? const [];
    for (final day in dates) {
      final d = _asDate(day.date);
      if (d == null) continue;

      final keyDay = _day(d);
      final shifts = day.data ?? const [];

      for (final sh in shifts) {
        final jid = _jobId(sh?.jobFrom?.id ?? sh?.jobId);
        if (jid == null) continue;

        final mapByJob = (out[keyDay] ??= <int, _Agg>{});
        final agg = (mapByJob[jid] ??= _Agg());

        agg.pay += _shiftIncome(sh);
        agg.hours += _shiftHours(sh);
      }
    }
  }

  return out;
}

_Agg _sumAggForJobInRange({
  required Map<DateTime, Map<int, _Agg>> index,
  required int jobId,
  required DateTime start,
  required DateTime end,
}) {
  final s = _day(start);
  final e = _day(end);

  final res = _Agg();
  for (DateTime d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
    final byJob = index[d];
    final a = byJob?[jobId];
    if (a != null) {
      res.pay += a.pay;
      res.hours += a.hours;
    }
  }
  return res;
}

Map<DateTime, PayCell> computePayCyclesMonthOnly({
  required DateTime focusedDay,
  required List<dynamic> jobs, // List<JobData>
  required dynamic shiftModel, // ShiftModel?
}) {
  final monthStart = _day(_monthStart(focusedDay));
  final monthEnd = _day(_monthEnd(focusedDay));

  final shiftIndex = _indexShiftsByDayJob(shiftModel);

  final tmp = <DateTime, List<PayJobLine>>{};

  for (final j in jobs) {
    final DateTime? lastPay = j.lastPayChequeDate;
    if (lastPay == null) continue;

    final step = _stepDays(j.payFrequency);
    if (step <= 0) continue;

    final int jobId = _jobId(j.id) ?? -1;
    if (jobId < 0) continue;

    final String jobName = (j.jobName ?? "Job").toString();
    final Color color = _parseColor(j.jobColor);

    // first pay date >= monthStart
    DateTime payDate = _day(lastPay);
    if (payDate.isBefore(monthStart)) {
      final diff = monthStart.difference(payDate).inDays;
      final jumps = (diff / step).ceil();
      payDate = payDate.add(Duration(days: jumps * step));
    }

    for (; !payDate.isAfter(monthEnd); payDate = payDate.add(Duration(days: step))) {
      final pd = _day(payDate);

      // paycheque period inclusive: [pd-(step-1), pd]
      final periodStart = pd.subtract(Duration(days: step - 1));
      final periodEnd = pd;

      final agg = _sumAggForJobInRange(
        index: shiftIndex,
        jobId: jobId,
        start: periodStart,
        end: periodEnd,
      );

      (tmp[pd] ??= <PayJobLine>[]).add(
        PayJobLine(
          jobId: jobId,
          jobName: jobName,
          color: color,
          payDate: pd,
          periodStart: periodStart,
          periodEnd: periodEnd,
          payTotal: agg.pay,
          hoursTotal: agg.hours,
        ),
      );
    }
  }

  final out = <DateTime, PayCell>{};
  tmp.forEach((payDate, lines) {
    lines.sort((a, b) => a.jobName.compareTo(b.jobName));
    out[payDate] = PayCell(lines);
  });

  return out;
}

// ------------------------------------------------------------
// 3) PAYCYCLE WINDOWS for INSIGHTS (month-only)
// Here each window is a payDate + PayCell.
// windowStart is the MIN of line.periodStart (in case multiple jobs have different periods).
// ------------------------------------------------------------

class PayCycleWindow {
  final DateTime payDate;
  final PayCell cell;

  PayCycleWindow({required this.payDate, required this.cell});

  DateTime get windowStart {
    if (cell.lines.isEmpty) return payDate;
    return cell.lines.map((x) => _day(x.periodStart)).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime get windowEnd => _day(payDate);

  String get id => "${_yyyymmdd(windowStart)}_${_yyyymmdd(windowEnd)}";
  String get label => _rangeLabel(windowStart, windowEnd);
}

List<PayCycleWindow> buildPayCycleWindowsMonthOnly({
  required DateTime now,
  required DateTime focusedDay,
  required Map<DateTime, PayCell> payCycles,
}) {
  final monthStart = _day(_monthStart(focusedDay));
  final monthEnd = _day(_monthEnd(focusedDay));

  var startCut = _day(now);
  if (startCut.isBefore(monthStart)) startCut = monthStart;

  final keys = payCycles.keys.map(_day).where((d) => !d.isBefore(startCut) && !d.isAfter(monthEnd)).toList()..sort((a, b) => a.compareTo(b));

  return keys.map((k) => PayCycleWindow(payDate: k, cell: payCycles[k]!)).toList();
}

// ------------------------------------------------------------
// 4) EXPENSE FREQUENCY RULES (same as your old code)
// ------------------------------------------------------------

enum _Freq { oneTime, monthly, weekly, perPaycheque, quarterly, yearly, unknown }

_Freq _parseFreq(String raw) {
  final s = raw.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
  if (s.contains('one') || s.contains('once') || s.contains('single')) return _Freq.oneTime;
  if (s.contains('month')) return _Freq.monthly;
  if (s.contains('week')) return _Freq.weekly;
  if (s.contains('pay')) return _Freq.perPaycheque;
  if (s.contains('quarter')) return _Freq.quarterly;
  if (s.contains('year') || s.contains('annual')) return _Freq.yearly;
  return _Freq.unknown;
}

int? _validDueDay(int? d) => (d == null || d <= 0) ? null : d;

// ------------------------------------------------------------
// 5) FOCUS DATA (window expense analysis) (same logic)
// ------------------------------------------------------------

class FocusData {
  final List<dynamic> billsDue;
  final List<dynamic> oneTimePlanned;
  final List<dynamic> unscheduledRecurring;

  final double billsDueTotal;
  final double oneTimeTotal;
  final double unscheduledMonthlyTotal;

  final dynamic topBill;
  final dynamic topOneTime;
  final dynamic topNonEssentialAny;

  final String confidenceLevel;
  final String confidenceReason;

  FocusData({
    required this.billsDue,
    required this.oneTimePlanned,
    required this.unscheduledRecurring,
    required this.billsDueTotal,
    required this.oneTimeTotal,
    required this.unscheduledMonthlyTotal,
    required this.topBill,
    required this.topOneTime,
    required this.topNonEssentialAny,
    required this.confidenceLevel,
    required this.confidenceReason,
  });
}

FocusData buildFocusForWindow({
  required List<dynamic> expenses, // List<ExpenseItem>
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  final billsDue = <dynamic>[];
  final oneTime = <dynamic>[];
  final unscheduled = <dynamic>[];

  double billsTotal = 0;
  double oneTimeTotal = 0;
  double unschedMonthlyTotal = 0;

  int monthlyRecurring = 0;
  int monthlyScheduled = 0;

  for (final e in expenses) {
    if (e.isActive != true) continue;

    final f = _parseFreq((e.frequency ?? "").toString());

    if (f == _Freq.oneTime) {
      final dt = _asDate(e.dateMs);
      if (dt != null && _inWindow(dt, windowStart, windowEnd)) {
        oneTime.add(e);
        oneTimeTotal += (e.amount as num).toDouble();
      }
      continue;
    }

    if (f == _Freq.monthly) {
      monthlyRecurring++;
      final dd = _validDueDay(e.dueDay as int?);

      if (dd == null) {
        unscheduled.add(e);
        unschedMonthlyTotal += (e.amount as num).toDouble();
      } else {
        monthlyScheduled++;
        final due = _nextMonthlyDueFrom(windowStart, dd);
        if (_inWindow(due, windowStart, windowEnd)) {
          billsDue.add(e);
          billsTotal += (e.amount as num).toDouble();
        }
      }
      continue;
    }

    unscheduled.add(e);
  }

  billsDue.sort((a, b) => (b.amount as num).compareTo(a.amount as num));
  oneTime.sort((a, b) => (b.amount as num).compareTo(a.amount as num));

  final topBill = billsDue.isEmpty ? null : billsDue.first;
  final topOT = oneTime.isEmpty ? null : oneTime.first;

  final candidates = <dynamic>[
    ...oneTime.where((x) => x.isEssential == false),
    ...billsDue.where((x) => x.isEssential == false),
    ...unscheduled.where((x) => x.isEssential == false),
  ]..sort((a, b) => (b.amount as num).compareTo(a.amount as num));
  final topNE = candidates.isEmpty ? null : candidates.first;

  String conf;
  String reason;
  if (monthlyRecurring == 0) {
    conf = "High";
    reason = "No monthly recurring bills set.";
  } else {
    final missing = monthlyRecurring - monthlyScheduled;
    final ratio = monthlyScheduled / monthlyRecurring;
    if (ratio >= 0.8) {
      conf = "High";
    } else if (ratio >= 0.4) {
      conf = "Medium";
    } else {
      conf = "Low";
    }
    reason = "$missing monthly recurring missing due dates.";
  }

  return FocusData(
    billsDue: billsDue,
    oneTimePlanned: oneTime,
    unscheduledRecurring: unscheduled,
    billsDueTotal: billsTotal,
    oneTimeTotal: oneTimeTotal,
    unscheduledMonthlyTotal: unschedMonthlyTotal,
    topBill: topBill,
    topOneTime: topOT,
    topNonEssentialAny: topNE,
    confidenceLevel: conf,
    confidenceReason: reason,
  );
}

// ------------------------------------------------------------
// 6) DETERMINISTIC COPY HELPERS (same as your old code)
// ------------------------------------------------------------

class CopyTpl {
  final String text;
  final Set<String> req;
  const CopyTpl(this.text, [this.req = const {}]);

  bool canUse(Map<String, String> tokens) => req.every(tokens.containsKey);
}

int stableHash32(String input) {
  const int fnvPrime = 16777619;
  int hash = 2166136261;
  for (final cu in input.codeUnits) {
    hash ^= cu;
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

T pickOne<T>(List<T> list, String seed) {
  final h = stableHash32(seed);
  return list[h % list.length];
}

List<T> pickManyUnique<T>(List<T> list, String seed, int n) {
  if (list.isEmpty || n <= 0) return const [];
  final out = <T>[];
  final used = <int>{};
  var i = 0;
  while (out.length < n && used.length < list.length) {
    final idx = stableHash32("$seed|$i") % list.length;
    if (used.add(idx)) out.add(list[idx]);
    i++;
  }
  return out;
}

String fillTokens(String template, Map<String, String> tokens) {
  var s = template;
  tokens.forEach((k, v) => s = s.replaceAll("{$k}", v));
  return s;
}

String clampText(String s, {int maxLines = 2, int maxChars = 150}) {
  var t = s.trim();
  if (t.isEmpty) return t;

  if (t.length > maxChars) {
    t = t.substring(0, maxChars).trimRight();
    final lastSpace = t.lastIndexOf(' ');
    if (lastSpace > 40) t = t.substring(0, lastSpace).trimRight();
    t = "$t…";
  }

  final lines = t.split('\n').where((x) => x.trim().isNotEmpty).toList();
  if (lines.length <= maxLines) return lines.join('\n');
  return lines.take(maxLines).join('\n');
}

CopyTpl pickTpl({
  required List<CopyTpl> pool,
  required Map<String, String> tokens,
  required String seed,
  required CopyTpl fallback,
}) {
  final eligible = pool.where((t) => t.canUse(tokens)).toList();
  if (eligible.isEmpty) return fallback;
  return pickOne(eligible, seed);
}

String money(num v) => "\$${v.toStringAsFixed(0)}";

String _bucketCut(double requiredCut) {
  if (requiredCut <= 0) return "0";
  if (requiredCut <= 25) return "1";
  if (requiredCut <= 75) return "2";
  if (requiredCut <= 150) return "3";
  return "4";
}

String buildSeed({
  required String risk,
  required FocusData f,
  required double requiredCut,
  required DateTime wStart,
  required DateTime wEnd,
}) {
  final topIds = [
    if (f.topBill != null) (f.topBill.id ?? "").toString(),
    if (f.topOneTime != null) (f.topOneTime.id ?? "").toString(),
    if (f.topNonEssentialAny != null) (f.topNonEssentialAny.id ?? "").toString(),
  ].join("|");

  return [
    risk,
    "cut:${_bucketCut(requiredCut)}",
    "bills:${f.billsDue.length}",
    "ot:${f.oneTimePlanned.length}",
    "uns:${f.unscheduledRecurring.length}",
    "conf:${f.confidenceLevel}",
    "top:$topIds",
    "w:${wStart.year}-${wStart.month}-${wStart.day}_${wEnd.month}-${wEnd.day}",
  ].join("|");
}

Map<String, String> buildTokens({
  required FocusData f,
  required DateTime wStart,
  required DateTime wEnd,
  required double incomeWindow,
  required double debtMins,
  required double buffer,
  required double safeRaw,
  required double safeClamped,
  required double requiredCut,
  required String risk,
}) {
  String listTop(List<dynamic> items, int n) => items.take(n).map((e) => "${e.name} ${money(e.amount)}").join(", ");

  final tokens = <String, String>{
    "WINDOW": _rangeLabel(wStart, wEnd),
    "PAYDAY": _md(wEnd),
    "INCOME": money(incomeWindow),
    "DEBT_MINS": money(debtMins),
    "BUFFER": money(buffer),
    "SAFE_RAW": money(safeRaw),
    "SAFE": money(safeClamped),
    "RISK": risk,
    "BILLS_DUE": money(f.billsDueTotal),
    "BILLS_DUE_COUNT": "${f.billsDue.length}",
    "ONE_TIME_PLANNED": money(f.oneTimeTotal),
    "ONE_TIME_COUNT": "${f.oneTimePlanned.length}",
    "UNSCHED_RECURRING_MONTHLY": money(f.unscheduledMonthlyTotal),
    "UNSCHED_COUNT": "${f.unscheduledRecurring.length}",
    "CUT_TARGET": money(requiredCut),
    "REQUIRED_CUT": money(requiredCut),
    "CONF": f.confidenceLevel,
    "CONF_REASON": f.confidenceReason,
  };

  if (f.billsDue.isNotEmpty) tokens["TOP_BILL_LIST"] = listTop(f.billsDue, 2);
  if (f.oneTimePlanned.isNotEmpty) tokens["TOP_OT_LIST"] = listTop(f.oneTimePlanned, 2);

  if (f.topBill != null) {
    tokens["TOP_BILL_NAME"] = (f.topBill.name ?? "").toString();
    tokens["TOP_BILL_AMT"] = money((f.topBill.amount as num).toDouble());
    tokens["TOP_BILL_CAT"] = (f.topBill.category ?? "").toString();
  }
  if (f.topOneTime != null) {
    tokens["TOP_OT_NAME"] = (f.topOneTime.name ?? "").toString();
    tokens["TOP_OT_AMT"] = money((f.topOneTime.amount as num).toDouble());
    tokens["TOP_OT_CAT"] = (f.topOneTime.category ?? "").toString();
  }
  if (f.topNonEssentialAny != null) {
    tokens["TOP_NE_NAME"] = (f.topNonEssentialAny.name ?? "").toString();
    tokens["TOP_NE_AMT"] = money((f.topNonEssentialAny.amount as num).toDouble());
    tokens["TOP_NE_CAT"] =
        ((f.topNonEssentialAny.category ?? "").toString().isEmpty) ? "Non-essential" : (f.topNonEssentialAny.category ?? "").toString();
  }

  final days = wEnd.difference(wStart).inDays.clamp(1, 30);
  final daily = (safeClamped / days).clamp(5, 250).toDouble();
  tokens["DAILY_CAP"] = money(daily);

  return tokens;
}

// ------------------------------------------------------------
// 7) COPY BANK (same style)
// ------------------------------------------------------------

class CopyBankV3 {
  static List<CopyTpl> forecastHead() {
    final openers = [
      "{WINDOW} is {RISK}.",
      "{WINDOW}: {RISK} window.",
      "Until {PAYDAY}: {RISK}.",
      "Payday window {WINDOW} is {RISK}.",
      "{RISK} window to {PAYDAY}.",
      "Now → {PAYDAY}: {RISK}.",
    ];
    final detail = [
      "Bills {BILLS_DUE} + one-time {ONE_TIME_PLANNED}.",
      "{BILLS_DUE_COUNT} bills + {ONE_TIME_COUNT} one-time.",
      "Confidence: {CONF}.",
      "Unscheduled monthly: {UNSCHED_RECURRING_MONTHLY}.",
      "Income {INCOME}. Buffer {BUFFER}.",
      "Debt mins {DEBT_MINS}.",
    ];
    final coachy = [
      "Protect the buffer first.",
      "Keep spending predictable.",
      "Avoid new one-time spending.",
      "If you edit expenses, recheck—numbers shift.",
      "Cap non-essential to keep the window stable.",
    ];

    final out = <CopyTpl>[];
    for (final a in openers) {
      out.add(CopyTpl(a, {"WINDOW", "RISK"}));
      for (final b in detail) {
        out.add(CopyTpl("$a $b", {}));
      }
      for (final c in coachy) {
        out.add(CopyTpl("$a $c", {}));
      }
    }
    for (final b in detail) {
      for (final c in coachy) {
        out.add(CopyTpl("$b $c", {}));
      }
    }
    return out;
  }

  static List<CopyTpl> forecastSub() {
    final lines = <CopyTpl>[
      CopyTpl("Safe-to-spend {SAFE} after bills + planned + minimums + buffer.", {"SAFE"}),
      CopyTpl("After buffer {BUFFER}, you have {SAFE} until {PAYDAY}.", {"BUFFER", "SAFE", "PAYDAY"}),
      CopyTpl("To fully protect buffer: cut/delay {REQUIRED_CUT}.", {"REQUIRED_CUT"}),
      CopyTpl("Best lever: delay {TOP_OT_NAME} ({TOP_OT_AMT}).", {"TOP_OT_NAME", "TOP_OT_AMT"}),
      CopyTpl("Cap {TOP_NE_CAT} ({TOP_NE_AMT}) so buffer survives.", {"TOP_NE_CAT", "TOP_NE_AMT"}),
      CopyTpl("Forecast confidence {CONF}: {CONF_REASON}", {"CONF", "CONF_REASON"}),
      CopyTpl("Unscheduled monthly {UNSCHED_RECURRING_MONTHLY} limits accuracy.", {"UNSCHED_RECURRING_MONTHLY"}),
      CopyTpl("Keep non-essential under {DAILY_CAP}/day until {PAYDAY}.", {"DAILY_CAP", "PAYDAY"}),
      CopyTpl("If this feels off, schedule due dates for monthly recurring.", {}),
    ];
    final prefixes = ["Quick plan:", "Reality check:", "Best move:", "Rule:", "Tip:"];
    final out = <CopyTpl>[...lines];
    for (final p in prefixes) {
      for (final l in lines) {
        out.add(CopyTpl("$p ${l.text}", l.req));
      }
    }
    return out;
  }

  static List<CopyTpl> nextMoveTitle() {
    final base = <CopyTpl>[
      CopyTpl("Protect {BUFFER} until {PAYDAY}.", {"BUFFER", "PAYDAY"}),
      CopyTpl("Delay {TOP_OT_NAME} until {PAYDAY}.", {"TOP_OT_NAME", "PAYDAY"}),
      CopyTpl("Cap {TOP_NE_CAT} for this window.", {"TOP_NE_CAT"}),
      CopyTpl("Fix due dates to raise confidence.", {}),
      CopyTpl("Move {REQUIRED_CUT} into buffer now.", {"REQUIRED_CUT"}),
    ];
    final starters = ["Now:", "This window:", "Next:", "Do this:"];
    final out = <CopyTpl>[...base];
    for (final s in starters) {
      for (final b in base) {
        out.add(CopyTpl("$s ${b.text}", b.req));
      }
    }
    return out;
  }

  static List<CopyTpl> nextMoveDesc() {
    final base = <CopyTpl>[
      CopyTpl(
        "You have {SAFE} left after bills {BILLS_DUE}, planned {ONE_TIME_PLANNED}, minimums, and buffer {BUFFER}.",
        {"SAFE", "BILLS_DUE", "ONE_TIME_PLANNED", "BUFFER"},
      ),
      CopyTpl("To protect buffer, create {REQUIRED_CUT} room by delaying the biggest optional item.", {"REQUIRED_CUT"}),
      CopyTpl("Fastest win: delay {TOP_OT_NAME} ({TOP_OT_AMT}).", {"TOP_OT_NAME", "TOP_OT_AMT"}),
      CopyTpl("Biggest non-essential: {TOP_NE_CAT} {TOP_NE_AMT}. Cap it temporarily.", {"TOP_NE_CAT", "TOP_NE_AMT"}),
      CopyTpl("Forecast is {CONF} because {CONF_REASON}. Schedule monthly bills to improve accuracy.", {"CONF", "CONF_REASON"}),
    ];
    final addOns = [
      "Keep it boring until payday.",
      "Avoid new one-time purchases.",
      "Recheck after edits—numbers update instantly.",
      "Protect buffer first, optimize later.",
    ];
    final out = <CopyTpl>[...base];
    for (final a in addOns) {
      for (final b in base) {
        out.add(CopyTpl("${b.text} $a", b.req));
      }
    }
    return out;
  }

  static List<CopyTpl> cutsIntro() => const [
        CopyTpl("Save \$50 fastest (based on your data).", {}),
        CopyTpl("Fast cuts to protect {BUFFER} before {PAYDAY}.", {"BUFFER", "PAYDAY"}),
        CopyTpl("Pick 1–2 and you’ll feel it immediately.", {}),
      ];

  static List<CopyTpl> cutBullets() {
    final base = <CopyTpl>[
      CopyTpl("Delay {TOP_OT_NAME} ({TOP_OT_AMT}) → frees {TOP_OT_AMT} now.", {"TOP_OT_NAME", "TOP_OT_AMT"}),
      CopyTpl("Cap {TOP_NE_CAT} ({TOP_NE_AMT}) for this window.", {"TOP_NE_CAT", "TOP_NE_AMT"}),
      CopyTpl("No new one-time purchases until {PAYDAY}.", {"PAYDAY"}),
      CopyTpl("Keep non-essential under {DAILY_CAP}/day until {PAYDAY}.", {"DAILY_CAP", "PAYDAY"}),
      CopyTpl("Set due dates for monthly recurring (unscheduled lowers accuracy).", {}),
    ];
    final verbs = ["Try:", "Rule:", "Do:", "Cut:"];
    final out = <CopyTpl>[...base];
    for (final v in verbs) {
      for (final b in base) {
        out.add(CopyTpl("$v ${b.text}", b.req));
      }
    }
    return out;
  }
}

// ------------------------------------------------------------
// 8) NEXT MOVE PICK
// ------------------------------------------------------------

class NextMovePick {
  final String kind;
  final double amount;
  NextMovePick({required this.kind, required this.amount});
}

NextMovePick chooseNextMove({
  required FocusData f,
  required double requiredCut,
}) {
  if (requiredCut > 0 && f.topOneTime != null && f.topOneTime.isEssential == false) {
    return NextMovePick(kind: "delay_one_time", amount: requiredCut);
  }
  if (requiredCut > 0 && f.topNonEssentialAny != null) {
    return NextMovePick(kind: "cap_nonessential", amount: requiredCut);
  }
  if (f.confidenceLevel == "Low") {
    return NextMovePick(kind: "fix_due_dates", amount: 0);
  }
  return NextMovePick(kind: "move_to_buffer", amount: requiredCut > 0 ? requiredCut : 0);
}

// ------------------------------------------------------------
// 9) CASHFLOW COMPUTE (same structure as your v3)
// ------------------------------------------------------------

class CashflowWindowCompute {
  final ExpensesResponse response;
  final FocusData focus;
  final String risk;
  final double safeRaw;
  final double safeClamped;
  final double requiredCut;

  CashflowWindowCompute({
    required this.response,
    required this.focus,
    required this.risk,
    required this.safeRaw,
    required this.safeClamped,
    required this.requiredCut,
  });
}

ExpensesResponse recomputeInsightsCashflowV3({
  required ExpensesResponse data,
  required DateTime windowStart,
  required DateTime payday,
  required double incomeWindow,
  required double bufferTarget,
  required double debtMinimumsWindow,
}) {
  return recomputeInsightsCashflowV3Full(
    data: data,
    windowStart: windowStart,
    payday: payday,
    incomeWindow: incomeWindow,
    bufferTarget: bufferTarget,
    debtMinimumsWindow: debtMinimumsWindow,
  ).response;
}

CashflowWindowCompute recomputeInsightsCashflowV3Full({
  required ExpensesResponse data,
  required DateTime windowStart,
  required DateTime payday,
  required double incomeWindow,
  required double bufferTarget,
  required double debtMinimumsWindow,
}) {
  final wStart = _day(windowStart);
  final wEnd = _day(payday);

  final focus = buildFocusForWindow(
    expenses: data.expenses,
    windowStart: wStart,
    windowEnd: wEnd,
  );

  final safeRaw = incomeWindow - focus.billsDueTotal - focus.oneTimeTotal - debtMinimumsWindow - bufferTarget;
  final safeClamped = safeRaw < 0 ? 0.0 : safeRaw;
  // ^^^ YOU HAD THIS EXACT LINE IN YOUR OLD CODE:
  // final safeRaw = incomeWindow - focus.billsDueTotal - focus.oneTimeTotal - debtMinimumsWindow - bufferTarget;

  final tightThreshold = (bufferTarget * 0.75).clamp(25, 75).toDouble();
  final risk = (safeRaw < 0) ? "High" : (safeRaw < tightThreshold ? "Tight" : "Safe");

  final requiredCut = (bufferTarget - safeRaw);
  final requiredCutClamped = requiredCut.isFinite && requiredCut > 0 ? requiredCut : 0.0;

  final tokens = buildTokens(
    f: focus,
    wStart: wStart,
    wEnd: wEnd,
    incomeWindow: incomeWindow,
    debtMins: debtMinimumsWindow,
    buffer: bufferTarget,
    safeRaw: safeRaw,
    safeClamped: safeClamped,
    requiredCut: requiredCutClamped,
    risk: risk,
  );

  final seed = buildSeed(
    risk: risk,
    f: focus,
    requiredCut: requiredCutClamped,
    wStart: wStart,
    wEnd: wEnd,
  );

  final headTpl = pickTpl(
    pool: CopyBankV3.forecastHead(),
    tokens: tokens,
    seed: "$seed|fh",
    fallback: const CopyTpl("{WINDOW} is {RISK}.", {"WINDOW", "RISK"}),
  );
  final subTpl = pickTpl(
    pool: CopyBankV3.forecastSub(),
    tokens: tokens,
    seed: "$seed|fs",
    fallback: const CopyTpl("Protect buffer {BUFFER} and avoid one-time spending.", {"BUFFER"}),
  );

  final forecastDesc = clampText(
    "${fillTokens(headTpl.text, tokens)}\n${fillTokens(subTpl.text, tokens)}",
    maxLines: 2,
    maxChars: 150,
  );

  final movePick = chooseNextMove(f: focus, requiredCut: requiredCutClamped);

  final titleTpl = pickTpl(
    pool: CopyBankV3.nextMoveTitle(),
    tokens: tokens,
    seed: "$seed|mt",
    fallback: const CopyTpl("Protect {BUFFER}.", {"BUFFER"}),
  );
  final descTpl = pickTpl(
    pool: CopyBankV3.nextMoveDesc(),
    tokens: tokens,
    seed: "$seed|md",
    fallback: const CopyTpl("Keep spending predictable until payday.", {}),
  );

  final nextMove = NextBestMove(
    title: clampText(fillTokens(titleTpl.text, tokens), maxLines: 1, maxChars: 60),
    description: clampText(fillTokens(descTpl.text, tokens), maxLines: 2, maxChars: 140),
    actionAmount: movePick.amount,
    dueDateMs: wEnd.millisecondsSinceEpoch,
  );

  final introTpl = pickTpl(
    pool: CopyBankV3.cutsIntro(),
    tokens: tokens,
    seed: "$seed|ci",
    fallback: const CopyTpl("Save \$50 fastest.", {}),
  );

  final bulletsPool = CopyBankV3.cutBullets();
  final eligible = bulletsPool.where((b) => b.canUse(tokens)).toList();
  final chosen = pickManyUnique(
    eligible.isEmpty ? bulletsPool : eligible,
    "$seed|cb",
    3,
  ).map((tpl) => clampText(fillTokens(tpl.text, tokens), maxLines: 1, maxChars: 90)).toList();

  final cutsChecklist = CutsChecklist(
    title: "Save \$50 fastest",
    tag: risk,
    bullets: [
      clampText(fillTokens(introTpl.text, tokens), maxLines: 1, maxChars: 90),
      ...chosen,
    ],
  );

  final safeToSpend = SafeToSpend(
    amount: safeClamped,
    untilDateMs: wEnd.millisecondsSinceEpoch,
    expectedIncome: incomeWindow,
    billsDue: focus.billsDueTotal + focus.oneTimeTotal,
    debtMinimums: debtMinimumsWindow,
    bufferTarget: bufferTarget,
  );

  final paydayBuffer = PaydayBuffer(
    amount: safeRaw,
    tag: risk,
    deltaMonth: null,
  );

  final monthSummary = MonthlySummary(
    fixed: focus.billsDueTotal + focus.unscheduledMonthlyTotal,
    variable: focus.oneTimeTotal,
    total: (focus.billsDueTotal + focus.unscheduledMonthlyTotal) + focus.oneTimeTotal,
    note: "This window: scheduled monthly due + unscheduled monthly + one-time planned",
  );

  final forecastRisk = ForecastRisk(
    level: risk,
    title: "Forecast risk",
    description: forecastDesc,
    actions: (risk == "Safe") ? const [] : const ["Move", "Cut"],
  );

  final insights = InsightsModel(
    safeToSpend: safeToSpend,
    nextBestMove: nextMove,
    leaksAndSpikes: const [],
    forecastRisk: forecastRisk,
    cutsChecklist: cutsChecklist,
  );

  final updated = ExpensesResponse(
    status: data.status,
    message: data.message,
    monthSummary: monthSummary,
    paydayBuffer: paydayBuffer,
    insights: insights,
    rules: data.rules,
    expenses: data.expenses,
  );

  return CashflowWindowCompute(
    response: updated,
    focus: focus,
    risk: risk,
    safeRaw: safeRaw,
    safeClamped: safeClamped,
    requiredCut: requiredCutClamped,
  );
}

// ------------------------------------------------------------
// 10) UI-FIRST DECK MODELS (same shape you were using)
// ------------------------------------------------------------

class NowToPaydaySectionVM {
  final String windowId;
  final String windowLabel;
  final DateTime payday;
  final String status;
  final double safeToSpend;
  final String untilLabel;
  final String subtitle;
  final Map<String, double> breakdown;

  NowToPaydaySectionVM({
    required this.windowId,
    required this.windowLabel,
    required this.payday,
    required this.status,
    required this.safeToSpend,
    required this.untilLabel,
    required this.subtitle,
    required this.breakdown,
  });
}

class NextBestMoveSectionVM {
  final String windowId;
  final String title;
  final String description;
  final double actionAmount;
  final DateTime dueDate;
  final String ctaLabel;

  NextBestMoveSectionVM({
    required this.windowId,
    required this.title,
    required this.description,
    required this.actionAmount,
    required this.dueDate,
    required this.ctaLabel,
  });
}

class LeaksAndSpikesRowVM {
  final String title;
  final String subtitle;
  final String trailing;
  LeaksAndSpikesRowVM({required this.title, required this.subtitle, required this.trailing});
}

class LeaksAndSpikesSectionVM {
  final String windowId;
  final List<LeaksAndSpikesRowVM> rows;
  LeaksAndSpikesSectionVM({required this.windowId, required this.rows});
}

class ForecastRiskSectionVM {
  final String windowId;
  final String level;
  final String title;
  final String headline;
  final String description;
  final List<String> actions;

  ForecastRiskSectionVM({
    required this.windowId,
    required this.level,
    required this.title,
    required this.headline,
    required this.description,
    required this.actions,
  });
}

class CutsChecklistSectionVM {
  final String windowId;
  final String title;
  final String tag;
  final String subtitle;
  final List<String> bullets;
  final String ctaLabel;

  CutsChecklistSectionVM({
    required this.windowId,
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.bullets,
    required this.ctaLabel,
  });
}

class AutomationRuleRowVM {
  final String id;
  final String title;
  final String subtitle;
  final bool enabled;

  AutomationRuleRowVM({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });
}

class AutomationRulesSectionVM {
  final String windowId;
  final String title;
  final List<AutomationRuleRowVM> rules;
  final String ctaLabel;

  AutomationRulesSectionVM({
    required this.windowId,
    required this.title,
    required this.rules,
    required this.ctaLabel,
  });
}

class WindowDeckItemVM {
  final PayCycleWindow window;
  final ExpensesResponse result;
  final FocusData focus;
  final double incomeWindow;

  final NowToPaydaySectionVM nowToPayday;
  final NextBestMoveSectionVM? nextBestMove;
  final LeaksAndSpikesSectionVM leaksAndSpikes;
  final ForecastRiskSectionVM forecastRisk;
  final CutsChecklistSectionVM cutsChecklist;
  final AutomationRulesSectionVM automationRules;

  WindowDeckItemVM({
    required this.window,
    required this.result,
    required this.focus,
    required this.incomeWindow,
    required this.nowToPayday,
    required this.nextBestMove,
    required this.leaksAndSpikes,
    required this.forecastRisk,
    required this.cutsChecklist,
    required this.automationRules,
  });

  String get windowId => window.id;
  String get windowLabel => window.label;
  DateTime get payday => window.payDate;
}

class InsightsDeckVM {
  final List<WindowDeckItemVM> items;
  final String activeWindowId;

  InsightsDeckVM({required this.items, required this.activeWindowId});

  WindowDeckItemVM get active => items.firstWhere(
        (x) => x.windowId == activeWindowId,
        orElse: () => items.isEmpty ? throw StateError("No windows") : items.first,
      );
}

// ------------------------------------------------------------
// 11) DECK BUILDERS (now based on PayCycleWindow/PayCell)
// ------------------------------------------------------------

String _ctaForNextMove(NextBestMove nm) {
  if (nm.actionAmount <= 0) return "Open";
  return "Reserve ${money(nm.actionAmount)} now";
}

String _headlineForForecast(PayCycleWindow w, FocusData f, String level) {
  final bills = f.billsDue.length;
  if (bills > 0) return "${w.label} is ${level.toLowerCase()} ($bills bills before pay).";
  return "${w.label} is ${level.toLowerCase()}.";
}

String _pickActiveWindowId(List<PayCycleWindow> windows, DateTime now) {
  final today = _day(now);
  for (final w in windows) {
    if (!w.windowEnd.isBefore(today)) return w.id;
  }
  return windows.isEmpty ? "" : windows.first.id;
}

InsightsDeckVM computeInsightsDeckForUpcomingPaydays_PayCycles({
  required ExpensesResponse expensesData,
  required DateTime focusedDay,
  required Map<DateTime, PayCell> payCycles, // ✅ FROM computePayCyclesMonthOnly
  required double bufferTarget,
  required double debtMinimumsWindow,
  DateTime? now,
}) {
  final t = now ?? DateTime.now();

  // ✅ month-only
  final windows = buildPayCycleWindowsMonthOnly(
    now: t,
    focusedDay: focusedDay,
    payCycles: payCycles,
  );

  final out = <WindowDeckItemVM>[];

  for (final w in windows) {
    // ✅ income/hours already computed in PayCell
    final incomeWindow = w.cell.totalPay;

    final computed = recomputeInsightsCashflowV3Full(
      data: expensesData,
      windowStart: w.windowStart,
      payday: w.windowEnd,
      incomeWindow: incomeWindow,
      bufferTarget: bufferTarget,
      debtMinimumsWindow: debtMinimumsWindow,
    );

    final updated = computed.response;
    final focus = computed.focus;

    final safe = updated.insights?.safeToSpend;
    final forecast = updated.insights?.forecastRisk;
    final cuts = updated.insights?.cutsChecklist;
    final next = updated.insights?.nextBestMove;

    final level = forecast?.level ?? (updated.paydayBuffer?.tag ?? computed.risk);
    final untilLabel = "until ${_md(w.windowEnd)}";

    final nowToPayday = NowToPaydaySectionVM(
      windowId: w.id,
      windowLabel: w.label,
      payday: w.payDate,
      status: level,
      safeToSpend: safe?.amount ?? 0,
      untilLabel: untilLabel,
      subtitle: "After bills + minimums + buffer (${money(bufferTarget)}).",
      breakdown: {
        "Expected income": safe?.expectedIncome ?? incomeWindow,
        "Bills due": safe?.billsDue ?? (focus.billsDueTotal + focus.oneTimeTotal),
        "Debt minimums": safe?.debtMinimums ?? debtMinimumsWindow,
        "Buffer target": safe?.bufferTarget ?? bufferTarget,
      },
    );

    final nextVM = next == null
        ? null
        : NextBestMoveSectionVM(
            windowId: w.id,
            title: next.title,
            description: next.description,
            actionAmount: next.actionAmount,
            dueDate: DateTime.fromMillisecondsSinceEpoch(next.dueDateMs),
            ctaLabel: _ctaForNextMove(next),
          );

    final leaksVM = LeaksAndSpikesSectionVM(
      windowId: w.id,
      rows: (updated.insights?.leaksAndSpikes ?? const []).map((x) {
        final dx = x as dynamic;
        return LeaksAndSpikesRowVM(
          title: (dx.title ?? "").toString(),
          subtitle: (dx.subtitle ?? dx.description ?? "").toString(),
          trailing: (dx.confidence ?? dx.kind ?? "").toString(),
        );
      }).toList(),
    );

    final forecastVM = ForecastRiskSectionVM(
      windowId: w.id,
      level: level,
      title: forecast?.title ?? "Forecast risk",
      headline: _headlineForForecast(w, focus, level),
      description: forecast?.description ?? "Not enough data to forecast this window yet.",
      actions: forecast?.actions ?? ((level == "Safe") ? const [] : const ["Move", "Cut"]),
    );

    final cutsVM = CutsChecklistSectionVM(
      windowId: w.id,
      title: cuts?.title ?? "Save \$50 fastest",
      tag: cuts?.tag ?? level,
      subtitle: "Quick cuts to protect your buffer before payday.",
      bullets: cuts?.bullets ?? const [],
      ctaLabel: "Open cuts checklist",
    );

    final rulesVM = AutomationRulesSectionVM(
      windowId: w.id,
      title: "Automation rules",
      rules: (updated.rules ?? const []).map((r) {
        final rr = r as dynamic;
        return AutomationRuleRowVM(
          id: (rr.id ?? "").toString(),
          title: (rr.title ?? "").toString(),
          subtitle: (rr.description ?? "").toString(), // ✅ no r.subtitle
          enabled: (rr.enabled ?? rr.isActive ?? rr.isEnabled ?? true) == true,
        );
      }).toList(),
      ctaLabel: "Add a rule",
    );

    out.add(
      WindowDeckItemVM(
        window: w,
        result: updated,
        focus: focus,
        incomeWindow: incomeWindow,
        nowToPayday: nowToPayday,
        nextBestMove: nextVM,
        leaksAndSpikes: leaksVM,
        forecastRisk: forecastVM,
        cutsChecklist: cutsVM,
        automationRules: rulesVM,
      ),
    );
  }

  final activeId = _pickActiveWindowId(windows, t);
  return InsightsDeckVM(items: out, activeWindowId: activeId);
}

// ------------------------------------------------------------
// 12) HOW TO USE (controller snippet)
// ------------------------------------------------------------
//
// final focusedDay = selectedMonth.value; // month user is viewing
//
// final payCyclesMap = computePayCyclesMonthOnly(
//   focusedDay: focusedDay,
//   jobs: account.jobs ?? const [],
//   shiftModel: shift.shiftModel.value,
// );
//
// payCycles?.value = payCyclesMap;
//
// final deck = computeInsightsDeckForUpcomingPaydays_PayCycles(
//   expensesData: expensesModel.value,
//   focusedDay: focusedDay,
//   payCycles: payCyclesMap,
//   bufferTarget: 40,
//   debtMinimumsWindow: 20,
// );
//
// windows.value = deck.items; // or store deck somewhere
//
// ------------------------------------------------------------
