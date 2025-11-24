import 'dart:convert';
import 'dart:math';

import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Shared%20Preferences.dart';
import 'package:emptyproject/Working%20UI/Shift/Calendar.dart';
import 'package:emptyproject/Working%20UI/Shift/Deposit.dart';
import 'package:emptyproject/Working%20UI/Shift/Overview.dart';
import 'package:emptyproject/Working%20UI/Shift/Projection.dart';
import 'package:emptyproject/Working%20UI/app_controller.dart';
import 'package:emptyproject/models/Overview%20Model.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/models/shift.dart';
import 'package:emptyproject/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum shiftEnums {
  calendar,
  overview,
  deposits,
  projections,
}

class JobDot {
  final Color color;
  const JobDot(this.color);
}

/// ======================= NEW: WEEK STATS MODEL =======================
class WeekStats {
  final int weekIndex; // 1..5
  final DateTime start;
  final DateTime end;
  double hours;
  double pay;

  WeekStats({
    required this.weekIndex,
    required this.start,
    required this.end,
    this.hours = 0,
    this.pay = 0,
  });
}

/// ======================= NEW: COMBINED BUILT RESULT =======================
class BuiltStats {
  final Map<int, CombinedOverview> overviews;
  final Map<int, List<WeekStats>> weekly;

  BuiltStats({required this.overviews, required this.weekly});
}

class ShiftController extends GetxController {
  RxString? activeShift = "Calendar".obs;
  Rx<Widget>? shiftScreen = Rx<Widget>(Calendar());
  Rx<DateTime>? selectedDay = DateTime.now().obs;
  RxString? period = 'weekly'.obs;
  RxString? metric = 'net'.obs;
  RxString? baseline = 'last'.obs;

  Rxn<JobData> selectedJob = Rxn<JobData>();

  /// existing monthly combined stats (per job)
  Rxn<Map<int, CombinedOverview>>? combinedMonthStat =
  Rxn<Map<int, CombinedOverview>>();

  /// NEW: weekly month breakdown (per job)
  Rxn<Map<int, List<WeekStats>>> weeklyMonthBreakdown =
  Rxn<Map<int, List<WeekStats>>>();

  Rxn<ShiftModel> shiftModel = Rxn<ShiftModel>();
  Rxn<AllShifts> selectedShift = Rxn<AllShifts>();
  RxList<ShiftMonth>? shifts = RxList<ShiftMonth>([]);
  RxList<AllShifts>? todayShifts = RxList<AllShifts>([]);

  RxList<TextForm>? newShiftColumns = RxList<TextForm>([
    TextForm(title: "Start time",
        controller: TextEditingController(text: '')),
    TextForm(title: "End time",
        controller: TextEditingController(text: '')),
    TextForm(title: "Unpaid break time",
        controller: TextEditingController(text: '')),
    TextForm(title: "Note",
        controller: TextEditingController(text: '')),
    TextForm(title: "Is this stat day ?",
        controller: TextEditingController(text: '0')),
  ]);

  RxInt? depositLookBack = 3.obs;
  RxInt? depositLookForward = 3.obs;

  RxDouble? combinedHours = 0.0.obs;
  RxDouble? combinedPay = 0.0.obs;

  // Projection tab
  final projHours = <String, double>{}.obs; // jobId -> hours
  final projScope = 'weekly'.obs; // weekly | biweekly | monthly

  /// ===================================================================
  /// ======================= SHARED HELPERS (ONE PLACE) =================
  /// ===================================================================

  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  bool _hasAP(String s) =>
      RegExp(r'\bAM\b|\bPM\b', caseSensitive: false).hasMatch(s);

  DateTime _p12(String s) {
    final a = s.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
    final ymd = a[0].split('-'), hm = a[1].split(':'), ap = a[2].toUpperCase();
    final y = int.parse(ymd[0]), m = int.parse(ymd[1]), dy = int.parse(ymd[2]);
    var h = int.parse(hm[0]);
    final mi = int.parse(hm[1]);
    if (ap == 'AM') {
      if (h == 12) h = 0;
    } else if (h != 12) {
      h += 12;
    }
    return DateTime(y, m, dy, h, mi);
  }

  DateTime _parseDT(String s) =>
      _hasAP(s) ? _p12(s) : DateTime.parse(s.contains('T') ? s : s.replaceFirst(' ', 'T'));

  int _breakMin(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  double _wage(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int _wday(String? n) {
    switch ((n ?? '').toLowerCase().trim()) {
      case 'monday': return DateTime.monday;
      case 'tuesday': return DateTime.tuesday;
      case 'wednesday': return DateTime.wednesday;
      case 'thursday': return DateTime.thursday;
      case 'friday': return DateTime.friday;
      case 'saturday': return DateTime.saturday;
      case 'sunday': return DateTime.sunday;
      default: return DateTime.monday;
    }
  }

  bool _isBiweekly(String? s) {
    final v = (s ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return v.contains('biweek') || v.contains('byweek');
  }

  DateTime _periodStart(DateTime anchor, int weekStartDay) {
    final a = _d(anchor);
    final diff = (a.weekday - weekStartDay + 7) % 7;
    return a.subtract(Duration(days: diff));
  }

  DateTime _periodEnd(DateTime start, bool biw) =>
      start.add(Duration(days: biw ? 14 : 7))
          .subtract(const Duration(seconds: 1));

  DateTime _nextDeposit(DateTime end, bool biw) =>
      _d(end).add(Duration(days: biw ? 14 : 7));

  double _pct(double cur, double base) =>
      base <= 0.0 ? 0.0 : ((cur - base) / base) * 100.0;

  /// ===================================================================
  /// ======================= DAY DETAILS ===============================
  /// ===================================================================

  void getShiftsForDay() {
    final mKey = monthName(selectedDay!.value); // "YYYY-MM"
    final dKey = monthDate(selectedDay!.value); // "YYYY-MM-DD"

    if (shifts!.isNotEmpty) {
      final mIdx = shifts!.indexWhere((m) => m.month == mKey);
      if (mIdx < 0) {
        todayShifts!.value = [];
        todayShifts!.refresh();
        return;
      }
      final days = shifts![mIdx].dates;
      if (days!.any((t) => t.date == dKey)) {
        final dIdx = days.indexWhere((d) => d.date == dKey);
        todayShifts!.value = shifts![mIdx].dates![dIdx].data!;
      } else {
        todayShifts!.value = [];
      }
    }
    todayShifts!.refresh();
  }

  /// ===================================================================
  /// ======================= LOAD & UPDATE =============================
  /// ===================================================================

  void loadShifts() async {
    final listData = await getLocalData('savedShifts') ?? '';
    shifts!.clear();

    if (listData != '') {
      shiftModel.value = ShiftModel.fromJson(jsonDecode(listData));
      for (var files in shiftModel.value!.data!) {
        shifts!.add(files);
      }
    }

    shiftModel.refresh();
    shifts!.refresh();

    Future.delayed(const Duration(seconds: 2), () {
      // ONE public stats builder
      final stats = buildMonthStats(
        month: DateTime.now(),
        back: 1,
        fwd: 2,
      );

      combinedMonthStat!.value = stats.overviews;
      weeklyMonthBreakdown.value = stats.weekly;

      // FIX: reset totals before summing (your old code inflated)
      combinedHours!.value = 0;
      combinedPay!.value = 0;

      for (final v in stats.overviews.values) {
        combinedHours!.value += v.totals.hours ?? 0;
        combinedPay!.value += v.totals.pay ?? 0;
      }

      combinedMonthStat!.refresh();
      weeklyMonthBreakdown.refresh();
    });
  }

  void updateStatus() {
    loadShifts();
    Future.delayed(const Duration(seconds: 1), () {
      getShiftsForDay();
    });
  }

  /// ===================================================================
  /// ======================= DOTS FOR CALENDAR =========================
  /// ===================================================================

  Map<DateTime, List<JobDot>> buildJobDotsAll({bool perShift = false}) {
    DateTime d0(DateTime d) => DateTime(d.year, d.month, d.day);

    DateTime p(String s) {
      if (_hasAP(s)) return _p12(s);
      final n = s.contains('T') ? s : s.replaceFirst(' ', 'T');
      return DateTime.parse(n);
    }

    Color c(String? x) {
      try {
        return Color(int.parse(x ?? '0xff999999'));
      } catch (_) {
        return const Color(0xff999999);
      }
    }

    final out = <DateTime, List<JobDot>>{};
    final seen = <DateTime, Set<String>>{};

    for (final m in (shifts?.toList() ?? const <ShiftMonth>[])) {
      for (final dd in (m.dates ?? const <ShiftDay>[])) {
        for (final s in (dd.data ?? const <AllShifts>[])) {
          final st = s.start;
          if (st == null || st.isEmpty) continue;

          DateTime dt;
          try {
            dt = p(st);
          } catch (_) {
            continue;
          }

          final k = d0(dt), color = c(s.jobFrom?.jobColor);

          if (perShift) {
            (out[k] ??= <JobDot>[]).add(JobDot(color));
          } else {
            final id = '${s.jobFrom?.id ?? ''}';
            if (id.isEmpty) continue;
            final set = (seen[k] ??= <String>{});
            if (set.add(id)) (out[k] ??= <JobDot>[]).add(JobDot(color));
          }
        }
      }
    }

    return out;
  }

  /// ===================================================================
  /// ======================= TABS ======================================
  /// ===================================================================

  RxList<Map> shiftStats = RxList<Map>([
    {"Route": shiftEnums.calendar, "Title": "Calendar"},
    {"Route": shiftEnums.overview, "Title": "Overview"},
    {"Route": shiftEnums.deposits, "Title": "Deposits"},
    {"Route": shiftEnums.projections, "Title": "Projection"},
  ]);

  void changeShiftTabs(shiftEnums screen) {
    switch (screen) {
      case shiftEnums.calendar:
        activeShift!.value = 'Calendar';
        shiftScreen!.value = Calendar();
        break;

      case shiftEnums.overview:
        activeShift!.value = 'Overview';
        shiftScreen!.value = OverviewTab();
        break;

      case shiftEnums.deposits:
        activeShift!.value = 'Deposits';
        shiftScreen!.value = DepositsTab();
        break;

      case shiftEnums.projections:
        activeShift!.value = 'Projection';
        shiftScreen!.value = ProjectionTab();
        break;
    }
    activeShift!.refresh();
  }

  /// ===================================================================
  /// ======================= SHIFT CRUD ================================
  /// ===================================================================

  Future<ShiftModel> saveShift({bool replaceById = true}) async {
    final data = await _loadModel();
    final monthKey = monthName(selectedDay!.value);
    final dateKey = monthDate(selectedDay!.value);

    AllShifts shiftItem = AllShifts(
      id: Random().nextInt(5000).toString(),
      date: monthDate(selectedDay!.value),
      start: newShiftColumns![0].controller.text,
      end: newShiftColumns![1].controller.text,
      breakMin: newShiftColumns![2].controller.text,
      notes: newShiftColumns![3].controller.text,
      jobFrom: selectedJob.value,
      isStat: newShiftColumns![4].controller.text == '0' ? false : true,
      totalHours: diffHoursMinutes(
        newShiftColumns![0].controller.text,
        newShiftColumns![1].controller.text,
      ),
    );

    // Ensure month/day nodes
    final months = data.data ??= <ShiftMonth>[];
    final monthNode = _getOrAddMonth(months, monthKey);
    final days = monthNode.dates ??= <ShiftDay>[];
    final dayNode = _getOrAddDay(days, dateKey);

    // Upsert shift
    final list = dayNode.data ??= <AllShifts>[];
    if (replaceById && shiftItem.id != null) {
      final i = list.indexWhere((e) => e.id == shiftItem.id);
      (i >= 0) ? list[i] = shiftItem : list.add(shiftItem);
    } else {
      list.add(shiftItem);
    }

    Get.back();
    showSnackBar("Success", "New shift created");
    await _saveModel(data);
    return data;
  }

  Future<ShiftModel> deleteShift({required String id}) async {
    final data = await _loadModel();
    final monthKey = monthName(selectedDay!.value);
    final dateKey = monthDate(selectedDay!.value);

    final months = data.data ??= <ShiftMonth>[];
    final mIdx = months.indexWhere((m) => m.month == monthKey);
    if (mIdx < 0) return data;

    final days = months[mIdx].dates ??= <ShiftDay>[];
    final dIdx = days.indexWhere((d) => d.date == dateKey);
    if (dIdx < 0) return data;

    final shiftsList = days[dIdx].data ??= <AllShifts>[];
    shiftsList.removeWhere((s) => s.id == id);

    if (shiftsList.isEmpty) {
      days.removeAt(dIdx);
      if (days.isEmpty) months.removeAt(mIdx);
    }

    Get.back();
    showSnackBar("Success", "Shift removed");
    await _saveModel(data);
    return data;
  }

  Future<ShiftModel> editShift() async {
    final data = await _loadModel();

    int mIdx = -1, dIdx = -1, sIdx = -1;
    final months = data.data ??= <ShiftMonth>[];

    for (var i = 0; i < months.length; i++) {
      final days = months[i].dates ??= <ShiftDay>[];
      for (var j = 0; j < days.length; j++) {
        final list = days[j].data ??= <AllShifts>[];
        final k = list.indexWhere((s) => s.id == selectedShift.value!.id);
        if (k >= 0) {
          mIdx = i;
          dIdx = j;
          sIdx = k;
          break;
        }
      }
      if (sIdx >= 0) break;
    }

    if (sIdx < 0) return data;

    final newMonthKey = monthName(selectedDay!.value);
    final newDateKey = monthDate(selectedDay!.value);

    final updated = AllShifts(
      id: selectedShift.value!.id,
      date: newDateKey,
      start: newShiftColumns![0].controller.text,
      end: newShiftColumns![1].controller.text,
      breakMin: newShiftColumns![2].controller.text,
      notes: newShiftColumns![3].controller.text,
      jobFrom: selectedShift.value!.jobFrom,
      isStat: newShiftColumns![4].controller.text != '0',
      totalHours: diffHoursMinutes(
        newShiftColumns![0].controller.text,
        newShiftColumns![1].controller.text,
      ),
    );

    final oldMonthKey = months[mIdx].month ?? '';
    final oldDateKey = months[mIdx].dates![dIdx].date ?? '';
    final dateChanged =
        (oldMonthKey != newMonthKey) || (oldDateKey != newDateKey);

    if (!dateChanged) {
      final list = months[mIdx].dates![dIdx].data ??= <AllShifts>[];
      list[sIdx] = updated;
    } else {
      final oldList = months[mIdx].dates![dIdx].data ??= <AllShifts>[];
      oldList.removeAt(sIdx);

      if (oldList.isEmpty) {
        months[mIdx].dates!.removeAt(dIdx);
        if (months[mIdx].dates!.isEmpty) {
          months.removeAt(mIdx);
        }
      }

      final mNode = _getOrAddMonth(months, newMonthKey);
      final dNode = _getOrAddDay(mNode.dates ??= <ShiftDay>[], newDateKey);
      (dNode.data ??= <AllShifts>[]).add(updated);
    }

    Get.back();
    showSnackBar("Success", "Shift changed");
    await _saveModel(data);
    return data;
  }

  // ---------------- Helpers for CRUD ----------------

  ShiftMonth _getOrAddMonth(List<ShiftMonth> months, String monthKey) {
    for (final m in months) {
      if (m.month == monthKey) return m;
    }
    final n = ShiftMonth(month: monthKey, dates: <ShiftDay>[]);
    months.add(n);
    return n;
  }

  ShiftDay _getOrAddDay(List<ShiftDay> days, String dateKey) {
    for (final d in days) {
      if (d.date == dateKey) return d;
    }
    final n = ShiftDay(date: dateKey, data: <AllShifts>[]);
    days.add(n);
    return n;
  }

  Future<ShiftModel> _loadModel() async {
    final saved = await getLocalData('savedShifts') ?? '';
    if (saved.isEmpty) {
      return ShiftModel(status: 200, message: 'ok', data: <ShiftMonth>[]);
    }
    return ShiftModel.fromJson(jsonDecode(saved));
  }

  Future<void> _saveModel(ShiftModel m) async {
    await saveLocalData('savedShifts', jsonEncode(m.toJson()));
    Future.delayed(const Duration(seconds: 1), () {
      updateStatus();
    });
  }

  /// ===================================================================
  /// =================== CORE CALCULATORS (NO DUPES) ====================
  /// ===================================================================

  Map<int, CombinedOverview> _buildOverviewsPerJobCompactCore({
    int back = 1,
    int fwd = 1,
    double otThreshold = 40.0,
    double otMult = 1.5,
    double netRate = 0.80,
  }) {
    // flatten once: jobId -> shifts
    final byJob = <int, List<AllShifts>>{};
    for (final m in shifts!) {
      for (final dd in (m.dates ?? const <ShiftDay>[])) {
        for (final s in (dd.data ?? const <AllShifts>[])) {
          final id = s.jobFrom?.id;
          if (id == null) continue;
          final st = s.start ?? '', en = s.end ?? '';
          if (st.isEmpty || en.isEmpty) continue;
          (byJob[id] ??= <AllShifts>[]).add(s);
        }
      }
    }

    final out = <int, CombinedOverview>{};
    final now = DateTime.now();

    for (final j in account.jobs!) {
      final id = j.id ?? -1;
      final jobShifts = byJob[id] ?? const <AllShifts>[];
      final biw = _isBiweekly(j.payFrequency);
      final wk = _wday(j.weekStart);

      var curStart = _periodStart(now, wk);
      for (int i = 0; i < back; i++) {
        curStart = _periodStart(curStart.subtract(const Duration(days: 1)), wk);
      }

      final series = <PeriodRow>[];
      var cursor = curStart;

      for (int k = 0; k < back + fwd + 1; k++) {
        final ps = cursor, pe = _periodEnd(ps, biw);
        double minsSum = 0.0, baseGross = 0.0, wageHours = 0.0;

        for (final s in jobShifts) {
          DateTime a, b;
          try {
            a = _parseDT(s.start!);
            b = _parseDT(s.end!);
          } catch (_) {
            continue;
          }
          if (b.isBefore(a)) {
            b = DateTime(b.year, b.month, b.day + 1, b.hour, b.minute);
          }
          if (b.isBefore(ps) || a.isAfter(pe)) continue;

          var mins = b.difference(a).inMinutes - _breakMin(s.breakMin);
          if (mins < 0) mins = 0;

          final hrs = mins / 60.0;
          final w = _wage(s.jobFrom?.wageHr);

          minsSum += mins.toDouble();
          baseGross += hrs * w;
          wageHours += hrs * w;
        }

        final hrs = minsSum / 60.0;
        final avgW = hrs > 0.0 ? (wageHours / hrs) : 0.0;
        final otH = hrs > otThreshold ? (hrs - otThreshold) : 0.0;
        final otPremium = otH * avgW * (otMult - 1.0);
        final gross = baseGross + otPremium;
        final net = gross * netRate;

        series.add(PeriodRow(
          start: ps,
          end: pe,
          deposit: _nextDeposit(pe, biw),
          hours: hrs,
          overtime: otH,
          gross: gross,
          net: net,
        ));

        cursor = _periodEnd(cursor, biw).add(const Duration(seconds: 1));
      }

      final totH = series.fold<double>(0.0, (s, x) => s + x.hours);
      final totN = series.fold<double>(0.0, (s, x) => s + x.net);

      final last = series.isNotEmpty ? series.last : null;
      final prev = series.length >= 2 ? series[series.length - 2] : null;

      final tail = series.length <= 1 ? <PeriodRow>[] : series.sublist(0, series.length - 1);
      final last3 = tail.length >= 3 ? tail.sublist(tail.length - 3) : tail;
      final avg3 = last3.isEmpty
          ? 0.0
          : last3.fold<double>(0.0, (s, x) => s + x.net) / last3.length;

      out[id] = CombinedOverview(
        totals: CombinedRow(
          jobId: id,
          jobName: j.jobName ?? 'Job $id',
          colorHex: j.jobColor,
          hours: totH,
          pay: totN,
        ),
        series: series,
        nextDeposit: last?.deposit,
        vsLastPct: (last != null && prev != null) ? _pct(last.net, prev.net) : 0.0,
        vsAvg3Pct: (last != null) ? _pct(last.net, avg3) : 0.0,
      );
    }

    return out;
  }

  Map<int, List<WeekStats>> _buildWeeklyBreakdownForMonthCore(DateTime month) {
    final m0 = DateTime(month.year, month.month, 1);
    final m1 = DateTime(month.year, month.month + 1, 0);

    // shifts by job, only those starting in this month
    final byJob = <int, List<AllShifts>>{};
    for (final sm in (shifts?.toList() ?? const <ShiftMonth>[])) {
      for (final dd in (sm.dates ?? const <ShiftDay>[])) {
        for (final s in (dd.data ?? const <AllShifts>[])) {
          final id = s.jobFrom?.id;
          if (id == null) continue;
          final st = s.start ?? '';
          final en = s.end ?? '';
          if (st.isEmpty || en.isEmpty) continue;

          DateTime a;
          try {
            a = _parseDT(st);
          } catch (_) {
            continue;
          }
          if (a.isBefore(m0) || a.isAfter(m1)) continue;

          (byJob[id] ??= <AllShifts>[]).add(s);
        }
      }
    }

    final out = <int, List<WeekStats>>{};

    for (final j in (account.jobs?.toList() ?? const <JobData>[])) {
      final id = j.id ?? -1;
      if (id < 0) continue;

      final wkStartDay = _wday(j.weekStart);
      DateTime wkStart = _periodStart(m0, wkStartDay);

      final buckets = <WeekStats>[];
      int wi = 1;
      while (!wkStart.isAfter(m1)) {
        final wkEnd = wkStart.add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
        buckets.add(WeekStats(weekIndex: wi, start: wkStart, end: wkEnd));
        wkStart = wkStart.add(const Duration(days: 7));
        wi++;
        if (wi > 6) break;
      }

      for (final s in (byJob[id] ?? const <AllShifts>[])) {
        DateTime a, b;
        try {
          a = _parseDT(s.start!);
          b = _parseDT(s.end!);
        } catch (_) {
          continue;
        }
        if (b.isBefore(a)) {
          b = DateTime(b.year, b.month, b.day + 1, b.hour, b.minute);
        }

        var mins = b.difference(a).inMinutes - _breakMin(s.breakMin);
        if (mins < 0) mins = 0;

        final hrs = mins / 60.0;
        final pay = _wage(s.jobFrom?.wageHr) * hrs;

        for (final bucket in buckets) {
          if (!a.isBefore(bucket.start) && !a.isAfter(bucket.end)) {
            bucket.hours += hrs;
            bucket.pay += pay;
            break;
          }
        }
      }

      out[id] = buckets;
    }

    return out;
  }

  /// ===================================================================
  /// ======================= PUBLIC SINGLE ENTRY =======================
  /// ===================================================================

  BuiltStats buildMonthStats({
    DateTime? month,
    int back = 1,
    int fwd = 2,
    double otThreshold = 40.0,
    double otMult = 1.5,
    double netRate = 0.80,
  }) {
    final m = month ?? DateTime.now();
    final overviews = _buildOverviewsPerJobCompactCore(
      back: back,
      fwd: fwd,
      otThreshold: otThreshold,
      otMult: otMult,
      netRate: netRate,
    );
    final weekly = _buildWeeklyBreakdownForMonthCore(m);
    return BuiltStats(overviews: overviews, weekly: weekly);
  }

  /// wrappers so other screens don’t break if they call old methods
  Map<int, CombinedOverview> buildOverviewsPerJobCompact({
    int back = 1,
    int fwd = 1,
    double otThreshold = 40.0,
    double otMult = 1.5,
    double netRate = 0.80,
  }) =>
      _buildOverviewsPerJobCompactCore(
        back: back,
        fwd: fwd,
        otThreshold: otThreshold,
        otMult: otMult,
        netRate: netRate,
      );

  Map<int, List<WeekStats>> buildWeeklyBreakdownForMonth(DateTime month) =>
      _buildWeeklyBreakdownForMonthCore(month);
}
