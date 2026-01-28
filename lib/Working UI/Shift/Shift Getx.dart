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
import '../Account/Account Getx.dart';
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
  Rx<DateTime>? selectedMonth = DateTime.now().obs;
  Rxn<ShiftMonth>? currentMonth = Rxn<ShiftMonth>();
  Rxn<JobData> selectedJob = Rxn<JobData>();
  Rxn<OverviewModel> combinedStats = Rxn<OverviewModel>();
  Rx<ButtonState> state = Rx<ButtonState>(ButtonState.loading);
  RxBool? minimumShifts = false.obs;
  RxBool? unpaidBreak = false.obs;
  RxBool? isStat = false.obs;
  Rxn<ShiftModel> shiftModel = Rxn<ShiftModel>();
  Rxn<AllShifts> selectedShift = Rxn<AllShifts>();
  RxList<AllShifts>? todayShifts = RxList<AllShifts>([]);
  RxMap<DateTime, PayCell>? payCycles = RxMap<DateTime, PayCell>();
  RxList<TextForm>? newShiftColumns = RxList<TextForm>([
    TextForm(title: "Start time", controller: TextEditingController(text: '')),
    TextForm(title: "End time", controller: TextEditingController(text: '')),
    TextForm(title: "Unpaid break time", controller: TextEditingController(text: '')),
    TextForm(title: "Note", controller: TextEditingController(text: '')),
  ]);

  void resetShiftState() {
    activeShift = "Calendar".obs;
    shiftScreen = Rx<Widget>(Calendar());
    selectedDay = DateTime.now().obs;
    selectedMonth = DateTime.now().obs;
    selectedJob = Rxn<JobData>();
    combinedStats = Rxn<OverviewModel>();
    state = Rx<ButtonState>(ButtonState.loading);
    minimumShifts = false.obs;
    unpaidBreak = false.obs;
    isStat = false.obs;
    shiftModel = Rxn<ShiftModel>();
    selectedShift = Rxn<AllShifts>();
    todayShifts = RxList<AllShifts>([]);
    for (var file in newShiftColumns!) {
      file.controller.text = '';
    }
  }

  /// ===================================================================
  /// ======================= DAY DETAILS ===============================
  /// ===================================================================

  void getShiftsForDay() {
    final dKey = monthDate(selectedDay!.value);
    if (currentMonth != null) {
      if (currentMonth!.value!.dates!.any((t) => t.date == dKey)) {
        final dIdx = currentMonth!.value!.dates!.indexWhere((d) => d.date! == dKey);
        todayShifts!.value = currentMonth!.value!.dates![dIdx].data!;
      } else {
        todayShifts!.value = [];
        todayShifts!.refresh();
      }
    }
    todayShifts!.refresh();
  }

  /// ===================================================================
  /// ======================= LOAD & UPDATE =============================
  /// ===================================================================

  ShiftMonth? getCurrentData(DateTime month) {
    return shiftModel.value?.data?.firstWhereOrNull((m) => monthName(DateTime.parse(m.month!)) == monthName(month));
  }

  int totalShiftsInCurrentMonth() => (currentMonth?.value?.dates ?? const <ShiftDay>[]).fold(0, (sum, d) => sum + (d.data?.length ?? 0));

  void loadShifts() async {
    final listData = await getLocalData('savedShifts') ?? '';
    if (listData != '') {
      shiftModel.value = ShiftModel.fromJson(jsonDecode(listData));
      currentMonth!.value = getCurrentData(selectedMonth!.value);
    }
    shiftModel.refresh();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (currentMonth!.value != null) {
        combinedStats.value = buildOverviewForMonth(currentMonth!.value!);
        minimumShifts!.value = totalShiftsInCurrentMonth() >= 10 ? true : false;
        payCycles!.value = account.buildPayCellsForMonth();
        payCycles!.refresh();
        print(totalShiftsInCurrentMonth());
        minimumShifts!.refresh();
      }
      combinedStats.refresh();
      state.value = ButtonState.init;
      state.refresh();
    });
  }

  void updateStatus() {
    resetShiftState();
    loadShifts();
  }

  /// ===================================================================
  /// ======================= DOTS FOR CALENDAR =========================
  /// ===================================================================

  Map<DateTime, List<JobDot>> buildJobDotsAll({bool perShift = false}) {
    DateTime d0(DateTime d) => DateTime(d.year, d.month, d.day);

    Color c(String? x) {
      try {
        return Color(int.parse(x ?? '0xff999999'));
      } catch (_) {
        return const Color(0xff999999);
      }
    }

    final out = <DateTime, List<JobDot>>{};
    final seen = <DateTime, Set<String>>{};

    final month = currentMonth?.value;
    if (month == null) return out; // ✅ nothing selected yet

    for (final dd in (month.dates ?? const <ShiftDay>[])) {
      for (final s in (dd.data ?? const <AllShifts>[])) {
        final dt = s.start;
        if (dt == null) continue;

        final k = d0(dt);
        final color = c(s.jobFrom?.jobColor);

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

    return out;
  }

  /// ===================================================================
  /// ======================= TABS ======================================
  /// ===================================================================
  RxList<String> shiftTypes = ["Calendar", "Overview", "Deposits", "Projection"].obs;

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
      date: selectedDay!.value,
      start: newShiftColumns![0].pickedDate,
      end: newShiftColumns![1].pickedDate,
      breakMin: shift.unpaidBreak!.value ? int.parse(newShiftColumns![2].controller.text) : 0,
      notes: newShiftColumns![3].controller.text,
      jobFrom: selectedJob.value,
      isStat: isStat!.value,
      totalHours: diffHoursMinutesDT(
        newShiftColumns![0].pickedDate!,
        newShiftColumns![1].pickedDate!,
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
      date: selectedDay!.value,
      start: newShiftColumns![0].pickedDate,
      end: newShiftColumns![1].pickedDate,
      breakMin: shift.unpaidBreak!.value ? int.parse(newShiftColumns![2].controller.text) : 0,
      notes: newShiftColumns![3].controller.text,
      jobFrom: selectedJob.value!,
      isStat: isStat!.value,
      totalHours: diffHoursMinutesDT(
        newShiftColumns![0].pickedDate!,
        newShiftColumns![1].pickedDate!,
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
    state.value = ButtonState.loading;
    state.refresh();
    Get.back();
    Get.back();
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

  OverviewModel buildOverviewForMonth(ShiftMonth sm) {
    if (account.jobs == null || account.jobs!.isEmpty) {
      return OverviewModel(
        month: DateTime.now(),
        totals: Totals(hours: 0, pay: 0),
        jobs: const <JobWeekly>[],
      );
    }

    double round2(double v) => (v * 100).roundToDouble() / 100.0;

    DateTime monthAnchor(ShiftMonth sm) {
      final raw = (sm.month ?? '').trim();
      if (raw.isEmpty) return DateTime.now();
      final fixed = RegExp(r'^\d{4}-\d{2}$').hasMatch(raw) ? '$raw-01' : raw;
      final dt = DateTime.parse(fixed);
      return DateTime(dt.year, dt.month, 1);
    }

    int wday(String? n) {
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

    DateTime periodStart(DateTime anchor, int weekStartDay) {
      final a = DateTime(anchor.year, anchor.month, anchor.day);
      final diff = (a.weekday - weekStartDay) % 7;
      return a.subtract(Duration(days: diff));
    }

    double statMult(int jobId) {
      final j = account.jobs!.firstWhere(
        (e) => e.id == jobId,
        orElse: () => JobData(id: jobId),
      );
      final cleaned = (j.statPay ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
      final mult = double.tryParse(cleaned);
      return (mult == null || mult <= 0) ? 1.0 : mult;
    }

    final m0 = monthAnchor(sm);
    final mNext = DateTime(m0.year, m0.month + 1, 1);
    final m1End = mNext.subtract(const Duration(seconds: 1));

    // jobId -> rows [start, hours, pay]
    final byJob = <int, List<List<dynamic>>>{};

    for (final dd in (sm.dates ?? const <ShiftDay>[])) {
      for (final s in (dd.data ?? const <AllShifts>[])) {
        final jobId = s.jobFrom?.id;
        if (jobId == null) continue;

        final start = s.start;
        final endRaw = s.end;
        if (start == null || endRaw == null) continue;

        // month filter (by shift start)
        if (start.isBefore(m0) || start.isAfter(m1End)) continue;

        var end = endRaw;
        if (end.isBefore(start)) end = end.add(const Duration(days: 1));

        final breakMin = (s.breakMin ?? 0); // ✅ no crash
        var workedMin = end.difference(start).inMinutes - breakMin;
        if (workedMin < 0) workedMin = 0;

        final hrs = workedMin / 60.0;

        final wage = double.tryParse((s.jobFrom?.wageHr ?? '').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        final basePay = wage * hrs;
        final pay = (s.isStat == true) ? basePay * statMult(jobId) : basePay;

        (byJob[jobId] ??= <List<dynamic>>[]).add(<dynamic>[start, hrs, pay]);
      }
    }

    // Build output
    final jobWeekly = <JobWeekly>[];
    double combinedH = 0.0, combinedP = 0.0;

    for (final j in account.jobs!) {
      final jobId = j.id ?? -1;
      if (jobId < 0) continue;

      final ws = wday(j.weekStart);

      final buckets = <List<DateTime>>[];
      var wkStart = periodStart(m0, ws);

      var wi = 1;
      while (!wkStart.isAfter(m1End) && wi <= 6) {
        final wkEnd = wkStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        buckets.add(<DateTime>[wkStart, wkEnd]);
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
          final b0 = buckets[i][0], b1 = buckets[i][1];
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

    return OverviewModel(
      month: m0,
      totals: Totals(hours: round2(combinedH), pay: round2(combinedP)),
      jobs: jobWeekly,
    );
  }
}
