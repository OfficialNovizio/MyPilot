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

class ShiftController extends GetxController {
  RxString? activeShift = "Calendar".obs;
  Rx<Widget>? shiftScreen = Rx<Widget>(Calendar());
  Rx<DateTime>? selectedDay = DateTime.now().obs;
  RxString? period = 'weekly'.obs;
  RxString? metric = 'net'.obs;
  RxString? baseline = 'last'.obs;
  Rxn<JobData> selectedJob = Rxn<JobData>();
  Rxn<Map<int, CombinedOverview>>? combinedMonthStat = Rxn<Map<int, CombinedOverview>>();
  Rxn<ShiftModel> shiftModel = Rxn<ShiftModel>();
  Rxn<AllShifts> selectedShift = Rxn<AllShifts>();
  RxList<ShiftMonth>? shifts = RxList<ShiftMonth>([]);
  RxList<AllShifts>? todayShifts = RxList<AllShifts>([]);

  RxList<TextForm>? newShiftColumns = RxList<TextForm>([
    TextForm(
      title: "Start time",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "End time",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Unpaid break time",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Note",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Is this stat day ?",
      controller: TextEditingController(text: '0'),
    ),
  ]);
  RxInt? depositLookBack = 3.obs;
  RxInt? depositLookForward = 3.obs;
  RxDouble? combinedHours = 0.0.obs;
  RxDouble? combinedPay = 0.0.obs;

  // Projection tab
  final projHours = <String, double>{}.obs; // jobId -> hours (per "period" below)
  final projScope = 'weekly'.obs; // weekly | biweekly | monthly

  void getShiftsForDay() {
    final mKey = monthName(selectedDay!.value); // "YYYY-MM"
    final dKey = monthDate(selectedDay!.value); // "YYYY-MM-DD"
    print(mKey);
    if (shifts!.isNotEmpty) {
      final mIdx = shifts!.indexWhere((m) => m.month == mKey);
      final days = shifts![mIdx].dates;
      if (days!.any((t) => t.date == dKey)) {
        final dIdx = days.indexWhere((d) => d.date == dKey);
        todayShifts!.value = shifts![mIdx].dates![dIdx].data!;
        todayShifts!.refresh();
        print(todayShifts);
      } else {
        todayShifts!.value = [];
      }
    }
    todayShifts!.refresh();
  }

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
      combinedMonthStat!.value = buildOverviewsPerJobCompact(
        back: 1,
        fwd: 2,
      );
      for (var files in shift.combinedMonthStat!.value!.values) {
        combinedHours!.value = combinedHours!.value + files.totals.hours!;
        combinedPay!.value = combinedPay!.value + files.totals.pay!;
      }
      combinedMonthStat!.refresh();
    });
    print(shifts);
  }

  void updateStatus() {
    loadShifts();
    Future.delayed(const Duration(seconds: 1), () {
      getShiftsForDay();
    });
  }

  // List<CombinedRow> combinedRowsThisMonth() {
  //   // month window
  //   DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  //   final now = DateTime.now(), m0 = DateTime(now.year, now.month, 1), m1 = DateTime(now.year, now.month + 1, 0);
  //   bool _inMonth(DateTime dt) => !_d(dt).isBefore(m0) && !_d(dt).isAfter(m1);
  //
  //   // parsers
  //   final _reAP = RegExp(r'\bAM\b|\bPM\b', caseSensitive: false);
  //   DateTime _p12(String s) {
  //     final a = s.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
  //     if (a.length < 3) throw const FormatException('bad 12h datetime');
  //     final ymd = a[0].split('-'), hm = a[1].split(':'), ap = a[2].toUpperCase();
  //     final y = int.parse(ymd[0]), m = int.parse(ymd[1]), d = int.parse(ymd[2]);
  //     var h = int.parse(hm[0]);
  //     final mi = int.parse(hm[1]);
  //     if (ap == 'AM') {
  //       if (h == 12) h = 0;
  //     } else if (h != 12) h += 12;
  //     return DateTime(y, m, d, h, mi);
  //   }
  //
  //   DateTime _parseDT(String s) {
  //     if (_reAP.hasMatch(s)) return _p12(s);
  //     final n = s.contains('T') ? s : s.replaceFirst(' ', 'T'); // "2025-11-13 05:30:00.000" -> ISO-ish
  //     return DateTime.parse(n);
  //   }
  //
  //   int _breakMin(dynamic v) {
  //     if (v is int) return v;
  //     if (v is String) {
  //       // numeric minutes like "30" -> 30; anything else (e.g., "2025-11-15 09:30 AM") -> 0
  //       final n = int.tryParse(v.trim());
  //       return n ?? 0;
  //     }
  //     return 0;
  //   }
  //
  //   double _wage(dynamic v) {
  //     if (v is num) return v.toDouble();
  //     if (v is String) return double.tryParse(v) ?? 0;
  //     return 0;
  //   }
  //
  //   final byJob = <String, CombinedRow>{};
  //   double allH = 0, allP = 0;
  //
  //   for (final m in (shifts?.toList() ?? const <ShiftMonth>[])) {
  //     for (final dd in (m.dates ?? const <ShiftDay>[])) {
  //       for (final s in (dd.data ?? const <AllShifts>[])) {
  //         final aS = s.start, bS = s.end, jf = s.jobFrom;
  //         if (aS == null || bS == null || aS.isEmpty || bS.isEmpty || jf == null) continue;
  //
  //         DateTime a, b;
  //         try {
  //           a = _parseDT(aS);
  //           b = _parseDT(bS);
  //         } catch (_) {
  //           continue;
  //         }
  //         if (!_inMonth(a)) continue;
  //
  //         if (b.isBefore(a)) b = DateTime(b.year, b.month, b.day + 1, b.hour, b.minute); // cross-midnight
  //         int mins = b.difference(a).inMinutes - _breakMin(s.breakMin);
  //         if (mins < 0) mins = 0;
  //
  //         final hrs = mins / 60.0;
  //         final pay = _wage(jf.wageHr) * hrs;
  //
  //         final key = (jf.id?.toString().isNotEmpty == true) ? jf.id.toString() : (jf.jobName ?? 'unknown');
  //         final row = byJob.putIfAbsent(key, () => CombinedRow(jobId: jf.id, jobName: jf.jobName ?? key, colorHex: jf.jobColor, hours: 0, pay: 0));
  //         row.hours = (row.hours ?? 0) + hrs;
  //         row.pay = (row.pay ?? 0) + pay;
  //
  //         allH += hrs;
  //         allP += pay;
  //       }
  //     }
  //   }
  //
  //   return [
  //     CombinedRow(jobId: null, jobName: 'All Jobs', hours: allH, pay: allP),
  //     ...byJob.values.toList()..sort((a, b) => ((b.pay ?? 0).compareTo(a.pay ?? 0))),
  //   ];
  // }

  Map<DateTime, List<JobDot>> buildJobDotsAll({bool perShift = false}) {
    DateTime d0(DateTime d) => DateTime(d.year, d.month, d.day);
    DateTime p(String s) {
      if (RegExp(r'\bAM\b|\bPM\b', caseSensitive: false).hasMatch(s)) {
        final a = s.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
        final y = int.parse(a[0].split('-')[0]), m = int.parse(a[0].split('-')[1]), d = int.parse(a[0].split('-')[2]);
        var h = int.parse(a[1].split(':')[0]);
        final mi = int.parse(a[1].split(':')[1]);
        final ap = a[2].toUpperCase();
        if (ap == 'AM') {
          if (h == 12) h = 0;
        } else if (h != 12) {
          h += 12;
        }
        ;
        return DateTime(y, m, d, h, mi);
      }
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

  RxList<Map> shiftStats = RxList<Map>([
    {
      "Route": shiftEnums.calendar,
      "Title": "Calendar",
    },
    {
      "Route": shiftEnums.overview,
      "Title": "Overview",
    },
    {
      "Route": shiftEnums.deposits,
      "Title": "Deposits",
    },
    {
      "Route": shiftEnums.projections,
      "Title": "Projection",
    },
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
    print(activeShift!.value);
    activeShift!.refresh();
  }

  Future<ShiftModel> saveShift({bool replaceById = true}) async {
    final data = await _loadModel();
    final monthKey = monthName(selectedDay!.value);
    final dateKey = monthDate(selectedDay!.value);

    AllShifts? shift = AllShifts(
      id: Random().nextInt(5000).toString(),
      date: monthDate(selectedDay!.value),
      start: newShiftColumns![0].controller.text,
      end: newShiftColumns![1].controller.text,
      breakMin: newShiftColumns![2].controller.text,
      notes: newShiftColumns![3].controller.text,
      jobFrom: selectedJob.value,
      isStat: newShiftColumns![4].controller.text == '0' ? false : true,
      totalHours: diffHoursMinutes(newShiftColumns![0].controller.text, newShiftColumns![1].controller.text),
    );
    print(shift.start);
    print(shift.end);
    print(shift.totalHours);
    // Ensure month/day nodes
    final months = data.data ??= <ShiftMonth>[];
    final monthNode = _getOrAddMonth(months, monthKey);
    final days = monthNode.dates ??= <ShiftDay>[];
    final dayNode = _getOrAddDay(days, dateKey);

    // Upsert shift
    final list = dayNode.data ??= <AllShifts>[];
    if (replaceById && shift.id != null) {
      final i = list.indexWhere((e) => e.id == shift.id);
      (i >= 0) ? list[i] = shift : list.add(shift);
    } else {
      list.add(shift);
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

    final shifts = days[dIdx].data ??= <AllShifts>[];
    shifts.removeWhere((s) => s.id == id);

    // Optional cleanup: drop empty day/month nodes
    if (shifts.isEmpty) {
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

    // 1) locate the existing shift (month/day/index)
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
    if (sIdx < 0) return data; // not found → nothing to edit

    // 2) build updated shift from your current UI state (keep same id)
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
      isStat: newShiftColumns![4].controller.text != '0' ? true : false,
      totalHours: diffHoursMinutes(newShiftColumns![0].controller.text, newShiftColumns![1].controller.text),
    );

    final oldMonthKey = months[mIdx].month ?? '';
    final oldDateKey = months[mIdx].dates![dIdx].date ?? '';
    final dateChanged = (oldMonthKey != newMonthKey) || (oldDateKey != newDateKey);

    if (!dateChanged) {
      // 3a) replace in place
      final list = months[mIdx].dates![dIdx].data ??= <AllShifts>[];
      list[sIdx] = updated;
    } else {
      // 3b) move: remove from old location
      final oldList = months[mIdx].dates![dIdx].data ??= <AllShifts>[];
      oldList.removeAt(sIdx);

      // clean up empty nodes
      if (oldList.isEmpty) {
        months[mIdx].dates!.removeAt(dIdx);
        if (months[mIdx].dates!.isEmpty) {
          months.removeAt(mIdx);
        }
      }

      // insert into new month/day
      final mNode = _getOrAddMonth(months, newMonthKey);
      final dNode = _getOrAddDay(mNode.dates ??= <ShiftDay>[], newDateKey);
      (dNode.data ??= <AllShifts>[]).add(updated);
    }
    Get.back();
    showSnackBar("Success", "Shift changed");
    await _saveModel(data);
    return data;
  }

// ----------------- Helpers -----------------

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

  ///======================================================================================
  ///======================================================================================
  ///======================================================================================
  ///============================Code for overview screen==================================
  ///======================================================================================
  ///======================================================================================
  ///======================================================================================

  Map<int, CombinedOverview> buildOverviewsPerJobCompact({
    int back = 1,
    int fwd = 1,
    double otThreshold = 40.0,
    double otMult = 1.5,
    double netRate = 0.80,
  }) {
    // —— helpers (scoped) ——
    DateTime d(DateTime x) => DateTime(x.year, x.month, x.day);
    bool hasAP(String s) => RegExp(r'\bAM\b|\bPM\b', caseSensitive: false).hasMatch(s);
    DateTime p12(String s) {
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

    DateTime parseDT(String s) => hasAP(s) ? p12(s) : DateTime.parse(s.contains('T') ? s : s.replaceFirst(' ', 'T'));
    int breakMin(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    double wage(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
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

    bool isBiweekly(String? s) {
      final v = (s ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
      return v.contains('biweek') || v.contains('byweek');
    }

    DateTime pStart(DateTime anchor, int wk) {
      final a = d(anchor), diff = (a.weekday - wk + 7) % 7;
      return a.subtract(Duration(days: diff));
    }

    DateTime pEnd(DateTime start, bool biw) => start.add(Duration(days: biw ? 14 : 7)).subtract(const Duration(seconds: 1));
    DateTime nextDep(DateTime end, bool biw) => d(end).add(Duration(days: biw ? 14 : 7));
    double pct(double cur, double base) => base <= 0.0 ? 0.0 : ((cur - base) / base) * 100.0;

    // flatten once: jobId → shifts
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
      final biw = isBiweekly(j.payFrequency);
      final wk = wday(j.weekStart);

      // start window for this job
      var curStart = pStart(now, wk);
      for (int i = 0; i < back; i++) {
        curStart = pStart(curStart.subtract(const Duration(days: 1)), wk);
      }

      final series = <PeriodRow>[];
      var cursor = curStart;

      for (int k = 0; k < back + fwd + 1; k++) {
        final ps = cursor, pe = pEnd(ps, biw);
        double minsSum = 0.0, baseGross = 0.0, wageHours = 0.0;

        for (final s in jobShifts) {
          DateTime a, b;
          try {
            a = parseDT(s.start!);
            b = parseDT(s.end!);
          } catch (_) {
            continue;
          }
          if (b.isBefore(a)) b = DateTime(b.year, b.month, b.day + 1, b.hour, b.minute);
          if (b.isBefore(ps) || a.isAfter(pe)) continue;

          var mins = b.difference(a).inMinutes - breakMin(s.breakMin);
          if (mins < 0) mins = 0;
          final hrs = mins / 60.0, w = wage(s.jobFrom?.wageHr);

          minsSum += mins.toDouble();
          baseGross += hrs * w;
          wageHours += hrs * w;
        }

        final hrs = minsSum / 60.0;
        final avgW = hrs > 0.0 ? (wageHours / hrs) : 0.0;
        final otH = hrs > otThreshold ? (hrs - otThreshold) : 0.0; // weekly-style OT
        final otPremium = otH * avgW * (otMult - 1.0);
        final gross = baseGross + otPremium;
        final net = gross * netRate;

        series.add(PeriodRow(
          start: ps,
          end: pe,
          deposit: nextDep(pe, biw),
          hours: hrs,
          overtime: otH,
          gross: gross,
          net: net,
        ));

        cursor = pEnd(cursor, biw).add(const Duration(seconds: 1));
      }

      final totH = series.fold<double>(0.0, (s, x) => s + x.hours);
      final totN = series.fold<double>(0.0, (s, x) => s + x.net);
      final last = series.isNotEmpty ? series.last : null;
      final prev = series.length >= 2 ? series[series.length - 2] : null;
      final tail = series.length <= 1 ? <PeriodRow>[] : series.sublist(0, series.length - 1);
      final last3 = tail.length >= 3 ? tail.sublist(tail.length - 3) : tail;
      final avg3 = last3.isEmpty ? 0.0 : last3.fold<double>(0.0, (s, x) => s + x.net) / last3.length;

      out[id] = CombinedOverview(
        totals: CombinedRow(jobId: id, jobName: j.jobName ?? 'Job $id', colorHex: j.jobColor, hours: totH, pay: totN),
        series: series,
        nextDeposit: last?.deposit,
        vsLastPct: (last != null && prev != null) ? pct(last.net, prev.net) : 0.0,
        vsAvg3Pct: (last != null) ? pct(last.net, avg3) : 0.0,
      );
    }

    return out;
  }
}

class ShiftForm extends StatefulWidget {
  final String? initialDate; // YYYY-MM-DD
  final Shift? existing;
  const ShiftForm({super.key, this.initialDate, this.existing});

  @override
  State<ShiftForm> createState() => _ShiftFormState();
}

class _ShiftFormState extends State<ShiftForm> {
  late String jobId;
  late final TextEditingController dateCtl;
  late final TextEditingController startCtl;
  late final TextEditingController endCtl;
  late final TextEditingController breakCtl;
  late final TextEditingController notesCtl;

// UI switch state

  @override
  void initState() {
    super.initState();
    final c = Get.find<AppController>();
    // jobId = (widget.existing?.jobId ?? (c.jobs.isNotEmpty ? c.jobs.first.id : ""))!;
    dateCtl = TextEditingController(
      text: widget.existing?.date ?? widget.initialDate ?? ymd(DateTime.now()),
    );
    startCtl = TextEditingController(text: widget.existing?.start ?? "09:00");
    endCtl = TextEditingController(text: widget.existing?.end ?? "17:00");
    breakCtl = TextEditingController(text: (widget.existing?.breakMin ?? 0).toString());
    notesCtl = TextEditingController(text: widget.existing?.notes ?? "");

    _syncStatFromJobAndDate();
  }

  void _syncStatFromJobAndDate() {
    final c = Get.find<AppController>();
    // final job = c.jobs.firstWhereOrNull((j) => j.id == jobId);
    final d = dateCtl.text.trim();
    // setState(() => _isStat = job != null && job.statDays!.contains(d));
  }

  void _applyStatToJob(bool v) {
    final c = Get.find<AppController>();
    // final idx = c.jobs.indexWhere((j) => j.id == jobId);
    // if (idx < 0) return;
    // final job = c.jobs[idx];
    // final d = dateCtl.text.trim();
    // if (v) {
    //   if (!job.statDays!.contains(d)) job.statDays!.add(d);
    // } else {
    //   job.statDays!.remove(d);
    // }
    // c.jobs[idx] = job; // trigger GetX update
  }

  @override
  void dispose() {
    dateCtl.dispose();
    startCtl.dispose();
    endCtl.dispose();
    breakCtl.dispose();
    notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1012),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(controller: controller, children: [
          Center(
            child: Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.existing == null ? 'Add Shift' : 'Edit Shift', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          // DropdownButtonFormField<String>(
          //   value: jobId.isNotEmpty ? jobId : null,
          //   items: [
          //     for (final j in c.jobs) DropdownMenuItem(value: j.id, child: Text(j.name!)),
          //   ],
          //   onChanged: (v) {
          //     setState(() => jobId = v ?? jobId);
          //     _syncStatFromJobAndDate();
          //   },
          //   decoration: const InputDecoration(labelText: 'Job', isDense: true),
          // ),
          const SizedBox(height: 12),

          // Date: read-only + picker
          TextField(
            controller: dateCtl,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Date (YYYY-MM-DD)',
              isDense: true,
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            onTap: () async {
              final existing = dateCtl.text.trim();
              final initial = (existing.isNotEmpty) ? DateTime.tryParse(existing) ?? DateTime.now() : DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                helpText: 'Select shift date',
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: Theme.of(ctx).colorScheme.copyWith(
                          primary: const Color(0xFF16A34A),
                        ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => dateCtl.text = ymd(picked));
                _syncStatFromJobAndDate();
              }
            },
          ),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: TextField(
                controller: startCtl,
                decoration: const InputDecoration(labelText: 'Start (HH:mm)', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: endCtl,
                decoration: const InputDecoration(labelText: 'End (HH:mm)', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: TextField(
                controller: breakCtl,
                decoration: const InputDecoration(labelText: 'Unpaid break (min)', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: notesCtl,
                decoration: const InputDecoration(labelText: 'Notes', isDense: true),
              ),
            ),
          ]),
          const SizedBox(height: 8),

          // NEW: Stat day switch
          // Builder(builder: (_) {
          //   final job = c.jobs.firstWhereOrNull((j) => j.id == jobId);
          //   final mult = job?.statMultiplier ?? 1.5;
          //   return SwitchListTile.adaptive(
          //     contentPadding: EdgeInsets.zero,
          //     title: const Text('Stat day (holiday)'),
          //     subtitle: Text('Apply ${mult.toStringAsFixed(2)}× pay for this date'),
          //     value: _isStat,
          //     onChanged: (v) {
          //       setState(() => _isStat = v);
          //       _applyStatToJob(v);
          //     },
          //   );
          // }),
          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed: () {
              // if (jobId.isEmpty) return;
              // final newShift = Shift(
              //   id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              //   jobId: jobId,
              //   date: dateCtl.text.trim(),
              //   start: startCtl.text.trim(),
              //   end: endCtl.text.trim(),
              //   breakMin: int.tryParse(breakCtl.text.trim()) ?? 0,
              //   notes: notesCtl.text.trim(),
              // );
              // final c = Get.find<AppController>();
              // if (widget.existing == null) {
              //   c.addShift(newShift);
              // } else {
              //   c.updateShift(widget.existing!.id!, newShift);
              // }
              // Get.back(); // close sheet
            },
            icon: const Icon(Icons.save),
            label: Text(widget.existing == null ? 'Add Shift' : 'Save Changes'),
          ),
        ]),
      ),
    );
  }
}
