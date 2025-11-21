import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/models/shift.dart';
import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide CustomCard;
import 'package:get/get.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: height * .05),
        OverviewControls(),
        SizedBox(height: height * .02),
        // CompareMiniCard(period: shift.period!.value, metric: shift.metric!.value, jobs: selectedJobs),

        SizedBox(height: height * .01),
        CompareTab(),
        SizedBox(height: height * .01),
        // Stable donut
        // PayComposition(period: shift.period!.value, jobs: selectedJobs),
        SizedBox(height: height * .01),
        // InsightsCard(period: shift.period!.value, jobs: selectedJobs),
      ],
    );
  }
}

class CompareTab extends StatelessWidget {
  const CompareTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // shift.initJobs(app.jobs.map((e) => e.id!));
      // final jobs = app.jobs.where((j) => shift.jobs.contains(j.id)).toList();

      final labels = <String>[];
      final series = <String, List<double>>{}; // jobId -> points

      if (shift.period!.value == 'monthly') {
        for (int i = 7; i >= 0; i--) {
          final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
          labels.add('${m.month}/${(m.year % 100).toString().padLeft(2, '0')}');
        }
        // for (final j in jobs) {
        //   series[j.id!] = [];
        //   for (int i = 7; i >= 0; i--) {
        //     final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
        //     final sum = app.monthNetSummary(m)['perJob'][j.id] as Map;
        //     series[j.id]!.add(pickMetric(sum, shift.metric!.value));
        //   }
        // }
      } else {
        // for (final j in jobs) {
        //   final ps = app.periodsAround(j, back: 8, forward: 0).reversed.toList();
        //   series[j.id!] = ps.map((p) => metricFromPeriod(app, j, p, shift.metric!.value)).toList();
        //   if (labels.length < ps.length) {
        //     labels
        //       ..clear()
        //       ..addAll(ps.map((p) => md(p.deposit)));
        //   }
        // }
      }

      // final colors = jobs.map((j) => app.jobColor(j.colorHex!)).toList();

      return CustomCard(
        title: 'Compare (${periodLabel(shift.period!.value)}) — ${metricTitle(shift.metric!.value)}',
        color: ProjectColors.whiteColor,
        child: SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true, horizontalInterval: 20),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(labels[i], style: const TextStyle(fontSize: 10)),
                    );
                  },
                )),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(labels.length, (i) {
                final rods = <BarChartRodData>[];
                // for (int j = 0; j < jobs.length; j++) {
                //   final jid = jobs[j].id;
                //   final y = i < (series[jid]?.length ?? 0) ? series[jid]![i] : 0.0;
                //   rods.add(BarChartRodData(toY: y, color: colors[j], width: 10));
                // }
                return BarChartGroupData(x: i, barRods: rods, barsSpace: 6);
              }),
            ),
          ),
        ),
      );
    });
  }
}

class OverviewControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
          label: textWidget(text: label, fontSize: .015),
          selected: sel,
          onSelected: (_) => onTap(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: ProjectColors.whiteColor,
          selectedColor: ProjectColors.greenColor,
          avatarBorder: Border.all(color: Colors.transparent),
        );

    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              chip('Weekly', shift.period!.value == 'weekly', () => shift.period!.value = 'weekly'),
              chip('Biweekly', shift.period!.value == 'biweekly', () => shift.period!.value = 'biweekly'),
              chip('Monthly', shift.period!.value == 'monthly', () => shift.period!.value = 'monthly'),
              chip('Net', shift.metric!.value == 'net', () => shift.metric!.value = 'net'),
              chip('Gross', shift.metric!.value == 'gross', () => shift.metric!.value = 'gross'),
              chip('Hours', shift.metric!.value == 'hours', () => shift.metric!.value = 'hours'),
              chip('OT', shift.metric!.value == 'ot', () => shift.metric!.value = 'ot'),
            ]),
            SizedBox(height: height * .02),
            Wrap(spacing: 8, children: [
              chip('vs Last', shift.baseline!.value == 'last', () => shift.baseline!.value = 'last'),
              chip('vs Avg(3)', shift.baseline!.value == 'avg', () => shift.baseline!.value = 'avg'),
            ]),
            SizedBox(height: height * .02),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // for (final j in app.jobs)
                // FilterChip(
                //   label: textWidget(text: j.name, fontSize: .015),
                //   selectedColor: ProjectColors.greenColor,
                //   backgroundColor: ProjectColors.greenColor.withOpacity(0.6),
                //   selected: shift.jobs.contains(j.id),
                //   onSelected: (_) {
                //     if (shift.jobs.contains(j.id)) {
                //       shift.jobs.remove(j.id);
                //     } else {
                //       shift.jobs.add(j.id);
                //     }
                //   },
                //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                // ),
                // if (app.jobs.isNotEmpty)
                // FilterChip(
                //   label: textWidget(text: 'Both', fontSize: .015),
                //   selectedColor: ProjectColors.greenColor,
                //   backgroundColor: ProjectColors.greenColor.withOpacity(0.6),
                //   selected: shift.jobs.length == app.jobs.length,
                //   onSelected: (_) {
                //     shift.jobs
                //       ..clear()
                //       ..addAll(app.jobs.map((e) => e.id));
                //   },
                // ),
              ],
            ),
          ],
        ));
  }
}

class CompareMiniCard extends StatelessWidget {
  final String period;
  final String metric;
  final List<Job> jobs;
  const CompareMiniCard({required this.period, required this.metric, required this.jobs});

  @override
  Widget build(BuildContext context) {
    double current = 0, base = 0;

    for (final j in jobs) {
      if (period == 'monthly') {
        final now = DateTime.now();
        final thisM = app.monthNetSummary(DateTime(now.year, now.month, 1));
        final prevM = app.monthNetSummary(DateTime(now.year, now.month - 1, 1));
        // current += pickMetric(thisM['perJob'][j.id] as Map, metric);
        // base += pickMetric(prevM['perJob'][j.id] as Map, metric);
      } else {
        // use pay periods
        final nowPs = app.periodsAround(j, back: 0, forward: 0);
        final prevPs = app.periodsAround(j, back: 1, forward: 0);
        if (nowPs.isNotEmpty) current += metricFromPeriod(app, j, nowPs.first, metric);
        if (prevPs.isNotEmpty) base += metricFromPeriod(app, j, prevPs.first, metric);
      }
    }

    final diff = current - base;
    final up = diff >= 0;
    final color = up ? const Color(0xFF013415) : const Color(0xFFEF4444);

    return CustomCard(
      title: 'Compare — ${metricTitle(metric)}',
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: height * .01, vertical: height * .01),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(999),
        ),
        child: textWidget(text: '${up ? '+' : ''}${diff.toStringAsFixed(2)}', fontSize: .015, fontWeight: FontWeight.w400, color: Colors.white),
      ),
      child: Row(
        children: [
          Expanded(child: _kpi('Current', current, metric)),
          // SizedBox(width: width * .012),
          Expanded(child: _kpi('Last', base, metric)),
        ],
      ),
    );
  }

  Widget _kpi(String label, double v, String metric) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(text: label, fontSize: .015, color: ProjectColors.pureBlackColor),
          SizedBox(height: height * .005),
          textWidget(text: fmt(metric, v), fontSize: .02, color: ProjectColors.pureBlackColor, fontWeight: FontWeight.w800),
        ],
      );
}

class PayComposition extends StatelessWidget {
  final String period;
  final List<Job> jobs;
  const PayComposition({required this.period, required this.jobs});

  @override
  Widget build(BuildContext context) {
    double gross = 0, net = 0, income = 0, cpp = 0, ei = 0, other = 0, post = 0;

    // for (final j in jobs) {
    //   if (period == 'monthly') {
    //     final m = app.monthNetSummary(DateTime(DateTime.now().year, DateTime.now().month, 1));
    //     // final row = (m['perJob'][j.id] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    //     gross += row['gross'] ?? row['pay'] ?? 0;
    //     net += row['net'] ?? row['pay'] ?? 0;
    //     income += row['incomeTax'] ?? 0;
    //     cpp += row['cpp'] ?? 0;
    //     ei += row['ei'] ?? 0;
    //     other += row['other'] ?? 0;
    //     post += row['fixed'] ?? 0;
    //   } else {
    //     final p = app.periodsAround(j, back: 0, forward: 0).firstOrNull;
    //     if (p == null) continue;
    //     gross += p.pay;
    //     net += app.estimateNetForPeriod(j, p);
    //     final t = app.taxFor(j.id!);
    //     income += p.pay * (t.incomeTaxPct / 100);
    //     cpp += p.pay * (t.cppPct / 100);
    //     ei += p.pay * (t.eiPct / 100);
    //     other += p.pay * (t.otherPct / 100);
    //     post += (p.pay - (income + cpp + ei + other)).clamp(0, double.infinity) * (t.postTaxExpensePct / 100);
    //   }
    // }

    final slices = [
      Slice('Net', net, const Color(0xFF035D24)),
      Slice('Income', income, const Color(0xFFEF4444)),
      Slice('CPP', cpp, const Color(0xFF60A5FA)),
      Slice('EI', ei, const Color(0xFFF59E0B)),
      Slice('Other %', other, const Color(0xFF9CA3AF)),
      Slice('Post-exp %', post, const Color(0xFF7C3AED)),
    ].where((s) => s.value > 0.01).toList();

    return CustomCard(
      color: ProjectColors.whiteColor,
      title: 'Pay Composition (this ${periodLabel(period)})',
      child: Column(
        children: [
          SizedBox(
            height: height * .25,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: height * .06,
                sectionsSpace: 1,
                sections: [
                  for (final s in slices) PieChartSectionData(value: s.value, color: s.color, title: '', radius: height * .06),
                ],
              ),
            ),
          ),
          SizedBox(height: height * .01),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final s in slices) legendDot(s.color, '${s.label} ${money(s.value)}'),
            ],
          ),
          SizedBox(height: height * .01),
          Align(
            alignment: Alignment.centerRight,
            child: textWidget(
                text: 'Effective deduction: ${gross == 0 ? '0.0' : (((gross - net) / gross) * 100).toStringAsFixed(1)}%',
                fontSize: .015,
                fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class InsightsCard extends StatelessWidget {
  final String period;
  final List<Job> jobs;
  const InsightsCard({required this.period, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final tips = <String>[
      'Tip: add stat days on Calendar to see premium effects in totals.',
      'Use each job’s Tax Settings to improve net accuracy.',
      'Projection tab estimates next period with custom hours per job.',
    ];
    if (jobs.isEmpty) tips.insert(0, 'No jobs selected.');
    return CustomCard(
      color: ProjectColors.whiteColor,
      title: 'Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $s'))).toList(),
      ),
    );
  }
}
