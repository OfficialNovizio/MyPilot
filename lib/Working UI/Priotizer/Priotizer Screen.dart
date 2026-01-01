import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/Priotizer model.dart';
import '../Constants.dart';
import 'Priotizer Getx.dart';

// ------- MAIN SCREEN -------
class PrioritizerScreen extends StatefulWidget {
  const PrioritizerScreen({super.key});

  @override
  State<PrioritizerScreen> createState() => _PrioritizerScreenState();
}

class _PrioritizerScreenState extends State<PrioritizerScreen> {
  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TaskSection type) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            priotizer.taskType.value = type;
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: height * 0.011),
            decoration: BoxDecoration(
              color: priotizer.taskType.value == type ? ProjectColors.greenColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: textWidget(
              text: label,
              fontSize: 0.015,
              color: priotizer.taskType.value == type ? ProjectColors.greenColor : ProjectColors.whiteColor,
              fontWeight: priotizer.taskType.value == type ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Obx(
      () => Padding(
        padding: EdgeInsets.symmetric(horizontal: width * .02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * .02),
            buildHeader(),
            SizedBox(height: height * .02),
            buildSummaryCard(),
            SizedBox(height: height * .02),
            Container(
              padding: EdgeInsets.all(height * 0.004),
              decoration: BoxDecoration(
                color: const Color(0xff222222),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  chip('Due Now', TaskSection.must),
                  SizedBox(width: width * 0.01),
                  chip('Coming Up', TaskSection.atRisk),
                  SizedBox(width: width * 0.01),
                  chip('Optional', TaskSection.ifTime),
                  SizedBox(width: width * 0.01),
                  chip('Done', TaskSection.completed),
                ],
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
                  : Column(
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
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: height * .1),
                              child: textWidget(
                                text: 'No tasks yet. Add your first task to stay organized and gain clear insights into your work.',
                                fontSize: 0.02,
                                color: ProjectColors.whiteColor,
                                cWidth: .8,
                                needContainer: true,
                                fontWeight: FontWeight.w800,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : SingleChildScrollView(child: PrioritizerScreen()),
                Padding(
                  padding: EdgeInsets.only(top: height * .84),
                  child: Center(
                    child: normalButton(
                      title: "Add New Task",
                      bColor: ProjectColors.greenColor,
                      cWidth: .5,
                      loading: false,
                      invertColors: true,
                      callback: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (_) => AddTaskBottomSheet(),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      Container(
        padding: EdgeInsets.all(height * 0.004),
        decoration: BoxDecoration(
          color: ProjectColors.blackColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            scopeChip('today', 'Today'),
            SizedBox(width: width * 0.01),
            scopeChip('week', 'Week'),
          ],
        ),
      ),
    ],
  );
}

Widget scopeChip(String key, String label) {
  final selected = priotizer.timeScope.value == key;
  return GestureDetector(
    onTap: () {
      priotizer.timeScope.value = key;
    },
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: height * 0.007,
      ),
      decoration: BoxDecoration(
        color: selected ? ProjectColors.whiteColor : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: textWidget(
        text: label,
        fontSize: 0.016,
        fontWeight: FontWeight.w600,
        color: selected ? ProjectColors.pureBlackColor : ProjectColors.whiteColor.withOpacity(0.7),
      ),
    ),
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
    padding: EdgeInsets.symmetric(
      horizontal: width * 0.03,
      vertical: height * 0.006,
    ),
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

Widget priorityChip(TaskPriority priority) {
  String label;
  Color color;
  switch (priority) {
    case TaskPriority.high:
      label = 'HIGH';
      color = ProjectColors.errorColor;
      break;
    case TaskPriority.medium:
      label = 'MEDIUM';
      color = ProjectColors.yellowColor;
      break;
    case TaskPriority.low:
      label = 'LOW';
      color = ProjectColors.whiteColor.withOpacity(0.7);
      break;
  }

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: width * 0.024,
      vertical: height * 0.004,
    ),
    decoration: BoxDecoration(
      color: ProjectColors.pureBlackColor,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color, width: 0.9),
    ),
    child: textWidget(
      text: label,
      fontSize: 0.013,
      color: color,
      fontWeight: FontWeight.w600,
    ),
  );
}
