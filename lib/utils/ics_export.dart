import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../Working UI/app_controller.dart';

String _z(DateTime d) {
  final utc = d.toUtc();
  String two(int n) => n < 10 ? '0$n' : '$n';
  return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

Future<void> exportCurrentWeekAsIcs(BuildContext context) async {
  final c = Get.find<AppController>();
  final start = c.currentWeekStart.value;
  final end = start.add(const Duration(days: 6));

  final buf = StringBuffer('BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Two Job Shift Planner//EN\n');
  for (final s in c.shifts) {
    final d = DateTime.parse('${s.date}T00:00:00');
    if (d.isBefore(start.subtract(const Duration(days: 1))) || d.isAfter(end.add(const Duration(days: 1)))) continue;
    final sh = int.parse(s.start!.substring(0, 2));
    final sm = int.parse(s.start!.substring(3, 5));
    final eh = int.parse(s.end!.substring(0, 2));
    final em = int.parse(s.end!.substring(3, 5));
    final localStart = DateTime(d.year, d.month, d.day, sh, sm);
    var localEnd = DateTime(d.year, d.month, d.day, eh, em);
    if (eh * 60 + em < sh * 60 + sm) localEnd = localEnd.add(const Duration(days: 1));
    final desc = 'Unpaid break: ${s.breakMin} min\\nNotes: ${s.notes!.replaceAll('\n', ' ')}';
    // final jobName = Get.find<AppController>().jobs.firstWhereOrNull((j) => j.id == s.jobId)?.name ?? 'Shift';
    // buf.write('BEGIN:VEVENT\nUID:${s.id}@twojob\nDTSTAMP:${_z(DateTime.now())}\nSUMMARY:$jobName\nDESCRIPTION:$desc\nDTSTART:${_z(localStart)}\nDTEND:${_z(localEnd)}\nEND:VEVENT\n');
  }
  buf.write('END:VCALENDAR');

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/shifts_${start.month}-${start.day}_to_${end.month}-${end.day}.ics');
  await file.writeAsString(buf.toString());
  await Share.shareXFiles([XFile(file.path)], text: 'My shifts this week');
}
