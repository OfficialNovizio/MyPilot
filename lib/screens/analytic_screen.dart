import 'dart:math';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../Working UI/app_controller.dart';
import '../models/job.dart';

class Slice {
  final String label;
  final double value;
  final Color color;
  Slice(this.label, this.value, this.color);
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

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    // Ensure controllers exist
    final app = Get.find<AppController>();
    final a = Get.find<DashboardState>();
    // a.initJobs(app.jobs.map((e) => e.id!));

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
        body: TabBarView(
          children: [
            // OverviewTab(),
            // DepositsTab(),
            // CompareTab(),
            // ProjectionTab(),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                OVERVIEW TAB                                */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                               DEPOSITS TAB                                 */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                               COMPARE TAB                                  */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                              PROJECTION TAB                                */
/* -------------------------------------------------------------------------- */

class HoursPickerRow extends StatelessWidget {
  final Job job;
  const HoursPickerRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final app = Get.find<AppController>();
    // final a = Get.find<DashboardState>();
    // final Color dot = app.jobColor(job.colorHex!);

    return Obx(() {
      // final h = a.projHours[job.id] ?? 30.0;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        // leading: CircleAvatar(radius: 6, backgroundColor: dot),
        // title: textWidget(text: job.name, fontSize: .02, fontWeight: FontWeight.bold),
        // trailing: OutlinedButton(
        //   onPressed: () async {
        //     showCupertinoModalPopup(
        //       context: context,
        //       builder: (context) => Invoices(hour: h),
        //     );
        //     // final values = List<double>.generate(81, (i) => (i + 10).toDouble()); // 10..90
        //     // final sel = await showCupertinoModalPopup<double>(
        //     //   context: context,
        //     //   builder: (_) {
        //     //     int index = values.indexWhere((x) => x == h);
        //     //     if (index < 0) index = 20;
        //     //     return Scaffold(
        //     //       body: Container(
        //     //         color: Theme.of(context).colorScheme.surface,
        //     //         height: height * .5,
        //     //         child: Column(
        //     //           children: [
        //     //             SizedBox(height: 8),
        //     //             const Text('Select hours', style: TextStyle(fontWeight: FontWeight.w700)),
        //     //             Expanded(
        //     //               child: CupertinoPicker(
        //     //                 scrollController: FixedExtentScrollController(initialItem: index),
        //     //                 itemExtent: 36,
        //     //                 onSelectedItemChanged: (i) {},
        //     //                 children: values.map((v) => Center(child: Text('${v.toStringAsFixed(0)} h'))).toList(),
        //     //               ),
        //     //             ),
        //     //             TextButton(
        //     //               onPressed: () {
        //     //                 final ctrl = PrimaryScrollController.of(context) as FixedExtentScrollController?;
        //     //                 final i = (ctrl?.selectedItem ?? index);
        //     //                 Navigator.pop(context, values[i]);
        //     //               },
        //     //               child: const Text('Done'),
        //     //             ),
        //     //           ],
        //     //         ),
        //     //       ),
        //     //     );
        //     //   },
        //     // );
        //     // if (sel != null) a.projHours[job.id] = sel;
        //   },
        //   // child: textWidget(
        //   //   text: '${h.toStringAsFixed(0)} h',
        //   //   fontSize: .015,
        //   //   color: ProjectColors.pureBlackColor,
        //   //   fontWeight: FontWeight.bold,
        //   // ),
        // ),
      );
    });
  }
}

class Invoices extends StatelessWidget {
  final double? hour;

  Invoices({this.hour});

  @override
  Widget build(BuildContext context) {
    final values = List<double>.generate(81, (i) => (i + 10).toDouble());
    int index = values.indexWhere((x) => x == hour);
    if (index < 0) index = 20;
    return Padding(
      padding: EdgeInsets.only(top: height * .5),
      child: ClipRRect(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            transitionBetweenRoutes: false,
            middle: textWidget(
              text: "Select Hours",
              fontSize: .025,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.white,
            leading: Padding(
              padding: EdgeInsets.only(top: height * .01),
              child: GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: textWidget(
                  text: "close",
                  fontSize: .02,
                  fontWeight: FontWeight.w500,
                  color: ProjectColors.pureBlackColor,
                ),
              ),
            ),
          ),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            height: height * .5,
            child: Column(
              children: [
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
          ),
        ),
      ),
    );
  }
}

class Est {
  final double gross, net, income, cpp, ei, other, post;
  Est(this.gross, this.net, this.income, this.cpp, this.ei, this.other, this.post);
}

Est estimateForHours(AppController c, Job j, String scope, double hours) {
  final weeklyThr = c.settings.value.overtimeThresholdWeekly.toDouble();
  final factor = scope == 'weekly' ? 1.0 : (scope == 'biweekly' ? 2.0 : 4.345);
  final thr = weeklyThr * factor;

  final overtime = max(0, hours - thr);
  final regular = hours - overtime;
  // final gross = regular * j.wage! + overtime * j.wage! * 1.5;

  // final t = c.taxFor(j.id!);
  // final income = gross * (t.incomeTaxPct / 100);
  // final cpp = gross * (t.cppPct / 100);
  // final ei = gross * (t.eiPct / 100);
  // final other = gross * (t.otherPct / 100);
  // final post = (gross - (income + cpp + ei + other)).clamp(0, double.infinity) * (t.postTaxExpensePct / 100);
  //
  // final net = (gross - income - cpp - ei - other - post).clamp(0, double.infinity).toDouble();
  // return Est(gross, net, income, cpp, ei, other, post);
  return null!;
}

Widget jobEstCard(Job j, Est est) {
  final c = Get.find<AppController>();
  return CustomCard(
    color: ProjectColors.whiteColor,
    // title: j.name,
    leading: Container(),
    // leading: CircleAvatar(radius: 6, backgroundColor: c.jobColor(j.colorHex!)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Gross', money(est.gross)),
        _kv('Net', money(est.net), strong: true),
        const Divider(),
        Wrap(spacing: 12, runSpacing: 6, children: [
          legendDot(Colors.pinkAccent, 'Income ${money(est.income)}'),
          legendDot(const Color(0xFF60A5FA), 'CPP ${money(est.cpp)}'),
          legendDot(const Color(0xFFF59E0B), 'EI ${money(est.ei)}'),
          legendDot(const Color(0xFF9CA3AF), 'Other ${money(est.other)}'),
          legendDot(const Color(0xFF7C3AED), 'Post-exp ${money(est.post)}'),
        ]),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*                                SHARED WIDGETS                               */
/* -------------------------------------------------------------------------- */

class CustomCard extends StatelessWidget {
  final String? title;
  final Color? color;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  const CustomCard({this.title = '', required this.child, this.leading, this.trailing, this.color = ProjectColors.greenColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color!,
        borderRadius: BorderRadius.circular(30),
      ),
      margin: EdgeInsets.symmetric(horizontal: width * .02),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  textWidget(text: title!, fontSize: .018, fontWeight: FontWeight.w600),
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
        Expanded(
          child: textWidget(text: k, fontWeight: FontWeight.bold, fontSize: .015),
        ),
        textWidget(text: v, fontWeight: FontWeight.bold, fontSize: .015),
      ],
    );

Widget legendDot(Color c, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: height * .01, height: width * .02, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      SizedBox(width: width * .02),
      textWidget(text: text, fontWeight: FontWeight.bold, fontSize: .015),
    ]);

Widget bullets(List<String> lines) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in lines) Padding(padding: EdgeInsets.symmetric(vertical: height * .002), child: textWidget(text: '• $s', fontSize: .015))
      ],
    );

/* -------------------------------------------------------------------------- */
/*                                   UTILS                                    */
/* -------------------------------------------------------------------------- */

double pickMetric(Map row, String metric) {
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

double metricFromPeriod(AppController c, Job j, dynamic p, String metric) {
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

String fmt(String metric, double v) => metric == 'hours' || metric == 'ot' ? '${v.toStringAsFixed(1)} h' : money(v);
String money(num v) => '\$${v.toStringAsFixed(2)}';
String md(DateTime d) => '${d.month}/${d.day}';
String periodLabel(String p) => p == 'weekly' ? 'week' : (p == 'biweekly' ? 'biweek' : 'month');
String metricTitle(String m) => {'net': 'Net', 'gross': 'Gross', 'hours': 'Hours', 'ot': 'OT'}[m] ?? m;

/// Small segmented control made from Chips
Widget seg<T>({required T value, required Map<T, String> items, required ValueChanged<T> onChanged}) {
  return Wrap(
    spacing: 6,
    children: items.entries.map((e) {
      final sel = e.key == value;
      return ChoiceChip(
        label: textWidget(text: e.value, fontSize: .015, color: ProjectColors.pureBlackColor),
        selected: sel,
        backgroundColor: ProjectColors.whiteColor,
        shadowColor: Colors.transparent,
        avatarBorder: Border.all(color: Colors.transparent),
        disabledColor: ProjectColors.pureBlackColor,
        selectedColor: ProjectColors.greenColor,
        onSelected: (_) => onChanged(e.key),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList(),
  );
}
