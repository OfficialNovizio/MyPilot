import 'dart:math';
import 'package:emptyproject/Working UI/Constant UI.dart';
import 'package:emptyproject/Working UI/Constants.dart';
import 'package:emptyproject/Working UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ---------------------------------------------------------------------------
/// ENUMS + MODELS
/// ---------------------------------------------------------------------------

enum GoalType { save, debt, surplus }
enum SavingFrequency { weekly, biweekly, monthly }
enum GoalPriority { high, medium, low }

class RequiredPlan {
  final double perPeriod;
  final int periods;
  RequiredPlan(this.perPeriod, this.periods);
}

class GoalItem {
  final String id;
  final GoalType type;
  final GoalPriority priority;
  final SavingFrequency frequency;
  final String title;
  final double amount;
  final DateTime targetDate;
  final String? description;
  final double requiredPerPeriod;
  final int periodsLeft;

  // later you can add: double funded, etc.

  GoalItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.frequency,
    required this.title,
    required this.amount,
    required this.targetDate,
    required this.requiredPerPeriod,
    required this.periodsLeft,
    this.description,
  });
}

/// ---------------------------------------------------------------------------
/// PROJECTION TAB (GOAL SCREEN)
/// ---------------------------------------------------------------------------

class ProjectionTab extends StatefulWidget {
  const ProjectionTab({Key? key}) : super(key: key);

  @override
  State<ProjectionTab> createState() => _ProjectionTabState();
}

class _ProjectionTabState extends State<ProjectionTab> {
  GoalType _goalType = GoalType.save;
  SavingFrequency _frequency = SavingFrequency.weekly;
  GoalPriority _priority = GoalPriority.medium;

  final TextEditingController _titleCtrl =
  TextEditingController(text: 'MacBook Fund');
  final TextEditingController _amountCtrl =
  TextEditingController(text: '2000');
  final TextEditingController _descriptionCtrl = TextEditingController();

  DateTime _targetDate =
  DateTime(DateTime.now().year, DateTime.now().month + 3, 1);

  final List<GoalItem> _goals = [];

  @override
  Widget build(BuildContext context) {
    height = Get.height;
    width = Get.width;

    final plan = _computeRequired();
    final canSave =
        _titleCtrl.text.trim().isNotEmpty && plan != null && _parseAmount() != null;

    return SingleChildScrollView(
      padding:
      EdgeInsets.symmetric(horizontal: width * .02, vertical: height * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) Income planner
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

          // 2) Goal setup card
          _GoalSetupCard(
            goalType: _goalType,
            onGoalTypeChanged: (t) => setState(() => _goalType = t),
            priority: _priority,
            onPriorityChanged: (p) => setState(() => _priority = p),
            frequency: _frequency,
            onFrequencyChanged: (f) => setState(() => _frequency = f),
            titleController: _titleCtrl,
            amountController: _amountCtrl,
            descriptionController: _descriptionCtrl,
            targetDate: _targetDate,
            onPickDate: _pickDate,
            requiredPerPeriod: plan?.perPeriod,
            periodsLeft: plan?.periods,
            onSave: _saveGoal,
            canSave: canSave,
          ),

          SizedBox(height: height * 0.02),

          // 3) Goals list, grouped by priority
          if (_goals.isNotEmpty)
            _GoalsSection(goals: _goals),
        ],
      ),
    );
  }

  // ---------- helpers ----------

  double? _parseAmount() {
    final raw = _amountCtrl.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return null;
    return v;
  }

  RequiredPlan? _computeRequired() {
    final amount = _parseAmount();
    if (amount == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!_targetDate.isAfter(today)) return null;

    final daysDiff = _targetDate.difference(today).inDays;
    if (daysDiff <= 0) return null;

    double periodDays;
    switch (_frequency) {
      case SavingFrequency.weekly:
        periodDays = 7;
        break;
      case SavingFrequency.biweekly:
        periodDays = 14;
        break;
      case SavingFrequency.monthly:
        periodDays = 30;
        break;
    }

    final periods = max(1, (daysDiff / periodDays).ceil());
    final per = amount / periods;
    return RequiredPlan(per, periods);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final initial = _targetDate.isBefore(first) ? first : _targetDate;
    final last = DateTime(now.year + 10, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
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

  void _saveGoal() {
    final amount = _parseAmount();
    final plan = _computeRequired();
    final title = _titleCtrl.text.trim();

    if (amount == null || plan == null || title.isEmpty) {
      Get.snackbar(
        'Missing info',
        'Add a title, amount and future date before saving.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final item = GoalItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _goalType,
      priority: _priority,
      frequency: _frequency,
      title: title,
      amount: amount,
      targetDate: _targetDate,
      requiredPerPeriod: plan.perPeriod,
      periodsLeft: plan.periods,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
    );

    setState(() {
      _goals.add(item);
    });

    Get.snackbar(
      'Goal saved',
      '“${item.title}” added to your goals list.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

/// ---------------------------------------------------------------------------
/// GOAL SETUP CARD
/// ---------------------------------------------------------------------------

class _GoalSetupCard extends StatelessWidget {
  final GoalType goalType;
  final ValueChanged<GoalType> onGoalTypeChanged;

  final GoalPriority priority;
  final ValueChanged<GoalPriority> onPriorityChanged;

  final SavingFrequency frequency;
  final ValueChanged<SavingFrequency> onFrequencyChanged;

  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController descriptionController;

  final DateTime targetDate;
  final VoidCallback onPickDate;

  final double? requiredPerPeriod;
  final int? periodsLeft;

  final VoidCallback onSave;
  final bool canSave;

  const _GoalSetupCard({
    Key? key,
    required this.goalType,
    required this.onGoalTypeChanged,
    required this.priority,
    required this.onPriorityChanged,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.titleController,
    required this.amountController,
    required this.descriptionController,
    required this.targetDate,
    required this.onPickDate,
    required this.requiredPerPeriod,
    required this.periodsLeft,
    required this.onSave,
    required this.canSave,
  }) : super(key: key);

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  String _frequencyShort() {
    switch (frequency) {
      case SavingFrequency.weekly:
        return 'week';
      case SavingFrequency.biweekly:
        return '2 weeks';
      case SavingFrequency.monthly:
        return 'month';
    }
  }

  String _frequencyPlural() {
    switch (frequency) {
      case SavingFrequency.weekly:
        return 'weeks';
      case SavingFrequency.biweekly:
        return '2-week periods';
      case SavingFrequency.monthly:
        return 'months';
    }
  }

  String _verb() {
    switch (goalType) {
      case GoalType.save:
        return 'save';
      case GoalType.debt:
        return 'pay';
      case GoalType.surplus:
        return 'set aside';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = '${_monthName(targetDate.month)} ${targetDate.year}';

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
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
          SizedBox(height: height * 0.018),

          // title
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

          // amount + date
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
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
          SizedBox(height: height * 0.015),

          // description
          textWidget(
            text: 'Description (optional)',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.6),
          ),
          SizedBox(height: height * 0.005),
          _DarkTextField(
            controller: descriptionController,
            hintText: 'Why is this goal important?',
            maxLines: 2,
          ),
          SizedBox(height: height * 0.018),

          // priority row
          _PriorityRow(
            priority: priority,
            onChanged: onPriorityChanged,
          ),
          SizedBox(height: height * 0.018),

          // frequency selector
          textWidget(
            text: 'How will you fund it?',
            fontSize: 0.017,
            color: ProjectColors.whiteColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: height * 0.008),
          _FrequencySegment(
            selected: frequency,
            onChanged: onFrequencyChanged,
          ),
          SizedBox(height: height * 0.015),

          // requirement text
          if (requiredPerPeriod != null && periodsLeft != null) ...[
            textWidget(
              text:
              'You need to ${_verb()} \$${requiredPerPeriod!.toStringAsFixed(0)} every ${_frequencyShort()}.',
              fontSize: 0.018,
              color: ProjectColors.whiteColor,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: height * 0.006),
            textWidget(
              text:
              '$periodsLeft ${_frequencyPlural()} left until $dateLabel.',
              fontSize: 0.016,
              color: ProjectColors.whiteColor.withOpacity(0.7),
            ),
          ] else
            textWidget(
              text:
              'Set amount and a future date to see how much you must ${_verb()}.',
              fontSize: 0.016,
              color: ProjectColors.whiteColor.withOpacity(0.7),
            ),

          SizedBox(height: height * 0.02),

          // save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSave ? onSave : null,
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
    );
  }
}

/// ---------------------------------------------------------------------------
/// GOALS LIST SECTION (UNDER SETUP CARD)
/// ---------------------------------------------------------------------------

class _GoalsSection extends StatelessWidget {
  final List<GoalItem> goals;

  const _GoalsSection({Key? key, required this.goals}) : super(key: key);

  double _weeklyCommitment(GoalItem g) {
    switch (g.frequency) {
      case SavingFrequency.weekly:
        return g.requiredPerPeriod;
      case SavingFrequency.biweekly:
        return g.requiredPerPeriod / 2.0;
      case SavingFrequency.monthly:
        return g.requiredPerPeriod / 4.33; // approx weeks / month
    }
  }

  String _priorityLabel(GoalPriority p) {
    switch (p) {
      case GoalPriority.high:
        return 'High Priority';
      case GoalPriority.medium:
        return 'Medium Priority';
      case GoalPriority.low:
        return 'Low Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final high = goals.where((g) => g.priority == GoalPriority.high).toList();
    final med = goals.where((g) => g.priority == GoalPriority.medium).toList();
    final low = goals.where((g) => g.priority == GoalPriority.low).toList();

    final committedWeekly = goals.fold<double>(
      0.0,
          (sum, g) => sum + _weeklyCommitment(g),
    );

    return Column(
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
          text:
          'Funding ${goals.length} goals • ~\$${committedWeekly.toStringAsFixed(0)}/week committed',
          fontSize: 0.016,
          color: ProjectColors.whiteColor.withOpacity(0.7),
        ),
        SizedBox(height: height * 0.018),

        if (high.isNotEmpty) ...[
          textWidget(
            text: _priorityLabel(GoalPriority.high),
            fontSize: 0.018,
            color: ProjectColors.whiteColor.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: height * 0.008),
          ...high.map((g) => _GoalListCard(
            goal: g,
            weeklyAmount: _weeklyCommitment(g),
          )),
          SizedBox(height: height * 0.018),
        ],

        if (med.isNotEmpty) ...[
          textWidget(
            text: _priorityLabel(GoalPriority.medium),
            fontSize: 0.018,
            color: ProjectColors.whiteColor.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: height * 0.008),
          ...med.map((g) => _GoalListCard(
            goal: g,
            weeklyAmount: _weeklyCommitment(g),
          )),
          SizedBox(height: height * 0.018),
        ],

        if (low.isNotEmpty) ...[
          textWidget(
            text: _priorityLabel(GoalPriority.low),
            fontSize: 0.018,
            color: ProjectColors.whiteColor.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: height * 0.008),
          ...low.map((g) => _GoalListCard(
            goal: g,
            weeklyAmount: _weeklyCommitment(g),
          )),
        ],
      ],
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

  Color _typeColor() {
    switch (goal.type) {
      case GoalType.save:
        return ProjectColors.greenColor;
      case GoalType.debt:
        return Colors.orangeAccent;
      case GoalType.surplus:
        return Colors.purpleAccent;
    }
  }

  IconData _typeIcon() {
    switch (goal.type) {
      case GoalType.save:
        return Icons.savings_rounded;
      case GoalType.debt:
        return Icons.credit_card_rounded;
      case GoalType.surplus:
        return Icons.trending_up_rounded;
    }
  }

  String _priorityPillText() {
    switch (goal.priority) {
      case GoalPriority.high:
        return 'HIGH';
      case GoalPriority.medium:
        return 'MED';
      case GoalPriority.low:
        return 'LOW';
    }
  }

  Color _priorityColor() {
    switch (goal.priority) {
      case GoalPriority.high:
        return Colors.deepOrangeAccent;
      case GoalPriority.medium:
        return Colors.amber;
      case GoalPriority.low:
        return Colors.blueGrey;
    }
  }

  String _monthYear(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor();

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
                  _typeIcon(),
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
                      text:
                      '\$${weeklyAmount.toStringAsFixed(0)} / week',
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
                  color: _priorityColor().withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: textWidget(
                  text: _priorityPillText(),
                  fontSize: 0.014,
                  color: _priorityColor(),
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
                text: 'Target: ${_monthYear(goal.targetDate)}',
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
/// SMALL SUBWIDGETS (segments, fields, etc.)
/// ---------------------------------------------------------------------------

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
              color: active
                  ? ProjectColors.greenColor.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: textWidget(
              text: label,
              fontSize: 0.017,
              color:
              active ? ProjectColors.greenColor : ProjectColors.whiteColor,
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

class _FrequencySegment extends StatelessWidget {
  final SavingFrequency selected;
  final ValueChanged<SavingFrequency> onChanged;

  const _FrequencySegment({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, SavingFrequency type) {
      final bool active = selected == type;

      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(type),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: height * 0.010),
            decoration: BoxDecoration(
              color: active
                  ? ProjectColors.greenColor.withOpacity(0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: textWidget(
              text: label,
              fontSize: 0.016,
              color:
              active ? ProjectColors.greenColor : ProjectColors.whiteColor,
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
          chip('Weekly', SavingFrequency.weekly),
          SizedBox(width: width * 0.01),
          chip('Bi-weekly', SavingFrequency.biweekly),
          SizedBox(width: width * 0.01),
          chip('Monthly', SavingFrequency.monthly),
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final GoalPriority priority;
  final ValueChanged<GoalPriority> onChanged;

  const _PriorityRow({
    Key? key,
    required this.priority,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, GoalPriority p, Color color) {
      final bool active = p == priority;
      return GestureDetector(
        onTap: () => onChanged(p),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.03,
            vertical: height * 0.008,
          ),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color : Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: height * 0.012,
                height: height * 0.012,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: width * 0.012),
              textWidget(
                text: label,
                fontSize: 0.015,
                color: ProjectColors.whiteColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: 'Priority',
          fontSize: 0.016,
          color: ProjectColors.whiteColor.withOpacity(0.6),
        ),
        SizedBox(height: height * 0.008),
        Row(
          children: [
            pill('High', GoalPriority.high, Colors.redAccent),
            SizedBox(width: width * 0.02),
            pill('Medium', GoalPriority.medium, Colors.orangeAccent),
            SizedBox(width: width * 0.02),
            pill('Low', GoalPriority.low, Colors.greenAccent),
          ],
        ),
      ],
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int maxLines;

  const _DarkTextField({
    Key? key,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.prefixText,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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

  double get totalHours =>
      widget.jobs.fold(0.0, (sum, job) => sum + job.hours);

  double get totalIncome =>
      widget.jobs.fold(0.0, (sum, job) => sum + job.hours * job.hourlyRate);

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

    final progress = widget.maxAvailableHours == 0
        ? 0.0
        : (totalHours / widget.maxAvailableHours).clamp(0.0, 1.0);

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
                text:
                '$hoursStr h  •  Max ${widget.maxAvailableHours.toStringAsFixed(0)} h',
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
