import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/Expense%20Model%20V2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import '../../../models/Expense Model.dart';
import '../../Cards and Account/Cards.dart';
import '../../Constants.dart';
import '../All Debts/Combined Data Dashboard.dart';
import 'Expense Insights.dart';
import 'Add Expense.dart';
import 'Expenses Getx.dart' hide money;

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
    expenseV2.loadExpenses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => expenseV2.state.value == ButtonState.loading
        ? Padding(padding: EdgeInsets.only(top: height * .4), child: loader())
        : expenseV2.expensesModel.value.expenses.isEmpty
            ? Padding(
                padding: EdgeInsets.only(top: height * .01),
                child: AddContent(
                  title: "Add an Expense",
                  subTitle: 'Fixed · Variable · Subscription · Bill',
                  callback: () {
                    expenseV2.resetForm();
                    Get.to(() => NewExpense());
                  },
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * .04),
                  Stack(
                    children: [
                      InsightCard(
                        title: "Payday buffer",
                        leftMain: "\$430",
                        leftTag: !expenseV2.gate.value!.allowed
                            ? Tag(
                                text: expenseV2.gate.value!.title,
                                color: ProjectColors.errorColor,
                              )
                            : Tag(
                                text: "Safe",
                                color: ProjectColors.whiteColor,
                              ),
                        leftSub: "• -\$320 this month",
                        rightWidget: Container(),
                        onTap: () async {
                          Get.to(() => NowToPaydayScreen());
                        },
                        disableCard: !expenseV2.gate.value!.allowed,
                        disableReason: expenseV2.gate.value,
                      ),
                    ],
                  ),
                  SizedBox(height: height * .01),
                  AddContent(
                    title: "Add an Expense",
                    subTitle: 'Fixed · Variable · Subscription · Bill',
                    callback: () {
                      expenseV2.resetForm();
                      Get.to(() => NewExpense());
                    },
                  ),
                  SizedBox(height: height * .02),
                  Visibility(
                    visible: expenseV2.expensesModel.value.expenses.isEmpty ? false : true,
                    child: Padding(
                      padding: EdgeInsets.only(left: width * .02, bottom: height * .01),
                      child: textWidget(text: 'Expenses', color: ProjectColors.whiteColor, fontSize: .02, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Column(
                    children: [
                      ...expenseV2.expensesModel.value.expenses
                          .map((f) => Padding(
                                padding: EdgeInsets.symmetric(vertical: height * .002),
                                child: Slidable(
                                  key: Key(f.id),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.75,
                                    children: [
                                      CustomSlidableAction(
                                        onPressed: (_) {
                                          expenseV2.deleteExpense(f.id);
                                        },
                                        backgroundColor: Colors.transparent,
                                        autoClose: true,
                                        child: Center(
                                          child: Container(
                                            height: height * .06,
                                            width: height * .15,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(50),
                                              color: ProjectColors.errorColor,
                                            ),
                                            child: Icon(Icons.remove_circle_outline, size: height * .03),
                                          ),
                                        ),
                                      ),
                                      CustomSlidableAction(
                                        onPressed: (_) {
                                          expenseV2.selectedExpense!.value = f;
                                          expenseV2.controllers[0].controller.text = f.amount.toString();
                                          expenseV2.controllers[1].controller.text = f.name;
                                          expenseV2.controllers[2].controller.text = f.notes;
                                          expenseV2.controllers[3].controller.text = f.category;
                                          expenseV2.controllers[4].controller.text = f.accounts[0].name!;
                                          expenseV2.controllers[5].controller.text = formatDate(f.date);
                                          expenseV2.controllers[5].pickedDate = f.date;
                                          expenseV2.controllers[6].controller.text = f.isEssential ? 'Yes' : 'No';
                                          expenseV2.isEssential.value = f.isEssential;
                                          expenseV2.controllers[7].controller.text = f.frequency;
                                          expenseV2.controllers[8].controller.text = f.mode;
                                          expenseV2.selectedMode.value = f.mode == ExpenseMode.spent ? ExpenseMode.spent : ExpenseMode.planned;
                                          expenseV2.selectedAccount!.value = f.accounts[0];
                                          expenseV2.controllers.refresh();
                                          Get.to(() => NewExpense(isEditing: true));
                                        },
                                        autoClose: true,
                                        backgroundColor: Colors.transparent,
                                        child: Center(
                                          child: Container(
                                            height: height * .06,
                                            width: height * .15,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(50),
                                              color: ProjectColors.yellowColor,
                                            ),
                                            child: Icon(Icons.edit_rounded, size: height * .03, color: ProjectColors.pureBlackColor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: DarkCard(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: width * .01),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: height * .05,
                                            height: height * .05,
                                            decoration: BoxDecoration(
                                              color: ProjectColors.whiteColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              expenseV2.categoryIcon(f.category),
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
                                                textWidget(
                                                    text: f.notes, color: ProjectColors.whiteColor, fontSize: 0.018, needContainer: true, cWidth: .6),
                                              ],
                                            ),
                                          ),
                                          // deltaWidget,
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              textWidget(
                                                  text: money(f.amount),
                                                  color: ProjectColors.whiteColor,
                                                  fontSize: 0.02,
                                                  fontWeight: FontWeight.w900),
                                              textWidget(text: f.accounts[0].name, color: ProjectColors.whiteColor, fontSize: 0.018),
                                              textWidget(text: f.frequency, color: ProjectColors.whiteColor, fontSize: 0.018),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                  // SizedBox(height: height * .02),
                  // Visibility(
                  //   visible: expenseV2.variableExpense.isEmpty ? false : true,
                  //   child: Padding(
                  //     padding: EdgeInsets.only(left: width * .02),
                  //     child: textWidget(text: 'Variable Expenses', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
                  //   ),
                  // ),
                  // SizedBox(height: height * .01),
                  // Column(
                  //   children: [
                  //     ...expenseV2.variableExpense
                  //         .map((f) => Padding(
                  //               padding: EdgeInsets.symmetric(vertical: height * .002),
                  //               child: Slidable(
                  //                 key: Key(f.id),
                  //                 endActionPane: ActionPane(
                  //                   motion: const DrawerMotion(),
                  //                   extentRatio: 0.75,
                  //                   children: [
                  //                     CustomSlidableAction(
                  //                       onPressed: (_) {
                  //                         expenseV2.selectedExpense = f;
                  //                         expenseV2.deleteExpense();
                  //                       },
                  //                       backgroundColor: Colors.transparent,
                  //                       autoClose: true,
                  //                       child: Center(
                  //                         child: Container(
                  //                           height: height * .06,
                  //                           width: height * .15,
                  //                           decoration: BoxDecoration(
                  //                             borderRadius: BorderRadius.circular(50),
                  //                             color: ProjectColors.errorColor,
                  //                           ),
                  //                           child: Icon(Icons.remove_circle_outline, size: height * .03),
                  //                         ),
                  //                       ),
                  //                     ),
                  //                     CustomSlidableAction(
                  //                       onPressed: (_) {
                  //                         expenseV2.selectedExpense = f;
                  //                         expenseV2.controllers[0].controller.text = f.amount.toString();
                  //                         expenseV2.controllers[1].controller.text = f.name;
                  //                         expenseV2.controllers[2].controller.text = f.notes!;
                  //                         expenseV2.controllers[3].controller.text = f.category;
                  //                         expenseV2.controllers[4].controller.text = f.accountName!;
                  //                         expenseV2.controllers[5].controller.text = formatDate(f.dateMs);
                  //                         expenseV2.controllers[5].pickedDate = f.dateMs;
                  //                         expenseV2.controllers[6].controller.text = f.isEssential ? 'Yes' : 'No';
                  //                         expenseV2.isEssential.value = f.isEssential;
                  //                         expenseV2.controllers[7].controller.text = f.frequency;
                  //                         expenseV2.controllers.refresh();
                  //                         Get.to(() => NewExpense(isEditing: true));
                  //                       },
                  //                       autoClose: true,
                  //                       backgroundColor: Colors.transparent,
                  //                       child: Center(
                  //                         child: Container(
                  //                           height: height * .06,
                  //                           width: height * .15,
                  //                           decoration: BoxDecoration(
                  //                             borderRadius: BorderRadius.circular(50),
                  //                             color: ProjectColors.yellowColor,
                  //                           ),
                  //                           child: Icon(Icons.edit_rounded, size: height * .03, color: ProjectColors.pureBlackColor),
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //                 child: DarkCard(
                  //                   child: Padding(
                  //                     padding: EdgeInsets.symmetric(horizontal: width * .01),
                  //                     child: Row(
                  //                       crossAxisAlignment: CrossAxisAlignment.start,
                  //                       children: [
                  //                         Container(
                  //                           width: height * .04,
                  //                           height: height * .04,
                  //                           decoration: BoxDecoration(
                  //                             color: ProjectColors.whiteColor.withOpacity(0.1),
                  //                             borderRadius: BorderRadius.circular(12),
                  //                           ),
                  //                           child: Icon(
                  //                             expenseV2.categoryIcon(f.category),
                  //                             color: ProjectColors.whiteColor,
                  //                             size: height * .02,
                  //                           ),
                  //                         ),
                  //                         SizedBox(width: width * .015),
                  //                         Expanded(
                  //                           child: Column(
                  //                             crossAxisAlignment: CrossAxisAlignment.start,
                  //                             children: [
                  //                               textWidget(text: f.name, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor, fontSize: .02),
                  //                               // SizedBox(height: height * .01),
                  //                               textWidget(text: f.category, color: ProjectColors.whiteColor, fontSize: 0.018),
                  //                               textWidget(text: f.notes, color: ProjectColors.whiteColor, fontSize: 0.018),
                  //                             ],
                  //                           ),
                  //                         ),
                  //                         // deltaWidget,
                  //                         Column(
                  //                           crossAxisAlignment: CrossAxisAlignment.end,
                  //                           children: [
                  //                             textWidget(
                  //                                 text: money(f.amount),
                  //                                 color: ProjectColors.whiteColor,
                  //                                 fontSize: 0.02,
                  //                                 fontWeight: FontWeight.w900),
                  //                             textWidget(text: f.accountName, color: ProjectColors.whiteColor, fontSize: 0.018),
                  //                             textWidget(text: f.frequency, color: ProjectColors.whiteColor, fontSize: 0.018),
                  //                           ],
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //             ))
                  //         .toList(),
                  //   ],
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
