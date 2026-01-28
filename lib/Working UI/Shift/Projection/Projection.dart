import 'dart:math';
import 'package:emptyproject/Working UI/Constant UI.dart';
import 'package:emptyproject/Working UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/Priotizer model.dart';
import '../../../models/Projection Model.dart';
import 'Projection Getx.dart';

/// ---------------------------------------------------------------------------
/// PROJECTION TAB (GOAL SCREEN)
/// ---------------------------------------------------------------------------

class ProjectionTab extends StatefulWidget {
  const ProjectionTab({Key? key}) : super(key: key);

  @override
  State<ProjectionTab> createState() => _ProjectionTabState();
}

class _ProjectionTabState extends State<ProjectionTab> {
  @override
  void initState() {
    projection.loadShifts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: width * .02),
      child: Obx(
        () => Column(
          children: [
            // 1) Income planner
            account.jobs!.isEmpty
                ? EmptyInsightsScreen(
                    title: 'Create a job profile to unlock projections',
                    subTitle: 'Add your job details to forecast monthly hours and income.',
                    btnTitle: 'Create job profile',
                    callback: () {},
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * .04),
                      IncomeProjectionCard(
                        jobs: account.jobs!.map((f) => JobProjection(name: f.jobName!, hourlyRate: double.parse(f.wageHr!), hours: 10)).toList(),
                        maxAvailableHours: 50,
                        periodLabel: 'Week',
                        safeGoalContribution: 150,
                      ),
                    ],
                  ),
            SizedBox(height: height * .02),
            AddContent(
              title: 'Add a Goal',
              subTitle: 'Choose a target and we’ll show how close you are each week.',
              callback: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => const AddGoal(),
                );
              },
            ),
            SizedBox(height: height * .02),
            Visibility(visible: !account.jobs!.isNotEmpty, child: GoalsSection()),
          ],
        ),
      ),
    );
  }

  // ---------- helpers ----------
}

/// ---------------------------------------------------------------------------
/// GOAL SETUP CARD
/// ---------------------------------------------------------------------------

class GoalSetupCard extends StatelessWidget {
  // final GoalType goalType;
  // final ValueChanged<GoalType> onGoalTypeChanged;
  //
  // final GoalPriority priority;
  // final ValueChanged<GoalPriority> onPriorityChanged;
  //
  // final SavingFrequency frequency;
  // final ValueChanged<SavingFrequency> onFrequencyChanged;
  //
  // final TextEditingController titleController;
  // final TextEditingController amountController;
  // final TextEditingController descriptionController;
  //
  // final DateTime targetDate;
  // final VoidCallback onPickDate;
  //
  // final double? requiredPerPeriod;
  // final int? periodsLeft;
  //
  // final VoidCallback onSave;
  // final bool canSave;
  //
  // const GoalSetupCard({
  //   Key? key,
  //   required this.goalType,
  //   required this.onGoalTypeChanged,
  //   required this.priority,
  //   required this.onPriorityChanged,
  //   required this.frequency,
  //   required this.onFrequencyChanged,
  //   required this.titleController,
  //   required this.amountController,
  //   required this.descriptionController,
  //   required this.targetDate,
  //   required this.onPickDate,
  //   required this.requiredPerPeriod,
  //   required this.periodsLeft,
  //   required this.onSave,
  //   required this.canSave,
  // }) : super(key: key);

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = '${monthName(projection.targetDate)} ${projection.targetDate.year}';
    final plan = projection.computeRequired();
    final canSave = projection.titleCtrl.text.trim().isNotEmpty && plan != null && projection.parseAmount() != null;

    return Obx(
      () => DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            segmentedToggle(
              options: projection.goalTypeList!.map((e) => e['name'] as String).toList(),
              itemWidthFactor: .23,
              verticalPadding: .012,
              selectedIndex: (() {
                final idx = projection.goalTypeList!.map((e) => e['type'] as GoalType).toList().indexOf(projection.goalType.value);
                return idx < 0 ? 0 : idx;
              })(),
              onChanged: (i, v) {
                projection.goalType.value = projection.goalTypeList!.map((e) => e['type'] as GoalType).toList()[i];
              },
            ),
            SizedBox(height: height * 0.018),
            DarkTextField(controller: projection.titleCtrl, hintText: 'Goal name', title: 'Goal Title'),
            SizedBox(height: height * 0.015),
            Row(
              children: [
                Expanded(
                  child: DarkTextField(
                    controller: projection.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixText: '\$',
                    title: 'Amount',
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(
                        text: 'Target Date',
                        fontSize: 0.016,
                        color: ProjectColors.whiteColor.withOpacity(0.6),
                      ),
                      SizedBox(height: height * 0.005),
                      DateField(
                        label: dateLabel,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.015),
            DarkTextField(
              controller: projection.descriptionCtrl,
              hintText: 'Why is this goal important?',
              maxLines: 2,
              title: 'Description (optional)',
            ),
            SizedBox(height: height * 0.018),
            PriorityRow(
              selected: projection.priority.value,
              onChanged: (p) {
                projection.priority.value = p;
              },
            ),
            SizedBox(height: height * 0.018),
            textWidget(
              text: 'How will you fund it?',
              fontSize: 0.017,
              color: ProjectColors.whiteColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: height * 0.008),
            segmentedToggle(
              options: projection.fundingType!.map((e) => e['name'] as String).toList(),
              itemWidthFactor: .23,
              verticalPadding: .012,
              selectedIndex: (() {
                final idx = projection.fundingType!.map((e) => e['type'] as SavingFrequency).toList().indexOf(projection.frequency.value);
                return idx < 0 ? 0 : idx;
              })(),
              onChanged: (i, v) {
                projection.frequency.value = projection.fundingType!.map((e) => e['type'] as SavingFrequency).toList()[i];
              },
            ),
            SizedBox(height: height * 0.015),
            if (plan?.perPeriod != null && plan?.periods != null) ...[
              textWidget(
                text: 'You need to ${projection.verb()} \$${plan?.perPeriod.toStringAsFixed(0)} every ${projection.frequencyShort()}.',
                fontSize: 0.018,
                color: ProjectColors.whiteColor,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: height * 0.006),
              textWidget(
                text: '${plan?.periods} ${projection.frequencyPlural()} left until $dateLabel.',
                fontSize: 0.016,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),
            ] else
              textWidget(
                text: 'Set amount and a future date to see how much you must ${projection.verb()}.',
                fontSize: 0.016,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),

            SizedBox(height: height * 0.02),

            // save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // onPressed: canSave ? onSave : null,
                onPressed: () {
                  projection.saveGoal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProjectColors.greenColor,
                  disabledBackgroundColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: height * 0.014,
                  ),
                ),
                child: textWidget(
                  text: 'Save goal to list',
                  fontSize: 0.018,
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// GOALS LIST SECTION (UNDER SETUP CARD)
/// ---------------------------------------------------------------------------

class GoalsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final high = projection.goals.where((g) => g.priority == GoalPriority.high).toList();
    final med = projection.goals.where((g) => g.priority == GoalPriority.medium).toList();
    final low = projection.goals.where((g) => g.priority == GoalPriority.low).toList();

    final committedWeekly = projection.goals.fold<double>(
      0.0,
      (sum, g) => sum + projection.weeklyCommitment(g)!,
    );

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: 'Goals',
            fontSize: 0.022,
            color: ProjectColors.whiteColor,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: height * 0.005),
          textWidget(
            text: 'Funding ${projection.goals.length} goals • ~\$${committedWeekly.toStringAsFixed(0)}/week committed',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.7),
          ),
          SizedBox(height: height * 0.018),
          if (high.isNotEmpty) ...[
            textWidget(
              text: projection.priorityLabel(GoalPriority.high),
              fontSize: 0.018,
              color: ProjectColors.whiteColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: height * 0.008),
            ...high.map((g) => _GoalListCard(
                  goal: g,
                  weeklyAmount: projection.weeklyCommitment(g)!,
                )),
            SizedBox(height: height * 0.018),
          ],
          if (med.isNotEmpty) ...[
            textWidget(
              text: projection.priorityLabel(GoalPriority.medium),
              fontSize: 0.018,
              color: ProjectColors.whiteColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: height * 0.008),
            ...med.map((g) => _GoalListCard(
                  goal: g,
                  weeklyAmount: projection.weeklyCommitment(g)!,
                )),
            SizedBox(height: height * 0.018),
          ],
          if (low.isNotEmpty) ...[
            textWidget(
              text: projection.priorityLabel(GoalPriority.low),
              fontSize: 0.018,
              color: ProjectColors.whiteColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: height * 0.008),
            ...low.map((g) => _GoalListCard(
                  goal: g,
                  weeklyAmount: projection.weeklyCommitment(g)!,
                )),
          ],
        ],
      ),
    );
  }
}

class _GoalListCard extends StatelessWidget {
  final GoalItem goal;
  final double weeklyAmount;

  const _GoalListCard({
    Key? key,
    required this.goal,
    required this.weeklyAmount,
  }) : super(key: key);

  String _monthYear(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = projection.typeColor(goal);

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.012),
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.015,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff151515),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: icon + title + pill
          Row(
            children: [
              Container(
                width: height * 0.04,
                height: height * 0.04,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  projection.typeIcon(goal),
                  color: typeColor,
                  size: height * 0.022,
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: goal.title,
                      fontSize: 0.018,
                      color: ProjectColors.whiteColor,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: height * 0.002),
                    textWidget(
                      text: '\$${weeklyAmount.toStringAsFixed(0)} / week',
                      fontSize: 0.017,
                      color: ProjectColors.whiteColor,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.03,
                  vertical: height * 0.006,
                ),
                decoration: BoxDecoration(
                  color: projection.priorityColor(goal).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: textWidget(
                  text: projection.priorityPillText(goal),
                  fontSize: 0.014,
                  color: projection.priorityColor(goal),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.012),

          // progress bar + funded text (0% for now)
          Container(
            height: height * 0.01,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.0, // placeholder until you track progress
              child: Container(
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          SizedBox(height: height * 0.006),
          Row(
            children: [
              textWidget(
                text: '0% funded',
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),
              const Spacer(),
              textWidget(
                text: 'Planned',
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),
            ],
          ),
          SizedBox(height: height * 0.008),

          // bottom row: target + simple status
          Row(
            children: [
              textWidget(
                text: 'Target: ${_monthYear(goal.targetDate!)}',
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.75),
              ),
              const Spacer(),
              textWidget(
                text: 'Not started yet',
                fontSize: 0.015,
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// INCOME PROJECTION (same as before)
/// ---------------------------------------------------------------------------

class JobProjection {
  final String name;
  final double hourlyRate;
  double hours;

  JobProjection({
    required this.name,
    required this.hourlyRate,
    required this.hours,
  });
}

class IncomeProjectionCard extends StatefulWidget {
  final List<JobProjection> jobs;
  final double maxAvailableHours;
  final String periodLabel;
  final double safeGoalContribution;

  const IncomeProjectionCard({
    Key? key,
    required this.jobs,
    required this.maxAvailableHours,
    this.periodLabel = "Week",
    this.safeGoalContribution = 150,
  }) : super(key: key);

  @override
  State<IncomeProjectionCard> createState() => _IncomeProjectionCardState();
}

class _IncomeProjectionCardState extends State<IncomeProjectionCard> {
  static const double step = 0.5;
  static const List<String> _periodOptions = ['Week', 'Bi-week', 'Month'];

  late String _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.periodLabel;
  }

  double get totalHours => widget.jobs.fold(0.0, (sum, job) => sum + job.hours);

  double get totalIncome => widget.jobs.fold(0.0, (sum, job) => sum + job.hours * job.hourlyRate);

  void _changeHours(JobProjection job, double delta) {
    setState(() {
      double next = (job.hours + delta).clamp(0.0, 168.0);
      job.hours = double.parse(next.toStringAsFixed(1));
    });
  }

  @override
  Widget build(BuildContext context) {
    height = Get.height;
    width = Get.width;

    final incomeStr = totalIncome.toStringAsFixed(0);
    final hoursStr = totalHours.toStringAsFixed(1);

    final progress = widget.maxAvailableHours == 0 ? 0.0 : (totalHours / widget.maxAvailableHours).clamp(0.0, 1.0);

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: textWidget(
                  text: 'Income Projection',
                  fontSize: 0.022,
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xff222222),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                initialValue: _selectedPeriod,
                onSelected: (value) {
                  setState(() => _selectedPeriod = value);
                },
                itemBuilder: (context) {
                  return _periodOptions
                      .map(
                        (p) => PopupMenuItem<String>(
                          value: p,
                          child: textWidget(
                            text: p,
                            fontSize: 0.017,
                            color: ProjectColors.whiteColor,
                          ),
                        ),
                      )
                      .toList();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: height * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff222222),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      textWidget(
                        text: _selectedPeriod,
                        fontSize: 0.016,
                        color: ProjectColors.whiteColor,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(width: width * 0.01),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: height * 0.02,
                        color: ProjectColors.whiteColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          textWidget(
            text: '~\$$incomeStr / ${_selectedPeriod.toLowerCase()}',
            fontSize: 0.027,
            color: ProjectColors.whiteColor,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: height * 0.004),
          textWidget(
            text: 'Based on ${widget.jobs.length} jobs • $hoursStr h',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.7),
          ),
          SizedBox(height: height * 0.016),
          ...widget.jobs.map(
            (job) => _JobRow(
              job: job,
              onMinus: () => _changeHours(job, -step),
              onPlus: () => _changeHours(job, step),
            ),
          ),
          SizedBox(height: height * 0.016),
          _HoursProgressBar(progress: progress),
          SizedBox(height: height * 0.007),
          Row(
            children: [
              textWidget(
                text: 'Planned hours',
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),
              const Spacer(),
              textWidget(
                text: '$hoursStr h  •  Max ${widget.maxAvailableHours.toStringAsFixed(0)} h',
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),
            ],
          ),
          SizedBox(height: height * 0.012),
          textWidget(
            text:
                'With this schedule, you can safely put \$${widget.safeGoalContribution.toStringAsFixed(0)}/${_selectedPeriod.toLowerCase()} toward this goal.',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.75),
          ),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final JobProjection job;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _JobRow({
    Key? key,
    required this.job,
    required this.onMinus,
    required this.onPlus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hoursStr = job.hours.toStringAsFixed(1);

    return Padding(
      padding: EdgeInsets.only(bottom: height * 0.008),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(
                  text: job.name,
                  fontSize: 0.018,
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: height * 0.003),
                textWidget(
                  text: '\$${job.hourlyRate.toStringAsFixed(2)}/h',
                  fontSize: 0.015,
                  color: ProjectColors.whiteColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
          SizedBox(width: width * 0.03),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xff222222),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperButton(icon: Icons.remove_rounded, onTap: onMinus),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: height * 0.006,
                  ),
                  child: textWidget(
                    text: hoursStr,
                    fontSize: 0.018,
                    color: ProjectColors.whiteColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _StepperButton(icon: Icons.add_rounded, onTap: onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.018,
          vertical: height * 0.006,
        ),
        child: Icon(
          icon,
          size: height * 0.02,
          color: ProjectColors.whiteColor,
        ),
      ),
    );
  }
}

class _HoursProgressBar extends StatelessWidget {
  final double progress;

  const _HoursProgressBar({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * 0.01,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: ProjectColors.greenColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
