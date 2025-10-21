import 'package:emptyproject/Working%20UI/Shift/Calendar.dart';
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

class ShiftController extends GetxController {
  RxString? activeShift = "Calendar".obs;
  Rx<Widget>? shiftScreen = Rx<Widget>(Calendar());
  Rx<DateTime> focusedDay = DateTime.now().obs;
  Rx<DateTime>? selectedDay;

  void openEditShift(AppController c, Shift s) {
    Get.bottomSheet(ShiftForm(existing: s), isScrollControlled: true);
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
