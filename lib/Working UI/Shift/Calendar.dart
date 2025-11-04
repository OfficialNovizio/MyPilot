import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Shift/Shift%20Getx.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    final c = Get.find<AppController>();
    return Obx(
      () => Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: shift.focusedDay.value,
            selectedDayPredicate: (d) => isSameDay(d, shift.selectedDay!.value),
            onDaySelected: (selected, focused) {
              setState(() {
                shift.selectedDay!.value = selected;
                shift.focusedDay.value = focused;
              });
              shift.openDaySheet(c, selected);
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: c.settings.value.weekStartsOnMonday ? StartingDayOfWeek.monday : StartingDayOfWeek.sunday,
            headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
            calendarStyle: const CalendarStyle(
              outsideTextStyle: TextStyle(color: Colors.red),
              outsideDaysVisible: true,
              defaultTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
              markersMaxCount: 4,
            ),
            eventLoader: (day) => shift.eventsForDay(c, day),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                final ctr = Get.find<AppController>();
                final shifts = events.where((e) => (e as DayEvent).type == 'shift').cast<DayEvent>().toList();
                final stats = events.where((e) => (e as DayEvent).type == 'stat').cast<DayEvent>().toList();
                final pays = events.where((e) => (e as DayEvent).type == 'payday').cast<DayEvent>().toList();

                final dots = <Widget>[];
                for (final e in shifts.take(3)) {
                  final job = ctr.jobs.firstWhereOrNull((j) => j.id == e.jobId);
                  dots.add(Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: ctr.jobColor(job?.colorHex ?? '#16a34a'),
                      shape: BoxShape.circle,
                    ),
                  ));
                }

                // Payday badge follows job color
                Color paydayBg = Colors.green.shade700;
                Color paydayFg = Colors.white;
                if (pays.isNotEmpty) {
                  final firstPay = pays.first;
                  final job = ctr.jobs.firstWhereOrNull((j) => j.id == firstPay.jobId);
                  paydayBg = ctr.jobColor(job?.colorHex ?? '#16a34a');
                  paydayFg = paydayBg.computeLuminance() < 0.5 ? Colors.white : Colors.black;
                }

                return Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(mainAxisSize: MainAxisSize.min, children: dots),
                    ),
                  ),
                  if (pays.isNotEmpty)
                    Positioned(
                      right: -1,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: paydayBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: paydayFg.withOpacity(.25)),
                        ),
                        child: Text(
                          '\$',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: paydayFg,
                          ),
                        ),
                      ),
                    ),
                  if (stats.isNotEmpty)
                    const Positioned(
                      left: -1,
                      top: -4,
                      child: Icon(Icons.star, size: 10, color: Color(0xFFFFC107)),
                    ),
                ]);
              },
            ),
          ),
          SizedBox(height: height * .02),
          _MonthSummary(month: shift.focusedDay.value),
          _PayPeriods(),
        ],
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  final DateTime month;
  const _MonthSummary({required this.month});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final perJob = c.monthSummary(month);
    final combined = perJob.values.fold<Map<String, double>>(
      {'hours': 0.0, 'pay': 0.0},
      (a, b) {
        a['hours'] = (a['hours'] ?? 0) + (b['hours'] ?? 0);
        a['pay'] = (a['pay'] ?? 0) + (b['pay'] ?? 0);
        return a;
      },
    );
    return GestureDetector(
      onTap: () => Get.to(
        () => SalaryDetailsScreen(month: month),
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
                    text: "Combined: ${(combined['hours'] ?? 0).toStringAsFixed(1)} h • \$${(combined['pay'] ?? 0).toStringAsFixed(2)}",
                    fontSize: .015,
                    fontWeight: FontWeight.bold),
              ],
            ),
            textWidget(text: "${month.month}/${month.year}", fontSize: .02, fontWeight: FontWeight.bold),
            SizedBox(height: height * .01),
            for (final j in c.jobs)
              Padding(
                padding: EdgeInsets.only(top: height * .01),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: c.jobColor(j.colorHex), radius: height * .01),
                        SizedBox(width: width * .02),
                        textWidget(text: j.name, fontSize: .02, fontWeight: FontWeight.w400),
                      ],
                    ),
                    textWidget(
                        text: '${(perJob[j.id]!['hours'] ?? 0.0).toStringAsFixed(1)} h   •   \$${(perJob[j.id]!['pay'] ?? 0.0).toStringAsFixed(2)}',
                        fontSize: .02,
                        fontWeight: FontWeight.w400),
                  ],
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _PayPeriods extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final j in c.jobs) Padding(
          padding: EdgeInsets.only(top: height * .01),
          child: _JobPeriods(jid: j.id),
        ),
      ],
    );
  }
}

class _JobPeriods extends StatelessWidget {
  final String jid;
  const _JobPeriods({required this.jid});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final j = c.jobs.firstWhere((x) => x.id == jid);
    final series = c.periodsAround(j, back: 0, forward: 2);
    final next = c.nextDeposit(j);
    return CustomCard(
      color: ProjectColors.whiteColor,
      child: Padding(
        padding: EdgeInsets.all(height * .01),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: c.jobColor(j.colorHex), radius: 6),
            SizedBox(width: width * .01),
            textWidget(
              text: "${j.name} — ${j.payFrequency == "biweekly" ? "Biweekly" : "Weekly"}",
              fontSize: .018,
              fontWeight: FontWeight.bold,
            ),
          ]),
          SizedBox(height: height * .002),
          if (next != null)
            textWidget(
              text: "Next deposit: ${monthDay(next)} "
                  "${next.hour.toString().padLeft(2, '0')}:"
                  "${next.minute.toString().padLeft(2, '0')}",
              fontSize: .015,
            ),
          SizedBox(height: height * .01),
          Column(
            children: [
              for (final p in series)
                Padding(
                  padding:  EdgeInsets.only(bottom: height * .001),
                  child: _PeriodRow(period: p),
                ),
            ],
          ),
        ]),
      ),
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
              Text(
                "\$${period.pay.toStringAsFixed(2)}",
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
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final dynamic period;
  const _PeriodCard({required this.period});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF121315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232427)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${monthDay(period.start)} → ${monthDay(period.end)}", style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text("Hours: ${period.hours.toStringAsFixed(2)}"),
        Text("OT: ${period.overtime.toStringAsFixed(2)}"),
        Text("Est. Cheque: \$${period.pay.toStringAsFixed(2)}"),
        const SizedBox(height: 4),
        Text("Deposit: ${monthDay(period.deposit)}"),
      ]),
    );
  }
}
