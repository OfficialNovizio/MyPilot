import 'dart:convert';
import 'dart:math';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/Projection Model.dart';
import '../../Constants.dart';
import '../../Controllers.dart';
import '../../Shared Preferences.dart';
import 'Projection.dart';

/// ---------------------------------------------------------------------------
/// INSIGHTS (GetX Controller)
/// ---------------------------------------------------------------------------

class ProjectionController extends GetxController {
  Rx<GoalType> goalType = GoalType.save.obs;
  Rx<SavingFrequency> frequency = SavingFrequency.weekly.obs;
  Rx<GoalPriority> priority = GoalPriority.medium.obs;
  final TextEditingController titleCtrl = TextEditingController(text: 'MacBook Fund');
  final TextEditingController amountCtrl = TextEditingController(text: '2000');
  final TextEditingController descriptionCtrl = TextEditingController();
  DateTime targetDate = DateTime(DateTime.now().year, DateTime.now().month + 3, 1);
  Rxn<ProjectionModel>? goalModel = Rxn<ProjectionModel>();
  RxList<GoalItem> goals = RxList<GoalItem>([]);
  Rxn<GoalItem> selectedGoal = Rxn<GoalItem>();
  Rx<ButtonState>? buttonState = Rx<ButtonState>(ButtonState.loading);

  RxList<Map>? goalTypeList = <Map<String, dynamic>>[
    {"name": "Save", "type": GoalType.save},
    {"name": "Debt", "type": GoalType.debt},
    {"name": "Surplus", "type": GoalType.surplus},
  ].obs;
  RxList<Map>? fundingType = <Map<String, dynamic>>[
    {"name": "Weekly", "type": SavingFrequency.weekly},
    {"name": "Bi-weekly", "type": SavingFrequency.biweekly},
    {"name": "Monthly", "type": SavingFrequency.monthly},
  ].obs;

  String verb() {
    switch (goalType.value) {
      case GoalType.save:
        return 'save';
      case GoalType.debt:
        return 'pay';
      case GoalType.surplus:
        return 'set aside';
    }
  }

  String frequencyShort() {
    switch (frequency.value) {
      case SavingFrequency.weekly:
        return 'week';
      case SavingFrequency.biweekly:
        return '2 weeks';
      case SavingFrequency.monthly:
        return 'month';
    }
  }

  String frequencyPlural() {
    switch (frequency.value) {
      case SavingFrequency.weekly:
        return 'weeks';
      case SavingFrequency.biweekly:
        return '2-week periods';
      case SavingFrequency.monthly:
        return 'months';
    }
  }

  double? weeklyCommitment(GoalItem g) {
    switch (g.frequency!) {
      case SavingFrequency.weekly:
        return g.requiredPerPeriod;
      case SavingFrequency.biweekly:
        return g.requiredPerPeriod! / 2.0;
      case SavingFrequency.monthly:
        return g.requiredPerPeriod! / 4.33;
    }
  }

  String priorityLabel(GoalPriority p) {
    switch (p) {
      case GoalPriority.high:
        return 'High Priority';
      case GoalPriority.medium:
        return 'Medium Priority';
      case GoalPriority.low:
        return 'Low Priority';
    }
  }

  Color typeColor(GoalItem goal) {
    switch (goal.type!) {
      case GoalType.save:
        return ProjectColors.greenColor;
      case GoalType.debt:
        return Colors.orangeAccent;
      case GoalType.surplus:
        return Colors.purpleAccent;
    }
  }

  IconData typeIcon(GoalItem goal) {
    switch (goal.type!) {
      case GoalType.save:
        return Icons.savings_rounded;
      case GoalType.debt:
        return Icons.credit_card_rounded;
      case GoalType.surplus:
        return Icons.trending_up_rounded;
    }
  }

  String priorityPillText(GoalItem goal) {
    switch (goal.priority!) {
      case GoalPriority.high:
        return 'HIGH';
      case GoalPriority.medium:
        return 'MED';
      case GoalPriority.low:
        return 'LOW';
    }
  }

  Color priorityColor(GoalItem goal) {
    switch (goal.priority!) {
      case GoalPriority.high:
        return Colors.deepOrangeAccent;
      case GoalPriority.medium:
        return Colors.amber;
      case GoalPriority.low:
        return Colors.blueGrey;
    }
  }

  double? parseAmount() {
    final raw = amountCtrl.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return null;
    return v;
  }

  RequiredPlan? computeRequired() {
    final amount = parseAmount();
    if (amount == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!targetDate.isAfter(today)) return null;

    final daysDiff = targetDate.difference(today).inDays;
    if (daysDiff <= 0) return null;

    double periodDays;
    switch (frequency.value) {
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

  void loadShifts() async {
    final listData = await _loadProjectionModel();
    goals.clear();
    goalModel!.value = listData;
    if (goalModel!.value!.data!.isNotEmpty) {
      for (var files in goalModel!.value!.data!) {
        goals.add(files);
      }
    }

    goalModel!.refresh();
    goals.refresh();

    Future.delayed(const Duration(seconds: 1), () {
      buttonState!.value = ButtonState.init;
      buttonState!.refresh();
    });
  }

  Future<ProjectionModel> saveGoal({bool replaceById = true}) async {
    final data = await _loadProjectionModel();

    final amount = parseAmount();
    final plan = computeRequired();
    final title = titleCtrl.text.trim();

    if (amount == null || plan == null || title.isEmpty) {
      showSnackBar("Missing Info", 'Add a title, amount and future date before saving.');
      return data;
    }

    final item = GoalItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // or Random().nextInt(...).toString()
      type: goalType.value,
      priority: priority.value,
      frequency: frequency.value,
      title: title,
      amount: amount,
      targetDate: targetDate,
      requiredPerPeriod: plan.perPeriod,
      periodsLeft: plan.periods,
      description: descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
    );

    final list = data.data ??= <GoalItem>[];

    if (replaceById && item.id != null) {
      final i = list.indexWhere((e) => e.id == item.id);
      (i >= 0) ? list[i] = item : list.add(item);
    } else {
      list.add(item);
    }

    goals.assignAll(list);
    goals.refresh();

    Get.back();
    buttonState!.value = ButtonState.loading;
    buttonState!.refresh();

    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "Goal saved to your goals list.");
    });

    await _saveProjectionModel(data);
    return data;
  }

  Future<ProjectionModel> deleteGoal({required String id}) async {
    final data = await _loadProjectionModel();

    final list = data.data ??= <GoalItem>[];
    list.removeWhere((g) => g.id == id);

    goals.assignAll(list);

    Get.back();
    buttonState!.value = ButtonState.loading;
    buttonState!.refresh();

    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "Goal removed.");
    });

    await _saveProjectionModel(data);
    return data;
  }

  Future<ProjectionModel> editGoal() async {
    final data = await _loadProjectionModel();

    final current = selectedGoal.value;
    if (current == null || current.id == null) return data;

    final list = data.data ??= <GoalItem>[];
    final idx = list.indexWhere((g) => g.id == current.id);
    if (idx < 0) return data;

    final amount = parseAmount();
    final plan = computeRequired();
    final title = titleCtrl.text.trim();

    if (amount == null || plan == null || title.isEmpty) {
      showSnackBar("Missing Info", 'Add a title, amount and future date before saving.');
      return data;
    }

    final updated = GoalItem(
      id: current.id, // keep same id
      type: goalType.value,
      priority: priority.value,
      frequency: frequency.value,
      title: title,
      amount: amount,
      targetDate: targetDate,
      requiredPerPeriod: plan.perPeriod,
      periodsLeft: plan.periods,
      description: descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
    );

    list[idx] = updated;
    goals.assignAll(list);

    Get.back();
    buttonState!.value = ButtonState.loading;
    buttonState!.refresh();

    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "Goal updated.");
    });

    await _saveProjectionModel(data);
    return data;
  }

// ======================= LOAD / SAVE =======================

  Future<ProjectionModel> _loadProjectionModel() async {
    final saved = await getLocalData('savedGoals') ?? '';
    if (saved.isEmpty) {
      return ProjectionModel(status: 200, message: 'ok', data: <GoalItem>[]);
    }
    return ProjectionModel.fromJson(jsonDecode(saved));
  }

  Future<void> _saveProjectionModel(ProjectionModel m) async {
    await saveLocalData('savedGoals', jsonEncode(m.toJson()));
    Future.delayed(const Duration(seconds: 1), () {
      loadShifts();
    });
  }
}

class AddGoal extends StatefulWidget {
  const AddGoal({super.key});

  @override
  State<AddGoal> createState() => _AddGoalState();
}

class _AddGoalState extends State<AddGoal> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * .9,
      child: Popup(
        color: ProjectColors.blackColor,
        title: 'Goal Setup',
        body: GoalSetupCard(
            // goalType: projection.goalType.value,
            // onGoalTypeChanged: (t) => setState(() => projection.goalType.value = t),
            // priority: projection.priority.value,
            // onPriorityChanged: (p) => setState(() => projection.priority.value = p),
            // frequency: projection.frequency.value,
            // onFrequencyChanged: (f) => setState(() => projection.frequency.value = f),
            // titleController: projection.titleCtrl,
            // amountController: projection.amountCtrl,
            // descriptionController: projection.descriptionCtrl,
            // targetDate: projection.targetDate,
            // onPickDate: projection.pickDate,
            // requiredPerPeriod: plan?.perPeriod,
            // periodsLeft: plan?.periods,
            // onSave: projection.saveGoal,
            // canSave: canSave,
            ),
      ),
    );
  }
}
