import 'dart:convert';
import 'dart:math';

import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Shared%20Preferences.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:emptyproject/models/job.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/shift.dart';
import '../Cards and Account/Cards.dart';
import 'Active Jobs.dart';

enum JobStatus { create, edit, delete }

class PayMarker {
  final String? jobName;
  final int? jobId;
  final Color? color;
  PayMarker({this.jobName, this.color, this.jobId});
}



class PayJobLine {
  final int jobId;
  final String jobName;
  final Color color;

  final DateTime payDate; // actual payday
  final DateTime periodStart; // inclusive
  final DateTime periodEnd; // inclusive

  final double payTotal; // sum of shift incomes in period
  final double hoursTotal; // sum of hours in period

  const PayJobLine({
    required this.jobId,
    required this.jobName,
    required this.color,
    required this.payDate,
    required this.periodStart,
    required this.periodEnd,
    required this.payTotal,
    required this.hoursTotal,
  });
}

class PayCell {
  final List<PayJobLine> lines;
  const PayCell(this.lines);

  int get count => lines.length;
  double get totalPay => lines.fold(0.0, (s, x) => s + x.payTotal);
  double get totalHours => lines.fold(0.0, (s, x) => s + x.hoursTotal);

  // UI convenience (still pick first color for badge)
  Color get color => lines.first.color;
}

class AccountController extends GetxController {
  final daysShort = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  final payFrequency = const {"Weekly": 7, "By Weekly": 14, "Monthly": 30};

  final colorChoices = const [
    '0xff16a34a',
    '0xff2563eb',
    '0xffe11d48',
    '0xff0ea5e9',
    '0xff10b981',
    '0xfff59e0b',
    '0xff8b5cf6',
    '0xff14b8a6',
    '0xffef4444'
  ];

  List<dynamic>? columns = [
    {'title': 'Active Jobs', 'icon': Icons.work_outline_rounded},
    {'title': 'Payment Accounts', 'icon': Icons.account_balance_outlined},
    {'title': 'Settings', 'icon': Icons.settings},
    {'title': 'Permissions', 'icon': Icons.perm_device_info_outlined},
    {'title': 'Privacy Policy', 'icon': Icons.policy_outlined},
    {'title': 'Logout', 'icon': Icons.logout_outlined},
  ];

  RxList<TextForm>? savedJobs = <TextForm>[].obs;
  RxList<JobData>? jobs = <JobData>[].obs;
  RxBool? showPayFrq = false.obs;
  RxBool? showDays = false.obs;
  JobData? addNewJob;

  RxList<TextForm>? controllers = RxList<TextForm>([
    TextForm(title: "Job name", controller: TextEditingController(text: '')),
    TextForm(title: "Wage/hr", controller: TextEditingController(text: '')),
    TextForm(title: "Job color", controller: TextEditingController(text: '0xff16a34a')),
    TextForm(title: "Last pay cheque date", controller: TextEditingController(text: '')),
    TextForm(title: "Pay frequency", controller: TextEditingController(text: '')),
    TextForm(title: "Week start", controller: TextEditingController(text: '')),
    TextForm(title: "Stat pay", controller: TextEditingController(text: '')),
  ]);

  void changeScreen(screen) {
    switch (screen) {
      case "Active Jobs":
        Get.to(() => ActiveJobs());
        break;

      case "Payment Accounts":
        Get.to(() => PaymentMethodsScreen());
        break;

      case "Settings":
        Get.to(() => ActiveJobs());
        break;

      case "Permissions":
        Get.to(() => ActiveJobs());
        break;
      case "Privacy Policy":
        Get.to(() => ActiveJobs());
        break;
      case "logout":
        Get.to(() => ActiveJobs());
        break;
    }
  }

  final GlobalKey<FormState> controllerValidator = GlobalKey<FormState>();
  Rx<JobStatus>? status = Rx<JobStatus>(JobStatus.create);

  /// ---------------- PUBLIC METHODS ----------------

  void loadSavedJobs() async {
    final listData = await getLocalData('savedJobs') ?? '';
    jobs!.clear();
    if (listData != '') {
      final job = Job.fromJson(jsonDecode(listData));
      for (final files in job.data ?? const <JobData>[]) {
        jobs!.add(files);
      }

      if (jobs!.isNotEmpty) {
        shift.selectedJob.value = jobs!.first;
        shift.selectedJob.refresh();
      }
    }
    jobs!.refresh();
  }

  Future<bool> createNewJob() async {
    final listData = await getLocalData('savedJobs') ?? '';
    Job job;

    if (status!.value == JobStatus.create) {
      addNewJob = null;
    }

    if (controllers!.any((test) => test.controller.text.isEmpty)) {
      showSnackBar('Missing details', 'Please fill all required fields before continuing.');
      return false;
    }

    final newItem = JobData(
      id: addNewJob == null ? Random().nextInt(500000) : addNewJob!.id,
      jobName: controllers![0].controller.text,
      wageHr: controllers![1].controller.text,
      jobColor: controllers![2].controller.text,
      lastPayChequeDate: controllers![3].pickedDate,
      payFrequency: controllers![4].controller.text,
      weekStart: controllers![5].controller.text,
      statPay: controllers![6].controller.text,
    );

    print(newItem.id);

    job = listData.isEmpty ? Job(status: 1, message: 'created data', data: []) : Job.fromJson(jsonDecode(listData));

    Get.back();

    switch (status!.value) {
      case JobStatus.create:
        job.data!.add(newItem);
        showSnackBar('Created', "New job has been created");
        break;

      case JobStatus.edit:
        final index = job.data!.indexWhere((t) => addNewJob!.id == t.id);
        if (index >= 0) job.data![index] = newItem;
        showSnackBar('Success', "Job has been edited");
        break;

      case JobStatus.delete:
        job.data!.removeWhere((t) => addNewJob!.id == t.id);
        showSnackBar('Success', "Job has been deleted");
        break;
    }

    await saveLocalData('savedJobs', jsonEncode(job.toJson()));
    loadSavedJobs(); // refresh jobs immediately
    return true;
  }

// hours from shift (prefer start/end - break, fallback to totalHours string)
  double shiftHours(AllShifts s) => (s.start == null || s.end == null)
      ? (double.tryParse((s.totalHours ?? '').trim()) ?? 0.0)
      : (((s.end!.difference(s.start!).inMinutes - (s.breakMin ?? 0)) <= 0)
          ? 0.0
          : (s.end!.difference(s.start!).inMinutes - (s.breakMin ?? 0)) / 60.0);

// pay from shift
  double shiftPay(AllShifts s) => s.income ?? 0.0;
  int weekStartFromString(String? s) =>
      const {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      }[(s ?? '').trim().toLowerCase()] ??
      DateTime.monday;

  Map<DateTime, PayCell> buildPayCellsForMonth({int bufferDays = 14}) {
    // --- tiny helpers ---
    DateTime dayKey(DateTime d) => DateUtils.dateOnly(d);

    DateTime startOfWeek(DateTime d, int weekStart) => dayKey(d.subtract(Duration(days: (d.weekday - weekStart + 7) % 7)));

    DateTime endOfWeek(DateTime d, int weekStart) => dayKey(startOfWeek(d, weekStart).add(const Duration(days: 6)));

    ({DateTime start, DateTime end}) periodFromPayDate({
      required DateTime payDate,
      required int cycleLenDays,
      required int weekStartDow,
    }) {
      final pay = dayKey(payDate);
      final thisWeekEnd = endOfWeek(pay, weekStartDow);

      // ✅ pick week-end BEFORE payDate
      final periodEnd = thisWeekEnd.isAfter(pay) ? dayKey(thisWeekEnd.subtract(const Duration(days: 7))) : thisWeekEnd;

      final periodStart = dayKey(periodEnd.subtract(Duration(days: cycleLenDays - 1)));
      return (start: periodStart, end: periodEnd);
    }

    // Prefer start/end/break over totalHours string
    double shiftHours(AllShifts s) {
      final st = s.start, en = s.end;
      if (st != null && en != null) {
        final mins = en.difference(st).inMinutes - (s.breakMin ?? 0);
        return mins <= 0 ? 0.0 : mins / 60.0;
      }
      final txt = (s.totalHours ?? '').trim();
      final asDouble = double.tryParse(txt);
      if (asDouble != null) return asDouble;
      final parts = txt.split(':');
      if (parts.length == 2) {
        final h = double.tryParse(parts[0]) ?? 0;
        final m = double.tryParse(parts[1]) ?? 0;
        return h + (m / 60.0);
      }
      return 0.0;
    }

    // --- month window ---
    final focused = shift.selectedMonth!.value;

    final start = dayKey(DateTime(focused.year, focused.month, 1).subtract(Duration(days: bufferDays)));

    final end = dayKey(DateTime(focused.year, focused.month + 1, 0).add(Duration(days: bufferDays)));

    // --- index shifts by day for fast summing ---
    final shiftsByDay = <DateTime, List<AllShifts>>{};
    for (final m in shift.shiftModel.value?.data ?? const <ShiftMonth>[]) {
      for (final day in m.dates ?? const <ShiftDay>[]) {
        for (final s in day.data ?? const <AllShifts>[]) {
          final k = dayKey(s.date ?? s.start ?? DateTime.now());
          (shiftsByDay[k] ??= <AllShifts>[]).add(s);
        }
      }
    }

    ({double pay, double hours}) sumJobPeriod(int jobId, DateTime a, DateTime b) {
      double pay = 0.0, hours = 0.0;
      for (var d = a; !d.isAfter(b); d = dayKey(d.add(const Duration(days: 1)))) {
        for (final s in shiftsByDay[d] ?? const <AllShifts>[]) {
          if (s.jobFrom?.id != jobId) continue;
          pay += (s.income ?? 0.0);
          hours += shiftHours(s);
        }
      }
      return (pay: pay, hours: hours);
    }

    // --- build pay cells ---
    final out = <DateTime, List<PayJobLine>>{};

    for (final j in jobs ?? const <JobData>[]) {
      final anchorPayDate = j.lastPayChequeDate;
      final jobId = j.id;
      if (anchorPayDate == null || jobId == null) continue;

      final step = payFrequency[j.payFrequency] ?? 0; // 7 / 14 etc.
      if (step <= 0) continue;

      // IMPORTANT: you said weekStart is known from job
      // Add this field to JobData: int? weekStartDow (DateTime.sunday/monday/etc.)

      final name = j.jobName ?? 'Job';
      final color = Color(int.parse(j.jobColor!)); // if your jobColor is already an int string

      var payDate = dayKey(anchorPayDate);

      // Jump forward into the visible window (fast)
      if (payDate.isBefore(start)) {
        final diff = start.difference(payDate).inDays;
        final jumps = (diff / step).ceil();
        payDate = dayKey(payDate.add(Duration(days: jumps * step)));
      }

      while (!payDate.isAfter(end)) {
        final p = periodFromPayDate(
          payDate: payDate,
          cycleLenDays: step,
          weekStartDow: weekStartFromString(j.weekStart),
        );

        final totals = sumJobPeriod(jobId, p.start, p.end);

        final line = PayJobLine(
          jobId: jobId,
          jobName: name,
          color: color,
          payDate: payDate,
          periodStart: p.start,
          periodEnd: p.end,
          payTotal: totals.pay,
          hoursTotal: totals.hours,
        );

        (out[payDate] ??= <PayJobLine>[]).add(line);
        payDate = dayKey(payDate.add(Duration(days: step)));
      }
    }

    return out.map((k, v) => MapEntry(k, PayCell(v)));
  }
}
