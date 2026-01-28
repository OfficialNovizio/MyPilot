import 'package:emptyproject/BaseScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Constant UI.dart';
import '../Constants.dart';
import '../Controllers.dart';
import 'Account Getx.dart';
import 'Add New Job.dart';

class ActiveJobs extends StatefulWidget {
  const ActiveJobs({super.key});

  @override
  State<ActiveJobs> createState() => _ActiveJobsState();
}

class _ActiveJobsState extends State<ActiveJobs> {
  @override
  void initState() {
    account.loadSavedJobs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BaseScreen(
        title: 'Active Jobs',
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: height * .02),
              AddContent(
                title: 'New Job',
                subTitle: 'Set up a job to track schedules',
                callback: () {
                  account.status!.value = JobStatus.create;
                  for (var files in account.controllers!) {
                    if (files.title != "Job Color") {
                      files.controller.text = '';
                    }
                  }
                  Get.to(() => NewJob());
                },
              ),
              SizedBox(height: height * .02),
              ...account.jobs!.map(
                (a) => Padding(
                  padding: EdgeInsets.symmetric(vertical: height * .005),
                  child: DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== Header =====
                        Row(
                          children: [
                            Container(
                              width: width * .015,
                              height: height * .03,
                              decoration: BoxDecoration(
                                color: Color(int.parse(a.jobColor!)),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            SizedBox(width: width * .02),
                            Row(
                              children: [
                                Icon(
                                  Icons.join_full,
                                  color: ProjectColors.whiteColor,
                                  size: height * .03,
                                ),
                                SizedBox(width: width * .02),
                                textWidget(
                                  text: a.jobName,
                                  fontSize: .03,
                                  color: ProjectColors.whiteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () {
                                account.status!.value = JobStatus.edit;
                                account.addNewJob = a;
                                account.controllers![0].controller.text = a.jobName!;
                                account.controllers![1].controller.text = a.wageHr!;
                                account.controllers![2].controller.text = a.jobColor!;
                                account.controllers![3].controller.text = formatDate(a.lastPayChequeDate!);
                                account.controllers![4].controller.text = a.payFrequency!;
                                account.controllers![5].controller.text = a.weekStart!;
                                account.controllers![6].controller.text = a.statPay!;
                                Get.to(() => NewJob());
                              },
                              icon: const Icon(Icons.edit_rounded),
                              splashRadius: 20,
                              tooltip: 'Edit',
                            ),
                          ],
                        ),
                        SizedBox(height: height * .01),
                        // ===== Primary stats surface =====
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Stat(value: a.wageHr!, label: "Hourly rate"),
                            _VLine(),
                            _Stat(value: a.payFrequency!, label: "Pay frequency"),
                            _VLine(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: ProjectColors.greenColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: textWidget(
                                    text: formatDate(a.lastPayChequeDate!),
                                    fontSize: .013,
                                    fontWeight: FontWeight.w800,
                                    color: ProjectColors.whiteColor,
                                  ),
                                ),
                                SizedBox(height: height * .01),
                                textWidget(
                                  text: "Last paid",
                                  fontSize: .013,
                                  fontWeight: FontWeight.w600,
                                  color: ProjectColors.whiteColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: height * .02),
                        // ===== Secondary row =====
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _KeyValue(k: 'Week starts', v: a.weekStart!),
                            _KeyValue(k: 'Stat mult', v: '${a.statPay!}×', alignEnd: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * .005,
      height: height * .04,
      margin: EdgeInsets.symmetric(horizontal: width * .01),
      color: ProjectColors.whiteColor.withOpacity(0.5),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        textWidget(
          text: value,
          fontSize: .018,
          color: ProjectColors.whiteColor,
          fontWeight: FontWeight.w900,
        ),
        SizedBox(height: height * .005),
        textWidget(text: label, fontSize: .012, color: ProjectColors.whiteColor),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.k, required this.v, this.alignEnd = false});

  final String k;
  final String v;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget(
            text: k,
            fontSize: .02,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * .0),
          textWidget(
            text: v,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor,
          ),
        ],
      ),
    );
  }
}
