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
import '../../../models/Overview Model.dart';
import '../../Account/Account.dart';

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

      return shift.state.value == ButtonState.loading
          ? Padding(padding: EdgeInsets.only(top: height * .4), child: loader())
          : Column(
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

                    // for(var files in shift.shifts!){
                    //   print(files.month);
                    // }

                    // reset inputs
                    for (final col in shift.newShiftColumns!) {
                      if (col.title == 'Is this stat day ?') {
                        col.controller.text = '0';
                      } else if (col.title == 'Unpaid break time') {
                        final now = DateTime.now();
                        col.controller.text = DateTime(now.year, now.month, now.day, 0, 0).toString();
                        print(col.controller.text);
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
                      DateTime d(DateTime x) => DateTime(x.year, x.month, x.day);

                      // shift dots
                      final jobDots = dotsMap[d(day)] ?? const <JobDot>[];
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
                _MonthSummary(),
                _WeeklyBreakdownByJob(),
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
      // final stats = shift.combinedMonthStat?.value;
      // if (stats == null || stats.isEmpty) return const SizedBox.shrink();

      // final income = shift.combinedPay!.value;
      // final hours = shift.combinedHours!.value;

      return GestureDetector(
        onTap: () {},
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: width * .01),
          padding: EdgeInsets.all(height * .018),
          decoration: BoxDecoration(
            color: ProjectColors.greenColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(.05),
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
                fontSize: .025,
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
                        fontSize: .02,
                        color: ProjectColors.pureBlackColor.withOpacity(.7),
                      ),
                      SizedBox(height: height * .004),
                      textWidget(
                        text: "\$${shift.combinedPay!.value.toStringAsFixed(0)}",
                        fontSize: .04,
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
                        fontSize: .02,
                        color: ProjectColors.pureBlackColor.withOpacity(.7),
                      ),
                      SizedBox(height: height * .004),
                      textWidget(
                        text: "${shift.combinedHours!.value} H",
                        fontSize: .04,
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
      // final weeklyMap = shift.weeklyMonthBreakdown.value;
      // final monthStats = shift.combinedMonthStat?.value;

      // if (weeklyMap == null || monthStats == null || monthStats.isEmpty) {
      //   return const SizedBox.shrink();
      // }

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
              ],
            ),
          ),
          shift.combinedStats.isNotEmpty
              ? Column(
                  children: [
                    ...shift.combinedStats[0].jobs!.map(
                      (t) => Padding(
                        padding: EdgeInsets.symmetric(vertical: height * .006),
                        child: WeeklyJobCard(overview: t),
                      ),
                    ),
                  ],
                )
              : SizedBox()
        ],
      );
    });
  }
}

// Per-job weekly card
class WeeklyJobCard extends StatelessWidget {
  final JobWeekly overview;

  const WeeklyJobCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          //View Job Name and total hours and pay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: height * .03,
                    backgroundColor: Color(int.parse(overview.colorHex)),
                    child: textWidget(
                      text: overview.jobName[0],
                      fontSize: .03,
                      color: ProjectColors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: width * .02),
                  textWidget(
                    text: overview.jobName.toUpperCase(),
                    fontSize: .02,
                    fontWeight: FontWeight.bold,
                    color: ProjectColors.whiteColor,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  textWidget(
                    text: "\$ ${overview.totals.pay}",
                    fontSize: .025,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.whiteColor,
                  ),
                  SizedBox(height: height * .004),
                  textWidget(
                    text: "${overview.totals.hours} hours",
                    fontSize: .025,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.whiteColor,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: height * .006),
          Wrap(
            spacing: 5,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: overview.weeks
                .map(
                  (w) => Container(
                    padding: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .03),
                    decoration: BoxDecoration(color: ProjectColors.greenColor, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textWidget(
                          text: "Week ${w.weekIndex.toString()}",
                          fontSize: .018,
                          color: ProjectColors.pureBlackColor.withOpacity(0.9),
                        ),
                        SizedBox(width: width * .02),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            textWidget(
                              text: "\$ ${w.pay}",
                              fontSize: .018,
                              fontWeight: FontWeight.bold,
                              color: ProjectColors.pureBlackColor.withOpacity(0.9),
                            ),
                            textWidget(
                              text: "${w.hours}h",
                              fontSize: .018,
                              fontWeight: FontWeight.bold,
                              color: ProjectColors.pureBlackColor.withOpacity(0.9),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
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
                                        int? index = shift.newShiftColumns!.indexWhere((test) => test.title == f.title);
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (context) => PickShiftTime(columnIndex: index),
                                        );
                                        // pickCupertinoDateTime(context,
                                        //         baseDate: shift.selectedDay!.value, minutesOnly: f.title == "Unpaid break time" ? true : false)
                                        //     .then((onValue) {
                                        //   // or .toUtc()
                                        //   final dateFormat = DateFormat('yyyy-MM-dd hh:mm a').format(onValue!);
                                        //   f.controller.text = dateFormat;
                                        //   shift.newShiftColumns!.refresh();
                                        //   print(f.controller.text);
                                        // });
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
                          if (shift.newShiftColumns![0].controller.text.isEmpty || shift.newShiftColumns![1].controller.text.isEmpty) {
                            showSnackBar("Error Input Required", "Start time and end time are required to create a shift.");
                          } else {
                            shift.saveShift();
                          }
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
