import 'dart:convert';

import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../models/Priotizer model.dart';
import '../../models/TextForm.dart';
import '../Constants.dart';
import '../Shared Preferences.dart';
import 'Add Priority Task.dart';

class ProitizerGetx extends GetxController {
  // ========= STATE =========

  // RxString timeScope = 'today'.obs;
  // Rx<TaskStatus> taskStatus = TaskStatus.pending.obs;
  Rx<ButtonState> state = Rx<ButtonState>(ButtonState.loading);
  Rx<TaskPriority> taskPriority = TaskPriority.low.obs;
  Rx<TaskSection> taskType = TaskSection.must.obs;
  Rx<PrioritizerModel?> taskModel = PrioritizerModel(status: 200, message: 'ok', data: <Task>[]).obs;
  RxList<Task> tasks = <Task>[].obs;
  RxList<Task> mustDoTask = <Task>[].obs;
  RxList<Task> atRisk = <Task>[].obs;
  RxList<Task> ifTime = <Task>[].obs;
  RxList<Task> completedTask = <Task>[].obs;
  Rx<Task?> selectedTask = Rx<Task?>(null);

  RxList<TextForm> controllers = RxList<TextForm>([
    TextForm(title: "Task Title", controller: TextEditingController(text: '')),
    TextForm(title: "Description", controller: TextEditingController(text: '')),
    TextForm(title: "Priority", controller: TextEditingController(text: '')),
    TextForm(title: "Deadline", controller: TextEditingController(text: '')),
  ]);
  RxList<Map>? visibleTasks = <Map<String, dynamic>>[
    {"name": "Due Now", "title": "Requires attention now", "subtitle": "Hard deadlines or tasks that can’t wait.", "type": TaskSection.must},
    {"name": "Coming Up", "title": "Coming up soon", "subtitle": "Important tasks approaching their deadline.", "type": TaskSection.atRisk},
    {"name": "Optional", "title": "Flexible tasks", "subtitle": "Work on these when time allows.", "type": TaskSection.ifTime},
    {"name": "Done", "title": "Completed", "subtitle": "Finished tasks for today.", "type": TaskSection.completed},
  ].obs;

  RxList? sections = ['Due Now', 'Coming Up', 'Optional', 'Done'].obs;

  RxList<Map> priorityType = RxList<Map>([
    {"Title": 'High', "Type": TaskPriority.high, 'Color': ProjectColors.errorColor},
    {"Title": 'Medium', "Type": TaskPriority.medium, 'Color': ProjectColors.yellowColor},
    {"Title": 'Low', "Type": TaskPriority.low, 'Color': ProjectColors.greenColor},
  ]);

  // ========= DATE HELPERS =========

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime? computeSoftDeadline(DateTime hardDeadline, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final hard = _dateOnly(hardDeadline);

    final days = hard.difference(today).inDays;
    if (days <= 0) return null; // due today or past => no soft

    var buffer = (days * 0.25).round(); // 25% window
    if (buffer < 1) buffer = 1;
    if (buffer > 3) buffer = 3;

    return hard.subtract(Duration(days: buffer));
  }

  TaskSection decideTaskSection({
    required DateTime hardDeadline,
    required TaskPriority priority,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final hard = _dateOnly(hardDeadline);
    final daysToHard = hard.difference(today).inDays;

    // Hard deadline today or past -> Must do now
    if (daysToHard <= 0) {
      return TaskSection.must;
    }

    final soft = computeSoftDeadline(hardDeadline, now: now);
    DateTime? softDate;
    int? daysToSoft;

    if (soft != null) {
      softDate = _dateOnly(soft);
      daysToSoft = softDate.difference(today).inDays;
    }

    if (softDate != null) {
      // on or past soft, but before hard
      if (daysToSoft != null && daysToSoft <= 0 && daysToHard > 0) {
        if (priority == TaskPriority.high) {
          return TaskSection.must;
        }
        return TaskSection.atRisk;
      }
      // soft in future
      return TaskSection.ifTime;
    }

    // no soft (should almost never hit here, but keep fallback)
    switch (priority) {
      case TaskPriority.high:
        return TaskSection.atRisk;
      case TaskPriority.medium:
      case TaskPriority.low:
        return TaskSection.ifTime;
    }
  }

  // ========= SORTING =========

  void _recomputeSectionsForAll() {
    for (var t in tasks) {
      if (t.status == TaskStatus.completed) continue;
      t.section = decideTaskSection(
        hardDeadline: t.hardDeadline,
        priority: t.priority,
      );
    }
    tasks.refresh();
  }

  void sortTaskAccordingToPriorities() {
    mustDoTask.clear();
    atRisk.clear();
    ifTime.clear();
    completedTask.clear();

    for (var t in tasks) {
      if (t.status == TaskStatus.completed) {
        completedTask.add(t);
        continue;
      }
      switch (t.section) {
        case TaskSection.must:
          mustDoTask.add(t);
          break;
        case TaskSection.atRisk:
          atRisk.add(t);
          break;
        case TaskSection.ifTime:
          ifTime.add(t);
          break;
        case TaskSection.completed:
          // completedTask.add(t);
          break;
      }
    }

    mustDoTask.refresh();
    atRisk.refresh();
    ifTime.refresh();
    completedTask.refresh();
    state.value = ButtonState.init;
    state.refresh();
  }

  // ========= CRUD PUBLIC APIS =========

  Future<void> loadTasks() async {
    final data = await _loadTaskModel();
    taskModel.value = data;

    if (data.data!.isEmpty) {
      state.value = ButtonState.init;
      state.refresh();
    } else {
      tasks.assignAll(data.data ?? <Task>[]);
      _recomputeSectionsForAll();
      sortTaskAccordingToPriorities();
    }
  }

  Future<PrioritizerModel> addTaskFromUI() async {
    final data = await _loadTaskModel();

    final soft = computeSoftDeadline(controllers[3].pickedDate!);
    final section = decideTaskSection(
      hardDeadline: controllers[3].pickedDate!,
      priority: taskPriority.value,
    );

    final item = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: controllers[0].controller.text,
      description: controllers[1].controller.text,
      section: section,
      hardDeadline: controllers[3].pickedDate!,
      softDeadline: soft,
      priority: taskPriority.value,
      status: TaskStatus.pending,
    );

    final list = data.data ??= <Task>[];
    list.add(item);

    tasks.assignAll(list);
    // _recomputeSectionsForAll();
    // sortTaskAccordingToPriorities();

    taskModel.value = data;
    await _saveTaskModel(data);
    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () {
      showSnackBar("Success", "Task added to your prioritizer");
    });
    return data;
  }

  Future<PrioritizerModel> editTaskFromUI() async {
    final data = await _loadTaskModel();
    final list = data.data ??= <Task>[];

    final idx = list.indexWhere((t) => t.id == selectedTask.value!.id);
    if (idx < 0) return data;

    final soft = computeSoftDeadline(controllers[3].pickedDate!);
    final section = decideTaskSection(
      hardDeadline: controllers[3].pickedDate!,
      priority: taskPriority.value,
    );

    final updated = Task(
      id: selectedTask.value!.id, // keep same id
      title: controllers[0].controller.text,
      description: controllers[1].controller.text,
      section: section,
      hardDeadline: controllers[3].pickedDate!,
      softDeadline: soft,
      priority: taskPriority.value,
      status: selectedTask.value!.status, // keep current status
    );

    list[idx] = updated;

    tasks.assignAll(list);
    // _recomputeSectionsForAll();
    // sortTaskAccordingToPriorities();

    taskModel.value = data;
    await _saveTaskModel(data);
    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () {
      showSnackBar("Success", "Task updated to your prioritizer");
    });
    return data;
  }

  Future<PrioritizerModel> deleteTask({required String id}) async {
    final data = await _loadTaskModel();
    final list = data.data ??= <Task>[];

    list.removeWhere((t) => t.id == id);

    tasks.assignAll(list);
    // _recomputeSectionsForAll();
    // sortTaskAccordingToPriorities();

    taskModel.value = data;
    await _saveTaskModel(data);
    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () {
      showSnackBar("Success", "Task removed.");
    });

    return data;
  }

  Future<PrioritizerModel> markTaskCompleted(Task task) async {
    final data = await _loadTaskModel();
    final list = data.data ??= <Task>[];

    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx < 0) return data;

    list[idx].status = TaskStatus.completed;

    tasks.assignAll(list);
    // _recomputeSectionsForAll();
    // sortTaskAccordingToPriorities();

    taskModel.value = data;
    await _saveTaskModel(data);
    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () {
      showSnackBar("Nice", "Task marked as completed.");
    });

    return data;
  }

  Future<PrioritizerModel> snoozeSoftDeadline(Task task, DateTime newSoft) async {
    final data = await _loadTaskModel();
    final list = data.data ??= <Task>[];

    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx < 0) return data;
    final soft = computeSoftDeadline(newSoft);
    list[idx].softDeadline = soft;
    list[idx].hardDeadline = _dateOnly(newSoft);

    tasks.assignAll(list);
    // _recomputeSectionsForAll();
    // sortTaskAccordingToPriorities();

    taskModel.value = data;
    await _saveTaskModel(data);
    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () {
      showSnackBar("Updated", "Soft deadline snoozed.");
    });

    return data;
  }

  // ========= LOAD / SAVE =========

  Future<PrioritizerModel> _loadTaskModel() async {
    final saved = await getLocalData('savedTasks') ?? '';
    if (saved.isEmpty) {
      return PrioritizerModel(status: 200, message: 'ok', data: <Task>[]);
    }
    return PrioritizerModel.fromJson(jsonDecode(saved));
  }

  Future<void> _saveTaskModel(PrioritizerModel m) async {
    await saveLocalData('savedTasks', jsonEncode(m.toJson()));
    Future.delayed(const Duration(milliseconds: 500), () {
      loadTasks();
    });
  }
}
