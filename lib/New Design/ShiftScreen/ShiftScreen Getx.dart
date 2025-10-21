import 'dart:math';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/models/period%20stat.dart';
import 'package:emptyproject/models/settings.dart';
import 'package:emptyproject/models/shift.dart';
import 'package:emptyproject/models/tax_config.dart';
import 'package:emptyproject/screens/shift_form.dart';
import 'package:emptyproject/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DayEvent {
  final String type; // 'shift', 'stat', 'payday'
  final String? jobId;
  final Shift? shift;
  DayEvent(this.type, {this.jobId, this.shift});
}

class PayPeriod {
  final DateTime start;
  final DateTime end;
  final DateTime deposit;
  final double hours;
  final double overtime;
  final double pay;
  PayPeriod({required this.start, required this.end, required this.deposit, required this.hours, required this.overtime, required this.pay});
}

class ShiftScreenController extends GetxController {
  Rx<DateTime>? focusedDay = DateTime.now().obs;
  Rx<DateTime>? selectedDay = DateTime.now().obs;
  RxList shifts = <Shift>[].obs;
  final settings = AppSettings(weekStartsOnMonday: true, overtimeEnabled: true, overtimeThresholdWeekly: 40).obs;
  double estimateNetForPeriod(Job j, PayPeriod p) => toPeriodStat(j, p).net;
  final taxes = <String, TaxConfig>{}.obs;
  TaxConfig taxFor(String jobId) => taxes[jobId] ?? TaxConfig(jobId: jobId);
  PeriodStat toPeriodStat(Job j, PayPeriod p) {
    final t = taxFor(j.id);
    final gross = p.pay;

    final income = gross * (t.incomeTaxPct / 100.0);
    final cpp    = gross * (t.cppPct       / 100.0);
    final ei     = gross * (t.eiPct        / 100.0);
    final other  = gross * (t.otherPct     / 100.0);
    final preNet = (gross - (income + cpp + ei + other)).clamp(0, double.infinity).toDouble();

    // post-tax expense %, if your TaxConfig has it; else 0
    final post = preNet * ((t.postTaxExpensePct ?? 0) / 100.0);
    final net = (preNet - post).clamp(0, double.infinity).toDouble();

    // simple estimate of stat uplift (what portion came from stat multiplier vs base)
    final statUplift = max(0.0, (j.statMultiplier - 1.0)) * (p.hours == 0 ? 0 : (p.pay / j.statMultiplier - (p.pay - (j.statMultiplier - 1) * j.wage * (p.hours))));

    return PeriodStat(
      start: p.start, end: p.end,
      gross: gross, net: net, hours: p.hours, ot: p.overtime,
      income: income, cpp: cpp, ei: ei, other: other, post: post, statUplift: statUplift,
    );
  }
  RxList jobs = <Job>[
    Job(
        id: 'starbucks',
        name: 'Starbucks',
        colorHex: '#16a34a',
        wage: 0,
        payFrequency: 'weekly',
        lastPaychequeIso: null,
        weekStartDOW: 4,
        statMultiplier: 1.5,
        statDays: []),
    Job(
        id: 'superstore',
        name: 'Superstore',
        colorHex: '#2563eb',
        wage: 16,
        payFrequency: 'weekly',
        lastPaychequeIso: null,
        weekStartDOW: 7,
        statMultiplier: 1.5,
        statDays: []),
  ].obs;
  int lenDays(Job j) => j.payFrequency == 'biweekly' ? 14 : 7;

  PayPeriod computePeriod(Job j, DateTime anchorStart) {
    final len = lenDays(j);
    final start = DateTime(anchorStart.year, anchorStart.month, anchorStart.day, 0, 0);
    final end = start.add(Duration(days: len)).subtract(const Duration(minutes: 1));
    final deposit = start.add(Duration(days: len));
    double hours = 0.0;
    double statHours = 0.0;
    for (final s in shifts.where((x) => x.jobId == j.id)) {
      final d = DateTime.parse('${s.date}T00:00:00');
      if (!d.isBefore(start) && !d.isAfter(end)) {
        final num mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
        final double h = mins / 60.0;
        hours += h;
        if (j.statDays.contains(s.date)) statHours += h;
      }
    }
    final bool overtimeOn = settings.value.overtimeEnabled;
    final double weeklyThr = settings.value.overtimeThresholdWeekly.toDouble();
    final double thrForPeriod = (len / 7.0).ceil() * weeklyThr;
    final double over = overtimeOn ? (hours - thrForPeriod).clamp(0.0, double.infinity) : 0.0;

    final double rateOT = 1.5;
    final double rateStat = j.statMultiplier;
    final double bestStatRate = rateStat >= rateOT ? rateStat : rateOT;

    final double nonStatHours = (hours - statHours).clamp(0.0, hours);
    double nonStatOver = over.clamp(0.0, nonStatHours);
    double statOverRemainder = (over - nonStatOver).clamp(0.0, statHours);

    final double nonStatReg = nonStatHours - nonStatOver;
    final double statReg = statHours - statOverRemainder;

    final double pay = nonStatReg * j.wage + nonStatOver * j.wage * rateOT + statReg * j.wage * rateStat + statOverRemainder * j.wage * bestStatRate;

    return PayPeriod(start: start, end: end, deposit: deposit, hours: hours, overtime: over, pay: pay);
  }

  DateTime? nextDeposit(Job j) {
    final base = parseIso(j.lastPaychequeIso);
    if (base == null) return null;
    final len = lenDays(j);
    final now = DateTime.now();
    int n = ((now.difference(base).inDays) / len).ceil();
    return base.add(Duration(days: n * len));
  }

  Map<String, Map<String, double>> monthSummary(DateTime month) {
    // month range [start, end)
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    // init per-job buckets
    final perJob = <String, Map<String, double>>{
      for (final j in jobs) j.id: {'hours': 0.0, 'pay': 0.0}
    };

    for (final s in shifts) {
      // shift date is stored as 'YYYY-MM-DD'
      final sd = DateTime.parse(s.date);
      if (sd.isBefore(start) || !sd.isBefore(end)) continue;

      final job = jobs.firstWhereOrNull((j) => j.id == s.jobId);
      if (job == null) continue;

      final mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
      final hours = (mins / 60.0).toDouble();

      // --- STAT logic (this is the bit you asked about) ---
      final isStat = (s.isStat == true) || job.statDays.contains(s.date);
      final hourly = (job.wage * (isStat ? job.statMultiplier : 1.0)).toDouble();
      // ----------------------------------------------------

      perJob[job.id]!['hours'] = (perJob[job.id]!['hours'] ?? 0) + hours;
      perJob[job.id]!['pay'] = (perJob[job.id]!['pay'] ?? 0) + (hours * hourly);
    }

    return perJob;
  }

  List<PayPeriod> periodsAround(Job j, {int back = 0, int forward = 2}) {
    final base = parseIso(j.lastPaychequeIso) ?? DateTime.now();
    final len = lenDays(j);
    final now = DateTime.now();
    int n = ((now.difference(base).inDays) / len).floor();
    final firstStart = base.add(Duration(days: n * len));
    final out = <PayPeriod>[];
    for (int i = -back; i <= forward; i++) {
      final s = firstStart.add(Duration(days: i * len));
      out.add(computePeriod(j, s));
    }
    return out;
  }

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

  Iterable<DateTime> paydaysForJobInRange(DateTime from, DateTime to, String jobId) sync* {
    final j = jobs.firstWhereOrNull((e) => e.id == jobId);
    if (j == null) return;
    final base = parseIso(j.lastPaychequeIso);
    if (base == null) return;
    final step = j.payFrequency == 'biweekly' ? 14 : 7;
    var d = base;
    while (d.isBefore(from)) d = d.add(Duration(days: step));
    while (!d.isAfter(to)) {
      yield d;
      d = d.add(Duration(days: step));
    }
  }

  List<DayEvent> eventsForDay(DateTime day) {
    final y = ymd(day);
    final shift = shifts.where((s) => s.date == y).toList();
    final events = <DayEvent>[];
    for (final s in shift) {
      final job = jobs.firstWhereOrNull((j) => j.id == s.jobId);
      if (job == null) continue;
      final isStat = job.statDays.contains(y);
      events.add(DayEvent(isStat ? 'stat' : 'shift', jobId: s.jobId, shift: s));
    }
    final monthStart = DateTime(focusedDay!.value.year, focusedDay!.value.month, 1).subtract(const Duration(days: 7));
    final monthEnd = DateTime(focusedDay!.value.year, focusedDay!.value.month + 1, 1).add(const Duration(days: 7));
    for (final j in jobs) {
      for (final d in paydaysForJobInRange(monthStart, monthEnd, j.id)) {
        if (d.year == day.year && d.month == day.month && d.day == day.day) {
          events.add(DayEvent('payday', jobId: j.id));
        }
      }
    }
    return events;
  }

  Color jobColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void deleteShift(String id) => shifts.removeWhere((e) => e.id == id);

  Future<void> confirmDeleteShift(Shift s) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete shift?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Delete')),
        ],
      ),
      barrierDismissible: true,
    );
    if (ok == true) deleteShift(s.id);
  }

  void openEditShift(Shift s) {
    // If your ShiftForm uses a different param name (e.g. initial: s),
    // change `existing:` below to match your constructor.
    Get.bottomSheet(ShiftForm(existing: s), isScrollControlled: true);
  }

  void openDaySheet(DateTime day) {
    final y = ymd(day);
    final events = eventsForDay(day);
    final shifts = events.where((e) => e.type == 'shift' || e.type == 'stat').toList();
    final paydays = events.where((e) => e.type == 'payday').toList();

    Get.bottomSheet(
      DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1012),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ListView(controller: controller, children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Details — ${monthDay(day)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (paydays.isNotEmpty) ...[
              const Text('Payday(s)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final p in paydays)
                Builder(builder: (_) {
                  final j = jobs.firstWhereOrNull((x) => x.id == p.jobId);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: jobColor(j?.colorHex ?? '#16a34a'),
                      radius: 6,
                    ),
                    title: Text(j?.name ?? 'Job'),
                    trailing: const Text('Deposit'),
                  );
                }),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
            ],
            const Text('Shifts', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),

            if (shifts.isEmpty)
              const Text('No shifts on this day', style: TextStyle(color: Colors.grey))
            else
              // ====== NEW: editable shift items (tap edit, swipe delete, icons) ======
              ...shifts.map((e) {
                final s = e.shift!;
                final j = jobs.firstWhereOrNull((x) => x.id == s.jobId);
                final mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
                final hours = mins / 60.0;
                final isStat = e.type == 'stat';

                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB00020),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await confirmDeleteShift(s);
                    return false; // handled manually
                  },
                  child: InkWell(
                    onTap: () => openEditShift(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121315),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF232427)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 48,
                            decoration: BoxDecoration(
                              color: jobColor(j?.colorHex ?? '#16a34a'),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(j?.name ?? 'Job', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (isStat) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                                  ],
                                  const Spacer(),
                                  IconButton(
                                    tooltip: "Edit",
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => openEditShift(s),
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () => confirmDeleteShift(s),
                                  ),
                                ]),
                                const SizedBox(height: 2),
                                Text(
                                  "${s.start} → ${s.end}  •  Break ${s.breakMin}m  •  ${hours.toStringAsFixed(2)} h",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            // ========================================================================

            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Get.bottomSheet(
                ShiftForm(initialDate: y),
                isScrollControlled: true,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add shift'),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void openDateSheet(DateTime day) {
    final y = ymd(day);
    final events = eventsForDay(day);
    final shifts = events.where((e) => e.type == 'shift' || e.type == 'stat').toList();
    final paydays = events.where((e) => e.type == 'payday').toList();

    Get.bottomSheet(
      DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1012),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ListView(controller: controller, children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Details — ${monthDay(day)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (paydays.isNotEmpty) ...[
              const Text('Payday(s)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final p in paydays)
                Builder(builder: (_) {
                  final j = jobs.firstWhereOrNull((x) => x.id == p.jobId);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: jobColor(j?.colorHex ?? '#16a34a'),
                      radius: 6,
                    ),
                    title: Text(j?.name ?? 'Job'),
                    trailing: const Text('Deposit'),
                  );
                }),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
            ],
            const Text('Shifts', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),

            if (shifts.isEmpty)
              const Text('No shifts on this day', style: TextStyle(color: Colors.grey))
            else
              // ====== NEW: editable shift items (tap edit, swipe delete, icons) ======
              ...shifts.map((e) {
                final s = e.shift!;
                final j = jobs.firstWhereOrNull((x) => x.id == s.jobId);
                final mins = (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
                final hours = mins / 60.0;
                final isStat = e.type == 'stat';

                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB00020),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await confirmDeleteShift(s);
                    return false; // handled manually
                  },
                  child: InkWell(
                    onTap: () => openEditShift(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121315),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF232427)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 48,
                            decoration: BoxDecoration(
                              color: jobColor(j?.colorHex ?? '#16a34a'),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(j?.name ?? 'Job', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (isStat) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                                  ],
                                  const Spacer(),
                                  IconButton(
                                    tooltip: "Edit",
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => openEditShift(s),
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () => confirmDeleteShift(s),
                                  ),
                                ]),
                                const SizedBox(height: 2),
                                Text(
                                  "${s.start} → ${s.end}  •  Break ${s.breakMin}m  •  ${hours.toStringAsFixed(2)} h",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            // ========================================================================

            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Get.bottomSheet(
                ShiftForm(initialDate: y),
                isScrollControlled: true,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add shift'),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
