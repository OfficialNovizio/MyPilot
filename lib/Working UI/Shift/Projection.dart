import 'dart:math';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ---------------------------------------------------------------------------
/// GOAL SCREEN
/// ---------------------------------------------------------------------------

enum GoalType { save, debt, surplus }

class ProjectionTab extends StatefulWidget {
  const ProjectionTab({Key? key}) : super(key: key);

  @override
  State<ProjectionTab> createState() => _ProjectionTabState();
}

class _ProjectionTabState extends State<ProjectionTab> {
  GoalType _goalType = GoalType.save;

  final TextEditingController _titleCtrl = TextEditingController(text: 'MacBook Fund');
  final TextEditingController _amountCtrl = TextEditingController(text: '2000');

  DateTime _targetDate = DateTime(2025, 8);

  double _contributionPerWeek = 120; // slider value
  final double _requiredPerWeek = 135;
  final double _progress = 0.18; // 18% funded

  @override
  Widget build(BuildContext context) {
    // refresh globals when screen builds

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * 0.03),
      child: Column(
        children: [
          IncomeProjectionCard(
            jobs: [
              JobProjection(name: 'Starbucks', hourlyRate: 18.5, hours: 20),
              JobProjection(name: 'Superstore', hourlyRate: 15, hours: 10),
              JobProjection(name: 'DoorDash', hourlyRate: 22, hours: 2.5),
            ],
            maxAvailableHours: 42,
            periodLabel: 'Week',
            safeGoalContribution: 150,
          ),
          SizedBox(height: height * .02),
          _GoalSetupCard(
            goalType: _goalType,
            onGoalTypeChanged: (type) => setState(() => _goalType = type),
            titleController: _titleCtrl,
            amountController: _amountCtrl,
            targetDate: _targetDate,
            onPickDate: _pickDate,
          ),
          SizedBox(height: height * 0.018),
          _PlanGeneratorCard(
            contributionPerWeek: _contributionPerWeek,
            requiredPerWeek: _requiredPerWeek,
            progress: _progress,
            onChangeContribution: (v) => setState(() => _contributionPerWeek = v),
          ),
          SizedBox(height: height * 0.018),
          const _InsightsAndNudgesCard(),
          SizedBox(height: height * 0.03),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ProjectColors.yellowColor,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: ProjectColors.whiteColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }
}

/// ---------------------------------------------------------------------------
/// GOAL SETUP CARD
/// ---------------------------------------------------------------------------

class _GoalSetupCard extends StatelessWidget {
  final GoalType goalType;
  final ValueChanged<GoalType> onGoalTypeChanged;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final DateTime targetDate;
  final VoidCallback onPickDate;

  const _GoalSetupCard({
    Key? key,
    required this.goalType,
    required this.onGoalTypeChanged,
    required this.titleController,
    required this.amountController,
    required this.targetDate,
    required this.onPickDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String dateLabel = '${_monthName(targetDate.month)} ${targetDate.year}';

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row
          Row(
            children: [
              textWidget(
                text: 'Goal Setup',
                fontSize: 0.022,
                color: ProjectColors.whiteColor,
                fontWeight: FontWeight.w600,
              ),
              const Spacer(),
              textWidget(
                text: 'Templates',
                fontSize: 0.018,
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
          SizedBox(height: height * 0.015),

          _GoalTypeSegment(
            selected: goalType,
            onChanged: onGoalTypeChanged,
          ),
          SizedBox(height: height * 0.02),

          // Goal title
          textWidget(
            text: 'Goal Title',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.6),
          ),
          SizedBox(height: height * 0.005),
          _DarkTextField(
            controller: titleController,
            hintText: 'Goal name',
          ),
          SizedBox(height: height * 0.015),

          // Amount + date row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: 'Amount',
                      fontSize: 0.016,
                      color: ProjectColors.whiteColor.withOpacity(0.6),
                    ),
                    SizedBox(height: height * 0.005),
                    _DarkTextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixText: '\$',
                    ),
                  ],
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
                    _DateField(
                      label: dateLabel,
                      onTap: onPickDate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}

class _GoalTypeSegment extends StatelessWidget {
  final GoalType selected;
  final ValueChanged<GoalType> onChanged;

  const _GoalTypeSegment({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, GoalType type) {
      final bool active = selected == type;

      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(type),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: height * 0.011),
            decoration: BoxDecoration(
              color: active ? ProjectColors.greenColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: textWidget(
              text: label,
              fontSize: 0.017,
              color: active ? ProjectColors.greenColor : ProjectColors.whiteColor,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(height * 0.004),
      decoration: BoxDecoration(
        color: const Color(0xff222222),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          chip('Save', GoalType.save),
          SizedBox(width: width * 0.01),
          chip('Debt', GoalType.debt),
          SizedBox(width: width * 0.01),
          chip('Surplus', GoalType.surplus),
        ],
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? prefixText;

  const _DarkTextField({
    Key? key,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.prefixText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: height * 0.018,
        color: ProjectColors.whiteColor,
        fontFamily: 'poppins',
      ),
      keyboardType: keyboardType,
      cursorColor: ProjectColors.yellowColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xff1c1c1c),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: height * 0.017,
          color: ProjectColors.blackColor.withOpacity(0.6),
          fontFamily: 'poppins',
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          fontSize: height * 0.018,
          color: ProjectColors.whiteColor,
          fontFamily: 'poppins',
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: height * 0.012,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ProjectColors.yellowColor,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateField({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: height * 0.012,
        ),
        decoration: BoxDecoration(
          color: const Color(0xff1c1c1c),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            textWidget(
              text: label,
              fontSize: 0.018,
              color: ProjectColors.whiteColor,
            ),
            const Spacer(),
            Icon(
              Icons.calendar_today_outlined,
              size: height * 0.018,
              color: ProjectColors.blackColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PLAN GENERATOR CARD
/// ---------------------------------------------------------------------------

class _PlanGeneratorCard extends StatelessWidget {
  final double contributionPerWeek;
  final double requiredPerWeek;
  final double progress;
  final ValueChanged<double> onChangeContribution;

  const _PlanGeneratorCard({
    Key? key,
    required this.contributionPerWeek,
    required this.requiredPerWeek,
    required this.progress,
    required this.onChangeContribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double min = 0;
    const double max = 2000;

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: 'Plan Generator',
            fontSize: 0.022,
            color: ProjectColors.whiteColor,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: height * 0.01),
          textWidget(
            text: 'Suggested contribution',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.6),
          ),
          SizedBox(height: height * 0.006),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: textWidget(
                  text: '\$${contributionPerWeek.toStringAsFixed(0)} / week',
                  fontSize: 0.027,
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _DonutProgress(
                progress: progress,
                label: '${(progress * 100).toStringAsFixed(0)}%\nFunded',
              ),
            ],
          ),
          SizedBox(height: height * 0.004),
          textWidget(
            text: 'Required: \$${requiredPerWeek.toStringAsFixed(0)}/week to stay on track',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.7),
          ),
          SizedBox(height: height * 0.017),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ProjectColors.greenColor,
              inactiveTrackColor: Colors.white.withOpacity(0.08),
              thumbColor: ProjectColors.greenColor,
              overlayColor: ProjectColors.greenColor.withOpacity(0.1),
            ),
            child: Slider(
              min: min,
              max: max,
              value: contributionPerWeek.clamp(min, max),
              onChanged: onChangeContribution,
            ),
          ),
          Row(
            children: [
              textWidget(
                text: '\$$min',
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),
              const Spacer(),
              textWidget(
                text: '\$$max',
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.7),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          textWidget(
            text: 'Est. finish at this pace: Jul 2026 (+11 months late)',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}

class _DonutProgress extends StatelessWidget {
  final double progress;
  final String label;

  const _DonutProgress({
    Key? key,
    required this.progress,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: height * .1,
          width: height * .1,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: ProjectColors.whiteColor.withOpacity(0.06),
            valueColor: const AlwaysStoppedAnimation<Color>(
              ProjectColors.greenColor,
            ),
          ),
        ),
        textWidget(
          text: label,
          fontSize: 0.012,
          color: ProjectColors.whiteColor.withOpacity(0.7),
          textAlign: TextAlign.center,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// INSIGHTS & NUDGES CARD
/// ---------------------------------------------------------------------------

class _InsightsAndNudgesCard extends StatelessWidget {
  const _InsightsAndNudgesCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget(
            text: 'Insights & Nudges',
            fontSize: 0.022,
            color: ProjectColors.whiteColor,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: height * 0.014),

          // Reality check banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.03,
              vertical: height * 0.012,
            ),
            decoration: BoxDecoration(
              color: const Color(0xff2a1d14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ProjectColors.greenColor.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: height * 0.021,
                      color: ProjectColors.yellowColor,
                    ),
                    SizedBox(width: width * 0.015),
                    textWidget(
                      text: 'Reality Check',
                      fontSize: 0.018,
                      color: ProjectColors.whiteColor,
                      fontWeight: FontWeight.w600,
                    ),
                    const Spacer(),
                    textWidget(
                      text: 'Adjust goal',
                      fontSize: 0.017,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
                SizedBox(height: height * 0.007),
                textWidget(
                  text: 'Your \$160 monthly surplus makes this goal aggressive.',
                  fontSize: 0.016,
                  color: ProjectColors.whiteColor,
                ),
                SizedBox(height: height * 0.005),
                textWidget(
                  text: '• Required: \$540/month   • Gap: \$380/month',
                  fontSize: 0.016,
                  color: ProjectColors.whiteColor.withOpacity(0.8),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.018),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              textWidget(
                text: 'Smart nudges',
                fontSize: 0.017,
                color: ProjectColors.whiteColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              const _SmallSwitch(),
            ],
          ),
          SizedBox(height: height * 0.008),
          textWidget(
            text: 'When you fall behind schedule, we’ll suggest extra shifts or spending cuts to close the gap.',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}

class _SmallSwitch extends StatefulWidget {
  const _SmallSwitch({Key? key}) : super(key: key);

  @override
  State<_SmallSwitch> createState() => _SmallSwitchState();
}

class _SmallSwitchState extends State<_SmallSwitch> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _value,
      activeColor: ProjectColors.greenColor,
      inactiveThumbColor: Colors.white.withOpacity(0.2),
      inactiveTrackColor: Colors.white.withOpacity(0.06),
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

class JobProjection {
  final String name;
  final double hourlyRate;
  double hours; // mutable for quick demo

  JobProjection({
    required this.name,
    required this.hourlyRate,
    required this.hours,
  });
}

class IncomeProjectionCard extends StatefulWidget {
  final List<JobProjection> jobs;
  final double maxAvailableHours;
  final String periodLabel; // initial label, e.g. "Week"
  final double safeGoalContribution; // e.g. 150.0

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
  static const double step = 0.5; // 0.5h increments
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
          // Header row: title + period dropdown pill
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

          // Summary income
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

          // Job rows
          ...widget.jobs.map(
            (job) => _JobRow(
              job: job,
              onMinus: () => _changeHours(job, -step),
              onPlus: () => _changeHours(job, step),
            ),
          ),
          SizedBox(height: height * 0.016),

          // Progress bar & hours info
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

          // Goal contribution line (still per period, label matches dropdown)
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
          // Job name + rate
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

          // Hours stepper
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
