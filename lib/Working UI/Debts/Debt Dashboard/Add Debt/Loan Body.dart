import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Cards and Account/Cards.dart';
import '../../../Constant UI.dart';
import '../../../Constants.dart';
import '../../../Controllers.dart';

class LoanBody extends StatelessWidget {
  const LoanBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * .02),

          // -------------------- Payback cadence --------------------
          textWidget(
            text: "How will you pay back the loan?",
            fontSize: .015,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .01),
          DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                segmentedToggle(
                  activeColor: ProjectColors.greenColor,
                  cWidth: .85,
                  bgColor: ProjectColors.pureBlackColor,
                  options: debtV2.paybackOptions,
                  verticalPadding: .015,
                  selectedIndex: debtV2.paybackOptions.indexOf(debtV2.payback.value).clamp(0, debtV2.paybackOptions.length - 1),
                  onChanged: (i, v) {
                    debtV2.payback.value = v;
                    debtV2.payback.refresh();
                  },
                ),
                SizedBox(height: height * .02),

                // Show due day ONLY for Monthly
                Row(
                  children: [
                    Expanded(
                      child: DarkTextField(
                        title: 'Last Charged',
                        backgroundColor: ProjectColors.pureBlackColor,
                        hintText: debtV2.controllers[4].controller.text.isEmpty ? '5' : debtV2.controllers[4].controller.text,
                        onTap: () async {
                          final res = await AppPicker.pick(mode: PickerMode.date, title: "Date of Charged");
                          if (res != null) {
                            debtV2.controllers[4].controller.text = formatDate(res.dateTime!);
                            debtV2.controllers[4].pickedDate = res.dateTime!;
                            debtV2.controllers.refresh();
                          }
                        },
                        trailing: Icon(Icons.calendar_month_rounded, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                      ),
                    ),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: DarkTextField(
                        backgroundColor: ProjectColors.pureBlackColor,
                        title: 'Minimum pay',
                        hintText: '\$',
                        controller: debtV2.controllers[3].controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * .01),

                // -------------------- Amount details --------------------
                Row(
                  children: [
                    Expanded(
                      child: DarkTextField(
                        backgroundColor: ProjectColors.pureBlackColor,
                        title: 'Balance',
                        hintText: '\$',
                        controller: debtV2.controllers[1].controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: DarkTextField(
                        backgroundColor: ProjectColors.pureBlackColor,
                        title: 'APR (%)',
                        hintText: '5',
                        controller: debtV2.controllers[2].controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: height * .02),
          textWidget(text: 'Loan Type', fontSize: .015, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
          SizedBox(height: height * .01),
          DarkCard(
            child: Wrap(
              spacing: width * .01,
              runSpacing: height * .005,
              children: debtV2.loanTypes
                  .map<Widget>((t) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => debtV2.loanType.value = t,
                        child: Container(
                          width: width * .45,
                          padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .012),
                          decoration: BoxDecoration(
                            color: debtV2.loanType.value == t ? ProjectColors.greenColor.withOpacity(.22) : ProjectColors.pureBlackColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  debtV2.loanType.value == t ? ProjectColors.greenColor.withOpacity(.7) : ProjectColors.whiteColor.withOpacity(.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: textWidget(
                                  text: t,
                                  fontSize: .014,
                                  fontWeight: FontWeight.w800,
                                  color: debtV2.loanType.value == t ? ProjectColors.greenColor : ProjectColors.whiteColor.withOpacity(.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: height * .02),

          // -------------------- Payment Info --------------------
          // textWidget(text: 'Payment Info', fontSize: .015, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
          // SizedBox(height: height * .01),
          // Row(
          //   children: [
          //     Expanded(
          //       child: DarkTextField(
          //         title: 'Secured',
          //         value: debtV2.secured.value ? "Yes" : 'No',
          //         trailing: Switch(
          //           value: debtV2.secured.value,
          //           onChanged: (val) => debtV2.secured.value = val,
          //           activeColor: ProjectColors.yellowColor,
          //           inactiveThumbColor: ProjectColors.whiteColor.withOpacity(0.7),
          //           inactiveTrackColor: ProjectColors.whiteColor.withOpacity(0.15),
          //         ),
          //       ),
          //     ),
          //     SizedBox(width: width * .02),
          //     Expanded(
          //       child: DarkTextField(
          //         title: 'Fixed Installment',
          //         value: debtV2.fixedInstallment.value ? 'Yes' : 'No',
          //         trailing: Switch(
          //           value: debtV2.fixedInstallment.value,
          //           onChanged: (val) {
          //             debtV2.fixedInstallment.value = val;
          //             debtV2.fixedInstallment.refresh();
          //           },
          //           activeColor: ProjectColors.yellowColor,
          //           inactiveThumbColor: ProjectColors.whiteColor.withOpacity(0.7),
          //           inactiveTrackColor: ProjectColors.whiteColor.withOpacity(0.15),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),

          // -------------------- Notes (wired) --------------------
          DarkTextField(
            title: 'Notes',
            hintText: 'Add notes (e.g., 0% promo ends in Feb)',
            controller: debtV2.controllers[5].controller,
          ),
        ],
      ),
    );
  }
}
