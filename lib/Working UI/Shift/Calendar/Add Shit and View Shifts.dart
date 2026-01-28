import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../Account/Add New Job.dart';
import '../../Constant UI.dart';
import '../../Constants.dart';
import '../../Controllers.dart';

class ShiftDayCard extends StatelessWidget {
  const ShiftDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * .9,
      child: Popup(
        color: ProjectColors.blackColor,
        title: "Shift Status",
        body: SingleChildScrollView(
          child: Column(children: [
            // ShiftCard(),
            Visibility(
              visible: shift.todayShifts!.isEmpty,
              child: Padding(
                padding: EdgeInsets.only(top: height * .15),
                child: account.jobs!.isEmpty
                    ? EmptyInsightsScreen(
                        title: 'No active jobs yet',
                        subTitle: 'Create an active job first, then add your shift for ${DateFormat('MMMM d').format(shift.selectedDay!.value)}.',
                        showButton: true,
                        btnTitle: 'Create job profile',
                        callback: () {
                          Get.back();
                          Get.to(() => NewJob());
                        },
                      )
                    : EmptyInsightsScreen(
                        title: 'No shifts logged',
                        subTitle: 'Add a shift for ${DateFormat('MMMM d').format(shift.selectedDay!.value)} to unlock insights this month.',
                        showButton: true,
                        callback: () {
                          shift.unpaidBreak!.value = false;
                          shift.isStat!.value = false;
                          shift.selectedJob.value = account.jobs!.first;
                          for (var file in shift.newShiftColumns!) {
                            file.controller.text = '';
                          }
                          callPopup(CreateShift());
                        },
                      ),
              ),
            ),
            Visibility(
              visible: shift.todayShifts!.isNotEmpty,
              child: AddContent(
                title: 'Add a new shift',
                subTitle: 'Log a shift for ${monthDateName(shift.selectedDay!.value)} to view insights this month.',
                callback: () {
                  callPopup(CreateShift());
                },
              ),
            ),
            SizedBox(height: height * .02),
            ...shift.todayShifts!.map(
              (f) => Padding(
                padding: EdgeInsets.symmetric(vertical: height * .001),
                child: Slidable(
                  key: Key(f.id!),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.75,
                    children: [
                      CustomSlidableAction(
                        onPressed: (_) {
                          shift.deleteShift(id: f.id!);
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
                          shift.newShiftColumns![0].controller.text = formatTime(f.start!);
                          shift.newShiftColumns![0].pickedDate = f.start!;
                          shift.newShiftColumns![1].controller.text = formatTime(f.end!);
                          shift.newShiftColumns![1].pickedDate = f.end!;
                          shift.newShiftColumns![2].controller.text = f.breakMin!.toString();
                          shift.unpaidBreak!.value = f.breakMin == 0 ? false : true;
                          shift.newShiftColumns![3].controller.text = f.notes!;
                          shift.selectedShift.value = f;
                          shift.selectedJob.value = f.jobFrom;
                          shift.isStat!.value = f.isStat!;
                          callPopup(CreateShift(editShift: true));
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                textWidget(
                                    text: "${formatTime(f.start!)} - ${formatTime(f.end!)}",
                                    fontSize: 0.02,
                                    color: ProjectColors.whiteColor,
                                    fontWeight: FontWeight.w800),
                                textWidget(
                                    text: "${monthName(f.start!)} ${monthDate(f.start!)}",
                                    fontSize: 0.014,
                                    color: ProjectColors.whiteColor.withOpacity(0.6),
                                    fontWeight: FontWeight.w600),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.006),
                              decoration: BoxDecoration(
                                color: ProjectColors.backgroundColor,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: ProjectColors.whiteColor.withOpacity(0.06)),
                              ),
                              child: textWidget(text: 'paid', fontSize: 0.015, color: ProjectColors.yellowColor, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),

                        SizedBox(height: height * 0.012),

                        // Job + Stat
                        Row(
                          children: [
                            Icon(Icons.work_outline_rounded, size: height * 0.022, color: Color(int.parse(f.jobFrom!.jobColor!)).withOpacity(0.8)),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: textWidget(
                                  text: f.jobFrom!.jobName,
                                  fontSize: 0.02,
                                  color: Color(int.parse(f.jobFrom!.jobColor!)),
                                  fontWeight: FontWeight.w800),
                            ),
                            if (true)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.006),
                                decoration: BoxDecoration(
                                  color: f.isStat.toString() == 'false'
                                      ? ProjectColors.whiteColor.withOpacity(.15)
                                      : ProjectColors.greenColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: f.isStat.toString() == 'false'
                                        ? ProjectColors.whiteColor.withOpacity(.35)
                                        : ProjectColors.greenColor.withOpacity(0.35),
                                  ),
                                ),
                                child: textWidget(
                                  text: f.isStat == true ? 'STAT' : 'NO STAT',
                                  fontSize: 0.013,
                                  color: f.isStat.toString() == 'false' ? ProjectColors.whiteColor : ProjectColors.greenColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: height * 0.01),

                        // Time + break
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: height * 0.02, color: ProjectColors.whiteColor.withOpacity(0.65)),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: textWidget(
                                  text: f.totalHours, fontSize: 0.016, color: ProjectColors.whiteColor.withOpacity(0.8), fontWeight: FontWeight.w600),
                            ),
                            if (30 > 0)
                              textWidget(
                                text: "-${f.breakMin}m break",
                                fontSize: 0.014,
                                color: ProjectColors.whiteColor.withOpacity(0.55),
                                fontWeight: FontWeight.w600,
                              ),
                          ],
                        ),

                        if (''.trim().isNotEmpty) ...[
                          SizedBox(height: height * 0.012),
                          Container(height: 1, color: ProjectColors.whiteColor.withOpacity(0.06)),
                          SizedBox(height: height * 0.01),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_rounded, size: height * 0.02, color: ProjectColors.whiteColor.withOpacity(0.55)),
                              SizedBox(width: width * 0.02),
                              Expanded(
                                child: textWidget(
                                  text: f.notes,
                                  fontSize: 0.015,
                                  color: ProjectColors.whiteColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Optional quick actions (if you want)
                        // if (onEdit != null || onDelete != null) ...[
                        //   SizedBox(height: height * 0.012),
                        //   Row(
                        //     children: [
                        //       if (onEdit != null)
                        //         GestureDetector(
                        //           onTap: onEdit,
                        //           child: _miniAction("Edit", Icons.edit_outlined),
                        //         ),
                        //       if (onDelete != null) ...[
                        //         SizedBox(width: width * 0.02),
                        //         GestureDetector(
                        //           onTap: onDelete,
                        //           child: _miniAction("Delete", Icons.delete_outline, danger: true),
                        //         ),
                        //       ],
                        //     ],
                        //   )
                        // ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: height * .02),
          ]),
        ),
      ),
    );
  }
}

class CreateShift extends StatelessWidget {
  final bool? editShift;
  CreateShift({this.editShift = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: height * .85,
        child: Popup(
          color: ProjectColors.blackColor,
          title: monthDateName(shift.selectedDay!.value),
          body: SingleChildScrollView(
            child: Column(
              children: [
                DarkCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .01),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textWidget(text: "Shift Details", fontSize: .02, color: ProjectColors.whiteColor, fontWeight: FontWeight.w800),
                        SizedBox(height: height * 0.02),
                        // Job dropdown
                        Container(
                          width: width * .44,
                          padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.004),
                          decoration: BoxDecoration(
                            color: ProjectColors.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ProjectColors.whiteColor.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              textWidget(
                                text: "Job",
                                color: ProjectColors.whiteColor.withOpacity(0.55),
                                fontWeight: FontWeight.w600,
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: shift.selectedJob.value!.id,
                                  dropdownColor: ProjectColors.loginMid,
                                  iconEnabledColor: ProjectColors.whiteColor.withOpacity(0.8),
                                  style: TextStyle(
                                    color: ProjectColors.whiteColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: height * 0.018,
                                    fontFamily: "poppins",
                                  ),
                                  items: (account.jobs ?? [])
                                      .where((j) => j.id != null)
                                      .map(
                                        (j) => DropdownMenuItem<int>(
                                          value: j.id!,
                                          child: textWidget(
                                            text: j.jobName,
                                            fontSize: .018,
                                            color: ProjectColors.whiteColor,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    shift.selectedJob.value = (account.jobs ?? []).firstWhereOrNull((j) => j.id == id);
                                    shift.selectedJob.refresh();
                                  },
                                ),
                              ),
                              // DropdownButtonHideUnderline(
                              //   child: DropdownButton<JobData>(
                              //     value: shift.selectedJob.value,
                              //     dropdownColor: ProjectColors.loginMid,
                              //     iconEnabledColor: ProjectColors.whiteColor.withOpacity(0.8),
                              //     style: TextStyle(
                              //       color: ProjectColors.whiteColor,
                              //       fontWeight: FontWeight.w700,
                              //       fontSize: height * 0.018,
                              //       fontFamily: "poppins",
                              //     ),
                              //     items: account.jobs!.map((x) => DropdownMenuItem(value: x, child: Text(x.jobName!))).toList(),
                              //     onChanged: (v) => shift.selectedJob.value = v,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.015),
                        // Start / End
                        Row(
                          children: [
                            Expanded(
                              child: DarkTextField(
                                title: 'Start',
                                value: shift.newShiftColumns![0].controller.text.isEmpty ? 'Select' : shift.newShiftColumns![0].controller.text,
                                onTap: () {
                                  callPopup(PickShiftTime(columnIndex: 0));
                                },
                                trailing: Icon(Icons.access_time_rounded, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                              ),
                            ),
                            SizedBox(width: width * .03),
                            Expanded(
                              child: DarkTextField(
                                title: 'End',
                                value: shift.newShiftColumns![1].controller.text.isEmpty ? 'Select' : shift.newShiftColumns![1].controller.text,
                                onTap: () {
                                  callPopup(PickShiftTime(columnIndex: 1));
                                },
                                trailing: Icon(Icons.access_time_rounded, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.02),

                        // Break row
                        Row(
                          children: [
                            Expanded(
                              child: DarkTextField(
                                title: 'Unpaid Break',
                                value: 'None',
                                trailing: Switch(
                                  value: shift.unpaidBreak!.value,
                                  onChanged: (val) {
                                    shift.unpaidBreak!.value = val;
                                  },
                                  activeColor: ProjectColors.yellowColor,
                                  inactiveThumbColor: ProjectColors.whiteColor.withOpacity(0.7),
                                  inactiveTrackColor: ProjectColors.whiteColor.withOpacity(0.15),
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.03),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  callPopup(PickShiftTime(columnIndex: 2));
                                },
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: shift.unpaidBreak!.value ? 1 : 0.35,
                                  child: IgnorePointer(
                                    ignoring: !shift.unpaidBreak!.value,
                                    child: DarkTextField(
                                      title: "Break (min)",
                                      hintText: shift.newShiftColumns![2].controller.text.isEmpty ? "30" : shift.newShiftColumns![2].controller.text,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.02),

                        // Stat
                        DarkTextField(
                          title: 'Stat Pay',
                          value: shift.isStat!.value ? 'Income boosted by ${shift.selectedJob.value!.statPay}x' : 'None',
                          trailing: Switch(
                            value: shift.isStat!.value,
                            onChanged: (val) {
                              shift.isStat!.value = val;
                            },
                            activeColor: ProjectColors.yellowColor,
                            inactiveThumbColor: ProjectColors.whiteColor.withOpacity(0.7),
                            inactiveTrackColor: ProjectColors.whiteColor.withOpacity(0.15),
                          ),
                        ),
                        SizedBox(height: height * 0.02),

                        // Notes
                        DarkTextField(
                          controller: shift.newShiftColumns![3].controller,
                          title: "Note (optional)",
                          hintText: "What happened in this shift…",
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * .01),
                normalButton(
                    title: editShift! ? 'Edit Shift' : 'Sync shift to calendar',
                    cWidth: .8,
                    bColor: ProjectColors.greenColor,
                    callback: () {
                      if (editShift!) {
                        shift.editShift();
                      } else {
                        if (shift.newShiftColumns![0].controller.text.isEmpty || shift.newShiftColumns![1].controller.text.isEmpty) {
                          showSnackBar("Error Input Required", "Start time and end time are required to create a shift.");
                        } else {
                          shift.saveShift();
                        }
                      }
                    }),
                SizedBox(height: height * .01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
