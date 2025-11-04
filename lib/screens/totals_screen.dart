
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Working UI/app_controller.dart';
import '../utils/ics_export.dart';
import 'analytic_screen.dart';

class TotalsScreen extends StatelessWidget {
  const TotalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final fmt = NumberFormat.simpleCurrency(name: 'CAD');
    return Obx(() {
      final t = c.weeklyTotalsUI();
      final perJob = t['perJob'] as Map<String, Map<String, double>>;
      final combined = t['combined'] as Map<String, double>;
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Totals & Pay (UI Week)')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final j in c.jobs)
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: c.jobColor(j.colorHex), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(j.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('@ \${fmt.currencySymbol}\${j.wage.toStringAsFixed(2)}/hr', style: const TextStyle(color: Colors.grey)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _MiniStat(title: 'Hours', value: (perJob[j.id]!['hours'] ?? 0.0).toStringAsFixed(2)),
                      _MiniStat(title: 'Overtime', value: (perJob[j.id]!['overtime'] ?? 0.0).toStringAsFixed(2)),
                      _MiniStat(title: 'Est. Pay', value: fmt.format(perJob[j.id]!['pay'] ?? 0.0)),
                    ]),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Combined (All Jobs)', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _MiniStat(title: 'Total Hours', value: (combined['hours'] ?? 0.0).toStringAsFixed(2)),
                    _MiniStat(title: 'Total OT', value: (combined['overtime'] ?? 0.0).toStringAsFixed(2)),
                    _MiniStat(title: 'Total Pay', value: fmt.format(combined['pay'] ?? 0.0)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => exportCurrentWeekAsIcs(context),
              icon: const Icon(Icons.ios_share),
              label: const Text('Export current week to .ics'),
            ),
          ],
        ),
      );
    });
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  const _MiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ]));
  }
}
