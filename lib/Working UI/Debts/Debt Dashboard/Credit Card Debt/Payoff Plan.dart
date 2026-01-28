import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../BaseScreen.dart';
import '../../../../models/Debt Model.dart';
import '../../../Constant UI.dart';
import '../../../Constants.dart';
import '../../../Controllers.dart';
import 'Credit Card Logic.dart';

class CreditPayoffPlanScreen extends StatefulWidget {
  const CreditPayoffPlanScreen({super.key});

  @override
  State<CreditPayoffPlanScreen> createState() => _DebtPayoffPlanScreenState();
}

class _DebtPayoffPlanScreenState extends State<CreditPayoffPlanScreen> {
  List<DebtScheduleRow> rows = const [];
  DebtProjection proj = const DebtProjection(months: 0, totalPaid: 0, totalInterest: 0);
  DateTime? debtFreeDate;

  @override
  void initState() {
    super.initState();
    // Wait for first frame so selectedDebt is already set by previous screen/nav
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final d = debtV2.selectedDebt.value;
    if (d == null) return;

    final r = await CreditCardDebtLogic().buildScheduleAndSave(months: 120);
    if (!mounted) return;

    DateTime? hitZero;
    for (final x in r) {
      if (x.endBalance <= 0) {
        hitZero = x.dueDate;
        break;
      }
    }

    setState(() {
      rows = r;
      proj = CreditCardDebtLogic().projectionFromSchedule(r);
      debtFreeDate = hitZero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Payoff Plan',
      body: Obx(() {
        final d = debtV2.selectedDebt.value;

        if (d == null) {
          return Center(
            child: textWidget(
              text: "No debt selected",
              fontSize: .018,
              fontWeight: FontWeight.w800,
              color: ProjectColors.whiteColor.withOpacity(.7),
            ),
          );
        }

        // Optional allocation (strategy across all debts)
        final lines = CreditCardDebtLogic().buildPayoffPlan();
        final mine = lines.firstWhereOrNull((x) => x.id == d.id);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: height * .012),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * .01),
              textWidget(
                text: "${d.name} • Strategy: ${debtV2.selectedLabel()}",
                fontSize: .016,
                fontWeight: FontWeight.w700,
                color: ProjectColors.whiteColor.withOpacity(.6),
              ),
              SizedBox(height: height * .01),

              // ✅ Projection card (from state rows/proj)
              DarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: "Projection (includes APR + your planned edits)",
                      fontSize: .016,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor.withOpacity(.7),
                    ),
                    SizedBox(height: height * .006),
                    textWidget(
                      text: debtFreeDate == null
                          ? "Not enough payment to finish"
                          : "${debtFreeDate!.month}/${debtFreeDate!.year}  (${proj.months} months)",
                      fontSize: .024,
                      fontWeight: FontWeight.w900,
                      color: ProjectColors.whiteColor,
                    ),
                    SizedBox(height: height * .012),
                    _kv("Current balance", money(d.balance)),
                    divider(),
                    _kv("Planned months", "${proj.months}"),
                    divider(),
                    _kv("Total interest", money2(proj.totalInterest)),
                    divider(),
                    _kv("Total you'll pay", money2(proj.totalPaid)),
                  ],
                ),
              ),

              SizedBox(height: height * .015),

              // Optional: Allocation view (only if multiple debts)
              if (lines.length > 1) ...[
                textWidget(
                  text: "This pay period allocation",
                  fontSize: .02,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
                SizedBox(height: height * .01),
                DarkCard(
                  child: Column(
                    children: [
                      for (int i = 0; i < lines.length; i++) ...[
                        _PlanRow(
                          name: lines[i].name,
                          min: lines[i].min,
                          extra: lines[i].extra,
                          highlight: lines[i].id == d.id,
                        ),
                        if (i != lines.length - 1) divider(),
                      ]
                    ],
                  ),
                ),
                if (mine != null) ...[
                  SizedBox(height: height * .02),
                  DarkCard(
                    child: textWidget(
                      text: "Your debt gets extra: ${money(mine.extra)} this period (based on strategy).",
                      fontSize: .015,
                      fontWeight: FontWeight.w700,
                      color: ProjectColors.whiteColor.withOpacity(.6),
                    ),
                  ),
                ],
                SizedBox(height: height * .015),
              ],

              DarkCard(
                child: textWidget(
                  text:
                      "Projection uses APR + your planned monthly payments (the ones you edit in Payment Schedule). Recording real payments updates balance and the projection recalculates.",
                  fontSize: .015,
                  fontWeight: FontWeight.w700,
                  color: ProjectColors.whiteColor.withOpacity(.6),
                ),
              ),

              SizedBox(height: height * .02),

              // Optional: show the first few schedule rows here too
              if (rows.isNotEmpty) ...[
                textWidget(
                  text: "Upcoming schedule",
                  fontSize: .02,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
                SizedBox(height: height * .01),
                DarkCard(
                  child: Column(
                    children: [
                      for (int i = 0; i < rows.length && i < 12; i++) ...[
                        _EditableScheduleRow(row: rows[i], onChanged: _load),
                        if (i != 11 && i != rows.length - 1) divider(),
                      ],
                    ],
                  ),
                ),
              ],

              SizedBox(height: height * .03),
            ],
          ),
        );
      }),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(
          child: textWidget(
            text: k,
            fontSize: .016,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor.withOpacity(.55),
          ),
        ),
        textWidget(
          text: v,
          fontSize: .016,
          fontWeight: FontWeight.w900,
          color: ProjectColors.whiteColor.withOpacity(.9),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String name;
  final double min;
  final double extra;
  final bool highlight;

  const _PlanRow({
    required this.name,
    required this.min,
    required this.extra,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final total = min + extra;

    return Row(
      children: [
        Expanded(
          child: textWidget(
            text: name,
            fontSize: .017,
            fontWeight: FontWeight.w900,
            color: highlight ? ProjectColors.whiteColor : ProjectColors.whiteColor.withOpacity(.8),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            textWidget(
              text: money(total),
              fontSize: .017,
              fontWeight: FontWeight.w900,
              color: highlight ? ProjectColors.greenColor : ProjectColors.whiteColor.withOpacity(.85),
            ),
            SizedBox(height: height * .002),
            textWidget(
              text: "min ${money(min)} + extra ${money(extra)}",
              fontSize: .013,
              fontWeight: FontWeight.w700,
              color: ProjectColors.whiteColor.withOpacity(.45),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditableScheduleRow extends StatelessWidget {
  final DebtScheduleRow row;
  final Future<void> Function()? onChanged;

  const _EditableScheduleRow({required this.row, this.onChanged});

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
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.15)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.35)),
              ),
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
                    if (onChanged != null) await onChanged!();
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
                    await CreditCardDebtLogic().setPlannedPaymentOverride(row.dueDate, toDouble(c.text) ?? 0);
                    Get.back();
                    if (onChanged != null) await onChanged!();
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
      ),
    );
  }
}
