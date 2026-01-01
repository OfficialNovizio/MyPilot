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

class ProitizerGetx extends GetxController {
  // ========= STATE =========

  RxString timeScope = 'today'.obs;
  Rx<TaskStatus> taskStatus = TaskStatus.pending.obs;
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
    {"title": "Requires attention now", "subtitle": "Hard deadlines or tasks that can’t wait.", "type": TaskSection.must},
    {"title": "Coming up soon", "subtitle": "Important tasks approaching their deadline.", "type": TaskSection.atRisk},
    {"title": "Flexible tasks", "subtitle": "Work on these when time allows.", "type": TaskSection.ifTime},
    {"title": "Completed", "subtitle": "Finished tasks for today.", "type": TaskSection.completed},
  ].obs;

  RxList<Map> priorityType = RxList<Map>([
    {"Title": 'High', "Type": TaskPriority.high, 'Color': ProjectColors.errorColor},
    {"Title": 'Medium', "Type": TaskPriority.medium, 'Color': ProjectColors.yellowColor},
    {"Title": 'Low', "Type": TaskPriority.low, 'Color': ProjectColors.greenColor},
  ]);

  // ========= INIT =========

  // @override
  // void onInit() {
  //   super.onInit();
  //   loadTasks();
  // }

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
      state.value == ButtonState.init;
      state.refresh();
    } else {
      tasks.assignAll(data.data ?? <Task>[]);
      _recomputeSectionsForAll();
      sortTaskAccordingToPriorities();
    }
  }

  Future<PrioritizerModel> addTaskFromUI({
    required String title,
    String? description,
    required DateTime hardDeadline,
    required TaskPriority priority,
  }) async {
    final data = await _loadTaskModel();

    if (title.trim().isEmpty) {
      showSnackBar("Missing Info", 'Add a task title before saving.');
      return data;
    }

    final soft = computeSoftDeadline(hardDeadline);
    final section = decideTaskSection(
      hardDeadline: hardDeadline,
      priority: priority,
    );

    final item = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      section: section,
      hardDeadline: hardDeadline,
      softDeadline: soft,
      priority: priority,
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
      showSnackBar("Success", "Task added to your prioritizer.");
    });
    return data;
  }

  Future<PrioritizerModel> editTaskFromUI({
    required Task current,
    required String title,
    String? description,
    required DateTime hardDeadline,
    required TaskPriority priority,
  }) async {
    final data = await _loadTaskModel();
    final list = data.data ??= <Task>[];

    final idx = list.indexWhere((t) => t.id == current.id);
    if (idx < 0) return data;

    final soft = computeSoftDeadline(hardDeadline);
    final section = decideTaskSection(
      hardDeadline: hardDeadline,
      priority: priority,
    );

    final updated = Task(
      id: current.id, // keep same id
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      section: section,
      hardDeadline: hardDeadline,
      softDeadline: soft,
      priority: priority,
      status: current.status, // keep current status
    );

    list[idx] = updated;

    tasks.assignAll(list);
    // _recomputeSectionsForAll();
    // sortTaskAccordingToPriorities();

    taskModel.value = data;
    await _saveTaskModel(data);

    showSnackBar("Success", "Task updated.");
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

    showSnackBar("Success", "Task removed.");
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

    showSnackBar("Nice", "Task marked as completed.");
    return data;
  }

  Future<PrioritizerModel> snoozeSoftDeadline(Task task, DateTime newSoft) async {
    final data = await _loadTaskModel();
    final list = data.data ??= <Task>[];

    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx < 0) return data;

    list[idx].softDeadline = _dateOnly(newSoft);

    tasks.assignAll(list);
    // _recomputeSectionsForAll();
    // sortTaskAccordingToPriorities();

    taskModel.value = data;
    await _saveTaskModel(data);

    showSnackBar("Updated", "Soft deadline snoozed.");
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

class StartTask extends StatefulWidget {
  final Task task;

  const StartTask({super.key, required this.task});

  @override
  State<StartTask> createState() => _StartTaskState();
}

class _StartTaskState extends State<StartTask> {
  @override
  Widget build(BuildContext context) {
    return Popup(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * 0.01),
          textWidget(
            text: 'Finish this task?',
            fontSize: 0.022,
            fontWeight: FontWeight.w600,
            color: ProjectColors.pureBlackColor,
          ),
          SizedBox(height: height * 0.008),
          textWidget(
            text: 'Mark "${widget.task.title}" as completed and remove it from today’s plan.',
            fontSize: 0.02,
            color: ProjectColors.blackColor,
          ),
          SizedBox(height: height * 0.02),
          Center(
            child: SizedBox(
              width: width * .5,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProjectColors.greenColor,
                  foregroundColor: ProjectColors.pureBlackColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.014),
                ),
                onPressed: () async {
                  await priotizer.markTaskCompleted(widget.task);
                  Get.back(); // close popup
                },
                child: textWidget(
                  text: 'Mark as completed',
                  fontSize: 0.018,
                  fontWeight: FontWeight.w600,
                  color: ProjectColors.pureBlackColor,
                ),
              ),
            ),
          ),
          SizedBox(height: height * 0.02),
        ],
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
                    color: widget.task.priority == TaskPriority.high ? ProjectColors.errorColor : ProjectColors.whiteColor.withOpacity(0.5),
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
        color: destructive ? ProjectColors.errorColor : ProjectColors.pureBlackColor,
      ),
      title: textWidget(
        text: label,
        fontSize: 0.02,
        color: destructive ? ProjectColors.errorColor : ProjectColors.pureBlackColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Popup(
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
              final picked = await showDatePicker(
                context: context,
                initialDate: task.softDeadline ?? now,
                firstDate: now,
                lastDate: DateTime(now.year + 5),
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
              showCupertinoModalPopup(
                context: context,
                builder: (ctx) => AddTaskBottomSheet(task: task),
              );
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

class AddTaskBottomSheet extends StatefulWidget {
  final Task? task; // null = create, not null = edit

  const AddTaskBottomSheet({super.key, this.task});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  DateTime? _hardDeadline;
  final int descControllerIndex = 4;
  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();

    // If editing, prefill fields with existing task
    if (isEdit) {
      final t = widget.task!;
      priotizer.controllers[0].controller.text = t.title;
      priotizer.controllers[1].controller.text = t.description ?? '';
      priotizer.taskPriority.value = t.priority;
      priotizer.controllers[2].controller.text = _priorityTitleFromEnum(t.priority);
      _hardDeadline = t.hardDeadline;
      priotizer.controllers[3].controller.text = _formatDate(_hardDeadline);
    } else {
      // optional: clear fields when creating new
      priotizer.controllers[0].controller.text = '';
      priotizer.controllers[1].controller.text = '';
      priotizer.controllers[2].controller.text = '';
      priotizer.controllers[3].controller.text = '';
      priotizer.taskPriority.value = TaskPriority.low;
      _hardDeadline = null;
    }
  }

  String _priorityTitleFromEnum(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Future<void> _pickHardDeadline() async {
    final picked = await AppDatePicker.pickDate(
      title: "Pick deadline",
      initialDate: _hardDeadline,
      minDate: DateTime.now(),
      maxDate: DateTime(DateTime.now().year + 5),
    );

    if (picked == null) return;

    setState(() {
      _hardDeadline = picked;
      // _softDeadline = priotizer.computeSoftDeadline(picked);
      priotizer.controllers[3].controller.text = _formatDate(_hardDeadline);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'None';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Popup(
      color: ProjectColors.blackColor,
      title: isEdit ? 'Edit Task' : 'Create Task',
      body: Obx(
        () => Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  width * 0.05,
                  height * 0.018,
                  width * 0.05,
                  height * 0.02,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.02),
                    _label("Task Title"),
                    SizedBox(height: height * 0.008),
                    _darkTextField(
                      controller: priotizer.controllers[0].controller,
                      hint: "Enter task title",
                      maxLines: 1,
                    ),
                    SizedBox(height: height * 0.018),
                    _label("Priority"),
                    SizedBox(height: height * 0.01),
                    _priorityRow(),
                    SizedBox(height: height * 0.018),
                    _label("Description"),
                    SizedBox(height: height * 0.008),
                    _darkTextField(
                      controller: priotizer.controllers[1].controller,
                      hint: "Enter description (optional)",
                      maxLines: 3,
                    ),
                    SizedBox(height: height * 0.018),
                    _deadlineTile(
                      label: "Deadline",
                      value: _formatDate(_hardDeadline),
                      onTap: _pickHardDeadline,
                    ),
                    SizedBox(height: height * 0.05),
                    _addButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return textWidget(
      text: text,
      fontSize: 0.015,
      fontWeight: FontWeight.w600,
      color: ProjectColors.whiteColor,
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ProjectColors.whiteColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProjectColors.whiteColor.withOpacity(0.08)),
      ),
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.004),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: ProjectColors.whiteColor, fontWeight: FontWeight.w600),
        cursorColor: ProjectColors.greenColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: ProjectColors.whiteColor.withOpacity(0.35)),
        ),
      ),
    );
  }

  Widget _priorityRow() {
    return Row(
      children: priotizer.priorityType!.map((type) {
        final bool active = priotizer.taskPriority.value == type['Type'];
        final Color activeColor = type['Color']; // your map color

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.01),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                priotizer.taskPriority.value = type['Type'];
                priotizer.controllers[2].controller.text = type['Title'];
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: height * 0.012),
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? Colors.transparent : Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (type['Title'].toString().toLowerCase() == "high")
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: ProjectColors.errorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    textWidget(
                      text: type['Title'],
                      color: active ? ProjectColors.pureBlackColor : ProjectColors.whiteColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 0.017,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _deadlineTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.016),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.white.withOpacity(0.7)),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: height * 0.017,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: value == "None" ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: width * 0.02),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return Center(
      child: normalButton(
        title: isEdit ? "Save Changes" : "Create Task",
        bColor: ProjectColors.greenColor,
        invertColors: true,
        cWidth: .7,
        loading: false,
        callback: () async {
          final title = priotizer.controllers[0].controller.text.trim();
          final desc = priotizer.controllers[1].controller.text.trim();
          final priority = priotizer.taskPriority.value;
          final hard = _hardDeadline;

          if (title.isEmpty) {
            showSnackBar("Missing Info", "Enter a task title.");
            return;
          }
          if (hard == null) {
            showSnackBar("Missing Info", "Pick a deadline before saving.");
            return;
          }

          // CREATE vs EDIT
          if (isEdit) {
            // EDIT EXISTING
            await priotizer.editTaskFromUI(
              current: widget.task!,
              title: title,
              description: desc,
              hardDeadline: hard,
              priority: priority,
            );
          } else {
            // CREATE NEW
            await priotizer.addTaskFromUI(
              title: title,
              description: desc,
              hardDeadline: hard,
              priority: priority,
            );
          }
        },
      ),
    );
  }
}
