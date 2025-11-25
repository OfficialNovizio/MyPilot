import 'package:emptyproject/Working%20UI/Account/Account%20Getx.dart';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Shift/Shift%20Getx.dart';
import 'package:emptyproject/models/job.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/Overview Model.dart';
import '../../screens/analytic_screen.dart';
import '../../screens/salary_detailed_screen.dart';
import '../../utils/time_utils.dart';
import '../Account/Account.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payMarkers = account.computePayMarkers(focusedDay: _focusedDay);

      return Column(
        children: [
          TableCalendar<PayMarker>(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => shift.selectedDay?.value != null && isSameDay(d, shift.selectedDay!.value),
            eventLoader: (day) => payMarkers[DateTime(day.year, day.month, day.day)] ?? const [],
            onDaySelected: (selected, focused) {
              _focusedDay = focused;
              shift.selectedDay!.value = selected;

              // reset inputs
              for (final col in shift.newShiftColumns!) {
                if (col.title == 'Is this stat day ?') {
                  col.controller.text = '0';
                } else {
                  col.controller.text = '';
                }
              }

              shift.getShiftsForDay();

              showCupertinoModalPopup(
                context: context,
                builder: (_) => const ShiftDayCard(),
              );
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                color: ProjectColors.whiteColor,
                fontSize: height * .018,
                fontWeight: FontWeight.w700,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideTextStyle: TextStyle(
                color: ProjectColors.errorColor.withOpacity(0.5),
                fontSize: height * .015,
              ),
              outsideDaysVisible: true,
              defaultTextStyle: TextStyle(
                color: ProjectColors.whiteColor,
                fontSize: height * .015,
              ),
              todayDecoration: const BoxDecoration(
                color: ProjectColors.greenColor,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.white60,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 4,
            ),
            calendarBuilders: CalendarBuilders<PayMarker>(
              markerBuilder: (context, day, events) {
                final dotsMap = shift.buildJobDotsAll(perShift: true);
                DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

                // shift dots
                final jobDots = dotsMap[_d(day)] ?? const <JobDot>[];
                final bottomDots = jobDots.isEmpty
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: jobDots
                              .take(3)
                              .map((e) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    decoration: BoxDecoration(
                                      color: e.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ))
                              .toList(),
                        ),
                      );

                // payday badge
                if (events.isEmpty) return bottomDots;

                final cBg = events.first.color;
                final cFg = cBg.computeLuminance() < 0.5 ? Colors.white : Colors.black;

                final paydayBadge = Positioned(
                  right: -1,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: cBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cFg.withOpacity(.25)),
                    ),
                    child: Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: cFg,
                      ),
                    ),
                  ),
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: bottomDots),
                    paydayBadge,
                  ],
                );
              },
            ),
          ),

          SizedBox(height: height * .04),

          const _MonthSummary(),
          const _WeeklyBreakdownByJob(), // ✅ NEW SECTION
          // const _PayPeriods(),
        ],
      );
    });
  }
}

// =========================
// 1) NEW MONTH SUMMARY UI
// =========================
class _MonthSummary extends StatelessWidget {
  const _MonthSummary();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = shift.combinedMonthStat?.value;
      if (stats == null || stats.isEmpty) return const SizedBox.shrink();

      final income = shift.combinedPay!.value;
      final hours = shift.combinedHours!.value;

      return GestureDetector(
        onTap: () => Get.to(() => SalaryDetailsScreen(month: DateTime.now())),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: width * .04),
          padding: EdgeInsets.all(height * .018),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: "This Month — All Jobs",
                fontSize: .02,
                fontWeight: FontWeight.bold,
                color: ProjectColors.pureBlackColor,
              ),
              SizedBox(height: height * .012),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Estimated Income
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(
                        text: "Estimated Income",
                        fontSize: .016,
                        color: ProjectColors.pureBlackColor.withOpacity(.7),
                      ),
                      SizedBox(height: height * .004),
                      textWidget(
                        text: "\$${income.toStringAsFixed(0)}",
                        fontSize: .028,
                        fontWeight: FontWeight.bold,
                        color: ProjectColors.pureBlackColor,
                      ),
                    ],
                  ),

                  // Total Hours
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      textWidget(
                        text: "Total Hours",
                        fontSize: .016,
                        color: ProjectColors.pureBlackColor.withOpacity(.7),
                      ),
                      SizedBox(height: height * .004),
                      textWidget(
                        text: "${hours.toStringAsFixed(0)} h",
                        fontSize: .028,
                        fontWeight: FontWeight.bold,
                        color: ProjectColors.pureBlackColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// =========================================
// 2) NEW WEEKLY BREAKDOWN UI (like image)
// =========================================
class _WeeklyBreakdownByJob extends StatefulWidget {
  const _WeeklyBreakdownByJob();

  @override
  State<_WeeklyBreakdownByJob> createState() => _WeeklyBreakdownByJobState();
}

class _WeeklyBreakdownByJobState extends State<_WeeklyBreakdownByJob> {
  int viewMode = 0; // 0 = Card, 1 = Chart (chart UI later)

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final weeklyMap = shift.weeklyMonthBreakdown.value;
      final monthStats = shift.combinedMonthStat?.value;

      if (weeklyMap == null || monthStats == null || monthStats.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * .04),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * .04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                textWidget(
                  text: "By Job — Weekly Breakdown",
                  fontSize: .02,
                  fontWeight: FontWeight.bold,
                  color: ProjectColors.whiteColor,
                ),

                // Card / Chart toggle
                Row(
                  children: [
                    _ToggleTab(
                      label: "Card",
                      active: viewMode == 1,
                      onTap: () => setState(() => viewMode = 0),
                    ),
                    SizedBox(width: width * .03),
                    _ToggleTab(
                      label: "Chart",
                      active: viewMode == 1,
                      onTap: () => setState(() => viewMode = 1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: height * .012),

          // Body
          if (viewMode == 0)
            Column(
              children: [
                for (final entry in weeklyMap.entries)
                  _WeeklyJobCard(
                    jobId: entry.key,
                    weeks: entry.value,
                    overview: monthStats[entry.key]!,
                  ),
              ],
            )
          else
            // Chart mode placeholder (you can plug recharts/fl_chart later)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * .04),
              child: Container(
                height: height * .18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: textWidget(
                  text: "Chart view coming next",
                  fontSize: .016,
                  color: ProjectColors.pureBlackColor.withOpacity(.6),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// Small underline tab (Card/Chart)
class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          textWidget(
            text: label,
            fontSize: .017,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: ProjectColors.whiteColor.withOpacity(active ? 1 : .6),
          ),
          SizedBox(height: 2),
          Container(
            height: 2,
            width: label.length * 7.0,
            color: active ? ProjectColors.whiteColor : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

// Per-job weekly card
class _WeeklyJobCard extends StatelessWidget {
  final int jobId;
  final List<WeekStats> weeks;
  final CombinedOverview overview;

  const _WeeklyJobCard({
    required this.jobId,
    required this.weeks,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = Color(int.parse(overview.totals.colorHex ?? "0xff999999"));
    final monthNameTxt = DateFormat('MMMM').format(DateTime.now()); // "Nov"
    final monthPay = (overview.totals.pay ?? 0).toStringAsFixed(0);
    final monthHours = (overview.totals.hours ?? 0).toStringAsFixed(0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .008),
      padding: EdgeInsets.all(height * .016),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: dotColor.withOpacity(.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: width * .03),
                  textWidget(
                    text: overview.totals.jobName ?? "Job",
                    fontSize: .02,
                    fontWeight: FontWeight.bold,
                    color: ProjectColors.pureBlackColor,
                  ),
                ],
              ),
              textWidget(
                text: "$monthNameTxt total: \$$monthPay • $monthHours h",
                fontSize: .016,
                fontWeight: FontWeight.w600,
                color: ProjectColors.pureBlackColor.withOpacity(.7),
              ),
            ],
          ),

          SizedBox(height: height * .006),

          // Weekly rows
          for (final w in weeks)
            Padding(
              padding: EdgeInsets.symmetric(vertical: height * .004,horizontal: width * .04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BodyCell("Week ${w.weekIndex}","\$${w.pay.toStringAsFixed(0)}"),
                  _BodyCell("Income","\$${w.pay.toStringAsFixed(0)}"),
                  _BodyCell("Hours","\$${w.hours.toStringAsFixed(0)}"),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * .26,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: height * .016,
          color: ProjectColors.pureBlackColor.withOpacity(.8),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final String title;
  const _BodyCell(this.text,this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       textWidget(text: text,fontSize: .018,color: ProjectColors.blackColor.withOpacity(0.9)),
       textWidget(text: title,fontSize: .015),
     ],
    );
  }
}

class _PayPeriods extends StatelessWidget {
  const _PayPeriods();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = shift.combinedMonthStat?.value;
      if (stats == null || stats.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final j in stats.values)
            Padding(
              padding: EdgeInsets.only(top: height * .01),
              child: CustomCard(
                color: ProjectColors.whiteColor,
                child: Padding(
                  padding: EdgeInsets.all(height * .01),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          backgroundColor: Color(int.parse(j.totals.colorHex ?? "0xff999999")),
                          radius: 6,
                        ),
                        SizedBox(width: width * .01),
                        textWidget(
                          text: (j.totals.jobName ?? "Job"),
                          fontSize: .018,
                          fontWeight: FontWeight.bold,
                        ),
                      ]),
                      SizedBox(height: height * .004),
                      textWidget(
                        text: "Next deposit: ${j.nextDeposit != null ? monthDay(j.nextDeposit!) : "--"}",
                        fontSize: .015,
                      ),
                      SizedBox(height: height * .01),
                      Column(
                        children: [
                          for (final p in j.series) _PeriodRow(period: p),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _PeriodRow extends StatelessWidget {
  final PeriodRow period;
  const _PeriodRow({required this.period});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: height * .006),
      child: Container(
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
                    "Hours: ${period.hours.toStringAsFixed(2)} • OT: ${period.overtime.toStringAsFixed(2)}",
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
                  "\$${period.net.toStringAsFixed(0)}",
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
      ),
    );
  }
}

class ShiftDayCard extends StatelessWidget {
  const ShiftDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * .65,
      child: Popup(
        title: "Shift Status",
        body: SingleChildScrollView(
          child: Column(children: [
            textWidget(
              text: "${DateFormat('MMMM d').format(shift.selectedDay!.value)} Payday(s)",
              fontSize: .02,
              color: ProjectColors.pureBlackColor,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: height * .02),
            Visibility(
              visible: shift.todayShifts!.isEmpty,
              child: textWidget(
                text: 'NO SHIFTS ON THIS DAY',
                fontSize: .02,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...shift.todayShifts!
                .map(
                  (t) => Padding(
                    padding: EdgeInsets.only(top: height * .01),
                    child: Dismissible(
                      key: ValueKey(t.id),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: width * .02),
                        decoration: BoxDecoration(
                          color: ProjectColors.errorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete, size: height * .03, color: ProjectColors.whiteColor),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: width * .02),
                        decoration: BoxDecoration(
                          color: ProjectColors.greenColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit, size: height * .03, color: ProjectColors.whiteColor),
                      ),
                      confirmDismiss: (direction) async {
                        bool? wantDismiss = true;
                        if (direction == DismissDirection.endToStart) {
                          shift.newShiftColumns![0].controller.text = t.start!;
                          shift.newShiftColumns![1].controller.text = t.end!;
                          shift.newShiftColumns![2].controller.text = t.breakMin!;
                          shift.newShiftColumns![3].controller.text = t.notes!;
                          shift.selectedShift.value = t;
                          shift.newShiftColumns![4].controller.text = t.isStat! ? '1' : "0";
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) => CreateShift(
                              editShift: true,
                            ),
                          );
                          wantDismiss = false;
                        } else {
                          shift.deleteShift(id: t.id!).then((onValue) => wantDismiss = true);
                        }
                        return wantDismiss;
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ProjectColors.pureBlackColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: width * .02,
                              height: height * .1,
                              decoration: BoxDecoration(
                                color: Color(int.parse(t.jobFrom!.jobColor!)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(width: width * .02),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      textWidget(text: t.jobFrom!.jobName, fontSize: .018, color: ProjectColors.whiteColor),
                                      SizedBox(width: width * .01),
                                      Visibility(visible: t.isStat!, child: Icon(Icons.star, size: height * .02, color: Color(0xFFFFC107))),
                                    ],
                                  ),
                                  SizedBox(height: height * .01),
                                  textWidget(
                                    text: "start → ${toHmAm(t.start!)}  •  Break : ${toHmAm(t.breakMin!, onlyMinutes: true)} min",
                                    fontSize: .018,
                                    color: ProjectColors.whiteColor,
                                  ),
                                  SizedBox(height: height * .005),
                                  textWidget(
                                    text: "end → ${toHmAm(t.end!)} •  Total hours : ${diffHoursMinutes(t.start!, t.end!)}",
                                    fontSize: .018,
                                    color: ProjectColors.whiteColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ========================================================================
                    ),
                  ),
                )
                .toList(),
            SizedBox(height: height * .02),
            normalButton(
                title: "Create Shift",
                cWidth: .4,
                callback: () {
                  showCupertinoModalPopup(context: context, builder: (context) => CreateShift());
                }),
          ]),
        ),
      ),
    );
  }
}

class CreateShift extends StatelessWidget {
  final bool? editShift;
  CreateShift({this.editShift = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: height * .5,
        child: Popup(
          title: DateFormat('MMMM d').format(shift.selectedDay!.value),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: height * .02),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: width * .05,
                    children: shift.newShiftColumns!
                        .map(
                          (f) => f.title == "Is this stat day ?"
                              ? SizedBox()
                              : f.title == "Note"
                                  ? TextField(
                                      controller: f.controller,
                                      decoration: const InputDecoration(labelText: 'Note', isDense: false),
                                      onSubmitted: (changed) {
                                        f.controller.text = changed;
                                        shift.newShiftColumns!.refresh();
                                      },
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        pickCupertinoDateTime(context,
                                                baseDate: shift.selectedDay!.value, minutesOnly: f.title == "Unpaid break time" ? true : false)
                                            .then((onValue) {
                                          // or .toUtc()
                                          final dateFormat = DateFormat('yyyy-MM-dd hh:mm a').format(onValue!);
                                          f.controller.text = dateFormat;
                                          shift.newShiftColumns!.refresh();
                                          print(f.controller.text);
                                        });
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        width: width * .4,
                                        margin: EdgeInsets.only(top: height * .02),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            CardFields(
                                              title: f.title,
                                              subTitle: f.controller.text != ''
                                                  ? toHmAm(f.controller.text, onlyMinutes: f.title == "Unpaid break time" ? true : false)
                                                  : f.controller.text,
                                            ),
                                            Divider(color: ProjectColors.blackColor.withOpacity(0.5)),
                                          ],
                                        ),
                                      ),
                                    ),
                        )
                        .toList(),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: shift.newShiftColumns![4].controller.text == '0' ? false : true,
                        onChanged: (onChanged) {
                          shift.newShiftColumns![4].controller.text = onChanged! ? "1" : '0';
                          shift.newShiftColumns!.refresh();
                        },
                      ),
                      textWidget(
                        text: shift.newShiftColumns![4].title,
                        fontSize: .018,
                      ),
                    ],
                  ),
                  SizedBox(height: height * .01),
                  Wrap(spacing: 8, children: [
                    UniversalChoiceChips<JobData>(
                      items: account.jobs!,
                      labelOf: (j) => j.jobName!,
                      value: shift.selectedJob.value,
                      keyOf: (j) => j.jobName!,
                      onChanged: (j) {
                        shift.selectedJob.value = j;
                      },
                    ),
                  ]),
                  SizedBox(height: height * .02),
                  normalButton(
                      title: editShift! ? 'Edit Shift' : 'Add Shift',
                      cWidth: .4,
                      callback: () {
                        if (editShift!) {
                          shift.editShift();
                        } else {
                          shift.saveShift();
                        }
                      }),
                  SizedBox(height: height * .01),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
