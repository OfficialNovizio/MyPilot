import 'package:emptyproject/Working%20UI/Account/Account%20Getx.dart';
import 'package:emptyproject/Working%20UI/Account/Account.dart';
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
import '../../screens/analytic_screen.dart';
import '../../screens/salary_detailed_screen.dart';
import '../app_controller.dart';
import '../../utils/time_utils.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});
  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<PayMarker>> payMarkers = account.computePayMarkers(focusedDay: DateTime.now());
    return Column(
      children: [
        TableCalendar<PayMarker>(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2035, 12, 31),
          focusedDay: DateTime(2025, 11, 16),
          selectedDayPredicate: (d) => isSameDay(d, shift.selectedDay!.value),
          eventLoader: (day) => payMarkers[DateTime(day.year, day.month, day.day)] ?? const [],
          onDaySelected: (selected, focused) {
            shift.selectedDay!.value = selected;
            for (var i in shift.newShiftColumns!) {
              if (i.title == 'Is this stat day ?') {
                i.controller.text = '0';
              } else {
                i.controller.text = '';
              }
            }
            shift.getShiftsForDay();
            showCupertinoModalPopup(
              context: context,
              builder: (context) => ShiftDayCard(),
            );
          },
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              color: ProjectColors.whiteColor,
              fontSize: height * .018,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideTextStyle: TextStyle(color: ProjectColors.errorColor.withOpacity(0.5), fontSize: height * .015),
            outsideDaysVisible: true,
            defaultTextStyle: TextStyle(color: ProjectColors.whiteColor, fontSize: height * .015),
            todayDecoration: BoxDecoration(color: ProjectColors.greenColor, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Colors.white60, shape: BoxShape.circle),
            markersMaxCount: 4,
          ),
          calendarBuilders: CalendarBuilders<PayMarker>(
            markerBuilder: (context, day, events) {
              final dotsMap = shift.buildJobDotsAll(perShift: true); // per SHIFT, not per company
              DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
              // --- bottom dots: shifts that day (from your saved shifts) ---
              final jobDots = dotsMap[_d(day)] ?? const <JobDot>[];
              final bottomDots = jobDots.isEmpty
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: jobDots
                            // drop .take(3) if you want all shift dots visible
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

              // --- payday badge: events are List<PayMarker> (paydays only) ---
              if (events.isEmpty) return bottomDots;

              final cBg = events.first.color; // first payday's job color
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
                  child: Text('\$', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cFg)),
                ),
              );

              return Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(child: bottomDots), // shift dots
                paydayBadge, // payday badge
              ]);
            },
          ),
        ),
        SizedBox(height: height * .04),
        _MonthSummary(),
        _PayPeriods(),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () => Get.to(
          () => SalaryDetailsScreen(month: DateTime.now()),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ProjectColors.greenColor,
            borderRadius: BorderRadius.circular(30),
          ),
          margin: EdgeInsets.symmetric(horizontal: width * .02),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  textWidget(text: "Month Summary", fontSize: .02, fontWeight: FontWeight.bold),
                  textWidget(
                      text: "Combined:  ${shift.combinedHours!.value} h • \$${shift.combinedPay!.value}",
                      fontSize: .015,
                      fontWeight: FontWeight.bold),
                ],
              ),
              textWidget(text: "${DateTime.now().month}", fontSize: .02, fontWeight: FontWeight.bold),
              SizedBox(height: height * .01),
              for (final j in shift.combinedMonthStat!.value!.values)
                Padding(
                  padding: EdgeInsets.only(top: height * .01),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: Color(int.parse(j.totals.colorHex!)), radius: height * .01),
                          SizedBox(width: width * .02),
                          textWidget(text: j.totals.jobName, fontSize: .02, fontWeight: FontWeight.w400),
                        ],
                      ),
                      textWidget(text: '${j.totals.hours} h     •    \$${j.totals.pay}', fontSize: .02, fontWeight: FontWeight.w400),
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PayPeriods extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final j in shift.combinedMonthStat!.value!.values)
          Padding(
              padding: EdgeInsets.only(top: height * .01),
              child: CustomCard(
                color: ProjectColors.whiteColor,
                child: Padding(
                  padding: EdgeInsets.all(height * .01),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(backgroundColor: Color(int.parse(j.totals.colorHex!)), radius: 6),
                      SizedBox(width: width * .01),
                      textWidget(
                        text: "biweekly",
                        // text: "${j.totals.jobName} — ${j.totals. == "biweekly" ? "Biweekly" : "Weekly"}",
                        fontSize: .018,
                        fontWeight: FontWeight.bold,
                      ),
                    ]),
                    SizedBox(height: height * .002),

                    textWidget(
                      text: "Next deposit: November 21",
                      fontSize: .015,
                    ),
                    // textWidget(
                    //   text: "Next deposit: ${monthName(j.nextDeposit!)} "
                    //       "${j.nextDeposit!.hour.toString().padLeft(2, '0')}:"
                    //       "${j.nextDeposit!.minute.toString().padLeft(2, '0')}",
                    //   fontSize: .015,
                    // ),
                    SizedBox(height: height * .01),
                    Column(
                      children: [
                        // for (final p in j.series)
                        Padding(
                          padding: EdgeInsets.only(bottom: height * .001),
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
                                        "mon → tue",
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      // Text(
                                      //   "${monthDay(period.start)} → ${monthDay(period.end)}",
                                      //   style: const TextStyle(fontWeight: FontWeight.w600),
                                      // ),
                                      const SizedBox(height: 4),
                                      // Text(
                                      //   "Hours: ${period.hours.toStringAsFixed(2)}   •   OT: ${period.overtime.toStringAsFixed(2)}",
                                      //   style: const TextStyle(color: Colors.grey),
                                      // ),
                                      Text(
                                        "Hours: 50   •   OT: 0",
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
                                      "1200",
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    // Text(
                                    //   "\$${period.pay.toStringAsFixed(2)}",
                                    //   style: const TextStyle(fontWeight: FontWeight.w700),
                                    // ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.attach_money, size: 14, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Deposit: 16 november",
                                          // "Deposit: ${monthDay(period.deposit)}",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              )),
      ],
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final dynamic period;
  const _PeriodRow({required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  "Hours: ${period.hours.toStringAsFixed(2)}   •   OT: ${period.overtime.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Est. Cheque", style: TextStyle(fontSize: 12, color: Colors.grey)),
              // Text(
              //   "\$${period.pay.toStringAsFixed(2)}",
              //   style: const TextStyle(fontWeight: FontWeight.w700),
              // ),
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
    );
  }
}

// class _PeriodCard extends StatelessWidget {
//   final dynamic period;
//   const _PeriodCard({required this.period});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(right: 8),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: const Color(0xFF121315),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF232427)),
//       ),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text("${monthDay(period.start)} → ${monthDay(period.end)}", style: const TextStyle(fontWeight: FontWeight.w600)),
//         const SizedBox(height: 4),
//         Text("Hours: ${period.hours.toStringAsFixed(2)}"),
//         Text("OT: ${period.overtime.toStringAsFixed(2)}"),
//         Text("Est. Cheque: \$${period.pay.toStringAsFixed(2)}"),
//         const SizedBox(height: 4),
//         Text("Deposit: ${monthDay(period.deposit)}"),
//       ]),
//     );
//   }
// }

class ShiftDayCard extends StatelessWidget {
  const ShiftDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
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
