import 'package:emptyproject/Working%20UI/Shift/Calendar.dart';
import 'package:emptyproject/Working%20UI/Shift/Deposit.dart';
import 'package:emptyproject/Working%20UI/Shift/Overview.dart';
import 'package:emptyproject/Working%20UI/Shift/Projection.dart';
import 'package:emptyproject/Working%20UI/app_controller.dart';
import 'package:emptyproject/models/shift.dart';
import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:emptyproject/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum shiftEnums {
  calendar,
  overview,
  deposits,
  projections,
}

class DayEvent {
  final String type; // 'shift', 'stat', 'payday'
  final String? jobId;
  final Shift? shift;
  DayEvent(this.type, {this.jobId, this.shift});
}

class ShiftController extends GetxController {
  RxString? activeShift = "Calendar".obs;
  Rx<Widget>? shiftScreen = Rx<Widget>(Calendar());
  Rx<DateTime> focusedDay = DateTime.now().obs;
  Rx<DateTime>? selectedDay = DateTime.now().obs;
  RxString? period = 'weekly'.obs; // weekly | biweekly | monthly
  RxString? metric = 'net'.obs; // net | gross | hours | ot
  RxString? baseline = 'last'.obs; // last | avg
  RxList jobs = <String>[].obs; // selected jobIds

  // Deposits tab
  RxInt? depositLookBack = 3.obs;
  RxInt? depositLookForward = 3.obs;

  // Projection tab
  final projHours = <String, double>{}.obs; // jobId -> hours (per "period" below)
  final projScope = 'weekly'.obs; // weekly | biweekly | monthly

  void initJobs(Iterable<String> ids) {
    if (jobs.isEmpty) {
      jobs.addAll(ids);
    }
    // default proj hours (per job) if empty
    for (final id in ids) {
      projHours.putIfAbsent(id, () => 30.0);
    }
  }

  void openEditShift(AppController c, Shift s) {
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
    final base = j.lastPaychequeIso;
    if (base == null) return;
    final step = j.payFrequency == 'biweekly' ? 14 : 7;
    var d = base;
    while (d.isBefore(from)) {
      d = d.add(Duration(days: step));
    }
    while (!d.isAfter(to)) {
      yield d;
      d = d.add(Duration(days: step));
    }
  }

  List<DayEvent> eventsForDay(AppController c, DateTime day) {
    final y = ymd(day);
    final shifts = c.shifts.where((s) => s.date == y).toList();
    final events = <DayEvent>[];
    for (final s in shifts) {
      final job = c.jobs.firstWhereOrNull((j) => j.id == s.jobId);
      if (job == null) continue;
      final isStat = job.statDays.contains(y);
      events.add(DayEvent(isStat ? 'stat' : 'shift', jobId: s.jobId, shift: s));
    }
    final monthStart = DateTime(focusedDay.value.year, focusedDay.value.month, 1).subtract(const Duration(days: 7));
    final monthEnd = DateTime(focusedDay.value.year, focusedDay.value.month + 1, 1).add(const Duration(days: 7));
    for (final j in c.jobs) {
      for (final d in _paydaysForJobInRange(c, monthStart, monthEnd, j.id)) {
        if (d.year == day.year && d.month == day.month && d.day == day.day) {
          events.add(DayEvent('payday', jobId: j.id));
        }
      }
    }
    return events;
  }

  void openDaySheet(AppController c, DateTime day) {
    final y = ymd(day);
    final events = eventsForDay(c, day);
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
                    onTap: () => openEditShift(c, s),
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
                                    onPressed: () => openEditShift(c, s),
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

  bool _isStat = false; // UI switch state

  @override
  void initState() {
    super.initState();
    final c = Get.find<AppController>();
    jobId = widget.existing?.jobId ?? (c.jobs.isNotEmpty ? c.jobs.first.id : "");
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
    final job = c.jobs.firstWhereOrNull((j) => j.id == jobId);
    final d = dateCtl.text.trim();
    setState(() => _isStat = job != null && job.statDays.contains(d));
  }

  void _applyStatToJob(bool v) {
    final c = Get.find<AppController>();
    final idx = c.jobs.indexWhere((j) => j.id == jobId);
    if (idx < 0) return;
    final job = c.jobs[idx];
    final d = dateCtl.text.trim();
    if (v) {
      if (!job.statDays.contains(d)) job.statDays.add(d);
    } else {
      job.statDays.remove(d);
    }
    c.jobs[idx] = job; // trigger GetX update
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

          DropdownButtonFormField<String>(
            value: jobId.isNotEmpty ? jobId : null,
            items: [
              for (final j in c.jobs) DropdownMenuItem(value: j.id, child: Text(j.name)),
            ],
            onChanged: (v) {
              setState(() => jobId = v ?? jobId);
              _syncStatFromJobAndDate();
            },
            decoration: const InputDecoration(labelText: 'Job', isDense: true),
          ),
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
          Builder(builder: (_) {
            final job = c.jobs.firstWhereOrNull((j) => j.id == jobId);
            final mult = job?.statMultiplier ?? 1.5;
            return SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Stat day (holiday)'),
              subtitle: Text('Apply ${mult.toStringAsFixed(2)}× pay for this date'),
              value: _isStat,
              onChanged: (v) {
                setState(() => _isStat = v);
                _applyStatToJob(v);
              },
            );
          }),
          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed: () {
              if (jobId.isEmpty) return;
              final newShift = Shift(
                id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                jobId: jobId,
                date: dateCtl.text.trim(),
                start: startCtl.text.trim(),
                end: endCtl.text.trim(),
                breakMin: int.tryParse(breakCtl.text.trim()) ?? 0,
                notes: notesCtl.text.trim(),
              );
              final c = Get.find<AppController>();
              if (widget.existing == null) {
                c.addShift(newShift);
              } else {
                c.updateShift(widget.existing!.id, newShift);
              }
              Get.back(); // close sheet
            },
            icon: const Icon(Icons.save),
            label: Text(widget.existing == null ? 'Add Shift' : 'Save Changes'),
          ),
        ]),
      ),
    );
  }
}
