import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/app_controller.dart';
import '../models/job.dart';

class _Slice {
  final String label;
  final double value;
  final Color color;
  _Slice(this.label, this.value, this.color);
}

/// Local, conflict-free state (do not import any other analytics controller)
class DashboardState extends GetxController {
  // Shared
  final period = 'weekly'.obs; // weekly | biweekly | monthly
  final metric = 'net'.obs; // net | gross | hours | ot
  final baseline = 'last'.obs; // last | avg
  final jobs = <String>[].obs; // selected jobIds

  // Deposits tab
  final depositLookBack = 3.obs;
  final depositLookForward = 3.obs;

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
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers exist
    if (!Get.isRegistered<AppController>()) Get.put(AppController());
    if (!Get.isRegistered<DashboardState>()) Get.put(DashboardState());
    final app = Get.find<AppController>();
    final a = Get.find<DashboardState>();
    a.initJobs(app.jobs.map((e) => e.id));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics Dashboard'),
          bottom: const TabBar(
            isScrollable: false,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_customize_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.savings_outlined), text: 'Deposits'),
              Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Compare'),
              Tab(icon: Icon(Icons.query_stats_outlined), text: 'Projection'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _DepositsTab(),
            _CompareTab(),
            _ProjectionTab(),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                OVERVIEW TAB                                */
/* -------------------------------------------------------------------------- */

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final app = Get.find<AppController>();
    final a = Get.find<DashboardState>();
    return Obx(() {
      a.initJobs(app.jobs.map((e) => e.id));
      final selectedJobs = app.jobs.where((j) => a.jobs.contains(j.id)).toList();

      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _OverviewControls(),
          const SizedBox(height: 8),

          // Compare mini KPI
          _CompareMiniCard(period: a.period.value, metric: a.metric.value, jobs: selectedJobs),

          const SizedBox(height: 12),
          // Stable donut
          _PayComposition(period: a.period.value, jobs: selectedJobs),

          const SizedBox(height: 12),
          _InsightsCard(period: a.period.value, jobs: selectedJobs),
        ],
      );
    });
  }
}

class _OverviewControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = Get.find<DashboardState>();
    final app = Get.find<AppController>();

    Widget chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
          label: Text(label),
          selected: sel,
          onSelected: (_) => onTap(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              chip('Weekly', a.period.value == 'weekly', () => a.period.value = 'weekly'),
              chip('Biweekly', a.period.value == 'biweekly', () => a.period.value = 'biweekly'),
              chip('Monthly', a.period.value == 'monthly', () => a.period.value = 'monthly'),
              const SizedBox(width: 12),
              chip('Net', a.metric.value == 'net', () => a.metric.value = 'net'),
              chip('Gross', a.metric.value == 'gross', () => a.metric.value = 'gross'),
              chip('Hours', a.metric.value == 'hours', () => a.metric.value = 'hours'),
              chip('OT', a.metric.value == 'ot', () => a.metric.value = 'ot'),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              chip('vs Last', a.baseline.value == 'last', () => a.baseline.value = 'last'),
              chip('vs Avg(3)', a.baseline.value == 'avg', () => a.baseline.value = 'avg'),
            ]),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final j in app.jobs)
                  FilterChip(
                    label: Text(j.name),
                    selected: a.jobs.contains(j.id),
                    onSelected: (_) {
                      if (a.jobs.contains(j.id)) {
                        a.jobs.remove(j.id);
                      } else {
                        a.jobs.add(j.id);
                      }
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (app.jobs.isNotEmpty)
                  FilterChip(
                    label: const Text('Both'),
                    selected: a.jobs.length == app.jobs.length,
                    onSelected: (_) {
                      a.jobs
                        ..clear()
                        ..addAll(app.jobs.map((e) => e.id));
                    },
                  ),
              ],
            ),
          ],
        ));
  }
}

class _CompareMiniCard extends StatelessWidget {
  final String period;
  final String metric;
  final List<Job> jobs;
  const _CompareMiniCard({required this.period, required this.metric, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    double current = 0, base = 0;

    for (final j in jobs) {
      if (period == 'monthly') {
        final now = DateTime.now();
        final thisM = c.monthNetSummary(DateTime(now.year, now.month, 1));
        final prevM = c.monthNetSummary(DateTime(now.year, now.month - 1, 1));
        current += _pickMetric(thisM['perJob'][j.id] as Map, metric);
        base += _pickMetric(prevM['perJob'][j.id] as Map, metric);
      } else {
        // use pay periods
        final nowPs = c.periodsAround(j, back: 0, forward: 0);
        final prevPs = c.periodsAround(j, back: 1, forward: 0);
        if (nowPs.isNotEmpty) current += _metricFromPeriod(c, j, nowPs.first, metric);
        if (prevPs.isNotEmpty) base += _metricFromPeriod(c, j, prevPs.first, metric);
      }
    }

    final diff = current - base;
    final up = diff >= 0;
    final color = up ? const Color(0xFF16A34A) : const Color(0xFFEF4444);

    return _Card(
      title: 'Compare — ${_metricTitle(metric)}',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          border: Border.all(color: color.withOpacity(.6)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('${up ? '+' : ''}${diff.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ),
      child: Row(
        children: [
          Expanded(child: _kpi('Current', current, metric)),
          const SizedBox(width: 12),
          Expanded(child: _kpi('Last', base, metric)),
        ],
      ),
    );
  }

  Widget _kpi(String label, double v, String metric) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(_fmt(metric, v), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      );
}

class _PayComposition extends StatelessWidget {
  final String period;
  final List<Job> jobs;
  const _PayComposition({required this.period, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();

    double gross = 0, net = 0, income = 0, cpp = 0, ei = 0, other = 0, post = 0;

    for (final j in jobs) {
      if (period == 'monthly') {
        final m = c.monthNetSummary(DateTime(DateTime.now().year, DateTime.now().month, 1));
        final row = (m['perJob'][j.id] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
        gross += row['gross'] ?? row['pay'] ?? 0;
        net += row['net'] ?? row['pay'] ?? 0;
        income += row['incomeTax'] ?? 0;
        cpp += row['cpp'] ?? 0;
        ei += row['ei'] ?? 0;
        other += row['other'] ?? 0;
        post += row['fixed'] ?? 0;
      } else {
        final p = c.periodsAround(j, back: 0, forward: 0).firstOrNull;
        if (p == null) continue;
        gross += p.pay;
        net += c.estimateNetForPeriod(j, p);
        final t = c.taxFor(j.id);
        income += p.pay * (t.incomeTaxPct / 100);
        cpp += p.pay * (t.cppPct / 100);
        ei += p.pay * (t.eiPct / 100);
        other += p.pay * (t.otherPct / 100);
        post += (p.pay - (income + cpp + ei + other)).clamp(0, double.infinity) * (t.postTaxExpensePct / 100);
      }
    }

    final slices = [
      _Slice('Net', net, const Color(0xFF22C55E)),
      _Slice('Income', income, const Color(0xFFEF4444)),
      _Slice('CPP', cpp, const Color(0xFF60A5FA)),
      _Slice('EI', ei, const Color(0xFFF59E0B)),
      _Slice('Other %', other, const Color(0xFF9CA3AF)),
      _Slice('Post-exp %', post, const Color(0xFF7C3AED)),
    ].where((s) => s.value > 0.01).toList();

    return _Card(
      title: 'Pay Composition (this ${_periodLabel(period)})',
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 48,
                sectionsSpace: 1,
                sections: [
                  for (final s in slices) PieChartSectionData(value: s.value, color: s.color, title: '', radius: 55),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final s in slices) _legendDot(s.color, '${s.label} ${_money(s.value)}'),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Effective deduction: ${gross == 0 ? '0.0' : (((gross - net) / gross) * 100).toStringAsFixed(1)}%'),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final String period;
  final List<Job> jobs;
  const _InsightsCard({required this.period, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final tips = <String>[
      'Tip: add stat days on Calendar to see premium effects in totals.',
      'Use each job’s Tax Settings to improve net accuracy.',
      'Projection tab estimates next period with custom hours per job.',
    ];
    if (jobs.isEmpty) tips.insert(0, 'No jobs selected.');
    return _Card(
      title: 'Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $s'))).toList(),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               DEPOSITS TAB                                 */
/* -------------------------------------------------------------------------- */

class _DepositsTab extends StatelessWidget {
  const _DepositsTab();

  @override
  Widget build(BuildContext context) {
    final app = Get.find<AppController>();
    final a = Get.find<DashboardState>();

    return Obx(() {
      a.initJobs(app.jobs.map((e) => e.id));
      final selected = app.jobs.where((j) => a.jobs.contains(j.id)).toList();

      // Controls
      final controls = _Card(
        title: 'Filters',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final j in app.jobs)
                FilterChip(
                  label: Text(j.name),
                  selected: a.jobs.contains(j.id),
                  onSelected: (_) {
                    if (a.jobs.contains(j.id))
                      a.jobs.remove(j.id);
                    else
                      a.jobs.add(j.id);
                  },
                ),
              if (app.jobs.isNotEmpty)
                FilterChip(
                  label: const Text('Both'),
                  selected: a.jobs.length == app.jobs.length,
                  onSelected: (_) {
                    a.jobs
                      ..clear()
                      ..addAll(app.jobs.map((e) => e.id));
                  },
                ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Show:'),
              const SizedBox(width: 8),
              _seg<int>(
                value: a.depositLookBack.value,
                items: const {2: '2 back', 3: '3 back', 4: '4 back'},
                onChanged: (v) => a.depositLookBack.value = v,
              ),
              const SizedBox(width: 8),
              _seg<int>(
                value: a.depositLookForward.value,
                items: const {2: '2 next', 3: '3 next', 4: '4 next'},
                onChanged: (v) => a.depositLookForward.value = v,
              ),
            ]),
          ],
        ),
      );

      // Build timeline points (sorted by date)
      final points = <_DepositPoint>[];
      void addJob(Job j) {
        final ps = app.periodsAround(j, back: a.depositLookBack.value, forward: a.depositLookForward.value);
        for (final p in ps) {
          final net = app.estimateNetForPeriod(j, p);
          points.add(_DepositPoint(p.deposit, net, j.id));
        }
      }

      for (final j in selected) addJob(j);
      points.sort((a, b) => a.d.compareTo(b.d));

      final maxY = max<double>(1, points.fold(0, (m, e) => e.net > m ? e.net : m));

      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          controls,
          _Card(
            title: 'Upcoming & Recent Deposits',
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.isEmpty ? 1 : points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY * 1.25,
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF22C55E),
                      spots: [
                        for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].net),
                      ],
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, __, ___, ____) {
                          final idx = s.x.toInt();
                          final job = app.jobs.firstWhereOrNull((e) => e.id == points[idx].job);
                          return FlDotCirclePainter(
                            color: app.jobColor(job?.colorHex ?? '#16a34a'),
                            radius: 4,
                            strokeColor: Colors.white,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Per-job upcoming cards
          for (final j in selected) _JobDepositRow(job: j),
        ],
      );
    });
  }
}

class _DepositPoint {
  final DateTime d;
  final double net;
  final String job;
  _DepositPoint(this.d, this.net, this.job);
}

class _JobDepositRow extends StatelessWidget {
  final Job job;
  const _JobDepositRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final periods = c.periodsAround(job, back: 0, forward: 2);
    return _Card(
      title: job.name,
      leading: CircleAvatar(radius: 6, backgroundColor: c.jobColor(job.colorHex)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final p in periods)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                width: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFF121315),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF232427)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_md(p.start)} → ${_md(p.end)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.attach_money, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(_money(c.estimateNetForPeriod(job, p))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.savings_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Deposit: ${_md(p.deposit)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               COMPARE TAB                                  */
/* -------------------------------------------------------------------------- */

class _CompareTab extends StatelessWidget {
  const _CompareTab();

  @override
  Widget build(BuildContext context) {
    final app = Get.find<AppController>();
    final a = Get.find<DashboardState>();
    return Obx(() {
      a.initJobs(app.jobs.map((e) => e.id));
      final jobs = app.jobs.where((j) => a.jobs.contains(j.id)).toList();

      final labels = <String>[];
      final series = <String, List<double>>{}; // jobId -> points

      if (a.period.value == 'monthly') {
        for (int i = 7; i >= 0; i--) {
          final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
          labels.add('${m.month}/${(m.year % 100).toString().padLeft(2, '0')}');
        }
        for (final j in jobs) {
          series[j.id] = [];
          for (int i = 7; i >= 0; i--) {
            final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
            final sum = app.monthNetSummary(m)['perJob'][j.id] as Map;
            series[j.id]!.add(_pickMetric(sum, a.metric.value));
          }
        }
      } else {
        for (final j in jobs) {
          final ps = app.periodsAround(j, back: 8, forward: 0).reversed.toList();
          series[j.id] = ps.map((p) => _metricFromPeriod(app, j, p, a.metric.value)).toList();
          if (labels.length < ps.length) {
            labels
              ..clear()
              ..addAll(ps.map((p) => _md(p.deposit)));
          }
        }
      }

      final colors = jobs.map((j) => app.jobColor(j.colorHex)).toList();

      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _Card(
            title: 'Compare (${_periodLabel(a.period.value)}) — ${_metricTitle(a.metric.value)}',
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
                    for (int j = 0; j < jobs.length; j++) {
                      final jid = jobs[j].id;
                      final y = i < (series[jid]?.length ?? 0) ? series[jid]![i] : 0.0;
                      rods.add(BarChartRodData(toY: y, color: colors[j], width: 10));
                    }
                    return BarChartGroupData(x: i, barRods: rods, barsSpace: 6);
                  }),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/* -------------------------------------------------------------------------- */
/*                              PROJECTION TAB                                */
/* -------------------------------------------------------------------------- */

class _ProjectionTab extends StatelessWidget {
  const _ProjectionTab();

  @override
  Widget build(BuildContext context) {
    final app = Get.find<AppController>();
    final a = Get.find<DashboardState>();

    return Obx(() {
      a.initJobs(app.jobs.map((e) => e.id));
      final jobs = app.jobs.where((j) => a.jobs.contains(j.id)).toList();

      // Header controls (scope + per job hours pickers)
      final header = _Card(
        title: 'Projection controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, children: [
              _seg<String>(
                value: a.projScope.value,
                items: const {'weekly': 'Weekly', 'biweekly': 'Biweekly', 'monthly': 'Monthly'},
                onChanged: (v) => a.projScope.value = v,
              ),
            ]),
            const SizedBox(height: 10),
            for (final j in jobs) _HoursPickerRow(job: j),
            const SizedBox(height: 6),
            const Text('Projection assumes no stat-day premium and uses your job tax settings.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

      // Compute estimates
      final estPerJob = <String, _Est>{};
      double gross = 0, net = 0, inc = 0, cp = 0, ei = 0, oth = 0, post = 0;
      for (final j in jobs) {
        final h = a.projHours[j.id] ?? 30.0;
        final est = _estimateForHours(app, j, a.projScope.value, h);
        estPerJob[j.id] = est;
        gross += est.gross;
        net += est.net;
        inc += est.income;
        cp += est.cpp;
        ei += est.ei;
        oth += est.other;
        post += est.post;
      }

      // Build comparison vs last comparable period (combined)
      double prevNet = 0;
      for (final j in jobs) {
        if (a.projScope.value == 'monthly') {
          final now = DateTime.now();
          final prev = app.monthNetSummary(DateTime(now.year, now.month - 1, 1));
          final row = prev['perJob'][j.id] as Map?;
          if (row != null) prevNet += (row['net'] ?? row['pay'] ?? 0) as num;
        } else {
          final ps = app.periodsAround(j, back: 1, forward: 0);
          if (ps.isNotEmpty) prevNet += app.estimateNetForPeriod(j, ps.first);
        }
      }
      final chartMax = max<double>(1, max(net, prevNet)) * 1.3;

      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          header,
          _Card(
            title: 'Combined — ${_periodLabel(a.projScope.value)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hours: ' + jobs.map((j) => '${j.name} ${a.projHours[j.id]!.toStringAsFixed(0)}h').join('  •  ')),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 16 / 7,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: chartMax,
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(v == 0 ? 'Projected' : 'Previous'),
                          ),
                        )),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: net, width: 22, color: const Color(0xFF22C55E))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: prevNet, width: 22, color: const Color(0xFF9CA3AF))]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _bullets([
                  'Gross ${_money(gross)}',
                  'Net ${_money(net)}',
                  'Income ${_money(inc)}  •  CPP ${_money(cp)}  •  EI ${_money(ei)}  •  Other ${_money(oth)}  •  Post-exp ${_money(post)}',
                ]),
              ],
            ),
          ),
          for (final j in jobs) _jobEstCard(j, estPerJob[j.id]!),
        ],
      );
    });
  }
}

class _HoursPickerRow extends StatelessWidget {
  final Job job;
  const _HoursPickerRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final app = Get.find<AppController>();
    final a = Get.find<DashboardState>();
    final Color dot = app.jobColor(job.colorHex);

    return Obx(() {
      final h = a.projHours[job.id] ?? 30.0;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(radius: 6, backgroundColor: dot),
        title: Text(job.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: OutlinedButton(
          onPressed: () async {
            final values = List<double>.generate(81, (i) => (i + 10).toDouble()); // 10..90
            final sel = await showCupertinoModalPopup<double>(
              context: context,
              builder: (_) {
                int index = values.indexWhere((x) => x == h);
                if (index < 0) index = 20;
                return Container(
                  color: Theme.of(context).colorScheme.surface,
                  height: 250,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text('Select hours', style: TextStyle(fontWeight: FontWeight.w700)),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: index),
                          itemExtent: 36,
                          onSelectedItemChanged: (i) {},
                          children: values.map((v) => Center(child: Text('${v.toStringAsFixed(0)} h'))).toList(),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final ctrl = PrimaryScrollController.of(context) as FixedExtentScrollController?;
                          final i = (ctrl?.selectedItem ?? index);
                          Navigator.pop(context, values[i]);
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                );
              },
            );
            if (sel != null) a.projHours[job.id] = sel;
          },
          child: Text('${h.toStringAsFixed(0)} h'),
        ),
      );
    });
  }
}

class _Est {
  final double gross, net, income, cpp, ei, other, post;
  _Est(this.gross, this.net, this.income, this.cpp, this.ei, this.other, this.post);
}

_Est _estimateForHours(AppController c, Job j, String scope, double hours) {
  final weeklyThr = c.settings.value.overtimeThresholdWeekly.toDouble();
  final factor = scope == 'weekly' ? 1.0 : (scope == 'biweekly' ? 2.0 : 4.345);
  final thr = weeklyThr * factor;

  final overtime = max(0, hours - thr);
  final regular = hours - overtime;
  final gross = regular * j.wage + overtime * j.wage * 1.5;

  final t = c.taxFor(j.id);
  final income = gross * (t.incomeTaxPct / 100);
  final cpp = gross * (t.cppPct / 100);
  final ei = gross * (t.eiPct / 100);
  final other = gross * (t.otherPct / 100);
  final post = (gross - (income + cpp + ei + other)).clamp(0, double.infinity) * (t.postTaxExpensePct / 100);

  final net = (gross - income - cpp - ei - other - post).clamp(0, double.infinity).toDouble();
  return _Est(gross, net, income, cpp, ei, other, post);
}

Widget _jobEstCard(Job j, _Est est) {
  final c = Get.find<AppController>();
  return _Card(
    title: j.name,
    leading: CircleAvatar(radius: 6, backgroundColor: c.jobColor(j.colorHex)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Gross', _money(est.gross)),
        _kv('Net', _money(est.net), strong: true),
        const Divider(),
        Wrap(spacing: 12, runSpacing: 6, children: [
          _legendDot(Colors.pinkAccent, 'Income ${_money(est.income)}'),
          _legendDot(const Color(0xFF60A5FA), 'CPP ${_money(est.cpp)}'),
          _legendDot(const Color(0xFFF59E0B), 'EI ${_money(est.ei)}'),
          _legendDot(const Color(0xFF9CA3AF), 'Other ${_money(est.other)}'),
          _legendDot(const Color(0xFF7C3AED), 'Post-exp ${_money(est.post)}'),
        ]),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*                                SHARED WIDGETS                               */
/* -------------------------------------------------------------------------- */

class _Card extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  const _Card({this.title, required this.child, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Text(title!, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

Widget _kv(String k, String v, {bool strong = false}) => Row(
      children: [
        Expanded(child: Text(k)),
        Text(v, style: TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w400)),
      ],
    );

Widget _legendDot(Color c, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(text),
    ]);

Widget _bullets(List<String> lines) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final s in lines) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $s'))],
    );

/* -------------------------------------------------------------------------- */
/*                                   UTILS                                    */
/* -------------------------------------------------------------------------- */

double _pickMetric(Map row, String metric) {
  num v = 0;
  switch (metric) {
    case 'net':
      v = (row['net'] ?? row['pay'] ?? 0) as num;
      break;
    case 'gross':
      v = (row['gross'] ?? row['pay'] ?? 0) as num;
      break;
    case 'hours':
      v = (row['hours'] ?? 0) as num;
      break;
    case 'ot':
      v = (row['overtime'] ?? 0) as num;
      break;
  }
  return v.toDouble();
}

double _metricFromPeriod(AppController c, Job j, dynamic p, String metric) {
  switch (metric) {
    case 'net':
      return c.estimateNetForPeriod(j, p);
    case 'gross':
      return p.pay;
    case 'hours':
      return p.hours;
    case 'ot':
      return p.overtime;
    default:
      return 0;
  }
}

String _fmt(String metric, double v) => metric == 'hours' || metric == 'ot' ? '${v.toStringAsFixed(1)} h' : _money(v);
String _money(num v) => '\$${v.toStringAsFixed(2)}';
String _md(DateTime d) => '${d.month}/${d.day}';
String _periodLabel(String p) => p == 'weekly' ? 'week' : (p == 'biweekly' ? 'biweek' : 'month');
String _metricTitle(String m) => {'net': 'Net', 'gross': 'Gross', 'hours': 'Hours', 'ot': 'OT'}[m] ?? m;

/// Small segmented control made from Chips
Widget _seg<T>({required T value, required Map<T, String> items, required ValueChanged<T> onChanged}) {
  return Wrap(
    spacing: 6,
    children: items.entries.map((e) {
      final sel = e.key == value;
      return ChoiceChip(
        label: Text(e.value),
        selected: sel,
        onSelected: (_) => onChanged(e.key),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList(),
  );
}
