import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'salary_detailed_screen.dart';
import '../controllers/app_controller.dart';
import '../models/shift.dart';
import '../utils/time_utils.dart';
import 'shift_form.dart';
import 'import_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _DayEvent {
  final String type; // 'shift', 'stat', 'payday'
  final String? jobId;
  final Shift? shift;
  _DayEvent(this.type, {this.jobId, this.shift});
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ====== NEW: helpers for edit / delete from calendar bottom sheet ======
  void _openEditShift(AppController c, Shift s) {
    // If your ShiftForm uses a different param name (e.g. initial: s),
    // change `existing:` below to match your constructor.
    Get.bottomSheet(ShiftForm(existing: s), isScrollControlled: true);
  }

  Future<void> _confirmDeleteShift(AppController c, Shift s) async {
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
    if (ok == true) c.deleteShift(s.id);
  }
  // ======================================================================

  Iterable<DateTime> _paydaysForJobInRange(AppController c, DateTime from, DateTime to, String jobId) sync* {
    final j = c.jobs.firstWhereOrNull((e) => e.id == jobId);
    if (j == null) return;
    final base = c.parseIso(j.lastPaychequeIso);
    if (base == null) return;
    final step = j.payFrequency == 'biweekly' ? 14 : 7;
    var d = base;
    while (d.isBefore(from)) d = d.add(Duration(days: step));
    while (!d.isAfter(to)) {
      yield d;
      d = d.add(Duration(days: step));
    }
  }

  List<_DayEvent> _eventsForDay(AppController c, DateTime day) {
    final y = ymd(day);
    final shifts = c.shifts.where((s) => s.date == y).toList();
    final events = <_DayEvent>[];
    for (final s in shifts) {
      final job = c.jobs.firstWhereOrNull((j) => j.id == s.jobId);
      if (job == null) continue;
      final isStat = job.statDays.contains(y);
      events.add(_DayEvent(isStat ? 'stat' : 'shift', jobId: s.jobId, shift: s));
    }
    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1).subtract(const Duration(days: 7));
    final monthEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 1).add(const Duration(days: 7));
    for (final j in c.jobs) {
      for (final d in _paydaysForJobInRange(c, monthStart, monthEnd, j.id)) {
        if (d.year == day.year && d.month == day.month && d.day == day.day) {
          events.add(_DayEvent('payday', jobId: j.id));
        }
      }
    }
    return events;
  }

  void _openDaySheet(AppController c, DateTime day) {
    final y = ymd(day);
    final events = _eventsForDay(c, day);
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
                  final j = c.jobs.firstWhereOrNull((x) => x.id == p.jobId);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: c.jobColor(j?.colorHex ?? '#16a34a'),
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
                final j = c.jobs.firstWhereOrNull((x) => x.id == s.jobId);
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
                    await _confirmDeleteShift(c, s);
                    return false; // handled manually
                  },
                  child: InkWell(
                    onTap: () => _openEditShift(c, s),
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
                              color: c.jobColor(j?.colorHex ?? '#16a34a'),
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
                                    onPressed: () => _openEditShift(c, s),
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () => _confirmDeleteShift(c, s),
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

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Obx(() => Scaffold(
          appBar: AppBar(
            title: const Text('Calendar'),
            actions: [
              IconButton(
                tooltip: 'Import from photo',
                onPressed: () => Get.to(() => const ImportScreen()),
                icon: const Icon(Icons.document_scanner_outlined),
              ),
            ],
          ),
          body: Column(children: [
            TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _openDaySheet(c, selected);
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: c.settings.value.weekStartsOnMonday ? StartingDayOfWeek.monday : StartingDayOfWeek.sunday,
              headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: true,
                todayDecoration: BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                markersMaxCount: 4,
              ),
              eventLoader: (day) => _eventsForDay(c, day),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  final ctr = Get.find<AppController>();
                  final shifts = events.where((e) => (e as _DayEvent).type == 'shift').cast<_DayEvent>().toList();
                  final stats = events.where((e) => (e as _DayEvent).type == 'stat').cast<_DayEvent>().toList();
                  final pays = events.where((e) => (e as _DayEvent).type == 'payday').cast<_DayEvent>().toList();

                  final dots = <Widget>[];
                  for (final e in shifts.take(3)) {
                    final job = ctr.jobs.firstWhereOrNull((j) => j.id == e.jobId);
                    dots.add(Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: ctr.jobColor(job?.colorHex ?? '#16a34a'),
                        shape: BoxShape.circle,
                      ),
                    ));
                  }

                  // Payday badge follows job color
                  Color paydayBg = Colors.green.shade700;
                  Color paydayFg = Colors.white;
                  if (pays.isNotEmpty) {
                    final firstPay = pays.first;
                    final job = ctr.jobs.firstWhereOrNull((j) => j.id == firstPay.jobId);
                    paydayBg = ctr.jobColor(job?.colorHex ?? '#16a34a');
                    paydayFg = paydayBg.computeLuminance() < 0.5 ? Colors.white : Colors.black;
                  }

                  return Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(mainAxisSize: MainAxisSize.min, children: dots),
                      ),
                    ),
                    if (pays.isNotEmpty)
                      Positioned(
                        right: -1,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: paydayBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: paydayFg.withOpacity(.25)),
                          ),
                          child: Text(
                            '\$',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: paydayFg,
                            ),
                          ),
                        ),
                      ),
                    if (stats.isNotEmpty)
                      const Positioned(
                        left: -1,
                        top: -4,
                        child: Icon(Icons.star, size: 10, color: Color(0xFFFFC107)),
                      ),
                  ]);
                },
              ),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.all(12), children: [
                _MonthSummary(month: _focusedDay),
                const SizedBox(height: 8),
                _PayPeriods(),
              ]),
            ),
          ]),
        ));
  }
}

class _MonthSummary extends StatelessWidget {
  final DateTime month;
  const _MonthSummary({required this.month});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final perJob = c.monthSummary(month);
    final combined = perJob.values.fold<Map<String, double>>(
      {'hours': 0.0, 'pay': 0.0},
      (a, b) {
        a['hours'] = (a['hours'] ?? 0) + (b['hours'] ?? 0);
        a['pay'] = (a['pay'] ?? 0) + (b['pay'] ?? 0);
        return a;
      },
    );
    return GestureDetector(
      onTap: () => Get.to(
        () => SalaryDetailsScreen(month: month),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Month Summary — ${month.month}/${month.year}", style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final j in c.jobs)
              ListTile(
                dense: true,
                leading: CircleAvatar(backgroundColor: c.jobColor(j.colorHex), radius: 6),
                title: Text(j.name),
                trailing: Text(
                  "${(perJob[j.id]!['hours'] ?? 0.0).toStringAsFixed(1)} h   •   \$${(perJob[j.id]!['pay'] ?? 0.0).toStringAsFixed(2)}",
                ),
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Combined: ${(combined['hours'] ?? 0).toStringAsFixed(1)} h • \$${(combined['pay'] ?? 0).toStringAsFixed(2)}",
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PayPeriods extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final j in c.jobs) _JobPeriods(jid: j.id),
      ],
    );
  }
}

class _JobPeriods extends StatelessWidget {
  final String jid;
  const _JobPeriods({required this.jid});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final j = c.jobs.firstWhere((x) => x.id == jid);
    final series = c.periodsAround(j, back: 0, forward: 2);
    final next = c.nextDeposit(j);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: c.jobColor(j.colorHex), radius: 6),
            const SizedBox(width: 8),
            Text(
              "${j.name} — ${j.payFrequency == "biweekly" ? "Biweekly" : "Weekly"}",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (next != null)
              Text(
                "Next deposit: ${monthDay(next)} "
                "${next.hour.toString().padLeft(2, '0')}:"
                "${next.minute.toString().padLeft(2, '0')}",
              ),
          ]),
          const SizedBox(height: 8),
          Column(
            children: [
              for (final p in series)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PeriodRow(period: p),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final dynamic period;
  const _PeriodRow({required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232427)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${monthDay(period.start)} → ${monthDay(period.end)}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "Hours: ${period.hours.toStringAsFixed(2)}   •   OT: ${period.overtime.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Est. Cheque", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                "\$${period.pay.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_money, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  Text(
                    "Deposit: ${monthDay(period.deposit)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final dynamic period;
  const _PeriodCard({required this.period});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF121315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232427)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${monthDay(period.start)} → ${monthDay(period.end)}", style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text("Hours: ${period.hours.toStringAsFixed(2)}"),
        Text("OT: ${period.overtime.toStringAsFixed(2)}"),
        Text("Est. Cheque: \$${period.pay.toStringAsFixed(2)}"),
        const SizedBox(height: 4),
        Text("Deposit: ${monthDay(period.deposit)}"),
      ]),
    );
  }
}
