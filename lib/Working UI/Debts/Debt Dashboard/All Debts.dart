import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Debts/Debt%20Dashboard/Credit%20Card%20Debt/Credit%20Card%20Body.dart';
import 'package:emptyproject/Working%20UI/Debts/Debt%20Dashboard/Credit%20Card%20Debt/Credit%20Debt%20Card.dart';
import 'package:emptyproject/Working%20UI/Shift/Projection/Projection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import '../../../models/Debt Model.dart';
import '../../Controllers.dart';
import 'Add Debt/Add New Debt.dart';
import 'Credit Card Debt/Credit Card Logic.dart';
import 'Debt Detailed Page/Debt Detail Screen.dart';
import 'Debt Insights.dart';
import '../Expenses/Expense Insights.dart';
import '../All Debts/Combined Data Dashboard.dart';

class AllDebts extends StatefulWidget {
  const AllDebts({super.key});

  @override
  State<AllDebts> createState() => _AllDebtsState();
}

class _AllDebtsState extends State<AllDebts> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final debts = debtV2.activeDebts;
      final totalDebt = debtV2.totalDebt;
      final paidPct = debtV2.paidPct;
      final alloc = CreditCardDebtLogic().buildPayoffPlan(extra: debtV2.extraBudget.value);

      return debtV2.state.value == ButtonState.loading
          ? Padding(padding: EdgeInsets.only(top: height * .4), child: loader())
          : debtV2.debtsModel.value.debts.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: height * .01),
                  child: AddContent(
                    title: "Add a Debt",
                    subTitle: "Credit Card · Loan · BNPL · Other",
                    callback: () => Get.to(() => AddDebt()),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * .04),
                    InsightCard(
                      title: "Interest burn",
                      leftMain: "\$92",
                      leftSub: "(Visa \$65)",
                      rightWidget: Container(),
                      // rightWidget: _Ring(
                      //   value: 0.62,
                      //   size: height * 0.075,
                      //   stroke: 10,
                      //   centerTop: "\$92",
                      //   centerBottom: "High",
                      //   ringColor: ProjectColors.yellowColor,
                      // ),
                      onTap: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (_) => ComparisonCardsHomeScreen(),
                        );
                      },
                    ),
                    SizedBox(height: height * .01),
                    DarkCard(
                      color: ProjectColors.greenColor,
                      opacity: 1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              textWidget(text: "Total Debt", fontSize: .02, fontWeight: FontWeight.bold, color: ProjectColors.whiteColor),
                              SizedBox(height: height * .01),
                              textWidget(text: money(totalDebt), fontSize: .04, fontWeight: FontWeight.bold, color: ProjectColors.whiteColor),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              textWidget(text: '${debts.length} debts', fontSize: .018, color: ProjectColors.whiteColor),
                              SizedBox(height: height * .01),
                              SizedBox(
                                width: width * .4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: paidPct,
                                    minHeight: 8,
                                    backgroundColor: ProjectColors.pureBlackColor.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation(ProjectColors.pureBlackColor),
                                  ),
                                ),
                              ),
                              SizedBox(height: height * .01),
                              textWidget(text: '${(paidPct * 100).round()}% paid', fontSize: .018, color: ProjectColors.whiteColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * .01),
                    AddContent(
                      title: "Add a Debt",
                      subTitle: "Credit Card · Loan · BNPL · Other",
                      callback: () => Get.to(() => AddDebt()),
                    ),
                    SizedBox(height: height * .02),
                    Padding(
                      padding: EdgeInsets.only(left: width * .02),
                      child: textWidget(text: 'Your Debts', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: height * .01),
                    ...debts
                        .map(
                          (t) => CreditDebtCard(data: t),
                        )
                        .toList(),
                    // DarkCard(
                    //   child: Column(
                    //     children: [
                    //       for (int i = 0; i < debts.length; i++) ...[
                    //         _DebtRowV2(debtItem: debts[i]),
                    //         if (i != debts.length - 1) Divider(height: 1, color: ProjectColors.whiteColor.withOpacity(0.1)),
                    //       ],
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: height * .02),
                    Padding(
                      padding: EdgeInsets.only(left: width * .02),
                      child: textWidget(text: 'Strategy', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: height * .01),
                    StrategySection(alloc: alloc),
                    // DarkCard(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       segmentedToggle(
                    //         activeColor: ProjectColors.greenColor,
                    //         bgColor: ProjectColors.pureBlackColor,
                    //         options: debtV2.strategies,
                    //         verticalPadding: .015,
                    //         selectedIndex: debtV2.strategies.indexOf(debtV2.selectedLabel()).clamp(0, debtV2.strategies.length - 1),
                    //         onChanged: (i, v) async {
                    //           await debtV2.setStrategyFromLabel(v);
                    //         },
                    //       ),
                    //
                    //       SizedBox(height: height * .01),
                    //       textWidget(
                    //         text: debtV2.strategyDescription(debtV2.strategy.value),
                    //         fontWeight: FontWeight.w600,
                    //         color: ProjectColors.whiteColor,
                    //       ),
                    //
                    //       SizedBox(height: height * .01),
                    //       divider(),
                    //       SizedBox(height: height * .01),
                    //
                    //       Row(
                    //         children: [
                    //           textWidget(
                    //             text: 'Debt pay period:',
                    //             fontWeight: FontWeight.w900,
                    //             color: ProjectColors.whiteColor,
                    //             fontSize: .016,
                    //           ),
                    //           const Spacer(),
                    //           Tag(text: "This Period", color: ProjectColors.loginAccentBlue),
                    //         ],
                    //       ),
                    //
                    //       SizedBox(height: height * .01),
                    //
                    //       // optional: allow extraBudget input quickly
                    //       DarkTextField(
                    //         title: "Extra Budget (optional)",
                    //         hintText: "\$0",
                    //         controller: TextEditingController(text: debtV2.extraBudget.value == 0 ? "" : debtV2.extraBudget.value.toStringAsFixed(0)),
                    //         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    //         prefixText: "",
                    //         trailing: Icon(Icons.edit, color: ProjectColors.whiteColor.withOpacity(.6)),
                    //         onTap: null,
                    //       ),
                    //
                    //       SizedBox(height: height * .01),
                    //
                    //       for (int i = 0; i < alloc.length; i++) ...[
                    //         _AllocationLineV2(line: alloc[i]),
                    //         if (i != alloc.length - 1) Divider(height: 1, color: Colors.black.withOpacity(0.06)),
                    //       ],
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: height * .02),
                  ],
                );
    });
  }
}

/// =====================
/// UI WIDGETS
/// =====================

/// =====================
/// DATA
/// =====================

// class _DebtRowV2 extends StatelessWidget {
//   final DebtItem debtItem;
//
//   const _DebtRowV2({
//     required this.debtItem,
//   });
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
//
//   @override
//   Widget build(BuildContext context) {
//
//     return GestureDetector(
//       onTap: () async {
//         debtV2.selectedDebt.value = debtItem;
//         Get.to(() => const CreditCardDebtBody());
//       },
//       child: Slidable(
//         key: Key(debtItem.id),
//         endActionPane: ActionPane(
//           motion: const DrawerMotion(),
//           extentRatio: 0.75,
//           children: [
//             CustomSlidableAction(
//               onPressed: (_) async {
//                 await debtV2.deleteDebt(debtItem.id);
//               },
//               backgroundColor: Colors.transparent,
//               autoClose: true,
//               child: Center(
//                 child: Container(
//                   height: height * .06,
//                   width: height * .12,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(50),
//                     color: ProjectColors.errorColor,
//                   ),
//                   child: Icon(Icons.remove_circle_outline, size: height * .03),
//                 ),
//               ),
//             ),
//             CustomSlidableAction(
//               onPressed: (_) {
//                 // expenseV2.selectedExpense!.value = f;
//                 // expenseV2.controllers[0].controller.text = f.amount.toString();
//                 // expenseV2.controllers[1].controller.text = f.name;
//                 // expenseV2.controllers[2].controller.text = f.notes;
//                 // expenseV2.controllers[3].controller.text = f.category;
//                 // expenseV2.controllers[4].controller.text = f.accounts[0].name;
//                 // expenseV2.controllers[5].controller.text = formatDate(f.date);
//                 // expenseV2.controllers[5].pickedDate = f.date;
//                 // expenseV2.controllers[6].controller.text = f.isEssential ? 'Yes' : 'No';
//                 // expenseV2.isEssential.value = f.isEssential;
//                 // expenseV2.controllers[7].controller.text = f.frequency;
//                 // expenseV2.controllers[8].controller.text = f.mode;
//                 // expenseV2.selectedMode.value = f.mode == ExpenseMode.spent ? ExpenseMode.spent : ExpenseMode.planned;
//                 // expenseV2.selectedAccount!.value = f.accounts[0];
//                 // expenseV2.controllers.refresh();
//                 // Get.to(() => NewExpense(isEditing: true));
//               },
//               autoClose: true,
//               backgroundColor: Colors.transparent,
//               child: Center(
//                 child: Container(
//                   height: height * .06,
//                   width: height * .12,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(50),
//                     color: ProjectColors.greenColor,
//                   ),
//                   child: Icon(Icons.toggle_on_outlined, size: height * .03, color: ProjectColors.pureBlackColor),
//                 ),
//               ),
//             ),
//             CustomSlidableAction(
//               onPressed: (_) {
//                 // expenseV2.selectedExpense!.value = f;
//                 // expenseV2.controllers[0].controller.text = f.amount.toString();
//                 // expenseV2.controllers[1].controller.text = f.name;
//                 // expenseV2.controllers[2].controller.text = f.notes;
//                 // expenseV2.controllers[3].controller.text = f.category;
//                 // expenseV2.controllers[4].controller.text = f.accounts[0].name;
//                 // expenseV2.controllers[5].controller.text = formatDate(f.date);
//                 // expenseV2.controllers[5].pickedDate = f.date;
//                 // expenseV2.controllers[6].controller.text = f.isEssential ? 'Yes' : 'No';
//                 // expenseV2.isEssential.value = f.isEssential;
//                 // expenseV2.controllers[7].controller.text = f.frequency;
//                 // expenseV2.controllers[8].controller.text = f.mode;
//                 // expenseV2.selectedMode.value = f.mode == ExpenseMode.spent ? ExpenseMode.spent : ExpenseMode.planned;
//                 // expenseV2.selectedAccount!.value = f.accounts[0];
//                 // expenseV2.controllers.refresh();
//                 // Get.to(() => NewExpense(isEditing: true));
//               },
//               autoClose: true,
//               backgroundColor: Colors.transparent,
//               child: Center(
//                 child: Container(
//                   height: height * .06,
//                   width: height * .12,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(50),
//                     color: ProjectColors.yellowColor,
//                   ),
//                   child: Icon(Icons.edit_rounded, size: height * .03, color: ProjectColors.pureBlackColor),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: width * .01, vertical: height * .015),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     textWidget(text: debtItem.name, fontWeight: FontWeight.w900, fontSize: .018, color: ProjectColors.whiteColor),
//                     SizedBox(height: height * .005),
//                     textWidget(text: money(debtItem.balance), fontWeight: FontWeight.w900, fontSize: .018, color: ProjectColors.whiteColor),
//                     SizedBox(height: height * .005),
//                     textWidget(
//                       text: 'Due ${formatDate(debtItem.dueDate!)}',
//                       color: ProjectColors.whiteColor.withOpacity(0.55),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(width: width * .03),
//               Tag(
//                 text: debtItem.isActive ? debtItem.type : "Inactive",
//                 color: debtItem.isActive ? ProjectColors.greenColor : ProjectColors.errorColor,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class _AllocationLineV2 extends StatelessWidget {
  final DebtPlanLine line;
  const _AllocationLineV2({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * .01),
      child: Row(
        children: [
          Expanded(
            child: textWidget(
              text: line.name,
              fontWeight: FontWeight.w800,
              color: ProjectColors.whiteColor,
            ),
          ),
          textWidget(
            text: '+ Extra ${line.extra.toStringAsFixed(0)}',
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor.withOpacity(0.6),
          ),
          SizedBox(width: width * .02),
          textWidget(
            text: '= \$${line.total.toStringAsFixed(0)}',
            fontWeight: FontWeight.w900,
            color: ProjectColors.whiteColor,
          ),
        ],
      ),
    );
  }
}

class StrategySection extends StatelessWidget {
  const StrategySection({super.key, required this.alloc});

  final List<DebtPlanLine> alloc;

  @override
  Widget build(BuildContext context) {
    final multiDebt = debtV2.activeDebts.length > 1;

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              textWidget(
                text: "Strategy",
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor,
                fontSize: .02,
              ),
              const Spacer(),
              if (!multiDebt) Tag(text: "Learning", color: ProjectColors.loginAccentBlue),
              if (multiDebt) Tag(text: "Active", color: ProjectColors.greenColor),
            ],
          ),

          SizedBox(height: height * .01),

          if (multiDebt) ...[
            // REAL selection
            segmentedToggle(
              activeColor: ProjectColors.greenColor,
              bgColor: ProjectColors.pureBlackColor,
              options: debtV2.strategies,
              verticalPadding: .015,
              selectedIndex: debtV2.strategies.indexOf(debtV2.selectedLabel()).clamp(0, debtV2.strategies.length - 1),
              onChanged: (i, v) async => debtV2.setStrategyFromLabel(v),
            ),

            SizedBox(height: height * .01),

            textWidget(
              text: debtV2.strategyDescription(debtV2.strategy.value),
              fontWeight: FontWeight.w600,
              color: ProjectColors.whiteColor.withOpacity(.85),
            ),

            SizedBox(height: height * .01),
            divider(),
            SizedBox(height: height * .01),

            // Extra Budget only makes sense when multiple debts exist
            Row(
              children: [
                textWidget(
                  text: "Extra Budget",
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                  fontSize: .016,
                ),
                const Spacer(),
                Tag(text: "Optional", color: ProjectColors.whiteColor.withOpacity(.10)),
              ],
            ),
            SizedBox(height: height * .01),

            DarkTextField(
              title: "Extra Budget (optional)",
              hintText: "\$0",
              controller: TextEditingController(
                text: debtV2.extraBudget.value == 0 ? "" : debtV2.extraBudget.value.toStringAsFixed(0),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixText: "",
              trailing: Icon(Icons.edit, color: ProjectColors.whiteColor.withOpacity(.6)),
              onChanged: (v) {
                final x = toDouble(v) ?? 0.0;
                debtV2.extraBudget.value = x.clamp(0.0, 1e12).toDouble();
              },
              onTap: null,
            ),

            SizedBox(height: height * .01),

            // Allocation preview (your existing list)
            for (int i = 0; i < alloc.length; i++) ...[
              _AllocationLineV2(line: alloc[i]),
              if (i != alloc.length - 1) Divider(height: 1, color: Colors.black.withOpacity(0.06)),
            ],
          ] else ...[
            // LEARNING MODE (single debt)
            textWidget(
              text: "With 1 debt, strategies don’t change the result. Your payoff speed depends on how much you pay above the minimum.",
              fontWeight: FontWeight.w600,
              color: ProjectColors.whiteColor.withOpacity(.75),
            ),

            SizedBox(height: height * .012),

            _StrategyLearnTile(
              title: "Snowball",
              subtitle: "Smallest balance first (motivation wins)",
              onTap: () => _showStrategySheet(context, PayoffStrategy.snowball),
            ),
            SizedBox(height: height * .01),
            _StrategyLearnTile(
              title: "Avalanche",
              subtitle: "Highest APR first (math wins)",
              onTap: () => _showStrategySheet(context, PayoffStrategy.avalanche),
            ),
            SizedBox(height: height * .01),
            _StrategyLearnTile(
              title: "Hybrid",
              subtitle: "Mix of motivation + interest savings",
              onTap: () => _showStrategySheet(context, PayoffStrategy.hybrid),
            ),
            SizedBox(height: height * .01),
            _StrategyLearnTile(
              title: "Manual",
              subtitle: "You decide where extra goes",
              onTap: () => _showStrategySheet(context, PayoffStrategy.manual),
            ),

            SizedBox(height: height * .012),
            divider(),
            SizedBox(height: height * .012),

            // In single debt mode, show "Pay more per month" input (NOT extra budget allocation)
            Row(
              children: [
                textWidget(
                  text: "Pay more per month",
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                  fontSize: .016,
                ),
                const Spacer(),
                Tag(text: "Optional", color: ProjectColors.whiteColor.withOpacity(.10)),
              ],
            ),
            SizedBox(height: height * .01),

            DarkTextField(
              title: "Extra payment (optional)",
              hintText: "\$0",
              controller: TextEditingController(
                text: debtV2.extraBudget.value == 0 ? "" : debtV2.extraBudget.value.toStringAsFixed(0),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixText: "",
              trailing: Icon(Icons.edit, color: ProjectColors.whiteColor.withOpacity(.6)),
              onChanged: (v) {
                final x = toDouble(v) ?? 0.0;
                debtV2.extraBudget.value = x.clamp(0.0, 1e12).toDouble();
              },
              onTap: null,
            ),

            SizedBox(height: height * .01),
            textWidget(
              text: "This extra amount is added to your minimum payment in your Payment Schedule (and updates your payoff plan).",
              fontSize: .015,
              fontWeight: FontWeight.w700,
              color: ProjectColors.whiteColor.withOpacity(.6),
            ),
          ],
        ],
      ),
    );
  }

  void _showStrategySheet(BuildContext context, PayoffStrategy s) {
    final title = _strategyTitle(s);
    final desc = debtV2.strategyDescription(s);

    String whenItHelps;
    String example;

    switch (s) {
      case PayoffStrategy.snowball:
        whenItHelps = "Best when you need momentum. You clear small debts fast and stay consistent.";
        example = "Debts: \$200 (min \$25), \$1,200 (min \$40), \$5,000 (min \$120). Snowball attacks \$200 first.";
        break;
      case PayoffStrategy.avalanche:
        whenItHelps = "Best when you want lowest total interest. You attack the highest APR first.";
        example = "Debts: 29% APR \$1,200, 12% APR \$2,000, 7% APR \$5,000. Avalanche attacks 29% first.";
        break;
      case PayoffStrategy.hybrid:
        whenItHelps = "Best when you want both progress + savings. It’s a blended scoring approach.";
        example = "It may pick a medium balance with high APR instead of the smallest balance.";
        break;
      case PayoffStrategy.manual:
        whenItHelps = "Best when your priorities change month to month (cashflow, deadlines, promos).";
        example = "You might target a debt with a promo ending soon or one tied to a secured asset.";
        break;
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: width * .05, vertical: height * .02),
        decoration: BoxDecoration(
          color: ProjectColors.blackColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: ProjectColors.whiteColor.withOpacity(.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textWidget(text: title, fontSize: .022, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor),
            SizedBox(height: height * .01),
            textWidget(
              text: desc,
              fontSize: .016,
              fontWeight: FontWeight.w700,
              color: ProjectColors.whiteColor.withOpacity(.75),
            ),
            SizedBox(height: height * .012),
            divider(),
            SizedBox(height: height * .012),
            textWidget(text: "When it helps", fontSize: .016, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor),
            SizedBox(height: height * .006),
            textWidget(
              text: whenItHelps,
              fontSize: .015,
              fontWeight: FontWeight.w700,
              color: ProjectColors.whiteColor.withOpacity(.65),
            ),
            SizedBox(height: height * .012),
            textWidget(text: "Example", fontSize: .016, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor),
            SizedBox(height: height * .006),
            textWidget(
              text: example,
              fontSize: .015,
              fontWeight: FontWeight.w700,
              color: ProjectColors.whiteColor.withOpacity(.65),
            ),
            SizedBox(height: height * .016),
            SizedBox(
              width: width,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProjectColors.whiteColor.withOpacity(.10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.symmetric(vertical: height * .014),
                ),
                onPressed: () => Get.back(),
                child: textWidget(text: "Close", fontWeight: FontWeight.w900, color: ProjectColors.whiteColor),
              ),
            ),
            SizedBox(height: height * .01),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _strategyTitle(PayoffStrategy s) {
    switch (s) {
      case PayoffStrategy.snowball:
        return "Snowball";
      case PayoffStrategy.avalanche:
        return "Avalanche";
      case PayoffStrategy.hybrid:
        return "Hybrid";
      case PayoffStrategy.manual:
        return "Manual";
    }
  }
}

class _StrategyLearnTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StrategyLearnTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .014),
        decoration: BoxDecoration(
          color: ProjectColors.whiteColor.withOpacity(.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ProjectColors.whiteColor.withOpacity(.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: title, fontSize: .017, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor),
                  SizedBox(height: height * .004),
                  textWidget(
                    text: subtitle,
                    fontSize: .015,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.whiteColor.withOpacity(.65),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ProjectColors.whiteColor.withOpacity(.55), size: height * .03),
          ],
        ),
      ),
    );
  }
}
