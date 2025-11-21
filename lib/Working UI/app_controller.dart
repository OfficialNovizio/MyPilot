import 'dart:math';
import 'package:emptyproject/models/period%20stat.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/shift.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../utils/time_utils.dart';
import '../models/tax_config.dart';
import '../seed/tax_seed.dart'; // for defaultTaxConfigs()
import '../models/deposit_point.dart';

class PayPeriod {
  final DateTime start;
  final DateTime end;
  final DateTime deposit;
  final double hours;
  final double overtime;
  final double pay;
  PayPeriod({required this.start, required this.end, required this.deposit, required this.hours, required this.overtime, required this.pay});
}

class AppController extends GetxController {
  final jobs = <Job>[
    // Job(
    //     id: 'starbucks',
    //     name: 'Starbucks',
    //     colorHex: '#16a34a',
    //     wage: 0,
    //     payFrequency: 'weekly',
    //     lastPaychequeIso: DateTime.now(),
    //     weekStartDOW: 4,
    //     statMultiplier: 1.5,
    //     statDays: []),
    // Job(
    //     id: 'superstore',
    //     name: 'Superstore',
    //     colorHex: '#2563eb',
    //     wage: 16,
    //     payFrequency: 'weekly',
    //     lastPaychequeIso: DateTime.now(),
    //     weekStartDOW: 7,
    //     statMultiplier: 1.5,
    //     statDays: []),
  ].obs;

  RxList colorChoices = ['#16a34a', '#2563eb', '#e11d48', '#0ea5e9', '#10b981', '#f59e0b', '#8b5cf6', '#14b8a6', '#ef4444'].obs;

  final shifts = <Shift>[].obs;
  final settings = AppSettings(weekStartsOnMonday: true, overtimeEnabled: true, overtimeThresholdWeekly: 40).obs;

  final currentWeekStart = startOfWeek(DateTime.now(), true).obs;

  static const _kJobs = 'jobs';
  static const _kShifts = 'shifts';
  static const _kSettings = 'settings';
  static const _kTaxes = 'taxes';
  final taxes = <String, TaxConfig>{}.obs; // jobId -> config

  @override
  void onInit() {
    super.onInit();
    _load();
    ever<List<Job>>(jobs, (_) => _save());
    ever<List<Shift>>(shifts, (_) => _save());
    ever<AppSettings>(settings, (_) => _save());
  }

  void _load() {
    final j = StorageService.read<List>(_kJobs);
    final s = StorageService.read<List>(_kShifts);
    final st = StorageService.read<Map>(_kSettings);
    if (j != null) jobs.assignAll(j.map((e) => Job.fromJson(Map<String, dynamic>.from(e))).toList());
    if (s != null) shifts.assignAll(s.map((e) => Shift.fromJson(Map<String, dynamic>.from(e))).toList());
    if (st != null) settings.value = AppSettings.fromJson(Map<String, dynamic>.from(st));
    currentWeekStart.value = startOfWeek(DateTime.now(), settings.value.weekStartsOnMonday);
    final tx = StorageService.read<Map>(_kTaxes);
    if (tx != null) {
      taxes.assignAll(tx.map((k, v) => MapEntry(k as String, TaxConfig.fromJson(Map<String, dynamic>.from(v)))));
    }
// seed once if empty
    if (taxes.isEmpty) {
      for (final t in defaultTaxConfigs()) {
        taxes[t.jobId] = t;
      }
    }
  }

  void _save() {
    StorageService.write(_kJobs, jobs.map((e) => e.toJson()).toList());
    StorageService.write(_kShifts, shifts.map((e) => e.toJson()).toList());
    StorageService.write(_kSettings, settings.value.toJson());
    StorageService.write(
      _kTaxes,
      taxes.map((k, v) => MapEntry(k, v.toJson())),
    );
  }

  TaxConfig taxFor(String jobId) => taxes[jobId] ?? TaxConfig(jobId: jobId);

  void saveTaxConfig(TaxConfig cfg) {
    taxes[cfg.jobId] = cfg;
    taxes.refresh();
    _save();
  }

  /// Uses your existing monthSummary() gross output and applies per-job taxes.
  Map<String, dynamic> monthNetSummary(DateTime month) {
    // final gross = monthSummary(month); // your existing, stat-aware
    // final perJobNet = <String, Map<String, double>>{};
    // double totalGross = 0.0, totalNet = 0.0;
    //
    // for (final j in jobs) {
    //   final g = ((gross[j.id]?['pay'] ?? 0) as num).toDouble();
    //   final t = taxFor(j.id!);
    //
    //   final income = g * (t.incomeTaxPct / 100.0);
    //   final cpp = g * (t.cppPct / 100.0);
    //   final ei = g * (t.eiPct / 100.0);
    //   final other = g * (t.otherPct / 100.0);
    //
    //   final deposits = depositYmdsForMonth(j, DateTime(month.year, month.month, 1));
    //   final chequeCount = deposits.length.toDouble();
    //   final fixedMonthly = t.fixedMonthly.toDouble();
    //   final fixedPerChequeTotal = t.fixedPerCheque.toDouble() * chequeCount;
    //
    //   double oneOffTotal = 0.0;
    //   for (final y in deposits) {
    //     oneOffTotal += (t.oneOffByDepositYmd[y] ?? 0.0);
    //   }
    //
    //   final fixedTotal = fixedMonthly + fixedPerChequeTotal + oneOffTotal;
    //   final net = (g - (income + cpp + ei + other + fixedTotal)).clamp(0.0, double.infinity).toDouble();
    //
    //   perJobNet[j.id!] = {
    //     'gross': g,
    //     'incomeTax': income,
    //     'cpp': cpp,
    //     'ei': ei,
    //     'other': other,
    //     'fixedMonthly': fixedMonthly,
    //     'fixedPerChequeTotal': fixedPerChequeTotal,
    //     'oneOffTotal': oneOffTotal,
    //     'fixed': fixedTotal,
    //     'depositCount': chequeCount,
    //     'net': net,
    //   };
    //
    //   totalGross += g;
    //   totalNet += net;
    // }
    //
    // return {
    //   'perJob': perJobNet,
    //   'combined': {'gross': totalGross, 'net': totalNet}
    // };
    return null!;
  }

  Color jobColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void toggleWeekStart(bool monday) {
    settings.update((s) {
      if (s == null) return;
      s.weekStartsOnMonday = monday;
    });
    currentWeekStart.value = startOfWeek(currentWeekStart.value, monday);
  }

  void prevWeek() => currentWeekStart.value = currentWeekStart.value.subtract(const Duration(days: 7));
  void nextWeek() => currentWeekStart.value = currentWeekStart.value.add(const Duration(days: 7));
  void thisWeek() => currentWeekStart.value = startOfWeek(DateTime.now(), settings.value.weekStartsOnMonday);

  List<DateTime> get weekDays => List.generate(7, (i) => addDays(currentWeekStart.value, i));
  List<Shift> shiftsOn(String ymdDate) => shifts.where((s) => s.date == ymdDate).toList();

  void addShift(Shift s) => shifts.add(s);
  void updateShift(String id, Shift patch) {
    final i = shifts.indexWhere((e) => e.id == id);
    if (i >= 0) shifts[i] = patch;
  }

  void deleteShift(String id) => shifts.removeWhere((e) => e.id == id);

  void addJob(Job j) => jobs.add(j);
  void removeJob(String id) {
    // jobs.removeWhere((e) => e.id == id);
    shifts.removeWhere((e) => e.jobId == id);
  }

  String randomColorHex() {
    const pool = ['#e11d48', '#0ea5e9', '#10b981', '#f59e0b', '#8b5cf6', '#14b8a6', '#ef4444', '#16a34a', '#2563eb'];
    return pool[Random().nextInt(pool.length)];
  }

  Map<String, dynamic> weeklyTotalsUI() {
    final start = atMidnight(currentWeekStart.value);
    final end = atMidnight(addDays(currentWeekStart.value, 7)).subtract(const Duration(seconds: 1));
    final perJob = <String, Map<String, double>>{};
    for (final j in jobs) {
      // perJob[j.id!] = {'hours': 0.0, 'overtime': 0.0, 'pay': 0.0};
    }
    for (final s in shifts) {
      final d = DateTime.parse('${s.date}T00:00:00');
      if (!d.isBefore(start) && !d.isAfter(end)) {
        final int mins = 0;
        final double h = mins / 60.0;
        perJob[s.jobId]!['hours'] = (perJob[s.jobId]!['hours'] ?? 0.0) + h;
      }
    }
    final bool overtimeOn = settings.value.overtimeEnabled;
    final double thr = settings.value.overtimeThresholdWeekly.toDouble();
    double totalHours = 0.0, totalPay = 0.0, totalOT = 0.0;
    for (final j in jobs) {
      // final t = perJob[j.id]!;
      // final weekly = (t['hours'] ?? 0.0);
      // final over = overtimeOn ? ((weekly - thr).clamp(0.0, double.infinity) as double) : 0.0;
      // final reg = weekly - over;
      // // final pay = reg * j.wage! + over * j.wage! * 1.5;
      // t['overtime'] = over;
      // t['pay'] = pay;
      // totalHours += weekly;
      // totalPay += pay;
      // totalOT += over;
    }
    return {
      'perJob': perJob,
      'combined': {'hours': totalHours, 'overtime': totalOT, 'pay': totalPay}
    };
  }

  // int _lenDays(Job j) => j.payFrequency == 'biweekly' ? 14 : 7;

  DateTime? parseIso(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    final parts = iso.split(' ');
    final dateParts = parts[0].split('-');
    if (dateParts.length != 3) return null;
    final y = int.tryParse(dateParts[0]) ?? 0;
    final m = int.tryParse(dateParts[1]) ?? 1;
    final d = int.tryParse(dateParts[2]) ?? 1;
    int hh = 0, mm = 0;
    if (parts.length > 1) {
      final t = parts[1].split(':');
      if (t.length >= 2) {
        hh = int.tryParse(t[0]) ?? 0;
        mm = int.tryParse(t[1]) ?? 0;
      }
    }
    return DateTime(y, m, d, hh, mm);
  }

  PayPeriod computePeriod(Job j, DateTime anchorStart) {
    // final len = _lenDays(j);
    // final start = DateTime(anchorStart.year, anchorStart.month, anchorStart.day, 0, 0);
    // final end = start.add(Duration(days: len)).subtract(const Duration(minutes: 1));
    // final deposit = start.add(Duration(days: len));
    // double hours = 0.0;
    // double statHours = 0.0;
    // for (final s in shifts.where((x) => x.jobId == j.id)) {
    //   final d = DateTime.parse('${s.date}T00:00:00');
    //   if (!d.isBefore(start) && !d.isAfter(end)) {
    //     final int mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
    //     final double h = mins / 60.0;
    //     hours += h;
    //     if (j.statDays!.contains(s.date)) statHours += h;
    //   }
    // }
    // final bool overtimeOn = settings.value.overtimeEnabled;
    // final double weeklyThr = settings.value.overtimeThresholdWeekly.toDouble();
    // final double thrForPeriod = (len / 7.0).ceil() * weeklyThr;
    // final double over = overtimeOn ? ((hours - thrForPeriod).clamp(0.0, double.infinity) as double) : 0.0;
    //
    // final double rateOT = 1.5;
    // final double rateStat = j.statMultiplier!;
    // final double bestStatRate = rateStat >= rateOT ? rateStat : rateOT;
    //
    // final double nonStatHours = (hours - statHours).clamp(0.0, hours);
    // double nonStatOver = over.clamp(0.0, nonStatHours);
    // double statOverRemainder = (over - nonStatOver).clamp(0.0, statHours);
    //
    // final double nonStatReg = nonStatHours - nonStatOver;
    // final double statReg = statHours - statOverRemainder;
    //
    // final double pay = nonStatReg * j.wage! + nonStatOver * j.wage! * rateOT + statReg * j.wage! * rateStat + statOverRemainder * j.wage! * bestStatRate;

    // return PayPeriod(start: 'start', end: end, deposit: deposit, hours: hours, overtime: over, pay: pay);
    return null!;
  }

  List<PayPeriod> periodsAround(Job j, {int back = 0, int forward = 2}) {
    // final base = j.lastPaychequeIso ?? DateTime.now();
    // final len = _lenDays(j);
    // final now = DateTime.now();
    // int n = ((now.difference(base).inDays) / len).floor();
    // final firstStart = base.add(Duration(days: n * len));
    // final out = <PayPeriod>[];
    // for (int i = -back; i <= forward; i++) {
    //   final s = firstStart.add(Duration(days: i * len));
    //   out.add(computePeriod(j, s));
    // }
    // return out;
    return null!;
  }

  DateTime? nextDeposit(Job j) {
    // final base = j.lastPaychequeIso;
    // if (base == null) return null;
    // final len = _lenDays(j);
    // final now = DateTime.now();
    // int n = ((now.difference(base).inDays) / len).ceil();
    // return base.add(Duration(days: n * len));
  }

  Map<String, Map<String, double>> monthSummary(DateTime month) {
    // month range [start, end)
    // final start = DateTime(month.year, month.month, 1);
    // final end = DateTime(month.year, month.month + 1, 1);
    //
    // // init per-job buckets
    // final perJob = <String, Map<String, double>>{
    //   for (final j in jobs) j.id!: {'hours': 0.0, 'pay': 0.0}
    // };
    //
    // for (final s in shifts) {
    //   // shift date is stored as 'YYYY-MM-DD'
    //   final sd = DateTime.parse(s.date);
    //   if (sd.isBefore(start) || !sd.isBefore(end)) continue;
    //
    //   final job = jobs.firstWhereOrNull((j) => j.id == s.jobId);
    //   if (job == null) continue;
    //
    //   final mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
    //   final hours = (mins / 60.0).toDouble();
    //
    //   // --- STAT logic (this is the bit you asked about) ---
    //   final isStat = (s.isStat == true) || job.statDays!.contains(s.date);
    //   final hourly = (job.wage! * (isStat ? job.statMultiplier : 1.0)!).toDouble();
    //   // ----------------------------------------------------
    //
    //   perJob[job.id]!['hours'] = (perJob[job.id]!['hours'] ?? 0) + hours;
    //   perJob[job.id]!['pay'] = (perJob[job.id]!['pay'] ?? 0) + (hours * hourly);
    // }

    // return perJob;
    return null!;
  }

  // Returns deposit dates (YYYY-MM-DD) for this job that fall in the given month.
  List<String> depositYmdsForMonth(Job j, DateTime month) {
    // final base = j.lastPaychequeIso; // your existing parse
    // if (base == null) return [];
    //
    // final stepDays = j.payFrequency == 'biweekly' ? 14 : 7;
    // final from = DateTime(month.year, month.month, 1);
    // final to = DateTime(month.year, month.month + 1, 1);
    //
    // var d = base;
    // while (d.isBefore(from)) d = d.add(Duration(days: stepDays));
    //
    // final out = <String>[];
    // while (d.isBefore(to)) {
    //   out.add(ymd(d)); // your existing ymd(DateTime) -> "YYYY-MM-DD"
    //   d = d.add(Duration(days: stepDays));
    // }
    // return out;
    return null!;
  }

  // ---------- Payroll-week helpers ----------

// Start of week for a specific DOW (Mon=1..Sun=7)
  DateTime startOfWeekDow(DateTime day, int dow) {
    final wd = day.weekday; // 1..7
    final diff = (wd - dow) % 7;
    final base = DateTime(day.year, day.month, day.day);
    return base.subtract(Duration(days: diff));
  }

// Sum hours in the current payroll week for a job
  double hoursInCurrentPayrollWeek(Job j, {DateTime? now}) {
    // now ??= DateTime.now();
    // final start = startOfWeekDow(now, j.weekStartDOW!);
    // final end = start.add(Duration(days: _lenDays(j))); // [start, end)
    // double hours = 0.0;
    // for (final s in shifts.where((x) => x.jobId == j.id)) {
    //   final d = DateTime.parse('${s.date}T00:00:00');
    //   if (d.isBefore(start) || !d.isBefore(end)) continue;
    //   final mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
    //   hours += mins / 60.0;
    // }
    // return hours;
    return null!;
  }

// ---------- Period-level net estimate ----------
//   double estimateNetForPeriod(Job j, PayPeriod p) {
//     final t = taxFor(j.id);
//     final g = p.pay;
//
//     final income = g * (t.incomeTaxPct / 100.0);
//     final cpp = g * (t.cppPct / 100.0);
//     final ei = g * (t.eiPct / 100.0);
//     final other = g * (t.otherPct / 100.0);
//
//     final baseNet = (g - (income + cpp + ei + other)).clamp(0.0, double.infinity).toDouble();
//     final post = baseNet * (t.postTaxExpensePct / 100.0);
//     final legacyM = t.fixedMonthly;
//     final oneOff = t.oneOffByDepositYmd[ymd(p.deposit)] ?? 0.0;
//
//     return (baseNet - post - legacyM - oneOff).clamp(0.0, double.infinity).toDouble();
//   }

// ---------- Build a combined deposit timeline (last N deposits) ----------

  // Build a combined deposit timeline (last N deposits)
  List<DepositPoint> recentDeposits({int count = 8}) {
    // final now = DateTime.now();
    //
    // List<PayPeriod> nextPeriods(Job j, int back) {
    //   final base = j.lastPaychequeIso ?? now;
    //   final step = _lenDays(j);
    //   // walk backwards from the first upcoming period start
    //   int n = ((now.difference(base).inDays) / step).floor();
    //   final first = base.add(Duration(days: n * step));
    //   final out = <PayPeriod>[];
    //   for (int i = 0; i < back; i++) {
    //     final s = first.subtract(Duration(days: i * step));
    //     out.add(computePeriod(j, s));
    //   }
    //   return out;
    // }
    //
    // final sb = jobs.firstWhereOrNull((j) => j.id == 'starbucks');
    // final ss = jobs.firstWhereOrNull((j) => j.id == 'superstore');
    //
    // final map = <String, DepositPoint>{}; // ymd -> point
    //
    // void addJob(Job? j) {
    //   if (j == null) return;
    //   for (final p in nextPeriods(j, count * 2)) {
    //     final y = ymd(p.deposit);
    //     final net = estimateNetForPeriod(j, p);
    //     final existing = map[y];
    //     if (existing == null) {
    //       map[y] = DepositPoint(
    //         p.deposit,
    //         j.id == 'starbucks' ? net : 0.0,
    //         j.id == 'superstore' ? net : 0.0,
    //       );
    //     } else {
    //       if (j.id == 'starbucks') {
    //         map[y] = existing.copyWith(starbucks: net);
    //       } else if (j.id == 'superstore') {
    //         map[y] = existing.copyWith(superstore: net);
    //       }
    //     }
    //   }
    // }
    //
    // addJob(sb);
    // addJob(ss);
    //
    // final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    // return list.length > count ? list.sublist(list.length - count) : list;
    return null!;
  }
  // ===== Add near your other helpers in AppController =====

// Length of a pay period for a job (public access for UI)
//   int lenDays(Job j) => j.payFrequency == 'biweekly' ? 14 : 7;

// Current payroll period containing "now"
  PeriodStat currentPayrollPeriod(Job j) {
    final pp = periodsAround(j, back: 0, forward: 0).first; // your computePeriod() already used here
    return toPeriodStat(j, pp);
  }

// Previous payroll period (one step back)
  PeriodStat prevPayrollPeriod(Job j) {
    final list = periodsAround(j, back: 1, forward: 0);
    final prev = list.first; // previous
    return toPeriodStat(j, prev);
  }

// Average of last N periods (quick baseline)
  PeriodStat avgPayrollPeriod(Job j, int n) {
    final list = periodsAround(j, back: n - 1, forward: 0);
    double g = 0, h = 0, ot = 0, net = 0, inc = 0, cpp = 0, ei = 0, oth = 0, post = 0, statU = 0;
    for (final p in list) {
      final s = toPeriodStat(j, p);
      g += s.gross;
      h += s.hours;
      ot += s.ot;
      net += s.net;
      inc += s.income;
      cpp += s.cpp;
      ei += s.ei;
      oth += s.other;
      post += s.post;
      statU += s.statUplift;
    }
    final d = max(1, list.length).toDouble();
    return PeriodStat(
      start: list.first.start,
      end: list.first.end,
      gross: g / d,
      net: net / d,
      hours: h / d,
      ot: ot / d,
      income: inc / d,
      cpp: cpp / d,
      ei: ei / d,
      other: oth / d,
      post: post / d,
      statUplift: statU / d,
    );
  }

// Convert PayPeriod -> stats with deductions using your TaxConfig
  PeriodStat toPeriodStat(Job j, PayPeriod p) {
    // final t = taxFor(j.id!);
    // final gross = p.pay;
    //
    // final income = gross * (t.incomeTaxPct / 100.0);
    // final cpp = gross * (t.cppPct / 100.0);
    // final ei = gross * (t.eiPct / 100.0);
    // final other = gross * (t.otherPct / 100.0);
    // final preNet = (gross - (income + cpp + ei + other)).clamp(0, double.infinity).toDouble();
    //
    // // post-tax expense %, if your TaxConfig has it; else 0
    // final post = preNet * ((t.postTaxExpensePct ?? 0) / 100.0);
    // final net = (preNet - post).clamp(0, double.infinity).toDouble();
    //
    // // simple estimate of stat uplift (what portion came from stat multiplier vs base)
    // final statUplift = max(0.0, (j.statMultiplier! - 1.0)) *
    //     (p.hours == 0 ? 0 : (p.pay / j.statMultiplier! - (p.pay - (j.statMultiplier! - 1) * j.wage! * (p.hours))));
    //
    // return PeriodStat(
    //   start: p.start,
    //   end: p.end,
    //   gross: gross,
    //   net: net,
    //   hours: p.hours,
    //   ot: p.overtime,
    //   income: income,
    //   cpp: cpp,
    //   ei: ei,
    //   other: other,
    //   post: post,
    //   statUplift: statUplift,
    // );
    return null!;
  }

// Public helper used by the timeline card
  double estimateNetForPeriod(Job j, PayPeriod p) => toPeriodStat(j, p).net;

// ---- Monthly bucket (used by compare + composition when Monthly selected) ----
  MonthBucket monthBucket(DateTime month, Job j) {
    // // use your existing monthSummary() + monthNetSummary() if you prefer;
    // // here we aggregate from actual shifts in that month for the job.
    // final start = DateTime(month.year, month.month, 1);
    // final end = DateTime(month.year, month.month + 1, 1);
    //
    // double hours = 0, statHours = 0, gross = 0;
    // for (final s in shifts.where((x) => x.jobId == j.id)) {
    //   final sd = DateTime.parse(s.date);
    //   if (sd.isBefore(start) || !sd.isBefore(end)) continue;
    //   final mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
    //   final h = mins / 60.0;
    //   hours += h;
    //   final isStat = j.statDays!.contains(s.date) || (s.isStat == true);
    //   final rate = j.wage! * (isStat ? j.statMultiplier : 1.0)!;
    //   if (isStat) statHours += h;
    //   gross += rate * h;
    // }
    //
    // // deductions
    // final t = taxFor(j.id!);
    // final income = gross * (t.incomeTaxPct / 100.0);
    // final cpp = gross * (t.cppPct / 100.0);
    // final ei = gross * (t.eiPct / 100.0);
    // final other = gross * (t.otherPct / 100.0);
    // final preNet = (gross - (income + cpp + ei + other)).clamp(0, double.infinity).toDouble();
    // final post = preNet * ((t.postTaxExpensePct ?? 0) / 100.0);
    // final net = (preNet - post).clamp(0, double.infinity).toDouble();
    //
    // // rough OT sum in the month: sum weekly across monthStart-aligned weeks
    // // (kept light for UI — your existing OT logic in weeklyTotals can be reused if preferred)
    // final ot = 0.0;
    //
    // // stat uplift (approx)
    // final statUplift = (j.statMultiplier! - 1.0) * j.wage! * statHours;
    //
    // return MonthBucket(
    //     gross: gross, net: net, hours: hours, ot: ot, income: income, cpp: cpp, ei: ei, other: other, post: post, statUplift: statUplift);
    return null!;
  }

// Average of last N months (for CompareKind.avg monthly baseline)
  MonthBucket monthAvg({required int count, required DateTime anchor, required Job job}) {
    double g = 0, n = 0, h = 0, ot = 0, inc = 0, cpp = 0, ei = 0, oth = 0, post = 0, uplift = 0;
    for (int i = 1; i <= count; i++) {
      final m = monthBucket(DateTime(anchor.year, anchor.month - i, 1), job);
      g += m.gross;
      n += m.net;
      h += m.hours;
      ot += m.ot;
      inc += m.income;
      cpp += m.cpp;
      ei += m.ei;
      oth += m.other;
      post += m.post;
      uplift += m.statUplift;
    }
    final d = count.toDouble();
    return MonthBucket(
        gross: g / d,
        net: n / d,
        hours: h / d,
        ot: ot / d,
        income: inc / d,
        cpp: cpp / d,
        ei: ei / d,
        other: oth / d,
        post: post / d,
        statUplift: uplift / d);
  }
}
