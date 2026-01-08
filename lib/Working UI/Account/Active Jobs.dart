import 'package:emptyproject/BaseScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../models/TextForm.dart';
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
    return BaseScreen(
      title: 'Active Jobs',
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            SizedBox(height: height * .02),
            ...account.jobs!.map(
              (a) => Container(
                width: width,
                padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .01),
                margin: EdgeInsets.symmetric(vertical: height * .01),
                decoration: BoxDecoration(color: ProjectColors.whiteColor, borderRadius: BorderRadius.circular(30)),
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
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            account.status!.value = JobStatus.edit;
                            account.addNewJob = a;
                            account.controllers![0].controller.text = a.jobName!;
                            account.controllers![1].controller.text = a.wageHr!;
                            account.controllers![2].controller.text = a.jobColor!;
                            account.controllers![3].controller.text = a.lastPayChequeDate!;
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
                    // ===== Primary stats surface =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Stat(value: a.wageHr!, label: "Hourly rate"),
                        _VLine(),
                        _Stat(value: a.payFrequency!, label: "Pay frequency"),
                        _VLine(),
                        _LastPaidPill(date: a.lastPayChequeDate!),
                      ],
                    ),
                    SizedBox(height: height * .01),
                    // ===== Secondary row =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _KeyValue(v: a.weekStart!, k: 'start'),
                        _KeyValue(k: 'Stat Pay Multiplier', v: a.statPay!, alignEnd: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: height * .02),
          ],
        ),
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * .01,
      height: height * .04,
      margin: EdgeInsets.symmetric(horizontal: width * .01),
      color: const Color(0x1A000000),
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
          fontWeight: FontWeight.w900,
        ),
        SizedBox(height: height * .005),
        textWidget(text: label, fontSize: .012, color: ProjectColors.blackColor),
      ],
    );
  }
}

class _LastPaidPill extends StatelessWidget {
  const _LastPaidPill({required this.date});

  final String? date;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            text: date!,
            fontSize: .013,
            fontWeight: FontWeight.w800,
            color: ProjectColors.whiteColor,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Last paid",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            k,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
