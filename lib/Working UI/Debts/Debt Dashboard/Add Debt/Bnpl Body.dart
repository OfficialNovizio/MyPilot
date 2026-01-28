import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../models/Bnpl model.dart';
import '../../../Cards and Account/Cards.dart';
import '../../../Constant UI.dart';
import '../../../Constants.dart';

// Assumes these exist in your project:
/// - DarkCard
/// - DarkTextField
/// - segmentedToggle
/// - textWidget
/// - ProjectColors
/// - toDouble(String) -> double?

class BnplBody extends StatefulWidget {
  @override
  State<BnplBody> createState() => _BnplPlanDetailsCardState();
}

class _BnplPlanDetailsCardState extends State<BnplBody> {
  final Rxn<BnplProvider> _provider = Rxn<BnplProvider>();

  final TextEditingController _monthsC = TextEditingController(); // only when installments == null
  final TextEditingController totalAmountC = TextEditingController(); // only when installments == null

  int? get _effectiveInstallments {
    final fixed = _provider.value?.plans.firstOrNull?.installments;
    if (fixed != null) return fixed;

    final m = int.tryParse(_monthsC.text.trim());
    return (m != null && m > 0) ? m : null;
  }

  double get _totalAmount => ((toDouble(totalAmountC.text) ?? 0.0).clamp(0.0, 1e12)).toDouble();

  double? get _installmentAmount {
    final n = _effectiveInstallments;
    final total = _totalAmount;
    return (n != null && n > 0 && total > 0) ? (total / n) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * .02),
          textWidget(
            text: "Plan Details",
            fontSize: .015,
            fontWeight: FontWeight.w800,
            color: ProjectColors.whiteColor.withOpacity(.85),
          ),
          SizedBox(height: height * .01),
          DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider dropdown
                DarkTextField(
                  title: 'Operator',
                  backgroundColor: ProjectColors.pureBlackColor,
                  hintText: debtV2.selectedBnpl.value == null ? 'Select' : debtV2.selectedBnpl.value!.name,
                  leading: Icon(Icons.credit_card_rounded, color: ProjectColors.whiteColor.withOpacity(0.75)),
                  onTap: () async {
                    callBottomSheet(child: Options(), title: 'Operators');
                  },
                  trailing: Icon(Icons.arrow_drop_down_outlined, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                ),

                SizedBox(height: height * .01),
                DarkTextField(
                  title: 'Plan',
                  backgroundColor: ProjectColors.pureBlackColor,
                  hintText: debtV2.selectedBnplPlan.value == null ? 'Select' : debtV2.planLabel(debtV2.selectedBnplPlan.value),
                  leading: Icon(Icons.receipt_outlined, color: ProjectColors.whiteColor.withOpacity(0.75)),
                  onTap: () async {
                    if (debtV2.selectedBnpl.value == null) {
                      showSnackBar('Select', 'Please select operator');
                    } else {
                      callBottomSheet(child: Options(showPlans: true), title: 'Operators');
                    }
                  },
                  trailing: Icon(Icons.arrow_drop_down_outlined, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                ),

                SizedBox(height: height * .01),

                // Total purchase + quick fixed selector row
                Row(
                  children: [
                    Expanded(
                      child: DarkTextField(
                        title: "Amount",
                        hintText: "\$",
                        controller: totalAmountC,
                        backgroundColor: ProjectColors.pureBlackColor,
                        leading: Icon(Icons.monetization_on_outlined, color: ProjectColors.whiteColor.withOpacity(0.75)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    Visibility(
                      visible: debtV2.selectedBnplPlan.value == null
                          ? false
                          : debtV2.selectedBnplPlan.value!.type == BnplPlanType.payMonthly
                              ? true
                              : false,
                      child: Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: width * .02),
                          child: DarkTextField(
                            title: "Installments",
                            hintText: "ex. 1,2,3",
                            controller: _monthsC,
                            backgroundColor: ProjectColors.pureBlackColor,
                            leading: Icon(Icons.calendar_month, color: ProjectColors.whiteColor.withOpacity(0.75)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * .02),

                // Installment amount line
                Row(
                  children: [
                    Expanded(
                      child: textWidget(
                        text: "Installment Amount",
                        fontSize: .0145,
                        fontWeight: FontWeight.w800,
                        color: ProjectColors.whiteColor.withOpacity(.7),
                      ),
                    ),
                    textWidget(
                      text: _installmentAmount == null ? "-" : "\$${_installmentAmount!.toStringAsFixed(0)} x ${_effectiveInstallments ?? "-"}",
                      fontSize: .015,
                      fontWeight: FontWeight.w900,
                      color: ProjectColors.whiteColor.withOpacity(.9),
                    ),
                    SizedBox(width: width * .01),
                    Icon(Icons.chevron_right_rounded, color: ProjectColors.whiteColor.withOpacity(.4)),
                  ],
                ),

                // Small helper line like your screenshot “4 payments of $100”
                if (_installmentAmount != null && _effectiveInstallments != null) ...[
                  SizedBox(height: height * .008),
                  textWidget(
                    text: "$_effectiveInstallments payments of \$${_installmentAmount!.toStringAsFixed(0)}",
                    fontSize: .0135,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.greenColor.withOpacity(.85),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

/* ------------------------- UI bits (small) ------------------------- */

class _DropdownRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DropdownRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .014),
        decoration: BoxDecoration(
          color: ProjectColors.pureBlackColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ProjectColors.whiteColor.withOpacity(.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: ProjectColors.whiteColor.withOpacity(.7)),
            SizedBox(width: width * .02),
            Expanded(
              child: textWidget(
                text: title,
                fontSize: .015,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor.withOpacity(.9),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: ProjectColors.whiteColor.withOpacity(.5)),
          ],
        ),
      ),
    );
  }
}

class _FixedInstallmentToggle extends StatelessWidget {
  final List<int> counts;
  final int? selected;
  final void Function(int count) onPick;

  const _FixedInstallmentToggle({
    required this.counts,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    // Uses your segmentedToggle for consistent look
    final options = counts.map((e) => e.toString()).toList();
    final selectedIndex = selected == null ? 0 : options.indexOf(selected.toString()).clamp(0, options.length - 1);

    return SizedBox(
      width: width * .28,
      child: segmentedToggle(
        activeColor: ProjectColors.greenColor,
        bgColor: ProjectColors.pureBlackColor,
        options: options,
        verticalPadding: .012,
        selectedIndex: selectedIndex,
        onChanged: (i, v) => onPick(int.parse(v)),
      ),
    );
  }
}

/* ------------------------- picker helper (tiny) ------------------------- */

class _PickItem {
  final String id;
  final String label;
  _PickItem({required this.id, required this.label});
}

Future<String?> _simplePicker(
  BuildContext context, {
  required String title,
  required List<_PickItem> items,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .02),
        decoration: BoxDecoration(
          color: ProjectColors.pureBlackColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: ProjectColors.whiteColor.withOpacity(.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            textWidget(text: title, fontSize: .016, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor),
            SizedBox(height: height * .012),
            ...items.map((x) {
              return ListTile(
                title: textWidget(
                  text: x.label,
                  fontSize: .015,
                  fontWeight: FontWeight.w800,
                  color: ProjectColors.whiteColor.withOpacity(.9),
                ),
                onTap: () => Navigator.pop(context, x.id),
              );
            }).toList(),
          ],
        ),
      );
    },
  );
}

class Options extends StatelessWidget {
  final bool? showPlans;
  Options({this.showPlans = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: showPlans!
          ? [
              ...debtV2.selectedBnpl.value!.plans.map((x) {
                return ListTile(
                  title: textWidget(
                    text: debtV2.planLabel(x),
                    fontSize: .015,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(.9),
                  ),
                  onTap: () {
                    debtV2.selectedBnplPlan.value = x;
                    debtV2.selectedBnplPlan.refresh();
                    Get.back();
                  },
                );
              }).toList(),
            ]
          : [
              ...debtV2.bnplProvidersCA.map((x) {
                return ListTile(
                  title: textWidget(
                    text: x.name,
                    fontSize: .015,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(.9),
                  ),
                  onTap: () {
                    debtV2.selectedBnpl.value = x;
                    debtV2.selectedBnpl.refresh();
                    Get.back();
                  },
                );
              }).toList(),
            ],
    );
  }
}
