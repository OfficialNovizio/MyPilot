import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Constant UI.dart';
import '../Constants.dart';
import 'Account Getx.dart';

class NewJob extends StatelessWidget {
  NewJob({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: ProjectColors.pureBlackColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .02),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          height: height * .045,
                          width: height * .045,
                          decoration: BoxDecoration(
                            color: ProjectColors.whiteColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ProjectColors.blackColor.withOpacity(.06),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(Icons.chevron_left_rounded, color: ProjectColors.blackColor, size: height * .03),
                        ),
                      ),
                      SizedBox(width: width * .2),
                      textWidget(
                        text: 'New Job',
                        fontSize: .03,
                        fontWeight: FontWeight.bold,
                        color: ProjectColors.whiteColor,
                      ),
                    ],
                  ),
                  SizedBox(height: height * .02),
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
                            text: "Add a job to improve cash-flow alerts and debt plan accuracy.",
                            fontSize: .016,
                            color: ProjectColors.whiteColor.withOpacity(.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * .01),
                  SizedBox(width: width * .7, child: BigFormField(form: account.controllers![0], fontScale: .04)),
                  SizedBox(height: height * .01),
                  Column(
                    children: [
                      _infoCard(
                        children: [
                          Row(
                            children: [
                              textWidget(
                                text: 'Hourly Rate',
                                fontSize: .016,
                                fontWeight: FontWeight.w600,
                                color: ProjectColors.whiteColor.withOpacity(.55),
                              ),
                              Spacer(),
                              Expanded(child: BigFormField(form: account.controllers![1], textAlign: TextAlign.end))
                            ],
                          ),
                          _divider(),
                          GestureDetector(
                            onTap: () {
                              account.showPayFrq!.value = !account.showPayFrq!.value;
                            },
                            child: _kvRow('Pay Frequency',
                                account.controllers![4].controller.text.isEmpty ? "Pay Frequency" : account.controllers![4].controller.text),
                          ),
                          Visibility(
                            visible: account.showPayFrq!.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: account.payFrequency.entries
                                  .map(
                                    (t) => Padding(
                                      padding: EdgeInsets.only(top: height * .01),
                                      child: GestureDetector(
                                        onTap: () {
                                          account.controllers![4].controller.text = t.key;
                                          account.showPayFrq!.value = !account.showPayFrq!.value;
                                        },
                                        child: textWidget(
                                          text: t.key,
                                          fontSize: .016,
                                          fontWeight: FontWeight.w600,
                                          color: ProjectColors.whiteColor.withOpacity(.55),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          _divider(),
                          GestureDetector(
                            onTap: () {
                              AppDatePicker.pickDate(minDate: DateTime.now().subtract(const Duration(days: 30)), maxDate: DateTime.now())
                                  .then((onValue) {
                                if (onValue != null) {
                                  account.controllers![3].controller.text = formatDate(onValue);
                                  account.controllers![3].pickedDate = onValue;
                                  account.controllers!.refresh();
                                }
                              });
                            },
                            child: _kvRow(
                              'Last Pay Cheque',
                              account.controllers![3].controller.text.isEmpty ? "Select Date" : account.controllers![3].controller.text,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * .014),
                      _infoCard(
                        children: [
                          GestureDetector(
                            onTap: () {
                              account.showDays!.value = !account.showDays!.value;
                            },
                            child: _kvRow('Week Start',
                                account.controllers![5].controller.text.isEmpty ? "Select Day" : account.controllers![5].controller.text),
                          ),
                          Visibility(
                            visible: account.showDays!.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: account.daysShort
                                  .map(
                                    (t) => Padding(
                                      padding: EdgeInsets.only(top: height * .01),
                                      child: GestureDetector(
                                        onTap: () {
                                          account.controllers![5].controller.text = t;
                                          account.showDays!.value = !account.showDays!.value;
                                        },
                                        child: textWidget(
                                          text: t,
                                          fontSize: .016,
                                          fontWeight: FontWeight.w600,
                                          color: ProjectColors.whiteColor.withOpacity(.55),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          _divider(),
                          Row(
                            children: [
                              textWidget(
                                text: 'Pay Multiplier (e.g., 1.2× base rate)',
                                fontSize: .016,
                                fontWeight: FontWeight.w600,
                                color: ProjectColors.whiteColor.withOpacity(.55),
                              ),
                              Spacer(),
                              Expanded(child: BigFormField(form: account.controllers![6], textAlign: TextAlign.end))
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: height * .014),
                      _infoCard(
                        children: [
                          Row(
                            children: [
                              textWidget(
                                text: 'Job Color',
                                fontSize: .016,
                                fontWeight: FontWeight.w600,
                                color: ProjectColors.whiteColor.withOpacity(.55),
                              ),
                              Spacer(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final hex in account.colorChoices)
                                    GestureDetector(
                                      onTap: () {
                                        account.controllers![2].controller.text = hex;
                                        account.controllers!.refresh();
                                      },
                                      child: Container(
                                        width: width * .05,
                                        height: height * .025,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(hex)),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: account.controllers![2].controller.text == hex
                                                ? ProjectColors.whiteColor.withOpacity(0.8)
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: height * .02),
                      Center(
                        child: normalButton(
                          title: "Save",
                          cWidth: .8,
                          bColor: ProjectColors.greenColor,
                          callback: () {
                            if (account.jobs!.any((test) => test.jobName!.toLowerCase() == account.controllers![0].controller.text.toLowerCase()) &&
                                account.status!.value == JobStatus.create) {
                              showSnackBar("Already exists", "A job with this name already exists.");
                            } else {
                              account.createNewJob();
                            }
                          },
                        ),
                      ),
                      SizedBox(height: height * .02),
                      Visibility(
                        visible: account.status!.value != JobStatus.create ? true : false,
                        child: Center(
                          child: outLinedButton(
                            title: "Delete",
                            color: ProjectColors.errorColor,
                            cHeight: .05,
                            cWidth: .8,
                            callback: () {
                              account.status!.value = JobStatus.delete;
                              account.createNewJob();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return DarkCard(
      child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: children),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * .006),
      child: Row(
        children: [
          Expanded(
            child: textWidget(
              text: k,
              fontSize: .016,
              fontWeight: FontWeight.w600,
              color: ProjectColors.whiteColor.withOpacity(.55),
            ),
          ),
          textWidget(
            text: v,
            fontSize: .018,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: height * .0012,
      margin: EdgeInsets.symmetric(vertical: height * .006),
      color: ProjectColors.whiteColor.withOpacity(.06),
    );
  }
}
