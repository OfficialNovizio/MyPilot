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
import '../../Account/Active Jobs.dart';
import '../../Account/Add New Job.dart';
import 'Add Shit and View Shifts.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return shift.state.value == ButtonState.loading
          ? Padding(padding: EdgeInsets.only(top: height * .4), child: loader())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime(2020, 1, 1),
                  lastDay: DateTime(2035, 12, 31),
                  rowHeight: height * .042,
                  focusedDay: shift.selectedMonth!.value,
                  eventLoader: (day) {
                    final cell = shift.payCycles![dayKey(day)];
                    return cell == null ? const [] : [cell];
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (_, day, events) {
                      // your shift dots (keep your function if you want)
                      final dotsMap = shift.buildJobDotsAll(perShift: true);
                      final jobDots = dotsMap[dayKey(day)] ?? const <JobDot>[];

                      Widget bottomDots() => jobDots.isEmpty
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
                                          decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
                                        ))
                                    .toList(),
                              ),
                            );

                      if (events.isEmpty) return bottomDots();

                      final badge = events.first as PayCell;
                      final fg = badge.color.computeLuminance() < 0.5 ? Colors.white : Colors.black;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(child: bottomDots()),
                          Positioned(
                            right: -1,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: badge.color,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: fg.withOpacity(.25)),
                              ),
                              child: Text(
                                badge.count == 1 ? '\$' : '\$${badge.count}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  onDaySelected: (selected, focused) {
                    shift.selectedDay!.value = selected;
                    shift.getShiftsForDay();
                    callPopup(ShiftDayCard());
                  },
                  onPageChanged: (focused) {
                    shift.selectedMonth!.value = focused;
                    shift.loadShifts();
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
                ),

                // TableCalendar<PayMarker>(
                //   rowHeight: height * .042,
                //   firstDay: DateTime(2020, 1, 1),
                //   lastDay: DateTime(2035, 12, 31),
                //   focusedDay: shift.selectedMonth!.value,
                //   selectedDayPredicate: (d) => shift.selectedDay?.value != null && isSameDay(d, shift.selectedDay!.value),
                //   // eventLoader: (day) => [PayMarker(color: Colors.red, jobId: 323, jobName: 'J')],
                //   eventLoader: (day) => payMarkers[DateTime(day.year, day.month, day.day)] ?? const [],
                //   calendarBuilders: CalendarBuilders<PayMarker>(
                //     markerBuilder: (context, day, events) {
                //       final dotsMap = shift.buildJobDotsAll(perShift: true);
                //       DateTime d(DateTime x) => DateTime(x.year, x.month, x.day);
                //
                //       // shift dots
                //       final jobDots = dotsMap[d(day)] ?? const <JobDot>[];
                //       final bottomDots = jobDots.isEmpty
                //           ? const SizedBox.shrink()
                //           : Align(
                //               alignment: Alignment.bottomCenter,
                //               child: Row(
                //                 mainAxisSize: MainAxisSize.min,
                //                 children: jobDots
                //                     .take(3)
                //                     .map((e) => Container(
                //                           width: 6,
                //                           height: 6,
                //                           margin: const EdgeInsets.symmetric(horizontal: 1.5),
                //                           decoration: BoxDecoration(
                //                             color: e.color,
                //                             shape: BoxShape.circle,
                //                           ),
                //                         ))
                //                     .toList(),
                //               ),
                //             );
                //
                //       // payday badge
                //       if (events.isEmpty) return bottomDots;
                //
                //       final cBg = events.first.color;
                //       final cFg = cBg!.computeLuminance() < 0.5 ? Colors.white : Colors.black;
                //
                //       final paydayBadge = Positioned(
                //         right: -1,
                //         top: -2,
                //         child: Container(
                //           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                //           decoration: BoxDecoration(
                //             color: cBg,
                //             borderRadius: BorderRadius.circular(6),
                //             border: Border.all(color: cFg.withOpacity(.25)),
                //           ),
                //           child: textWidget(
                //             text: '\$',
                //             fontSize: .01,
                //             fontWeight: FontWeight.w700,
                //             color: cFg,
                //           ),
                //         ),
                //       );
                //
                //       return Stack(
                //         clipBehavior: Clip.none,
                //         children: [
                //           Positioned.fill(child: bottomDots),
                //           paydayBadge,
                //         ],
                //       );
                //     },
                //   ),
                //   onDaySelected: (selected, focused) {
                //     shift.selectedDay!.value = selected;
                //     shift.getShiftsForDay();
                //     callPopup(ShiftDayCard());
                //   },
                //   onPageChanged: (focused) {
                //     shift.selectedMonth!.value = focused;
                //     shift.loadShifts();
                //   },
                //   calendarFormat: CalendarFormat.month,
                //   startingDayOfWeek: StartingDayOfWeek.sunday,
                //   headerStyle: HeaderStyle(
                //     titleCentered: true,
                //     formatButtonVisible: false,
                //     titleTextStyle: TextStyle(
                //       color: ProjectColors.whiteColor,
                //       fontSize: height * .018,
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                //   calendarStyle: CalendarStyle(
                //     outsideTextStyle: TextStyle(
                //       color: ProjectColors.errorColor.withOpacity(0.5),
                //       fontSize: height * .015,
                //     ),
                //     outsideDaysVisible: true,
                //     defaultTextStyle: TextStyle(
                //       color: ProjectColors.whiteColor,
                //       fontSize: height * .015,
                //     ),
                //     todayDecoration: const BoxDecoration(
                //       color: ProjectColors.greenColor,
                //       shape: BoxShape.circle,
                //     ),
                //     selectedDecoration: const BoxDecoration(
                //       color: Colors.white60,
                //       shape: BoxShape.circle,
                //     ),
                //     markersMaxCount: 4,
                //   ),
                // ),
                SizedBox(height: height * .02),
                shift.currentMonth!.value == null
                    ? Padding(
                        padding: EdgeInsets.only(top: height * 0),
                        child: EmptyInsightsScreen(
                          title: 'Start tracking to unlock insights',
                          subTitle: 'Log a shift to see hours, earnings, and patterns this month.',
                          showButton: false,
                        ),
                      )
                    : Column(
                        children: [
                          _MonthSummary(),
                          _WeeklyBreakdownByJob(),
                        ],
                      ),
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
      return Container(
        margin: EdgeInsets.symmetric(horizontal: width * .01),
        padding: EdgeInsets.all(height * .015),
        decoration: BoxDecoration(
          color: ProjectColors.greenColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textWidget(
              text: "This Month",
              fontSize: .025,
              fontWeight: FontWeight.bold,
              color: ProjectColors.pureBlackColor,
            ),
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
                      text: "\$${shift.combinedStats.value!.totals!.pay.toStringAsFixed(0)}",
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
                      text: "${shift.combinedStats.value!.totals!.hours} H",
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
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * .01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                textWidget(
                  text: "Weekly Job Breakdown",
                  fontSize: .02,
                  fontWeight: FontWeight.bold,
                  color: ProjectColors.whiteColor,
                ),
              ],
            ),
          ),
          Column(
            children: [
              ...shift.combinedStats.value!.jobs!.map(
                (overview) => Padding(
                  padding: EdgeInsets.symmetric(vertical: height * .006),
                  child: DarkCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        //View Job Name and total hours and pay
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: width * .015,
                              height: height * .03,
                              decoration: BoxDecoration(
                                color: Color(int.parse(overview.colorHex)),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            SizedBox(width: width * .02),
                            Icon(
                              Icons.join_full,
                              color: ProjectColors.whiteColor,
                              size: height * .03,
                            ),
                            SizedBox(width: width * .02),
                            textWidget(
                              text: overview.jobName,
                              fontSize: .02,
                              color: ProjectColors.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                            Spacer(),
                            textWidget(
                              text: "\$ ${overview.totals.pay} in ${overview.totals.hours} h",
                              fontSize: .02,
                              fontWeight: FontWeight.w600,
                              color: ProjectColors.whiteColor,
                            ),
                          ],
                        ),
                        SizedBox(height: height * .02),
                        Wrap(
                          spacing: 5,
                          runSpacing: 0,
                          alignment: WrapAlignment.center,
                          children: overview.weeks
                              .map(
                                (w) => DarkCard(
                                  color: ProjectColors.greenColor,
                                  opacity: 1,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      textWidget(
                                        text: "Week ${w.weekIndex.toString()}",
                                        color: ProjectColors.whiteColor.withOpacity(0.9),
                                      ),
                                      SizedBox(width: width * .02),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          textWidget(
                                            text: "\$ ${w.pay}",
                                            fontSize: .018,
                                            fontWeight: FontWeight.bold,
                                            color: ProjectColors.whiteColor.withOpacity(0.9),
                                          ),
                                          textWidget(
                                            text: "${w.hours}h",
                                            fontSize: .018,
                                            fontWeight: FontWeight.bold,
                                            color: ProjectColors.whiteColor.withOpacity(0.9),
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
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
