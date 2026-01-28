import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/Priotizer model.dart';
import '../../models/Projection Model.dart';
import '../Constants.dart';
import '../Debts/Debt Dashboard/Add Debt/Add New Debt.dart';
import 'Add Priority Task.dart';
import 'Priotizer Getx.dart';

class PrioritizerBody extends StatefulWidget {
  const PrioritizerBody({super.key});
  @override
  State<PrioritizerBody> createState() => _PrioritizerBodyState();
}

class _PrioritizerBodyState extends State<PrioritizerBody> {
  @override
  void initState() {
    super.initState();
    priotizer.loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: ColoredBox(
          color: ProjectColors.pureBlackColor,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                priotizer.state.value == ButtonState.loading
                    ? Padding(padding: EdgeInsets.only(top: height * .1), child: loader())
                    : priotizer.tasks.isEmpty
                        ? EmptyInsightsScreen(
                            title: 'Start tracking to unlock insights',
                            subTitle: 'Log a shift to see hours, earnings, and patterns this month.',
                            btnTitle: 'Add Task',
                            callback: () {
                              Get.to(() => AddTask());
                            },
                          )
                        : SingleChildScrollView(child: PrioritizerScreen()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------- MAIN SCREEN -------
class PrioritizerScreen extends StatefulWidget {
  const PrioritizerScreen({super.key});

  @override
  State<PrioritizerScreen> createState() => _PrioritizerScreenState();
}

class _PrioritizerScreenState extends State<PrioritizerScreen> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: EdgeInsets.symmetric(horizontal: width * .02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * .01),
            buildHeader(),
            SizedBox(height: height * .01),
            buildSummaryCard(),
            SizedBox(height: height * .01),
            AddContent(
                title: "Add a Task",
                subTitle: "Set a priority and deadline in seconds",
                callback: () {
                  Get.to(() => AddTask());
                }),
            SizedBox(height: height * .01),
            Center(
              child: segmentedToggle(
                options: priotizer.visibleTasks!.map((e) => e['name'] as String).toList(),
                bgColor: ProjectColors.blackColor,
                activeColor: ProjectColors.greenColor.withOpacity(0.2),
                textColor: ProjectColors.whiteColor,
                itemWidthFactor: .23,
                verticalPadding: .012,
                selectedIndex: (() {
                  final idx = priotizer.visibleTasks!.map((e) => e['type'] as TaskSection).toList().indexOf(priotizer.taskType.value);
                  return idx < 0 ? 0 : idx;
                })(),
                onChanged: (i, v) {
                  priotizer.taskType.value = priotizer.visibleTasks!.map((e) => e['type'] as TaskSection).toList()[i];
                },
              ),
            ),
            SizedBox(height: height * .02),
            ...priotizer.visibleTasks!.map((f) {
              final data = f['type'] == TaskSection.must
                  ? priotizer.mustDoTask
                  : f['type'] == TaskSection.atRisk
                      ? priotizer.atRisk
                      : f['type'] == TaskSection.completed
                          ? priotizer.completedTask
                          : priotizer.ifTime;
              return f['type'] != priotizer.taskType.value
                  ? SizedBox()
                  : Visibility(
                      visible: data.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textWidget(
                            text: f['title'],
                            fontSize: .02,
                            color: ProjectColors.whiteColor,
                            fontWeight: FontWeight.w800,
                          ),
                          SizedBox(height: height * .01),
                          textWidget(
                            text: f['subtitle'],
                            fontSize: .016,
                            color: ProjectColors.whiteColor,
                            needContainer: true,
                            cWidth: .8,
                          ),
                          ...data.map((items) => TaskBody(task: items)),
                        ],
                      ),
                    );
            }),
            SizedBox(height: height * .04),
          ],
        ),
      ),
    );
  }
}

// ------- MODELS & ENUMS -------

// ------- header + summary -------

Widget buildHeader() {
  return Row(
    children: [
      textWidget(
        text: 'Prioritizer',
        fontSize: 0.028,
        fontWeight: FontWeight.w700,
        color: ProjectColors.whiteColor,
      ),
      const Spacer(),
    ],
  );
}

Widget buildSummaryCard() {
  final completionRatio = priotizer.tasks.isEmpty ? 0.0 : priotizer.completedTask.length / priotizer.tasks.length.toDouble();

  return DarkCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: "Today’s priorities",
          fontSize: 0.024,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor,
        ),
        SizedBox(height: height * 0.006),
        textWidget(
          text: 'Based on soft & hard deadlines and tasks.',
          fontSize: 0.016,
          color: ProjectColors.whiteColor.withOpacity(0.7),
        ),
        SizedBox(height: height * 0.014),
        Row(
          children: [
            summaryChip(
              label: 'Must: ${priotizer.mustDoTask.length}',
              bg: ProjectColors.errorColor.withOpacity(0.2),
              textColor: ProjectColors.errorColor,
            ),
            SizedBox(width: width * 0.02),
            summaryChip(
              label: 'Should:  ${priotizer.atRisk.length}',
              bg: ProjectColors.yellowColor.withOpacity(0.25),
              textColor: ProjectColors.yellowColor,
            ),
            SizedBox(width: width * 0.02),
            summaryChip(
              label: 'If time: ${priotizer.ifTime.length}',
              bg: ProjectColors.pureBlackColor,
              textColor: ProjectColors.whiteColor.withOpacity(0.8),
            ),
          ],
        ),
        SizedBox(height: height * 0.014),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: ProjectColors.pureBlackColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: completionRatio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: ProjectColors.greenColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        SizedBox(height: height * 0.006),
        textWidget(
          text: 'Completed ${priotizer.completedTask.length} / Total ${priotizer.tasks.length}',
          fontSize: 0.016,
          color: ProjectColors.whiteColor,
        ),
      ],
    ),
  );
}

Widget summaryChip({required String label, required Color bg, required Color textColor}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.006),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: textWidget(
      text: label,
      fontSize: 0.014,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
  );
}

class StartTask extends StatefulWidget {
  final Task task;

  const StartTask({super.key, required this.task});

  @override
  State<StartTask> createState() => _StartTaskState();
}

class _StartTaskState extends State<StartTask> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * .35,
      child: Popup(
        color: ProjectColors.blackColor,
        title: 'End Task',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textWidget(
              text: 'Do you want to complete this task?',
              fontSize: 0.025,
              fontWeight: FontWeight.w600,
              color: ProjectColors.whiteColor,
            ),
            SizedBox(height: height * 0.008),
            textWidget(
              text: 'Marked "${widget.task.title}" will be completed and remove it from today’s plan.',
              color: ProjectColors.whiteColor.withOpacity(0.5),
            ),
            SizedBox(height: height * 0.02),
            Center(
              child: normalButton(
                  bColor: ProjectColors.greenColor,
                  callback: () async {
                    await priotizer.markTaskCompleted(widget.task);
                    Get.back();
                  },
                  title: 'Mark as completed',
                  cWidth: .5),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskBody extends StatefulWidget {
  final Task task;

  const TaskBody({super.key, required this.task});

  @override
  State<TaskBody> createState() => _TaskBodyState();
}

class _TaskBodyState extends State<TaskBody> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * .01),
      child: DarkCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onLongPress: () => showCupertinoModalPopup(
            context: context,
            builder: (context) => TaskActions(task: widget.task),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: widget.task.title,
                    fontSize: 0.018,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.whiteColor,
                  ),
                  SizedBox(height: height * 0.004),
                  if (widget.task.softDeadlineText != null)
                    Padding(
                      padding: EdgeInsets.only(right: width * .02),
                      child: textWidget(
                        text: widget.task.softDeadlineText!,
                        fontSize: 0.02,
                        color: ProjectColors.whiteColor.withOpacity(0.7),
                      ),
                    ),
                  textWidget(
                    text: 'Due On ${widget.task.hardDeadlineText}',
                    fontSize: 0.02,
                    color: widget.task.priority == GoalPriority.high ? ProjectColors.errorColor : ProjectColors.whiteColor.withOpacity(0.5),
                  ),
                  SizedBox(height: height * 0.004),
                  textWidget(
                    text: widget.task.status.name.toUpperCase(),
                    fontSize: 0.015,
                    color: ProjectColors.whiteColor.withOpacity(0.7),
                  ),
                ],
              ),
              Visibility(
                visible: !widget.task.isCompleted,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => StartTask(
                            task: widget.task,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: ProjectColors.greenColor),
                        padding: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .05),
                        child: textWidget(
                          text: widget.task.status.name == TaskStatus.pending.name ? 'Start' : 'Done',
                          fontSize: 0.017,
                          fontWeight: FontWeight.w600,
                          color: ProjectColors.pureBlackColor,
                        ),
                      ),
                    ),
                    SizedBox(height: height * .01),
                    GestureDetector(
                      onTap: () {
                        showCupertinoModalPopup(context: context, builder: (context) => TaskActions(task: widget.task));
                      },
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: ProjectColors.yellowColor)),
                        padding: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .05),
                        child: textWidget(
                          text: 'Edit',
                          fontSize: 0.017,
                          fontWeight: FontWeight.w600,
                          color: ProjectColors.whiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskActions extends StatelessWidget {
  final Task task;

  const TaskActions({super.key, required this.task});

  ListTile _actionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool destructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: destructive ? ProjectColors.errorColor : ProjectColors.whiteColor,
      ),
      title: textWidget(
        text: label,
        fontSize: 0.02,
        color: destructive ? ProjectColors.errorColor : ProjectColors.whiteColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Popup(
      color: ProjectColors.blackColor,
      title: 'Actions',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MARK AS COMPLETED
          _actionTile(
            context: context,
            icon: Icons.check_circle_outline,
            label: 'Mark as completed',
            onTap: () async {
              await priotizer.markTaskCompleted(task);
              Get.back();
            },
          ),

          // SNOOZE SOFT DEADLINE
          _actionTile(
            context: context,
            icon: Icons.snooze,
            label: 'Snooze soft deadline',
            onTap: () async {
              final now = DateTime.now();
              final picked = await AppDatePicker.pickDate(
                title: "Pick deadline",
                initialDate: task.softDeadline ?? now,
                minDate: now,
                maxDate: DateTime(now.year + 5),
              );
              if (picked != null) {
                await priotizer.snoozeSoftDeadline(task, picked);
              }
              Get.back();
            },
          ),

          // EDIT TASK (you can wire this later)
          _actionTile(
            context: context,
            icon: Icons.edit_outlined,
            label: 'Edit task',
            onTap: () {
              Get.to(()=>AddTask(task: task));
            },
          ),

          // DELETE
          _actionTile(
            context: context,
            icon: Icons.delete_outline,
            label: 'Delete',
            destructive: true,
            onTap: () async {
              await priotizer.deleteTask(id: task.id);
              Get.back();
            },
          ),
          SizedBox(height: height * 0.015),
        ],
      ),
    );
  }
}
