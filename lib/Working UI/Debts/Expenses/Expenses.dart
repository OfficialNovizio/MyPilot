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
                  showCupertinoModalPopup(context: context, builder: (_) => AddExpenseScreen());
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
                              padding: EdgeInsets.only(right: width * .12),
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
                                    fontSize: .025,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: height * .01),
                    ClipRRect(
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
                    SizedBox(height: height * .01),
                    textWidget(text: 'Based on your monthly & per-paycheque expenses', fontSize: .018),
                  ],
                ),
              ),
              SizedBox(height: height * .01),
              DarkCard(
                child: InkWell(
                  onTap: () {
                    showCupertinoModalPopup(context: context, builder: (_) => AddExpenseScreen());
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
                                padding: EdgeInsets.symmetric(horizontal: width * .02),
                                child: Row(
                                  children: [
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
                    // for (int i = 0; i < fixedList.length; i++) ...[
                    //   _ExpenseRow(
                    //     expense: fixedList[i],
                    //     rightText: '${_money(fixedList[i].amount)} / month',
                    //     onTap: () => _openEditExpense(fixedList[i]),
                    //   ),
                    //   if (i != fixedList.length - 1) Divider(height: 1, color: ProjectColors.whiteColor.withOpacity(0.1)),
                    // ]
                  ],
                ),
              ),
              SizedBox(height: height * .02),
              Padding(
                padding: EdgeInsets.only(left: width * .02),
                child: textWidget(text: 'Variable Expenses', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
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

// class _ExpenseRow extends StatelessWidget {
//   final String rightText;
//   final VoidCallback onTap;
//   final int? insightDelta; // optional: +/- vs last period
//
//   const _ExpenseRow({
//     required this.rightText,
//     required this.onTap,
//     this.insightDelta,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final delta = insightDelta;
//     final deltaWidget = delta == null
//         ? const SizedBox.shrink()
//         : Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 delta >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
//                 size: height * .02,
//                 color: delta >= 0 ? ProjectColors.greenColor : Colors.blue,
//               ),
//               const SizedBox(width: 2),
//               textWidget(
//                 text: '\$${delta.abs()}',
//                 fontWeight: FontWeight.w800,
//                 color: ProjectColors.whiteColor,
//               ),
//               const SizedBox(width: 8),
//             ],
//           );
//
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(14),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .014),
//         child: Row(
//           children: [
//             Container(
//               width: height * .04,
//               height: height * .04,
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.04),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(expense.icon, color: ProjectColors.whiteColor.withOpacity(0.70)),
//             ),
//             SizedBox(width: width * .015),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   textWidget(text: expense.name, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor, fontSize: .02),
//                   // SizedBox(height: height * .01),
//                   textWidget(text: _subLabel(expense), color: ProjectColors.whiteColor, fontSize: 0.018),
//                 ],
//               ),
//             ),
//             deltaWidget,
//             textWidget(text: rightText, color: ProjectColors.whiteColor, fontSize: 0.02),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _subLabel(ExpenseModel e) {
//     if (e.type == ExpenseType.fixed || e.type == ExpenseType.bill || e.type == ExpenseType.subscription) {
//       if (e.dueDay != null) return 'Due ${e.dueDay}${_suffix(e.dueDay!)}';
//       return 'Recurring';
//     }
//     return 'Budget';
//   }
//
//   String _suffix(int d) {
//     if (d >= 11 && d <= 13) return 'th';
//     switch (d % 10) {
//       case 1:
//         return 'st';
//       case 2:
//         return 'nd';
//       case 3:
//         return 'rd';
//       default:
//         return 'th';
//     }
//   }
// }

/// ===============================
/// SMALL COMPONENTS
/// ===============================

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AddExpenseScreen extends StatelessWidget {
  AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * .95,
      child: Popup(
        title: 'Create Expense',
        color: ProjectColors.blackColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: height * .04, top: height * .01),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .02),
                  decoration: BoxDecoration(
                    color: ProjectColors.whiteColor.withOpacity(.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ProjectColors.whiteColor.withOpacity(.06)),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: width * .01),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: ProjectColors.whiteColor.withOpacity(.7)),
                      SizedBox(width: width * .03),
                      Expanded(
                        child: textWidget(
                          text: "Log expenses to improve cash-flow alerts and debt plan accuracy.",
                          fontSize: .016,
                          color: ProjectColors.whiteColor.withOpacity(.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: height * .01),
                MyFormField(
                  form: expense.controllers[0],
                  needDigitKeyboard: true,
                  textInputDone: false,
                  inverseColor: true,
                  needCustomPadding: true,
                  padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .01),
                  validator: (v) {
                    final val = double.tryParse((v ?? "").trim());
                    if (val == null || val <= 0) return "Enter a valid amount";
                    return null;
                  },
                ),
                MyFormField(
                  form: expense.controllers[1],
                  textInputDone: false,
                  inverseColor: true,
                  needCustomPadding: true,
                  padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .01),
                  validator: (v) {
                    if ((v ?? "").trim().isEmpty) return "Enter expense name";
                    return null;
                  },
                ),
                MyFormField(
                  form: expense.controllers[2],
                  textInputDone: true,
                  inverseColor: true,
                  needCustomPadding: true,
                  padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .01),
                ),
                SizedBox(height: height * .02),
                textWidget(
                  text: 'Details',
                  fontSize: .02,
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: height * .01),
                DropdownButtonFormField<String>(
                  value: expense.category.value, // use real state, not controller.text
                  isExpanded: true,

                  items: expense.categories.map((x) {
                    return DropdownMenuItem<String>(
                      value: x,
                      child: Text(x, style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),

                  onChanged: (v) {
                    expense.category.value = v!;
                    expense.controllers[3].controller.text = v;
                  },

                  // Selected value shown on the RIGHT
                  selectedItemBuilder: (context) {
                    return expense.categories.map((x) {
                      return Padding(
                        padding: EdgeInsets.only(right: width * .02), // space for arrow
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: textWidget(
                            text: x,
                            fontWeight: FontWeight.w700,
                            fontSize: .02,
                          ),
                        ),
                      );
                    }).toList();
                  },

                  // When nothing selected, show nothing on right (or put "Select" right-aligned)
                  hint: const SizedBox.shrink(),

                  iconEnabledColor: ProjectColors.blackColor.withOpacity(.8),
                  dropdownColor: ProjectColors.whiteColor,

                  decoration: InputDecoration(
                    // Fixed LEFT label inside the field
                    prefix: Padding(
                      padding: EdgeInsets.only(right: width * .02),
                      child: textWidget(
                        text: 'Category',
                        color: ProjectColors.blackColor,
                        fontWeight: FontWeight.w700,
                        fontSize: .018,
                      ),
                    ),

                    filled: true,
                    fillColor: ProjectColors.greenColor,
                    contentPadding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .018),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: ProjectColors.greenColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: ProjectColors.greenColor),
                    ),
                  ),
                ),
                SizedBox(height: height * .003),
                GestureDetector(
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (_) => SizedBox(
                        height: height * .9,
                        child: Popup(
                          color: ProjectColors.blackColor,
                          title: "Cards & Accounts",
                          body: PaymentMethodsScreen(),
                        ),
                      ),
                    );
                  },
                  child: DetailWidgetRow(
                    title: expense.controllers[4].title,
                    right: textWidget(
                      text: expense.controllers[4].controller.text.isEmpty ? "Select account" : expense.controllers[4].controller.text,
                      fontSize: .02,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AppDatePicker.pickDate().then((onValue) {
                      if (onValue != null) {
                        expense.controllers[5].controller.text = formatDate(onValue);
                        expense.controllers.refresh();
                      }
                    });
                  },
                  child: DetailWidgetRow(
                    title: expense.controllers[5].title,
                    right: textWidget(
                      text: expense.controllers[5].controller.text.isEmpty ? "Select Date" : expense.controllers[5].controller.text,
                      fontSize: .02,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DetailWidgetRow(
                  title: expense.controllers[6].title,
                  right: Wrap(
                    spacing: width * .02,
                    runSpacing: height * .012,
                    children: {true: 'Yes', false: 'No'}.entries.map((e) {
                      final isActive = expense.isEssential.value == e.key;
                      return InkWell(
                        onTap: () {
                          expense.isEssential.value = e.key;
                          expense.controllers[6].controller.text = e.key.toString();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .012),
                          decoration: BoxDecoration(
                            color: isActive ? ProjectColors.whiteColor : ProjectColors.whiteColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: ProjectColors.blackColor.withOpacity(.14)),
                          ),
                          child: textWidget(
                            text: e.value, // Yes/No label
                            fontSize: .014,
                            color: ProjectColors.blackColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .02),
                  margin: EdgeInsets.symmetric(vertical: height * .002),
                  decoration: BoxDecoration(
                    color: ProjectColors.greenColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  width: width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(
                        text: expense.controllers[7].title,
                        fontWeight: FontWeight.bold,
                        fontSize: .018,
                        color: ProjectColors.blackColor,
                      ),
                      SizedBox(height: height * .01),
                      Row(
                        children: expense.frequencies.map((freq) {
                          final isActive = expense.frequency.value == freq; // RxString / RxnString

                          return Padding(
                            padding: EdgeInsets.only(right: width * .01),
                            child: InkWell(
                              onTap: () {
                                expense.frequency.value = freq;
                                expense.controllers[7].controller.text = freq;
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * .04,
                                  vertical: height * .012,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive ? ProjectColors.whiteColor : ProjectColors.whiteColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: ProjectColors.blackColor.withOpacity(.14)),
                                ),
                                child: textWidget(
                                  text: freq, // One-time / Weekly / Biweekly / Monthly
                                  fontSize: .014,
                                  color: ProjectColors.blackColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ),
                SizedBox(height: height * .02),
                Center(
                  child: normalButton(
                    title: "Add Expense",
                    callback: () {
                      expense.addExpenseFromUI();
                    },
                    cWidth: .8,
                    invertColors: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
