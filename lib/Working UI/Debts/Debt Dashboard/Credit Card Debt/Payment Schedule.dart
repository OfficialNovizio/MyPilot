import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../BaseScreen.dart';
import '../../../../models/Debt Model.dart';
import '../../../Constant UI.dart';
import '../../../Constants.dart';
import '../../../Controllers.dart';
import 'Credit Card Logic.dart';

class CreditPaymentScheduleScreen extends StatefulWidget {
  const CreditPaymentScheduleScreen({super.key});

  @override
  State<CreditPaymentScheduleScreen> createState() => _DebtPaymentScheduleScreenState();
}

class _DebtPaymentScheduleScreenState extends State<CreditPaymentScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Payment Schedule',
      body: Obx(() {
        final d = debtV2.selectedDebt.value;

        // ✅ use saved rows from model (you must have scheduleRows in DebtItem)
        final rows = d!.paymentScheduleOverride ?? const <DebtScheduleRow>[];

        final proj = CreditCardDebtLogic().projectionFromSchedule(rows);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: height * .015),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * .01),
              // textWidget(
              //   text: "${d.name} • due day ${d.dueDayOfMonth ?? '-'}",
              //   fontSize: .016,
              //   fontWeight: FontWeight.w700,
              //   color: ProjectColors.whiteColor.withOpacity(.6),
              // ),
              SizedBox(height: height * .01),
              DarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: "Projection",
                      fontSize: .018,
                      fontWeight: FontWeight.w900,
                      color: ProjectColors.whiteColor,
                    ),
                    SizedBox(height: height * .012),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ProjItem(label: "Months", value: "${proj.months}")),
                        Expanded(child: _ProjItem(label: "Total APR cost", value: money2(proj.totalInterest))),
                        _ProjItem(label: "Total you'll pay", value: money2(proj.totalPaid), big: true),
                      ],
                    ),
                    SizedBox(height: height * .012),
                    divider(),
                    SizedBox(height: height * .012),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: ProjectColors.whiteColor.withOpacity(.55), size: height * .022),
                        SizedBox(width: width * .03),
                        Expanded(
                          child: textWidget(
                            text: "Edit any month's planned payment. Recording real payments updates balance and this schedule recalculates.",
                            fontSize: .015,
                            fontWeight: FontWeight.w700,
                            color: ProjectColors.whiteColor.withOpacity(.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * .02),
              scheduleExplainerCard(d: d, proj: proj),
              SizedBox(height: height * .02),
              DarkCard(
                child: rows.isEmpty
                    ? textWidget(
                        text: "Add a Due Day (1–31) to generate a schedule.",
                        fontSize: .016,
                        fontWeight: FontWeight.w700,
                        color: ProjectColors.whiteColor.withOpacity(.65),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < rows.length; i++) ...[
                            _EditableScheduleRow(row: rows[i]),
                            if (i != rows.length - 1) divider(),
                          ],
                        ],
                      ),
              ),
              SizedBox(height: height * .03),
            ],
          ),
        );
      }),
    );
  }

  Widget scheduleExplainerCard({required DebtItem d, required DebtProjection proj}) {
    final apr = d.apr;
    final monthlyRate = (apr / 100.0) / 12.0;
    final firstMonthInterest = d.balance * monthlyRate;

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: ProjectColors.whiteColor.withOpacity(.75), size: height * .022),
              SizedBox(width: width * .02),
              textWidget(
                text: "How this schedule works",
                fontSize: .018,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor,
              ),
            ],
          ),
          SizedBox(height: height * .012),
          _miniLine(
            title: "APR is yearly",
            body: "${apr.toStringAsFixed(apr == 0 ? 0 : 1)}% APR means interest accrues over the year, not per month.",
          ),
          SizedBox(height: height * .01),
          _miniLine(
            title: "Why you may see \$0 interest",
            body: "Monthly interest can be cents. Example: first month ≈ ${money2(firstMonthInterest)}.",
          ),
          SizedBox(height: height * .01),
          Container(
            padding: EdgeInsets.all(width * .03),
            decoration: BoxDecoration(
              color: ProjectColors.whiteColor.withOpacity(.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ProjectColors.whiteColor.withOpacity(.10)),
            ),
            child: Column(
              children: [
                _kvRow("Months", "${proj.months}"),
                divider(),
                _kvRow("Total APR cost", money2(proj.totalInterest)),
                divider(),
                _kvRow("Total you'll pay", money2(proj.totalPaid)),
              ],
            ),
          ),
          SizedBox(height: height * .012),
          textWidget(
            text: "Tip: Edit any month’s planned payment. Recording real payments updates your balance and this schedule recalculates.",
            fontSize: .015,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor.withOpacity(.6),
          ),
        ],
      ),
    );
  }

  Widget _miniLine({required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(text: title, fontSize: .016, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor.withOpacity(.9)),
        SizedBox(height: height * .004),
        textWidget(text: body, fontSize: .015, fontWeight: FontWeight.w700, color: ProjectColors.whiteColor.withOpacity(.6)),
      ],
    );
  }

  Widget _kvRow(String k, String v) {
    return Row(
      children: [
        Expanded(child: textWidget(text: k, fontSize: .015, fontWeight: FontWeight.w700, color: ProjectColors.whiteColor.withOpacity(.55))),
        textWidget(text: v, fontSize: .016, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor.withOpacity(.9)),
      ],
    );
  }
}

class _ProjItem extends StatelessWidget {
  final String label;
  final String value;
  final bool big;

  const _ProjItem({required this.label, required this.value, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: label,
          fontSize: .015,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor.withOpacity(.55),
        ),
        SizedBox(height: height * .006),
        textWidget(
          text: value,
          fontSize: big ? .028 : .022,
          fontWeight: FontWeight.w900,
          color: ProjectColors.whiteColor,
        ),
      ],
    );
  }
}

class _EditableScheduleRow extends StatelessWidget {
  final DebtScheduleRow row;
  const _EditableScheduleRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final date = "${row.dueDate.month}/${row.dueDate.day}/${row.dueDate.year}";
    final interestTxt = money2(row.interest);
    final afterTxt = money2(row.endBalance);

    return InkWell(
      onTap: () => _editPlannedPayment(context),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: height * .012),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: date, fontSize: .018, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor),
                  SizedBox(height: height * .006),
                  Row(
                    children: [
                      textWidget(
                        text: "Interest $interestTxt  • After $afterTxt",
                        fontSize: .015,
                        fontWeight: FontWeight.w700,
                        color: ProjectColors.whiteColor.withOpacity(.55),
                      ),
                      const Spacer(),
                      textWidget(
                        text: "Tap to edit",
                        fontSize: .014,
                        fontWeight: FontWeight.w700,
                        color: ProjectColors.whiteColor.withOpacity(.35),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: width * .03),
            textWidget(
              text: money2(row.plannedPayment),
              fontSize: .02,
              fontWeight: FontWeight.w900,
              color: ProjectColors.whiteColor,
            ),
          ],
        ),
      ),
    );
  }

  void _editPlannedPayment(BuildContext context) {
    final c = TextEditingController(text: row.plannedPayment.toStringAsFixed(2));
    callBottomSheet(
        title: 'Edit planned payment',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: c,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: ProjectColors.whiteColor),
              decoration: InputDecoration(
                hintText: "Amount",
                hintStyle: TextStyle(color: ProjectColors.whiteColor.withOpacity(.35)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.15))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.35))),
              ),
            ),
            SizedBox(height: height * .018),
            Row(
              children: [
                Expanded(
                  child: normalButton(
                    callback: () async {
                      await CreditCardDebtLogic().setPlannedPaymentOverride(row.dueDate, 0);
                      Get.back();
                    },
                    title: "Reset",
                    bColor: ProjectColors.whiteColor.withOpacity(.1),
                    invertColors: false,
                  ),
                ),
                SizedBox(width: width * .03),
                Expanded(
                  child: normalButton(
                    callback: () async {
                      await CreditCardDebtLogic().setPlannedPaymentOverride(row.dueDate, toDouble(c.text)!);
                      Get.back();
                    },
                    title: "Save",
                    bColor: ProjectColors.greenColor,
                    invertColors: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: height * .02),
          ],
        ));
  }
}
