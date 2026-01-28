import 'package:emptyproject/BaseScreen.dart';
import 'package:emptyproject/models/Projection%20Model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/Priotizer model.dart';
import '../Constant UI.dart';
import '../Constants.dart';
import '../Controllers.dart';

class AddTask extends StatefulWidget {
  final Task? task; // null = create, not null = edit

  const AddTask({super.key, this.task});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
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
      priotizer.priority.value = t.priority;
      priotizer.controllers[2].controller.text = priotizer.priority.value.toString();
      priotizer.controllers[3].controller.text = formatDate(t.hardDeadline);
      priotizer.controllers[3].pickedDate = t.hardDeadline;
    } else {
      // optional: clear fields when creating new
      priotizer.controllers[0].controller.text = '';
      priotizer.controllers[1].controller.text = '';
      priotizer.controllers[2].controller.text = '';
      priotizer.controllers[3].controller.text = '';
      priotizer.priority.value = GoalPriority.low;
    }
  }

  Future<void> _pickHardDeadline() async {
    final picked = await AppDatePicker.pickDate(
      title: "Pick deadline",
      initialDate: DateTime.now(),
      minDate: DateTime.now(),
      maxDate: DateTime(DateTime.now().year + 5),
    );

    if (picked == null) return;

    setState(() {
      priotizer.controllers[3].controller.text = formatDate(picked);
      priotizer.controllers[3].pickedDate = picked;
      priotizer.controllers.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: isEdit ? 'Edit Task' : 'Create Task',
      body: Obx(
        () => SizedBox(
          height: height * .65,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: height * .02),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height * 0.03),
                PriorityRow(
                  selected: priotizer.priority.value,
                  onChanged: (p) {
                    priotizer.priority.value = p;
                  },
                ),
                SizedBox(height: height * 0.03),
                DarkTextField(
                  controller: priotizer.controllers[0].controller,
                  hintText: 'Give this task a clear name',
                  maxLines: 1,
                  title: 'Task title',
                ),
                SizedBox(height: height * 0.01),
                DarkTextField(
                  controller: priotizer.controllers[1].controller,
                  hintText: 'Why is this goal important?',
                  maxLines: 2,
                  title: 'Description (optional)',
                ),
                SizedBox(height: height * 0.01),
                DarkTextField(
                  title: 'Deadline',
                  hintText: priotizer.controllers[3].controller.text.isEmpty ? '5' : priotizer.controllers[3].controller.text,
                  onTap: () async {
                    final res = await AppPicker.pick(mode: PickerMode.date, title: "Date of Charged");
                    if (res != null) {
                      priotizer.controllers[3].controller.text = formatDate(res.dateTime!);
                      priotizer.controllers[3].pickedDate = res.dateTime!;
                      priotizer.controllers.refresh();
                    }
                  },
                  trailing: Icon(Icons.calendar_month_rounded, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                ),
                SizedBox(height: height * 0.02),
                Center(
                  child: normalButton(
                    title: isEdit ? "Save Changes" : "Create Task",
                    bColor: ProjectColors.greenColor,
                    cWidth: .7,
                    loading: false,
                    callback: () async {
                      if (priotizer.controllers.any((t) => t.controller.text.isEmpty)) {
                        showSnackBar("Missing Info", "Please fill all required fields");
                        return;
                      }
                      for (var files in priotizer.controllers) {
                        print(files.controller.text);
                      }
                      print(priotizer.controllers);
                      if (isEdit) {
                        await priotizer.editTaskFromUI();
                      } else {
                        await priotizer.addTaskFromUI();
                      }
                    },
                  ),
                ),
              ],
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

  // Widget _priorityRow() {
  //   return Row(
  //     children: priotizer.priorityType.map((type) {
  //       final bool active = priotizer.taskPriority.value == type['Type'];
  //       final Color activeColor = type['Color']; // your map color
  //
  //       return Expanded(
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: width * 0.01),
  //           child: InkWell(
  //             borderRadius: BorderRadius.circular(999),
  //             onTap: () {
  //               priotizer.taskPriority.value = type['Type'];
  //               priotizer.controllers[2].controller.text = type['Title'];
  //             },
  //             child: Container(
  //               padding: EdgeInsets.symmetric(vertical: height * 0.012),
  //               decoration: BoxDecoration(
  //                 color: active ? activeColor : Colors.white.withOpacity(0.03),
  //                 borderRadius: BorderRadius.circular(999),
  //                 border: Border.all(
  //                   color: active ? Colors.transparent : Colors.white.withOpacity(0.10),
  //                 ),
  //               ),
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   if (type['Title'].toString().toLowerCase() == "high")
  //                     Padding(
  //                       padding: const EdgeInsets.only(right: 8),
  //                       child: Container(
  //                         width: 7,
  //                         height: 7,
  //                         decoration: BoxDecoration(
  //                           color: ProjectColors.errorColor,
  //                           shape: BoxShape.circle,
  //                         ),
  //                       ),
  //                     ),
  //                   textWidget(
  //                     text: type['Title'],
  //                     color: active ? ProjectColors.pureBlackColor : ProjectColors.whiteColor,
  //                     fontWeight: FontWeight.w500,
  //                     fontSize: 0.017,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }
}
