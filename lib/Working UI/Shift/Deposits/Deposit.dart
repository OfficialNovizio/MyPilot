import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:flutter/material.dart';
import '../../Constant UI.dart';
import '../../Controllers.dart';
import '../Overview/Overview.dart';
import 'Deposit Getx.dart';
import 'Deposit UI Elements.dart';

class DepositsTab extends StatefulWidget {
  const DepositsTab({super.key});

  @override
  State<DepositsTab> createState() => _DepositsTabState();
}

class _DepositsTabState extends State<DepositsTab> {
  @override
  void initState() {
    deposit.setOverviews();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: height * .02, bottom: height * .02),
              child: MonthPill(
                label: deposit.formatMonth(),
                onPrev: deposit.goToPreviousMonth,
                onNext: deposit.goToNextMonth,
                canGoNext: !DateTime(
                  deposit.selectedMonth.value.year,
                  deposit.selectedMonth.value.month + 1,
                  1,
                ).isAfter(DateTime(DateTime.now().year, DateTime.now().month, 1)),
              ),
            ),
          ),
          shift.shifts!.isEmpty || shift.shifts!.firstWhere((m) => m.month == monthName(overview.selectedMonth.value)).dates!.length < 10
              ? Padding(
                  padding: EdgeInsets.only(top: height * .15),
                  child: EmptyInsightsScreen(
                    title: 'Start tracking to unlock insights',
                    subTitle: 'We need about 10 shifts to show accurate hours, earnings, and monthly trends',
                  ),
                )
              : Column(
                  children: [
                    DepositInsightsScreen(vm: deposit.depositInsight!.value!, showAll: true),

                    // _WeeklyDepositsCard(),
                    SizedBox(height: height * .018),
                    MonthlyKpiLineCard(
                      title: deposit.weekChart!.value!.title,
                      totalText: deposit.weekChart!.value!.totalText,
                      changeText: deposit.weekChart!.value!.changeText,
                      xLabels: deposit.weekChart!.value!.xLabels,
                      values: deposit.weekChart!.value!.values,
                      color: deposit.weekChart!.value!.color,
                    ),
                    SizedBox(height: height * .018),
                    MonthlyKpiBarCard(
                      title: deposit.sixMonthChart!.value!.title,
                      totalText: deposit.sixMonthChart!.value!.totalText,
                      changeText: deposit.sixMonthChart!.value!.changeText,
                      xLabels: deposit.sixMonthChart!.value!.xLabels,
                      values: deposit.sixMonthChart!.value!.values,
                      color: ProjectColors.greenColor,
                    ),
                  ],
                ),
          SizedBox(height: height * .04),
        ],
      ),
    );
  }
}
