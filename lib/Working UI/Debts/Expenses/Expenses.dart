import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/Expense Model.dart';
import '../../Cards and Account/Cards.dart';
import '../../Constants.dart';
import '../All Debts/Combined Data Dashboard.dart';
import '../Debt Dashboard/New Data.dart';
import 'Add Expense.dart';
import 'Expenses Getx.dart';

/// ===============================
/// MODELS
/// ===============================

/// ===============================
/// SCREEN 1: EXPENSES
/// ===============================

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    expense.loadExpenses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => expense.expenses.isEmpty
        ? Padding(
            padding: EdgeInsets.only(top: height * .01),
            child: DarkCard(
              child: InkWell(
                onTap: () {
                  Get.to(() => NewExpense());
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      width: height * .05,
                      height: height * .05,
                      decoration: BoxDecoration(
                        color: ProjectColors.whiteColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add, color: ProjectColors.whiteColor),
                    ),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textWidget(text: "Add an Expense", fontSize: .02, color: ProjectColors.whiteColor, fontWeight: FontWeight.bold),
                          SizedBox(height: height * .005),
                          textWidget(text: 'Fixed · Variable · Subscription · Bill', color: ProjectColors.whiteColor),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: ProjectColors.whiteColor),
                  ],
                ),
              ),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * .04),
              InsightCard(
                title: "Payday buffer",
                leftMain: "\$430",
                leftTag: const Tag(text: "Safe", color: ProjectColors.greenColor),
                leftSub: "• -\$320 this month",
                rightWidget: Container(),
                onTap: () async {
                  showCupertinoModalPopup(context: context, builder: (_) => NowToPaydayScreen());
                },
              ),
              SizedBox(height: height * .01),
              DarkCard(
                color: ProjectColors.greenColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(text: 'This Month', fontSize: .02, fontWeight: FontWeight.w900),
                    SizedBox(height: height * .01),
                    Row(
                      children: ['Fixed', 'Variable', 'Total']
                          .map(
                            (t) => Padding(
                              padding: EdgeInsets.only(right: width * .1),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  textWidget(text: t, fontWeight: FontWeight.w700, fontSize: .018),
                                  SizedBox(height: height * .005),
                                  textWidget(
                                    text: t == 'Fixed'
                                        ? money(expense.totalFixedExpense!.value)
                                        : t == 'Variable'
                                            ? money(expense.totalVariableExpense!.value)
                                            : money(expense.totalFixedExpense!.value + expense.totalVariableExpense!.value),
                                    fontWeight: FontWeight.w900,
                                    fontSize: .022,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: height * .01),
                    SizedBox(
                      width: width * .8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: expense.totalFixedExpense!.value + expense.totalVariableExpense!.value <= 0
                              ? 0.0
                              : (expense.totalFixedExpense!.value / expense.totalFixedExpense!.value + expense.totalVariableExpense!.value)
                                  .clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: ProjectColors.pureBlackColor.withOpacity(0.06),
                          valueColor: const AlwaysStoppedAnimation(ProjectColors.pureBlackColor),
                        ),
                      ),
                    ),
                    SizedBox(height: height * .01),
                    textWidget(text: 'Based on your monthly & per-paycheque expenses', fontSize: .015),
                  ],
                ),
              ),
              SizedBox(height: height * .01),
              DarkCard(
                child: InkWell(
                  onTap: () {
                    Get.to(() => NewExpense());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Container(
                        width: height * .05,
                        height: height * .05,
                        decoration: BoxDecoration(
                          color: ProjectColors.whiteColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add, color: ProjectColors.whiteColor),
                      ),
                      SizedBox(width: width * .02),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            textWidget(text: "Add an Expense", fontSize: .02, color: ProjectColors.whiteColor, fontWeight: FontWeight.bold),
                            SizedBox(height: height * .005),
                            textWidget(text: 'Fixed · Variable · Subscription · Bill', color: ProjectColors.whiteColor),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: ProjectColors.whiteColor),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height * .02),
              Visibility(
                visible: expense.fixedExpenses.isEmpty ? false : true,
                child: Padding(
                  padding: EdgeInsets.only(left: width * .02, bottom: height * .01),
                  child: textWidget(text: 'Fixed Expenses', color: ProjectColors.whiteColor, fontSize: .02, fontWeight: FontWeight.bold),
                ),
              ),
              DarkCard(
                child: Column(
                  children: [
                    ...expense.fixedExpenses
                        .map((f) => InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: width * .01),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: height * .04,
                                      height: height * .04,
                                      decoration: BoxDecoration(
                                        color: ProjectColors.whiteColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        expense.categoryIcon(f.category),
                                        color: ProjectColors.whiteColor,
                                        size: height * .02,
                                      ),
                                    ),
                                    SizedBox(width: width * .015),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          textWidget(text: f.name, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor, fontSize: .02),
                                          // SizedBox(height: height * .01),
                                          textWidget(text: f.category, color: ProjectColors.whiteColor, fontSize: 0.018),
                                          textWidget(text: f.notes, color: ProjectColors.whiteColor, fontSize: 0.018),
                                        ],
                                      ),
                                    ),
                                    // deltaWidget,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        textWidget(
                                            text: money(f.amount), color: ProjectColors.whiteColor, fontSize: 0.02, fontWeight: FontWeight.w900),
                                        textWidget(text: f.accountName, color: ProjectColors.whiteColor, fontSize: 0.018),
                                        textWidget(text: f.frequency, color: ProjectColors.whiteColor, fontSize: 0.018),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
              SizedBox(height: height * .02),
              Visibility(
                visible: expense.variableExpense.isEmpty ? false : true,
                child: Padding(
                  padding: EdgeInsets.only(left: width * .02),
                  child: textWidget(text: 'Variable Expenses', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: height * .01),
              // DarkCard(
              //   child: Column(
              //     children: [
              //       for (int i = 0; i < variableList.length; i++) ...[
              //         _ExpenseRow(
              //           expense: variableList[i],
              //           rightText: _freqLabel(variableList[i].frequency, variableList[i].amount),
              //           onTap: () => _openEditExpense(variableList[i]),
              //           insightDelta: _insights[variableList[i].name],
              //         ),
              //         if (i != variableList.length - 1) Divider(height: 1, color: ProjectColors.whiteColor.withOpacity(0.1)),
              //       ]
              //     ],
              //   ),
              // ),
              SizedBox(height: height * .02),
              // Padding(
              //   padding: EdgeInsets.only(left: width * .02),
              //   child: textWidget(text: 'Spending Insights', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 10),
              // _Card(
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       _InsightLine(title: 'Groceries', delta: _insights['Groceries'] ?? 0),
              //       const SizedBox(height: 8),
              //       _InsightLine(title: 'Transport', delta: _insights['Transport'] ?? 0),
              //     ],
              //   ),
              // ),
            ],
          ));
  }
}

class DetailWidgetRow extends StatelessWidget {
  const DetailWidgetRow({super.key, this.title, this.right, this.color = ProjectColors.greenColor});

  final String? title;
  final Widget? right;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .02),
      margin: EdgeInsets.symmetric(vertical: height * .002),
      decoration: BoxDecoration(
        color: color!,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          textWidget(
            text: title,
            fontWeight: FontWeight.bold,
            fontSize: .018,
            color: ProjectColors.blackColor,
          ),
          const Spacer(),
          Flexible(child: right!),
          SizedBox(width: width * .01),
          Icon(Icons.arrow_drop_down, color: ProjectColors.blackColor),
        ],
      ),
    );
  }
}
