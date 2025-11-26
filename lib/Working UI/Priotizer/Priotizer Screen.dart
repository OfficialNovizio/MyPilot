import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/material.dart';

import '../Constants.dart';
// import 'package:get/get.dart';  // you already use Get for height/width & textWidget

// ------- MODELS & ENUMS -------

enum TaskSection { must, atRisk, ifTime }

enum TaskPriority { high, medium, low }

enum TaskStatus { pending, inProgress, completed }

class Task {
  Task({
    required this.id,
    required this.title,
    required this.section,
    this.softDeadlineText,
    this.hardDeadlineText,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
  });

  final String id;
  final String title;
  final TaskSection section;
  final String? softDeadlineText; // soft deadline label (e.g., "Try by Thu")
  final String? hardDeadlineText; // hard deadline label (e.g., "Due Mon 11:59 PM")
  final TaskPriority priority;
  TaskStatus status;
}

// ------- SCREEN -------

class PrioritizerBody extends StatefulWidget {
  const PrioritizerBody({super.key});
  @override
  State<PrioritizerBody> createState() => _PrioritizerBodyState();
}

class _PrioritizerBodyState extends State<PrioritizerBody> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: ColoredBox(
        color: ProjectColors.pureBlackColor,
        child: SizedBox(
          width: width,
          height: height,
          child: SingleChildScrollView(child: PrioritizerScreen()),
        ),
      ),
    );
  }
}

class PrioritizerScreen extends StatefulWidget {
  const PrioritizerScreen({super.key});

  @override
  State<PrioritizerScreen> createState() => _PrioritizerScreenState();
}

class _PrioritizerScreenState extends State<PrioritizerScreen> {
  String _timeScope = 'today'; // "today" | "week"

  // Dummy data for now – replace with your real tasks later
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Submit ethics assignment',
      section: TaskSection.must,
      softDeadlineText: 'Try by Thu',
      hardDeadlineText: 'Due Mon 11:59 PM',
      priority: TaskPriority.high,
    ),
    Task(
      id: '2',
      title: 'Plan weekend trip',
      section: TaskSection.atRisk,
      softDeadlineText: 'Soft: Thu',
      hardDeadlineText: 'Hard: Mon',
      priority: TaskPriority.high,
    ),
    Task(
      id: '3',
      title: 'Grocery shopping',
      section: TaskSection.atRisk,
      softDeadlineText: 'Soft: Fri',
      hardDeadlineText: 'Hard: Sun',
      priority: TaskPriority.medium,
    ),
    Task(
      id: '4',
      title: 'Order supplies',
      section: TaskSection.ifTime,
      softDeadlineText: 'Soft: Apr 30',
      hardDeadlineText: 'Hard: May 5',
      priority: TaskPriority.low,
    ),
    Task(
      id: '5',
      title: 'Move stuff to storage',
      section: TaskSection.ifTime,
      softDeadlineText: null,
      hardDeadlineText: 'No deadline',
      priority: TaskPriority.low,
    ),
  ];

  // ------- derived numbers for chips / summary -------

  int get _mustCount => _tasks.where((t) => t.section == TaskSection.must && t.status != TaskStatus.completed).length;

  int get _shouldCount => _tasks.where((t) => t.section == TaskSection.atRisk && t.status != TaskStatus.completed).length;

  int get _ifTimeCount => _tasks.where((t) => t.section == TaskSection.ifTime && t.status != TaskStatus.completed).length;

  int get _completedCount => _tasks.where((t) => t.status == TaskStatus.completed).length;

  int get _totalCount => _tasks.length;

  Task? get _firstMustTask {
    final list = _tasks.where((t) => t.section == TaskSection.must && t.status != TaskStatus.completed).toList();
    if (list.isEmpty) return null;
    // could sort by priority later, for now just first
    return list.first;
  }

  List<Task> get _atRiskTasks => _tasks.where((t) => t.section == TaskSection.atRisk && t.status != TaskStatus.completed).toList();

  List<Task> get _ifTimeTasks => _tasks.where((t) => t.section == TaskSection.ifTime && t.status != TaskStatus.completed).toList();

  // ------- actions -------

  void _toggleScope(String key) {
    setState(() {
      _timeScope = key;
    });
  }

  Future<void> _handleStartOrDone(Task task) async {
    if (task.status == TaskStatus.pending) {
      setState(() {
        task.status = TaskStatus.inProgress;
      });
      return;
    }

    // in progress -> confirm complete
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ProjectColors.blackColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(width * 0.04, height * 0.02, width * 0.04, height * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: 'Finish this task?',
                fontSize: 0.022,
                fontWeight: FontWeight.w600,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(height: height * 0.008),
              textWidget(
                text: 'Mark "${task.title}" as completed and remove it from today’s plan.',
                fontSize: 0.016,
                color: ProjectColors.whiteColor.withOpacity(0.75),
              ),
              SizedBox(height: height * 0.02),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProjectColors.greenColor,
                    foregroundColor: ProjectColors.pureBlackColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: EdgeInsets.symmetric(vertical: height * 0.014),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: textWidget(
                    text: 'Mark as completed',
                    fontSize: 0.018,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.pureBlackColor,
                  ),
                ),
              ),
              SizedBox(height: height * 0.01),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: textWidget(
                  text: 'Cancel',
                  fontSize: 0.016,
                  color: ProjectColors.whiteColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      _completeTask(task);
    }
  }

  void _completeTask(Task task) {
    setState(() {
      task.status = TaskStatus.completed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ProjectColors.blackColor,
        content: textWidget(
          text: 'Task completed',
          fontSize: 0.016,
          color: ProjectColors.whiteColor,
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: ProjectColors.greenColor,
          onPressed: () {
            setState(() {
              task.status = TaskStatus.pending;
            });
          },
        ),
      ),
    );
  }

  void _showTaskActions(Task task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ProjectColors.blackColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: height * 0.01),
                child: Container(
                  width: width * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ProjectColors.pureBlackColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              _actionTile(
                icon: Icons.check_circle_outline,
                label: 'Mark as completed',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _completeTask(task);
                },
              ),
              _actionTile(
                icon: Icons.snooze,
                label: 'Snooze soft deadline',
                onTap: () {
                  Navigator.of(ctx).pop();
                  // you can adjust softDeadlineText here when you implement real logic
                },
              ),
              _actionTile(
                icon: Icons.edit_outlined,
                label: 'Edit task',
                onTap: () {
                  Navigator.of(ctx).pop();
                  // TODO: open edit flow
                },
              ),
              _actionTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                destructive: true,
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _tasks.removeWhere((t) => t.id == task.id);
                  });
                },
              ),
              SizedBox(height: height * 0.015),
            ],
          ),
        );
      },
    );
  }

  ListTile _actionTile({
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
        fontSize: 0.018,
        color: destructive ? ProjectColors.errorColor : ProjectColors.whiteColor,
      ),
    );
  }

  // ------- build -------

  @override
  Widget build(BuildContext context) {
    final mustTask = _firstMustTask;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * .02),
          _buildHeader(),
          SizedBox(height: height * .02),
          _buildSummaryCard(),
          SizedBox(height: height * .02),
          _buildMustSection(mustTask),
          SizedBox(height: height * .02),
          _buildLowerSections(),
        ],
      ),
    );

    // floatingActionButton: FloatingActionButton(
    //   backgroundColor: ProjectColors.greenColor,
    //   foregroundColor: ProjectColors.pureBlackColor,
    //   onPressed: () {
    //     // TODO: open add-task bottom sheet
    //   },
    //   child: const Icon(Icons.add),
    // ),
  }

  // ------- header + summary -------

  Widget _buildHeader() {
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
              _scopeChip('today', 'Today'),
              SizedBox(width: width * 0.01),
              _scopeChip('week', 'Week'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scopeChip(String key, String label) {
    final selected = _timeScope == key;
    return GestureDetector(
      onTap: () => _toggleScope(key),
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

  Widget _buildSummaryCard() {
    final completionRatio = _totalCount == 0 ? 0.0 : _completedCount / _totalCount;

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
              _summaryChip(
                label: 'Must: $_mustCount',
                bg: ProjectColors.errorColor.withOpacity(0.2),
                textColor: ProjectColors.errorColor,
              ),
              SizedBox(width: width * 0.02),
              _summaryChip(
                label: 'Should: $_shouldCount',
                bg: ProjectColors.yellowColor.withOpacity(0.25),
                textColor: ProjectColors.yellowColor,
              ),
              SizedBox(width: width * 0.02),
              _summaryChip(
                label: 'If time: $_ifTimeCount',
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
            text: 'Completed $_completedCount / Total $_totalCount',
            fontSize: 0.016,
            color: ProjectColors.whiteColor,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required Color bg,
    required Color textColor,
  }) {
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

  // ------- sections -------

  Widget _buildMustSection(Task? mustTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: 'Must do now',
          fontSize: 0.022,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor,
        ),
        SizedBox(height: height * 0.004),
        textWidget(
          text: 'Hard deadlines or critical overdue tasks.',
          fontSize: 0.016,
          color: ProjectColors.whiteColor.withOpacity(0.7),
        ),
        SizedBox(height: height * 0.012),
        if (mustTask == null)
          textWidget(
            text: 'Nothing urgent. Focus on “At risk” tasks.',
            fontSize: 0.016,
            color: ProjectColors.whiteColor.withOpacity(0.6),
          )
        else
          _mustTaskCard(mustTask),
      ],
    );
  }

  Widget _mustTaskCard(Task task) {
    return DarkCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onLongPress: () => _showTaskActions(task),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: textWidget(
                          text: task.title,
                          fontSize: 0.018,
                          fontWeight: FontWeight.w600,
                          color: ProjectColors.whiteColor,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      if (task.softDeadlineText != null)
                        _pill(
                          task.softDeadlineText!,
                          bg: ProjectColors.pureBlackColor,
                          textColor: ProjectColors.whiteColor.withOpacity(0.8),
                        ),
                    ],
                  ),
                  SizedBox(height: height * 0.005),
                  if (task.hardDeadlineText != null)
                    textWidget(
                      text: task.hardDeadlineText!,
                      fontSize: 0.016,
                      color: ProjectColors.yellowColor,
                    ),
                  SizedBox(height: height * 0.006),
                  textWidget(
                    text: task.status == TaskStatus.pending ? 'Not started' : 'In progress',
                    fontSize: 0.015,
                    color: ProjectColors.whiteColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            SizedBox(width: width * 0.03),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProjectColors.greenColor,
                foregroundColor: ProjectColors.pureBlackColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.06,
                  vertical: height * 0.01,
                ),
              ),
              onPressed: () => _handleStartOrDone(task),
              child: textWidget(
                text: task.status == TaskStatus.pending ? 'Start' : 'Done',
                fontSize: 0.017,
                fontWeight: FontWeight.w600,
                color: ProjectColors.pureBlackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, {required Color bg, required Color textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.022,
        vertical: height * 0.004,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: textWidget(
        text: label,
        fontSize: 0.013,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLowerSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: 'At risk – do soon',
          fontSize: 0.022,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor,
        ),
        SizedBox(height: height * 0.004),
        textWidget(
          text: 'You’re between soft and hard deadlines.',
          fontSize: 0.016,
          color: ProjectColors.whiteColor.withOpacity(0.7),
        ),
        SizedBox(height: height * 0.012),
        ..._atRiskTasks.map(_atRiskCard).toList(),
        SizedBox(height: height * 0.022),
        textWidget(
          text: 'If time',
          fontSize: 0.022,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor,
        ),
        SizedBox(height: height * 0.004),
        textWidget(
          text: 'Do these when you clear the urgent stuff.',
          fontSize: 0.016,
          color: ProjectColors.whiteColor.withOpacity(0.7),
        ),
        SizedBox(height: height * 0.012),
        ..._ifTimeTasks.map(_ifTimeCard).toList(),
        SizedBox(height: height * 0.03),
      ],
    );
  }

  Widget _atRiskCard(Task task) {
    return Padding(
      padding: EdgeInsets.only(top: height * .01),
      child: DarkCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onLongPress: () => _showTaskActions(task),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: task.title,
                      fontSize: 0.018,
                      fontWeight: FontWeight.w600,
                      color: ProjectColors.whiteColor,
                    ),
                    SizedBox(height: height * 0.004),
                    textWidget(
                      text:
                          '${task.softDeadlineText ?? ''}${task.softDeadlineText != null && task.hardDeadlineText != null ? '  •  ' : ''}${task.hardDeadlineText ?? ''}',
                      fontSize: 0.015,
                      color: ProjectColors.whiteColor.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
              _priorityChip(task.priority),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ifTimeCard(Task task) {
    return DarkCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onLongPress: () => _showTaskActions(task),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: task.title,
                    fontSize: 0.018,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.whiteColor,
                  ),
                  SizedBox(height: height * 0.004),
                  if (task.softDeadlineText != null || task.hardDeadlineText != null)
                    textWidget(
                      text:
                          '${task.softDeadlineText ?? ''}${task.softDeadlineText != null && task.hardDeadlineText != null ? '  •  ' : ''}${task.hardDeadlineText ?? ''}',
                      fontSize: 0.015,
                      color: ProjectColors.whiteColor.withOpacity(0.7),
                    ),
                ],
              ),
            ),
            _priorityChip(task.priority),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(TaskPriority priority) {
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
}
