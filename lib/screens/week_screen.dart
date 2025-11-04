import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Working UI/app_controller.dart';
import '../models/shift.dart';
import '../utils/time_utils.dart';
import 'analytic_screen.dart';
import 'shift_form.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Obx(() => Scaffold(
      appBar: AppBar(
        // Show the week range in the title (reactive)
        title: Text(
          "${formatShort(c.currentWeekStart.value)} — "
              "${formatShort(c.currentWeekStart.value.add(const Duration(days: 6)))}",
        ),
        actions: [
          IconButton(onPressed: c.prevWeek, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: c.nextWeek, icon: const Icon(Icons.chevron_right)),
          TextButton(onPressed: c.thisWeek, child: const Text('This Week')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [for (int i = 0; i < 7; i++) _DayCard(index: i)],
      ),
    ));
  }
}

class _DayCard extends StatelessWidget {
  final int index;
  const _DayCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final day = c.weekDays[index];
    final dateStr = ymd(day);
    final items = c.shiftsOn(dateStr);
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              "${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index]}  •  ${formatShort(day)}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () => _openForm(dateStr),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Shift'),
            ),
          ]),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Text('No shifts', style: TextStyle(color: Colors.grey))
          else
            ...items.map((s) => _ShiftTile(s: s)),
        ]),
      ),
    );
  }

  void _openForm(String date) =>
      Get.bottomSheet(ShiftForm(initialDate: date), isScrollControlled: true);
}

class _ShiftTile extends StatelessWidget {
  final Shift s;
  const _ShiftTile({required this.s});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final job = c.jobs.firstWhereOrNull((j) => j.id == s.jobId);
    final color = job != null ? c.jobColor(job.colorHex) : Colors.grey;
    final int mins =
    (minutesBetween(s.start, s.end) - s.breakMin).clamp(0, 24 * 60);
    final double hours = mins / 60.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF121315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232427)),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 48,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job?.name ?? 'Job', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              "${s.start} → ${s.end}  •  Break ${s.breakMin}m  •  ${hours.toStringAsFixed(2)} h",
              style: const TextStyle(color: Colors.grey),
            ),
            if (s.notes!.isNotEmpty) Text(s.notes!, style: const TextStyle(color: Colors.grey)),
          ]),
        ),
        IconButton(
          onPressed: () => Get.bottomSheet(ShiftForm(existing: s), isScrollControlled: true),
          icon: const Icon(Icons.edit),
        ),
        IconButton(onPressed: () => c.deleteShift(s.id), icon: const Icon(Icons.delete_outline)),
      ]),
    );
  }
}
