import 'dart:math';

import 'package:emptyproject/Working%20UI/Account/Account%20Getx.dart';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    account.loadSavedJobs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: ColoredBox(
          color: ProjectColors.pureBlackColor,
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * .02, horizontal: width * .01),
                    child: textWidget(
                      text: "ACTIVE JOBS",
                      fontSize: .03,
                      color: ProjectColors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...account.jobs!.map((a) => Container(
                        decoration: BoxDecoration(color: ProjectColors.whiteColor, borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .01),
                        margin: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .02),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.join_full,
                                  color: ProjectColors.blackColor,
                                  size: height * .03,
                                ),
                                SizedBox(width: width * .02),
                                textWidget(
                                  text: a.jobName,
                                  fontSize: .03,
                                  color: ProjectColors.blackColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            SizedBox(height: height * .02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CardFields(title: 'Wage / hr', subTitle: a.wageHr),
                                CardFields(title: 'Last Deposit', subTitle: a.lastPayChequeDate ?? DateTime.now().toString()),
                              ],
                            ),
                            Divider(color: ProjectColors.blackColor.withOpacity(.5)),
                            SizedBox(height: height * .01),
                            textWidget(
                              text: 'Color',
                              fontSize: .015,
                              color: ProjectColors.blackColor,
                              fontWeight: FontWeight.bold,
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final hex in account.colorChoices)
                                  Container(
                                    width: width * .05,
                                    height: height * .025,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(hex)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: hex == a.jobColor ? ProjectColors.blackColor : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Divider(color: ProjectColors.blackColor.withOpacity(.5)),
                            SizedBox(height: height * .01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CardFields(title: 'Week Start', subTitle: a.weekStart),
                                CardFields(title: 'Pay Frequency', subTitle: a.payFrequency),
                              ],
                            ),
                            Divider(color: ProjectColors.blackColor.withOpacity(.5)),
                            SizedBox(height: height * .01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    textWidget(
                                      text: 'Stat Pay',
                                      fontSize: .015,
                                      color: ProjectColors.blackColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textWidget(
                                      text: a.statPay,
                                      fontSize: .015,
                                      color: ProjectColors.blackColor,
                                    ),
                                  ],
                                ),
                                normalButton(
                                    title: "EDIT",
                                    cWidth: .2,
                                    callback: () {
                                      account.status!.value = JobStatus.edit;
                                      account.addNewJob = a;
                                      account.controllers![0].controller.text = a.jobName!;
                                      account.controllers![1].controller.text = a.wageHr!;
                                      account.controllers![2].controller.text = a.jobColor!;
                                      account.controllers![3].controller.text = a.lastPayChequeDate!;
                                      account.controllers![4].controller.text = a.payFrequency!;
                                      account.controllers![5].controller.text = a.weekStart!;
                                      account.controllers![6].controller.text = a.statPay!;
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (context) => CreateNewJob(),
                                      );
                                    }),
                              ],
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: height * .02),
                  Center(
                    child: normalButton(
                      title: "New Job",
                      cWidth: .5,
                      invertColors: true,
                      callback: () {
                        account.status!.value = JobStatus.create;
                        for (var files in account.controllers!) {
                          if (files.title != "Job Color") {
                            files.controller.text = '';
                          }
                        }
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => CreateNewJob(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class CreateNewJob extends StatefulWidget {
  @override
  State<CreateNewJob> createState() => _CreateNewJobState();
}

class _CreateNewJobState extends State<CreateNewJob> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: height * .8,
        child: Popup(
          title: 'Create New Job',
          body: Form(
            key: account.controllerValidator,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ...account.controllers!.map<Widget>((TextForm form) {
                  return form.title == "Job color"
                      ? Padding(
                          padding: EdgeInsets.only(left: width * .05, top: height * .02),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              textWidget(text: "Job color type", fontSize: .018, color: ProjectColors.blackColor.withOpacity(.7)),
                              SizedBox(height: height * .01),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final hex in account.colorChoices)
                                    GestureDetector(
                                      onTap: () {
                                        form.controller.text = hex;
                                        account.controllers!.refresh();
                                      },
                                      child: Container(
                                        width: width * .05,
                                        height: height * .025,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(hex)),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: form.controller.text == hex ? ProjectColors.blackColor.withOpacity(0.8) : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: height * .005, right: width * .05),
                                child: Divider(color: ProjectColors.blackColor.withOpacity(.5)),
                              ),
                            ],
                          ),
                        )
                      : form.title == "Last pay cheque date"
                          ? Padding(
                              padding: EdgeInsets.only(left: width * .05, top: height * .02),
                              child: GestureDetector(
                                onTap: () async {
                                  final existing = form.controller.text.isEmpty ? DateTime.now().toString() : form.controller.text;
                                  final initial = (existing.isNotEmpty) ? DateTime.tryParse(existing) ?? DateTime.now() : DateTime.now();

                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initial,
                                    firstDate: DateTime(2020, 1, 1),
                                    lastDate: DateTime(2035, 12, 31),
                                    helpText: 'Select last pay cheque date',
                                    builder: (ctx, child) => Theme(
                                      data: Theme.of(ctx).copyWith(
                                        colorScheme: Theme.of(ctx).colorScheme.copyWith(
                                              primary: const Color(0xFF16A34A),
                                            ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked != null) {
                                    final selectedDated = DateFormat('yyyy/MM/dd').format(picked);
                                    form.controller.text = selectedDated;
                                    account.controllers!.refresh();
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    textWidget(text: "Last pay cheque date", fontSize: .018, color: ProjectColors.blackColor.withOpacity(.7)),
                                    Visibility(
                                      visible: form.controller.text.isEmpty ? false : true,
                                      child: Padding(
                                        padding: EdgeInsets.only(top: height * .005),
                                        child:
                                            textWidget(text: form.controller.text, fontSize: .018, color: ProjectColors.blackColor.withOpacity(.7)),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: height * .002, right: width * .05),
                                      child: Divider(color: ProjectColors.blackColor.withOpacity(.5)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : form.title == "Pay frequency"
                              ? Padding(
                                  padding: EdgeInsets.symmetric(horizontal: width * .05, vertical: height * .02),
                                  child: SizedBox(
                                    width: width,
                                    child: DropdownButtonFormField<int>(
                                      value: 1,
                                      decoration: InputDecoration(
                                        labelText: 'Pay frequency',
                                        labelStyle: TextStyle(fontSize: height * .018, color: ProjectColors.blackColor.withOpacity(.7)),
                                        isDense: true,
                                      ),
                                      items: List.generate(
                                        account.payFrequency.length,
                                        (i) => DropdownMenuItem(
                                          value: i + 1,
                                          child: textWidget(
                                              text: account.payFrequency[i], fontSize: .018, color: ProjectColors.blackColor.withOpacity(.7)),
                                        ),
                                      ),
                                      onChanged: (v) {
                                        form.controller.text = account.payFrequency[v! - 1].toString();
                                        account.controllers!.refresh();
                                      },
                                    ),
                                  ),
                                )
                              : form.title == "Week start"
                                  ? Visibility(
                                      visible: account.controllers![4].controller.text == "Monthly" ? false : true,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: width * .05, vertical: height * .02),
                                        child: SizedBox(
                                          width: width,
                                          child: DropdownButtonFormField<int>(
                                            value: 1,
                                            decoration: InputDecoration(
                                              labelText: 'Week starts',
                                              labelStyle: TextStyle(fontSize: height * .018, color: ProjectColors.blackColor.withOpacity(.7)),
                                              isDense: true,
                                            ),
                                            items: List.generate(
                                              7,
                                              (i) => DropdownMenuItem(
                                                value: i + 1,
                                                child: textWidget(
                                                    text: account.daysShort[i], fontSize: .018, color: ProjectColors.blackColor.withOpacity(.7)),
                                              ),
                                            ),
                                            onChanged: (v) {
                                              form.controller.text = account.daysShort[v! - 1].toString();
                                              account.controllers!.refresh();
                                            },
                                          ),
                                        ),
                                      ),
                                    )
                                  : MyFormField(
                                      form: form,
                                      textInputDone: form.title == "Stat pay (Ex 1.2 from base pay)" ? true : false,
                                      needCustomPadding: true,
                                      padding: EdgeInsets.symmetric(horizontal: width * .05, vertical: height * .01),
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Please Enter ${form.title}";
                                        }
                                        return null;
                                      },
                                    );
                }).toList(),
                SizedBox(height: height * .02),
                Center(
                  child: normalButton(
                    title: "Save",
                    cWidth: .5,
                    callback: () {
                      if (account.jobs!.any((test) => test.jobName!.toLowerCase() == account.controllers![0].controller.text.toLowerCase()) &&
                          account.status!.value == JobStatus.create) {
                        showSnackBar("Existed", "A job under this name is already existed");
                      } else {
                        account.createNewJob().then((onValue) {
                          if (onValue) {
                            account.loadSavedJobs();
                          }
                        });
                      }
                    },
                  ),
                ),
                SizedBox(height: height * .02),
                Visibility(
                  visible: account.status!.value != JobStatus.create ? true : false,
                  child: Center(
                    child: normalButton(
                      title: "Delete",
                      cWidth: .5,
                      callback: () {
                        account.status!.value = JobStatus.delete;
                        account.createNewJob().then((onValue) {
                          if (onValue) {
                            account.loadSavedJobs();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class CardFields extends StatelessWidget {
  final String? title;
  final String? subTitle;

  CardFields({this.title, this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: title,
          fontSize: .015,
          color: ProjectColors.blackColor,
          fontWeight: FontWeight.bold,
        ),
        textWidget(
          text: subTitle,
          fontSize: .015,
          color: ProjectColors.blackColor,
        ),
      ],
    );
  }
}
