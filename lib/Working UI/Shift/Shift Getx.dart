import 'dart:convert';
import 'dart:math';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Shared%20Preferences.dart';
import 'package:emptyproject/Working%20UI/Shift/Calendar/Calendar.dart';
import 'package:emptyproject/Working%20UI/Shift/Deposits/Deposit.dart';
import 'package:emptyproject/Working%20UI/Shift/Projection/Projection.dart';
import 'package:emptyproject/models/Overview%20Model.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/models/shift.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Overview/Overview.dart';

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

class ShiftController extends GetxController {
  RxString? activeShift = "Calendar".obs;
  Rx<Widget>? shiftScreen = Rx<Widget>(Calendar());
  Rx<DateTime>? selectedDay = DateTime.now().obs;
  RxString? period = 'weekly'.obs;
  RxString? metric = 'net'.obs;
  RxString? baseline = 'last'.obs;
  Rxn<JobData> selectedJob = Rxn<JobData>();
  Rxn<MonthStats> monthStats = Rxn<MonthStats>();
  RxList<OverviewModel> combinedStats = RxList<OverviewModel>([]);
  Rx<ButtonState> state = Rx<ButtonState>(ButtonState.loading);

  /// existing monthly combined stats (per job)
  Rxn<Map<int, CombinedOverview>>? combinedMonthStat = Rxn<Map<int, CombinedOverview>>();

  /// NEW: weekly month breakdown (per job)
  Rxn<Map<int, List<WeekStats>>> weeklyMonthBreakdown = Rxn<Map<int, List<WeekStats>>>();

  Rxn<ShiftModel> shiftModel = Rxn<ShiftModel>();
  Rxn<AllShifts> selectedShift = Rxn<AllShifts>();
  RxList<ShiftMonth>? shifts = RxList<ShiftMonth>([]);
  RxList<AllShifts>? todayShifts = RxList<AllShifts>([]);

  RxList<TextForm>? newShiftColumns = RxList<TextForm>([
    TextForm(title: "Start time", controller: TextEditingController(text: '')),
    TextForm(title: "End time", controller: TextEditingController(text: '')),
    TextForm(title: "Unpaid break time", controller: TextEditingController(text: '')),
    TextForm(title: "Note", controller: TextEditingController(text: '')),
    TextForm(title: "Is this stat day ?", controller: TextEditingController(text: '0')),
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

  // DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  bool _hasAP(String s) => RegExp(r'\bAM\b|\bPM\b', caseSensitive: false).hasMatch(s);

  DateTime _p12(String s) {
    final parts = s.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
    if (parts.length < 3) throw FormatException('Invalid 12h datetime', s);

    final ymd = parts[0].split('-');
    final hm = parts[1].split(':');
    final ap = parts[2].toUpperCase();

    if (ymd.length != 3 || hm.length != 2 || (ap != 'AM' && ap != 'PM')) {
      throw FormatException('Invalid 12h datetime', s);
    }

    final y = int.parse(ymd[0]);
    final m = int.parse(ymd[1]);
    final d = int.parse(ymd[2]);

    var h = int.parse(hm[0]);
    final mi = int.parse(hm[1]);

    if (ap == 'AM') {
      if (h == 12) h = 0;
    } else {
      if (h != 12) h += 12;
    }

    return DateTime(y, m, d, h, mi);
  }

  DateTime _parseDT(String s) => _hasAP(s) ? _p12(s) : DateTime.parse(s.contains('T') ? s : s.replaceFirst(' ', 'T'));

  // int _breakMin(dynamic v) {
  //   if (v is int) return v;
  //   if (v is String) return int.tryParse(v.trim()) ?? 0;
  //   return 0;
  // }
  //
  // double _wage(dynamic v) {
  //   if (v is num) return v.toDouble();
  //   if (v is String) return double.tryParse(v) ?? 0.0;
  //   return 0.0;
  // }

  int _wday(String? n) {
    switch ((n ?? '').toLowerCase().trim()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  // bool _isBiweekly(String? s) {
  //   final v = (s ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
  //   return v.contains('biweek') || v.contains('byweek');
  // }
  //
  // DateTime _periodStart(DateTime anchor, int weekStartDay) {
  //   final a = _d(anchor);
  //   final diff = (a.weekday - weekStartDay + 7) % 7;
  //   return a.subtract(Duration(days: diff));
  // }
  //
  // DateTime _periodEnd(DateTime start, bool biw) => start.add(Duration(days: biw ? 14 : 7)).subtract(const Duration(seconds: 1));
  //
  // DateTime _nextDeposit(DateTime end, bool biw) => _d(end).add(Duration(days: biw ? 14 : 7));
  //
  // double _pct(double cur, double base) => base <= 0.0 ? 0.0 : ((cur - base) / base) * 100.0;

  /// ===================================================================
  /// ======================= DAY DETAILS ===============================
  /// ===================================================================

  void getShiftsForDay() {
    final mKey = monthName(selectedDay!.value); // "YYYY-MM"
    final dKey = monthDate(selectedDay!.value); // "YYYY-MM-DD"
    // todayShifts!.value = [];
    // todayShifts!.refresh();
    if (shifts!.isNotEmpty) {
      final mIdx = shifts!.indexWhere((m) => monthName(DateTime.parse(m.month!)) == mKey);
      if (mIdx < 0) {
        todayShifts!.value = [];
        todayShifts!.refresh();
        return;
      }
      final dates = shifts![mIdx].dates;
      if (dates!.any((t) => t.date == dKey)) {
        final dIdx = dates.indexWhere((d) => d.date == dKey);
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
    // await removeLocalData('savedShifts');
    final listData = await getLocalData('savedShifts') ?? '';
    shifts!.clear();
    // reWriteSavedData();

    if (listData != '') {
      shiftModel.value = ShiftModel.fromJson(jsonDecode(listData));
      for (var files in shiftModel.value!.data!) {
        shifts!.add(files);
      }
    }

    shiftModel.refresh();
    shifts!.refresh();

    Future.delayed(const Duration(seconds: 1), () {
      // ONE public stats builder
      combinedStats.value = buildCombinedOverviews();
      combinedHours!.value = 0;
      combinedPay!.value = 0;

      for (final v in combinedStats) {
        combinedHours!.value += v.totals!.hours;
        combinedPay!.value += v.totals!.pay;
      }
      combinedStats.refresh();
      state.value = ButtonState.init;
      state.refresh();
    });
  }

  void reWriteSavedData() async {
    // await removeLocalData('savedShifts');
    var data = await _loadModel();

    for (var files in data.data!) {
      for (var days in files.dates!) {
        days.totalWorkingHour = 0.0;
        days.totalDayIncome = 0.0;
        for (var shift in days.data!) {
          final parts = shift.totalHours!.replaceAll('h', '').replaceAll('m', '').trim().split(RegExp(r'\s+'));
          final hours = int.parse(parts[0]) + int.parse(parts[1]) / 60.0;
          shift.income = hours * double.parse(shift.jobFrom!.wageHr!) * double.parse(shift.jobFrom!.statPay!);
          days.totalWorkingHour = days.totalWorkingHour! + hours;
          days.totalDayIncome = days.totalDayIncome! + shift.income!;
        }
      }
    }

    ShiftModel model = data;
    _saveModel(model);
    print(model);
  }

  void updateStatus() {
    loadShifts();
    // Future.delayed(const Duration(seconds: 1), () {
    //   getShiftsForDay();
    // });
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

  // RxList<Map> shiftStats = RxList<Map>([
  //   {"Route": shiftEnums.calendar, "Title": "Calendar"},
  //   {"Route": shiftEnums.overview, "Title": "Overview"},
  //   {"Route": shiftEnums.deposits, "Title": "Deposits"},
  //   {"Route": shiftEnums.projections, "Title": "Projection"},
  // ]);
  RxList<String> shiftTypes = [
    "Calendar",
    "Overview",
    "Deposits",
    "Projection",
  ].obs;

  void changeShiftTabs(screen) {
    switch (screen) {
      case "Calendar":
        activeShift!.value = 'Calendar';
        shiftScreen!.value = Calendar();
        break;

      case "Overview":
        activeShift!.value = 'Overview';
        shiftScreen!.value = OverviewTab();
        break;

      case "Deposits":
        activeShift!.value = 'Deposits';
        shiftScreen!.value = DepositsTab();
        break;

      case "Projection":
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
    final monthNode = _getOrAddMonth(months);
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
    Get.back();
    state.value = ButtonState.loading;
    state.refresh();
    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "The new shift has been added to your schedule.");
    });
    await _saveModel(data);
    return data;
  }

  Future<ShiftModel> deleteShift({required String id}) async {
    final data = await _loadModel();
    final monthKey = monthName(selectedDay!.value);
    final dateKey = monthDate(selectedDay!.value);

    final months = data.data ??= <ShiftMonth>[];
    final mIdx = months.indexWhere((m) => monthName(DateTime.parse(m.month!)) == monthKey);
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
    state.value = ButtonState.loading;
    state.refresh();
    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "Your current shift has been removed from schedule.");
    });
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
    final dateChanged = (oldMonthKey != newMonthKey) || (oldDateKey != newDateKey);

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

      final mNode = _getOrAddMonth(months);
      final dNode = _getOrAddDay(mNode.dates ??= <ShiftDay>[], newDateKey);
      (dNode.data ??= <AllShifts>[]).add(updated);
    }

    Get.back();
    state.value = ButtonState.loading;
    state.refresh();
    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "Your current shift has been changed from schedule.");
    });
    await _saveModel(data);
    return data;
  }

  // ---------------- Helpers for CRUD ----------------

  ShiftMonth _getOrAddMonth(List<ShiftMonth> months) {
    for (final m in months) {
      if (monthName(DateTime.parse(m.month!)) == monthName(selectedDay!.value)) return m;
    }
    final n = ShiftMonth(month: DateTime(selectedDay!.value.year, selectedDay!.value.month, 1).toString(), dates: <ShiftDay>[]);
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

  List<OverviewModel> buildCombinedOverviews() {
    if (shifts == null || shifts!.isEmpty) return const <OverviewModel>[];
    if (account.jobs == null || account.jobs!.isEmpty) return const <OverviewModel>[];

    int breakMin(String? s) => int.tryParse((s ?? '').trim()) ?? 0;
    double round2(double v) => (v * 100).roundToDouble() / 100.0;

    DateTime monthAnchor(ShiftMonth sm) {
      final raw = (sm.month ?? '').trim();
      if (raw.isEmpty) return DateTime.now();
      final fixed = RegExp(r'^\d{4}-\d{2}$').hasMatch(raw) ? '$raw-01' : raw;
      final dt = DateTime.parse(fixed);
      return DateTime(dt.year, dt.month, 1);
    }

    DateTime periodStart(DateTime anchor, int weekStartDay) {
      final a = DateTime(anchor.year, anchor.month, anchor.day);
      final diff = (a.weekday - weekStartDay) % 7;
      return a.subtract(Duration(days: diff));
    }

    double statMult(int jobId) {
      final j = account.jobs!.firstWhere((e) => e.id == jobId, orElse: () => JobData(id: jobId));
      final cleaned = (j.statPay ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
      final mult = double.tryParse(cleaned);
      return (mult == null || mult <= 0) ? 1.0 : mult;
    }

    // sort oldest -> newest
    shifts!.sort((a, b) => monthAnchor(a).compareTo(monthAnchor(b)));

    final out = <OverviewModel>[];

    for (final sm in shifts!) {
      final m0 = monthAnchor(sm);
      final mNext = DateTime(m0.year, m0.month + 1, 1);
      final m1End = mNext.subtract(const Duration(seconds: 1)); // end of month

      // Flatten only THIS month's shifts grouped by jobId (same rule as old: start must be in month)
      final byJob = <int, List<List<dynamic>>>{};

      for (final dd in (sm.dates ?? const <ShiftDay>[])) {
        for (final s in (dd.data ?? const <AllShifts>[])) {
          final jobId = s.jobFrom?.id;
          if (jobId == null) continue;

          final stStr = s.start ?? '';
          final enStr = s.end ?? '';
          if (stStr.isEmpty || enStr.isEmpty) continue;

          DateTime start;
          try {
            start = _parseDT(stStr);
          } catch (_) {
            continue;
          }

          // month filter like old code
          if (start.isBefore(m0) || start.isAfter(m1End)) continue;

          DateTime end;
          try {
            end = _parseDT(enStr);
          } catch (_) {
            continue;
          }

          if (end.isBefore(start)) end = end.add(const Duration(days: 1));

          var workedMin = end.difference(start).inMinutes - breakMin(s.breakMin);
          if (workedMin < 0) workedMin = 0;

          final hrs = workedMin / 60.0;

          final wage = double.tryParse((s.jobFrom?.wageHr ?? '').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          final basePay = wage * hrs;
          final pay = ((s.isStat ?? false) == true) ? basePay * statMult(jobId) : basePay;

          (byJob[jobId] ??= <List<dynamic>>[]).add(<dynamic>[start, hrs, pay]);
        }
      }

      // Build output for this month
      final jobWeekly = <JobWeekly>[];
      double combinedH = 0.0, combinedP = 0.0;

      for (final j in account.jobs!) {
        final jobId = j.id ?? -1;
        if (jobId < 0) continue;

        final ws = _wday(j.weekStart);

        // ✅ calendar-style week buckets (NOT clipped to month)
        final buckets = <List<DateTime>>[];
        var wkStart = periodStart(m0, ws);

        var wi = 1;
        while (!wkStart.isAfter(m1End) && wi <= 6) {
          final wkEnd = wkStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
          buckets.add(<DateTime>[wkStart, wkEnd]); // inclusive end like old
          wkStart = wkStart.add(const Duration(days: 7));
          wi++;
        }

        final wh = List<double>.filled(buckets.length, 0.0);
        final wp = List<double>.filled(buckets.length, 0.0);

        for (final row in (byJob[jobId] ?? const <List<dynamic>>[])) {
          final start = row[0] as DateTime;
          final hrs = row[1] as double;
          final pay = row[2] as double;

          for (var i = 0; i < buckets.length; i++) {
            final b0 = buckets[i][0], b1 = buckets[i][1]; // inclusive end
            if (!start.isBefore(b0) && !start.isAfter(b1)) {
              wh[i] += hrs;
              wp[i] += pay;
              break;
            }
          }
        }

        final weeks = <WeekRow>[];
        double jobH = 0.0, jobP = 0.0;

        for (var i = 0; i < buckets.length; i++) {
          final h = round2(wh[i]);
          final p = round2(wp[i]);
          jobH += h;
          jobP += p;

          weeks.add(WeekRow(
            weekIndex: i + 1,
            start: buckets[i][0],
            end: buckets[i][1],
            hours: h,
            pay: p,
          ));
        }

        combinedH += jobH;
        combinedP += jobP;

        jobWeekly.add(JobWeekly(
          jobId: jobId,
          jobName: ((j.jobName ?? '').trim().isEmpty) ? 'Job $jobId' : (j.jobName ?? '').trim(),
          colorHex: (j.jobColor ?? '#000000'),
          totals: Totals(hours: round2(jobH), pay: round2(jobP)),
          weeks: weeks,
        ));
      }

      jobWeekly.sort((a, b) => b.totals.pay.compareTo(a.totals.pay));

      out.add(
        OverviewModel(
          month: m0,
          totals: Totals(hours: round2(combinedH), pay: round2(combinedP)),
          jobs: jobWeekly,
        ),
      );
    }

    return out;
  }
}
