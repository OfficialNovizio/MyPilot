import 'dart:math';

import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/Overview Model.dart';
import '../../Constant UI.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  @override
  void initState() {
    overview.shiftMonth(0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .02),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============= TOP: MONTH PILL + RANGE TOGGLE ============
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: height * .02, bottom: height * .02),
                child: MonthPill(
                  label: overview.formatMonth(),
                  onPrev: () {
                    overview.goToPreviousMonth();
                  },
                  onNext: overview.goToNextMonth,
                  canGoNext: !DateTime(
                    overview.selectedMonth.value.year,
                    overview.selectedMonth.value.month + 1,
                    1,
                  ).isAfter(DateTime(DateTime.now().year, DateTime.now().month, 1)),
                ),
              ),
            ),
            shift.minimumShifts!.value == false
                ? Padding(
                    padding: EdgeInsets.only(top: height * .15),
                    child: EmptyInsightsScreen(
                      title: 'Start tracking to unlock insights',
                      subTitle: 'We need about 10 shifts to show accurate hours, earnings, and monthly trends',
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * .015),

                      // ============= ESTIMATED INCOME CARD ============
                      const _EstimatedIncomeCard(),

                      // ============= INSIGHTS ============
                      SizedBox(height: height * .01),
                      _InsightsCard(),
                      SizedBox(height: height * .025),

                      // ============= WEEKLY BREAKDOWN ============
                      textWidget(
                        text: "Weekly Breakdown",
                        fontSize: .025,
                        fontWeight: FontWeight.w600,
                        color: ProjectColors.whiteColor,
                      ),
                      SizedBox(height: height * .01),
                      ...overview.currentMonthOverView!.value!.jobs!
                          .map(
                            (a) => Padding(
                              padding: EdgeInsets.symmetric(vertical: height * .005),
                              child: AppleWeeklyJobCard(
                                job: a,
                                monthTotalPay: overview.currentMonthOverView!.value!.totals!.pay,
                                onWeekTap: (w) {
                                  // optional: open your modal
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
            // ============= OVERVIEW TITLE ============

            SizedBox(height: height * .025),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
//                         ESTIMATED INCOME CARD
// ===================================================================

class _EstimatedIncomeCard extends StatelessWidget {
  const _EstimatedIncomeCard();

  @override
  Widget build(BuildContext context) {
    final double progress = (overview.currentMonthOverView!.value!.totals!.pay / 2500); // 62%

    return DarkCard(
      color: ProjectColors.greenColor,
      opacity: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top line: title + %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textWidget(
                text: "Estimated Income",
                fontSize: .018,
                fontWeight: FontWeight.w500,
                color: ProjectColors.whiteColor,
              ),
              textWidget(
                text: "${progress * 100}%",
                fontSize: .018,
                fontWeight: FontWeight.w600,
                color: ProjectColors.whiteColor,
              ),
            ],
          ),
          SizedBox(height: height * .012),

          // Main amount
          textWidget(
            text: "\$${overview.currentMonthOverView!.value!.totals!.pay}",
            fontSize: .035,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .012),

          // Progress bar
          SizedBox(
            width: width * .8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: ProjectColors.pureBlackColor.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(ProjectColors.pureBlackColor),
              ),
            ),
          ),
          SizedBox(height: height * .01),

          // Goal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textWidget(
                text: "Goal: \$${2500}",
                fontSize: .016,
                color: ProjectColors.whiteColor.withOpacity(.7),
              ),
              textWidget(
                text: "Total hours ${overview.currentMonthOverView!.value!.totals!.hours}",
                fontSize: .016,
                color: ProjectColors.whiteColor.withOpacity(.7),
              ),
            ],
          ),
          SizedBox(height: height * .01),
          textWidget(
            text: 'The goal value is debt-dependent and automatically calculated. The default initialized value is 2,500.',
            color: ProjectColors.whiteColor.withOpacity(.7),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
//                              INSIGHTS
// ===================================================================

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .01),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          textWidget(
            text: "Insights",
            fontSize: .025,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .02),
          ...overview.insights!
              .map(
                (f) => Padding(
                  padding: EdgeInsets.symmetric(vertical: height * .006),
                  child: _InsightRow(
                    icon: f.icon,
                    iconColor: f.iconColor,
                    bgColor: f.iconBg,
                    text: " ${f.title} : ${f.subtitle!}",
                  ),
                ),
              )
              .toList(),
        ]),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String text;

  const _InsightRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: height * .032,
          height: height * .032,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: height * .02,
            color: iconColor,
          ),
        ),
        SizedBox(width: width * .03),
        Expanded(
          child: textWidget(
            text: text,
            fontSize: .018,
            fontWeight: FontWeight.w500,
            color: ProjectColors.whiteColor,
          ),
        ),
      ],
    );
  }
} // <-- change this import

class AppleWeeklyJobCard extends StatefulWidget {
  final JobWeekly job;
  final double monthTotalPay; // currentMonthOverView.value?.totals.pay ?? 0
  final void Function(WeekRow week)? onWeekTap;

  const AppleWeeklyJobCard({super.key, required this.job, required this.monthTotalPay, this.onWeekTap});

  @override
  State<AppleWeeklyJobCard> createState() => _AppleWeeklyJobCardState();
}

class _AppleWeeklyJobCardState extends State<AppleWeeklyJobCard> {
  bool showEmptyWeeks = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final double pay = job.totals.pay;
    final double hours = job.totals.hours;
    final double rate = hours <= 0 ? 0 : pay / hours;

    final double share = (widget.monthTotalPay <= 0) ? 0 : (pay / widget.monthTotalPay).clamp(0.0, 1.0);

    // Sort + normalize to W1..W6 (stable bars & spacing)
    final fixedWeeks = _normalizeWeeksToSix(job.weeks);

    // Pills: hide empty by default
    final nonZero = fixedWeeks.where((w) => w.pay.abs() > 0.01 || w.hours.abs() > 0.01).toList();
    final pillsPool = showEmptyWeeks ? fixedWeeks : (nonZero.isEmpty ? fixedWeeks : nonZero);

    const int collapsedMax = 3;
    final bool needsCollapse = pillsPool.length > collapsedMax;
    final List<WeekRow> visiblePills = (!expanded && needsCollapse) ? pillsPool.take(collapsedMax).toList() : pillsPool;
    final int hiddenCount = pillsPool.length - visiblePills.length;

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- Header ----------------
          Row(
            children: [
              Container(
                height: height * .018,
                width: height * .018,
                decoration: BoxDecoration(
                  color: Color(int.parse(job.colorHex)).withOpacity(.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(width: width * .025),
              Expanded(
                child: textWidget(
                  text: job.jobName.isEmpty ? "Job" : job.jobName,
                  fontSize: .022,
                  fontWeight: FontWeight.w800,
                  color: ProjectColors.whiteColor,
                ),
              ),
              textWidget(
                text: money(pay),
                fontSize: .024,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor,
              ),
            ],
          ),

          SizedBox(height: height * .008),

          // ---------------- Subheader ----------------
          Row(
            children: [
              Expanded(
                child: textWidget(
                  text: "${_fmtHours(hours)} • ${money(rate)}/hr • ${(share * 100).round()}% of month",
                  fontSize: .015,
                  fontWeight: FontWeight.w600,
                  color: ProjectColors.softText,
                ),
              ),
              if (needsCollapse)
                GestureDetector(
                  onTap: () => setState(() => expanded = !expanded),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .008),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Color(int.parse(job.colorHex)).withOpacity(.14),
                      border: Border.all(color: Color(int.parse(job.colorHex)).withOpacity(.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        textWidget(
                          text: expanded ? "Less" : "+$hiddenCount",
                          fontSize: .015,
                          fontWeight: FontWeight.w900,
                          color: ProjectColors.whiteColor,
                        ),
                        SizedBox(width: width * .01),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white.withOpacity(.85)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: height * .014),

          // ---------------- Share bar (subtle) ----------------
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation<Color>(Color(int.parse(job.colorHex)).withOpacity(.65)),
            ),
          ),

          SizedBox(height: height * .018),

          // ---------------- Weekly bars (fl_chart) ----------------
          SizedBox(
            height: height * .11,
            child: BarChart(
              BarChartData(
                maxY: max(1.0, fixedWeeks.map((w) => w.pay).toList().fold<double>(0, (m, v) => max(m, v))) * 1.15,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "W${i + 1}",
                            style: TextStyle(
                              fontFamily: "poppins",
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(fixedWeeks.length, (i) {
                  final v = fixedWeeks[i].pay;
                  final isZero = v.abs() <= 0.01;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: max(0, v),
                        width: 10,
                        borderRadius: BorderRadius.circular(6),
                        color: isZero ? Colors.white.withOpacity(.12) : Color(int.parse(job.colorHex)).withOpacity(.55),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: max(1.0, fixedWeeks.map((w) => w.pay).toList().fold<double>(0, (m, v) => max(m, v))) * 1.05,
                          color: Colors.white.withOpacity(.06),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: height * .01),
          Row(
            children: [
              Switch(
                value: showEmptyWeeks,
                onChanged: (val) {
                  setState(() => showEmptyWeeks = !showEmptyWeeks);
                },
                activeColor: Color(int.parse(job.colorHex)),
                inactiveThumbColor: Color(int.parse(job.colorHex)),
                inactiveTrackColor: ProjectColors.whiteColor.withOpacity(0.15),
              ),
              SizedBox(width: width * .02),
              textWidget(
                text: "Empty weeks",
                fontSize: .015,
                fontWeight: FontWeight.w700,
                color: ProjectColors.softText,
              ),
            ],
          ),

          // ---------------- Toggle ----------------
          SizedBox(height: height * .01),

          // ---------------- Pills ----------------
          Wrap(
            spacing: width * .01,
            runSpacing: height * .005,
            alignment: WrapAlignment.center,
            children: [
              for (final w in visiblePills)
                GestureDetector(
                  onTap: () {},
                  child: Opacity(
                    opacity: w.pay.abs() <= 0.01 && w.hours.abs() <= 0.01 ? .45 : 1,
                    child: SizedBox(
                      width: width * .28,
                      child: DarkCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            textWidget(
                              text: "W${w.weekIndex}",
                              fontWeight: FontWeight.w800,
                              color: ProjectColors.softText,
                            ),
                            textWidget(
                              text: money(w.pay),
                              fontSize: .018,
                              fontWeight: FontWeight.w900,
                              color: ProjectColors.whiteColor,
                            ),
                            textWidget(
                              text: _fmtHours(w.hours),
                              fontWeight: FontWeight.w800,
                              color: ProjectColors.softText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }

  // ====== model helpers ======
  List<WeekRow> _normalizeWeeksToSix(List<WeekRow> weeks) {
    final sorted = weeks.toList()..sort((a, b) => a.weekIndex.compareTo(b.weekIndex));
    final map = <int, WeekRow>{for (final w in sorted) w.weekIndex: w};

    WeekRow z(int i) => WeekRow(
          weekIndex: i,
          start: DateTime(2000, 1, 1),
          end: DateTime(2000, 1, 1),
          hours: 0.0,
          pay: 0.0,
        );

    return List.generate(6, (i) => map[i + 1] ?? z(i + 1));
  }

  String _fmtHours(double h) {
    final isInt = (h - h.floorToDouble()).abs() < 0.001;
    return isInt ? "${h.toStringAsFixed(0)}h" : "${h.toStringAsFixed(1)}h";
  }
}
