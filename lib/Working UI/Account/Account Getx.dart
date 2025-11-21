import 'dart:convert';
import 'dart:math';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Shared%20Preferences.dart';
import 'package:emptyproject/Working%20UI/Shift/Calendar.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:emptyproject/models/job.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum JobStatus { create, edit, delete }

class PayMarker {
  final String jobName;
  final Color color;
  const PayMarker({required this.jobName, required this.color});
}

class AccountController extends GetxController {
  final daysShort = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final payFrequency = ["Weekly", "By Weekly", "Monthly"];
  final colorChoices = ['0xff16a34a', '0xff2563eb', '0xffe11d48', '0xff0ea5e9', '0xff10b981', '0xfff59e0b', '0xff8b5cf6', '0xff14b8a6', '0xffef4444'];
  RxList<TextForm>? savedJobs = <TextForm>[].obs;
  RxList<JobData>? jobs = <JobData>[].obs;
  JobData? addNewJob;
  RxList<TextForm>? controllers = RxList<TextForm>([
    TextForm(
      title: "Job name",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Wage/hr",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Job color",
      controller: TextEditingController(text: '0xff16a34a'),
    ),
    TextForm(
      title: "Last pay cheque date",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Pay frequency",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Week start",
      controller: TextEditingController(text: ''),
    ),
    TextForm(
      title: "Stat pay (Ex 1.2 from base pay)",
      controller: TextEditingController(text: ''),
    ),
  ]);
  final GlobalKey<FormState> controllerValidator = GlobalKey<FormState>();
  Rx<JobStatus>? status = Rx<JobStatus>(JobStatus.create);
  void loadSavedJobs() async {
    final listData = await getLocalData('savedJobs') ?? '';
    Job job = Job.fromJson(jsonDecode(listData));
    jobs!.clear();
    for (var files in job.data!) {
      jobs!.add(files);
    }
    shift.selectedJob.value = jobs![0];
    shift.selectedJob.refresh();
    print(jobs);
  }

  void refreshData() {}

  Future<bool> createNewJob() async {
    final listData = await getLocalData('savedJobs') ?? '';
    Job job;

    final newItem = JobData(
      id: addNewJob == null ? Random().nextInt(500000) : addNewJob!.id,
      jobName: controllers![0].controller.text,
      wageHr: controllers![1].controller.text,
      jobColor: controllers![2].controller.text,
      lastPayChequeDate: controllers![3].controller.text,
      payFrequency: controllers![4].controller.text,
      weekStart: controllers![5].controller.text,
      statPay: controllers![6].controller.text,
    );
    job = listData == '' ? Job(status: 1, message: 'created data', data: [newItem]) : Job.fromJson(jsonDecode(listData));
    Get.back();
    switch (status!.value) {
      case JobStatus.create:
        job.data!.add(newItem);
        showSnackBar('Created', "New job has been created");
        break;
      case JobStatus.edit:
        int? index = job.data!.indexWhere((test) => addNewJob!.id == test.id);
        job.data![index] = newItem;
        showSnackBar('Success', "Job has been edited");
        break;
      case JobStatus.delete:
        job.data!.removeWhere((test) => addNewJob!.id == test.id);
        showSnackBar('Success', "Job has been deleted");
        break;
    }
    print('executed');
    await saveLocalData('savedJobs', jsonEncode(job.toJson()));
    return true;
  }

  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  DateTime _parseYmdSlashes(String s) {
    final p = s.split('/');
    if (p.length != 3) throw const FormatException('Bad date');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  int _stepDays(String? freq) {
    final v = (freq ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return (v.contains('biweek') || v.contains('byweek')) ? 14 : 7; // handles "By Weekly"
  }

  Color _parseColor(String? hex, {int fallback = 0xff999999}) {
    try {
      return Color(int.parse(hex ?? '$fallback'));
    } catch (_) {
      return Color(fallback);
    }
  }

  Map<DateTime, List<PayMarker>> computePayMarkers({
    required DateTime focusedDay,
    int bufferDays = 14,
  }) {
    // ---- tiny helpers ----
    DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
    DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
    int _stepDays(String? freq) {
      final v = (freq ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
      return (v.contains('biweek') || v.contains('byweek')) ? 14 : 7; // weekly default
    }

    DateTime _parseYmdSlashes(String s) {
      final p = s.split('/');
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    }

    Color _parseColor(String? hex) {
      try {
        return Color(int.parse(hex ?? '0xff999999'));
      } catch (_) {
        return const Color(0xff999999);
      }
    }

    // range (month ± buffer)
    final start = _day(DateTime(focusedDay.year, focusedDay.month, 1).subtract(Duration(days: bufferDays)));
    final end = _day(DateTime(focusedDay.year, focusedDay.month + 1, 0).add(Duration(days: bufferDays)));

    final out = <DateTime, List<PayMarker>>{};

    for (final j in (jobs?.toList() ?? const <JobData>[])) {
      final last = j.lastPayChequeDate;
      if (last == null || last.isEmpty) continue;

      DateTime d;
      try {
        d = _day(_parseYmdSlashes(last));
      } catch (_) {
        continue;
      }

      final step = _stepDays(j.payFrequency); // 7 or 14
      final color = _parseColor(j.jobColor);
      final name = j.jobName ?? 'Job';

      // jump to first payday >= start (calendar-day arithmetic)
      if (d.isBefore(start)) {
        final diff = _day(start).difference(d).inDays; // whole days
        final jumps = (diff / step).ceil();
        d = _addDays(d, jumps * step);
      }

      // walk the window
      for (; !d.isAfter(end); d = _addDays(d, step)) {
        final key = _day(d);
        (out[key] ??= <PayMarker>[]).add(PayMarker(jobName: name, color: color));
      }
    }

    return out;
  }
}
