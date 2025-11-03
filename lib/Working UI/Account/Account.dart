import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_controller.dart';
import '../../models/job.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();

    return Obx(() {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: ColoredBox(
          color: ProjectColors.pureBlackColor,
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * .02, horizontal: width * .01),
                    child: textWidget(
                      text: "ACTIVE JOBS",
                      fontSize: .03,
                      color: ProjectColors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...app.jobs.map((a) => Container(
                        decoration: BoxDecoration(color: ProjectColors.greenColor, borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .01),
                        margin: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .02),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.join_full,
                                  color: ProjectColors.whiteColor,
                                  size: height * .03,
                                ),
                                SizedBox(width: width * .02),
                                textWidget(
                                  text: a.name,
                                  fontSize: .03,
                                  color: ProjectColors.whiteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            SizedBox(height: height * .02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CardFields(title: 'Wage / hr', subTitle: a.wage.toString()),
                                CardFields(title: 'Last Deposit', subTitle: a.lastPaychequeIso.toString() ?? DateTime.now().toString()),
                              ],
                            ),
                            Divider(color: ProjectColors.whiteColor.withOpacity(.5)),
                            SizedBox(height: height * .01),
                            textWidget(
                              text: 'Color',
                              fontSize: .015,
                              color: ProjectColors.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final hex in app.colorChoices)
                                  GestureDetector(
                                    onTap: () {
                                      // setState(() => widget.job.colorHex = hex)
                                    },
                                    child: Container(
                                      width: width * .05,
                                      height: height * .025,
                                      decoration: BoxDecoration(
                                        color: c.jobColor(hex),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: hex == a.colorHex ? ProjectColors.whiteColor : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Divider(color: ProjectColors.whiteColor.withOpacity(.5)),
                            SizedBox(height: height * .01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CardFields(title: 'Week Start', subTitle: 'Monday'),
                                CardFields(title: 'Pay Frequency', subTitle: 'Weekly'),
                              ],
                            ),
                            Divider(color: ProjectColors.whiteColor.withOpacity(.5)),
                            SizedBox(height: height * .01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    textWidget(
                                      text: 'Stat Pay',
                                      fontSize: .015,
                                      color: ProjectColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textWidget(
                                      text: '1.5',
                                      fontSize: .015,
                                      color: ProjectColors.whiteColor,
                                    ),
                                  ],
                                ),
                                normalButton(title: "SAVE", cWidth: .2, invertColors: true),
                              ],
                            ),
                          ],
                        ),
                        // child: Padding(
                        //   padding: const EdgeInsets.all(12),
                        //   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        //     TextField(
                        //       controller: nameCtl,
                        //       decoration: const InputDecoration(labelText: 'Job name', isDense: true),
                        //     ),
                        //     const SizedBox(height: 10),
                        //     TextField(
                        //       controller: wageCtl,
                        //       keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        //       decoration: const InputDecoration(labelText: 'Wage / hr (CAD)', isDense: true),
                        //     ),
                        //     const SizedBox(height: 12),
                        //
                        //     Text('Colour', style: Theme.of(context).textTheme.labelMedium),
                        //     const SizedBox(height: 6),
                        //     Wrap(
                        //       spacing: 8,
                        //       runSpacing: 8,
                        //       children: [
                        //         for (final hex in colorChoices)
                        //           GestureDetector(
                        //             onTap: () => setState(() => widget.job.colorHex = hex),
                        //             child: Container(
                        //               width: 28,
                        //               height: 28,
                        //               decoration: BoxDecoration(
                        //                 color: c.jobColor(hex),
                        //                 shape: BoxShape.circle,
                        //                 border: Border.all(
                        //                   color: hex == widget.job.colorHex ? Colors.white : Colors.transparent,
                        //                   width: 2,
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //       ],
                        //     ),
                        //     const SizedBox(height: 16),
                        //
                        //     LayoutBuilder(builder: (ctx, cons) {
                        //       final twoCols = cons.maxWidth >= 360;
                        //       final fieldW = twoCols ? (cons.maxWidth - 8) / 2 : cons.maxWidth;
                        //       return Wrap(
                        //         spacing: 8,
                        //         runSpacing: 12,
                        //         children: [
                        //           SizedBox(
                        //             width: fieldW,
                        //             child: DropdownButtonFormField<int>(
                        //               value: weekVal,
                        //               decoration: const InputDecoration(labelText: 'Week starts', isDense: true),
                        //               items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text(daysShort[i]))),
                        //               onChanged: (v) => setState(() => widget.job.weekStartDOW = v ?? 1),
                        //             ),
                        //           ),
                        //           SizedBox(
                        //             width: fieldW,
                        //             child: DropdownButtonFormField<String>(
                        //               value: freqVal,
                        //               decoration: const InputDecoration(labelText: 'Pay frequency', isDense: true),
                        //               items: const [
                        //                 DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        //                 DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
                        //               ],
                        //               onChanged: (v) => setState(() => widget.job.payFrequency = v ?? 'weekly'),
                        //             ),
                        //           ),
                        //
                        //           // Last paycheque: date picker (read-only)
                        //           SizedBox(
                        //             width: fieldW,
                        //             child: TextField(
                        //               controller: lastPayCtl,
                        //               readOnly: true,
                        //               decoration: const InputDecoration(
                        //                 labelText: 'Last paycheque',
                        //                 hintText: 'YYYY-MM-DD',
                        //                 isDense: true,
                        //                 suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                        //               ),
                        //               onTap: () async {
                        //                 final existing = lastPayCtl.text.trim();
                        //                 final initial = (existing.isNotEmpty) ? DateTime.tryParse(existing) ?? DateTime.now() : DateTime.now();
                        //
                        //                 final picked = await showDatePicker(
                        //                   context: context,
                        //                   initialDate: initial,
                        //                   firstDate: DateTime(2020, 1, 1),
                        //                   lastDate: DateTime(2035, 12, 31),
                        //                   helpText: 'Select last paycheque date',
                        //                   builder: (ctx, child) => Theme(
                        //                     data: Theme.of(ctx).copyWith(
                        //                       colorScheme: Theme.of(ctx).colorScheme.copyWith(
                        //                             primary: const Color(0xFF16A34A),
                        //                           ),
                        //                     ),
                        //                     child: child!,
                        //                   ),
                        //                 );
                        //                 if (picked != null) {
                        //                   lastPayCtl.text = picked.toIso8601String().split('T').first;
                        //                   setState(() {});
                        //                 }
                        //               },
                        //             ),
                        //           ),
                        //         ],
                        //       );
                        //     }),
                        //
                        //     const SizedBox(height: 16),
                        //     const Divider(),
                        //     const SizedBox(height: 8),
                        //
                        //     Text(
                        //       'Stat pay',
                        //       style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        //     ),
                        //     const SizedBox(height: 8),
                        //
                        //     // Only the multiplier here (individual stat dates are set per-shift)
                        //     TextField(
                        //       controller: statMultCtl,
                        //       keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        //       decoration: const InputDecoration(
                        //         labelText: 'Multiplier',
                        //         hintText: 'e.g. 1.5',
                        //         isDense: true,
                        //       ),
                        //     ),
                        //
                        //     const SizedBox(height: 12),
                        //     Row(children: [
                        //       FilledButton.icon(
                        //         onPressed: () {
                        //           widget.job.name = nameCtl.text.trim();
                        //           widget.job.wage = double.tryParse(wageCtl.text) ?? widget.job.wage;
                        //           widget.job.lastPaychequeIso = lastPayCtl.text.trim().isEmpty ? null : lastPayCtl.text.trim();
                        //           widget.job.statMultiplier = double.tryParse(statMultCtl.text) ?? widget.job.statMultiplier;
                        //
                        //           final ctrl = Get.find<AppController>();
                        //           final i = ctrl.jobs.indexWhere((e) => e.id == widget.job.id);
                        //           if (i >= 0) ctrl.jobs[i] = widget.job;
                        //         },
                        //         icon: const Icon(Icons.save),
                        //         label: const Text('Save'),
                        //       ),
                        //       const Spacer(),
                        //       TextButton.icon(
                        //         onPressed: () => Get.find<AppController>().removeJob(widget.job.id),
                        //         icon: const Icon(Icons.delete_outline),
                        //         label: const Text('Delete Job'),
                        //       ),
                        //     ]),
                        //   ]),
                        // ),
                      )),
                  SizedBox(height: height * .02),
                  Center(child: normalButton(title: "New Job", cWidth: .5, invertColors: true)),
                  // ListView.separated(
                  //   padding: const EdgeInsets.all(12),
                  //   itemCount: app.jobs.length + 1,
                  //   separatorBuilder: (_, __) => SizedBox(height: height * .01),
                  //   itemBuilder: (_, i) {
                  //     if (i < jobs.length) {
                  //       return _JobCard(key: ValueKey(jobs[i].id), job: jobs[i]);
                  //     }
                  //     return Center(
                  //       child: OutlinedButton.icon(
                  //         onPressed: () => c.addJob(
                  //           Job(
                  //             id: DateTime.now().millisecondsSinceEpoch.toString(),
                  //             name: 'New Job',
                  //             colorHex: c.randomColorHex(),
                  //             wage: 0,
                  //             payFrequency: 'weekly',
                  //             lastPaychequeIso: null,
                  //             weekStartDOW: 1,
                  //             statMultiplier: 1.5,
                  //             statDays: [],
                  //           ),
                  //         ),
                  //         icon: const Icon(Icons.add),
                  //         label: const Text('Add Job'),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// class _JobCard extends StatefulWidget {
//   final Job job;
//   const _JobCard({super.key, required this.job});
//
//   @override
//   State<_JobCard> createState() => _JobCardState();
// }
//
// class _JobCardState extends State<_JobCard> {
//   late final TextEditingController nameCtl;
//   late final TextEditingController wageCtl;
//   late final TextEditingController lastPayCtl;
//   late final TextEditingController statMultCtl;
//
//   @override
//   void initState() {
//     super.initState();
//     nameCtl = TextEditingController(text: widget.job.name);
//     wageCtl = TextEditingController(text: widget.job.wage.toStringAsFixed(2));
//     lastPayCtl = TextEditingController(text: widget.job.lastPaychequeIso ?? '');
//     statMultCtl = TextEditingController(text: widget.job.statMultiplier.toStringAsFixed(2));
//
//     if (widget.job.weekStartDOW < 1 || widget.job.weekStartDOW > 7) widget.job.weekStartDOW = 1;
//     if (widget.job.payFrequency != 'weekly' && widget.job.payFrequency != 'biweekly') {
//       widget.job.payFrequency = 'weekly';
//     }
//     // statDays stays but we no longer edit individual dates here (done in Shift form)
//   }
//
//   @override
//   void dispose() {
//     nameCtl.dispose();
//     wageCtl.dispose();
//     lastPayCtl.dispose();
//     statMultCtl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final c = Get.find<AppController>();
//     final daysShort = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//     final colorChoices = ['#16a34a', '#2563eb', '#e11d48', '#0ea5e9', '#10b981', '#f59e0b', '#8b5cf6', '#14b8a6', '#ef4444'];
//
//     final weekVal = (widget.job.weekStartDOW >= 1 && widget.job.weekStartDOW <= 7) ? widget.job.weekStartDOW : 1;
//     final freqVal = (widget.job.payFrequency == 'weekly' || widget.job.payFrequency == 'biweekly') ? widget.job.payFrequency : 'weekly';
//
//     return Container(
//       decoration: BoxDecoration(color: ProjectColors.greenColor, borderRadius: BorderRadius.circular(20)),
//       padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .01),
//       margin: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .02),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.join_full,
//                 color: ProjectColors.whiteColor,
//                 size: height * .03,
//               ),
//               textWidget(
//                 text: 'Starbucks',
//                 fontSize: .03,
//                 color: ProjectColors.whiteColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ],
//           ),
//           SizedBox(height: height * .02),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               CardFields(title: 'Wage / hr', subTitle: '\$ 18'),
//               CardFields(title: 'Last Deposit', subTitle: 'Nov 1'),
//             ],
//           ),
//           Divider(color: ProjectColors.whiteColor.withOpacity(.5)),
//           SizedBox(height: height * .01),
//           textWidget(
//             text: 'Color',
//             fontSize: .015,
//             color: ProjectColors.whiteColor,
//             fontWeight: FontWeight.bold,
//           ),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: [
//               for (final hex in colorChoices)
//                 GestureDetector(
//                   onTap: () => setState(() => widget.job.colorHex = hex),
//                   child: Container(
//                     width: width * .05,
//                     height: height * .025,
//                     decoration: BoxDecoration(
//                       color: c.jobColor(hex),
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: hex == widget.job.colorHex ? ProjectColors.whiteColor : Colors.transparent,
//                         width: 2,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           Divider(color: ProjectColors.whiteColor.withOpacity(.5)),
//           SizedBox(height: height * .01),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               CardFields(title: 'Week Start', subTitle: 'Thursday'),
//               CardFields(title: 'Pay Frequency', subTitle: 'Weekly'),
//             ],
//           ),
//           Divider(color: ProjectColors.whiteColor.withOpacity(.5)),
//           SizedBox(height: height * .01),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   textWidget(
//                     text: 'Stat Pay',
//                     fontSize: .015,
//                     color: ProjectColors.whiteColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textWidget(
//                     text: '1.5',
//                     fontSize: .015,
//                     color: ProjectColors.whiteColor,
//                   ),
//                 ],
//               ),
//               normalButton(title: "SAVE", cWidth: .2, invertColors: true),
//             ],
//           ),
//         ],
//       ),
//       // child: Padding(
//       //   padding: const EdgeInsets.all(12),
//       //   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       //     TextField(
//       //       controller: nameCtl,
//       //       decoration: const InputDecoration(labelText: 'Job name', isDense: true),
//       //     ),
//       //     const SizedBox(height: 10),
//       //     TextField(
//       //       controller: wageCtl,
//       //       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//       //       decoration: const InputDecoration(labelText: 'Wage / hr (CAD)', isDense: true),
//       //     ),
//       //     const SizedBox(height: 12),
//       //
//       //     Text('Colour', style: Theme.of(context).textTheme.labelMedium),
//       //     const SizedBox(height: 6),
//       //     Wrap(
//       //       spacing: 8,
//       //       runSpacing: 8,
//       //       children: [
//       //         for (final hex in colorChoices)
//       //           GestureDetector(
//       //             onTap: () => setState(() => widget.job.colorHex = hex),
//       //             child: Container(
//       //               width: 28,
//       //               height: 28,
//       //               decoration: BoxDecoration(
//       //                 color: c.jobColor(hex),
//       //                 shape: BoxShape.circle,
//       //                 border: Border.all(
//       //                   color: hex == widget.job.colorHex ? Colors.white : Colors.transparent,
//       //                   width: 2,
//       //                 ),
//       //               ),
//       //             ),
//       //           ),
//       //       ],
//       //     ),
//       //     const SizedBox(height: 16),
//       //
//       //     LayoutBuilder(builder: (ctx, cons) {
//       //       final twoCols = cons.maxWidth >= 360;
//       //       final fieldW = twoCols ? (cons.maxWidth - 8) / 2 : cons.maxWidth;
//       //       return Wrap(
//       //         spacing: 8,
//       //         runSpacing: 12,
//       //         children: [
//       //           SizedBox(
//       //             width: fieldW,
//       //             child: DropdownButtonFormField<int>(
//       //               value: weekVal,
//       //               decoration: const InputDecoration(labelText: 'Week starts', isDense: true),
//       //               items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text(daysShort[i]))),
//       //               onChanged: (v) => setState(() => widget.job.weekStartDOW = v ?? 1),
//       //             ),
//       //           ),
//       //           SizedBox(
//       //             width: fieldW,
//       //             child: DropdownButtonFormField<String>(
//       //               value: freqVal,
//       //               decoration: const InputDecoration(labelText: 'Pay frequency', isDense: true),
//       //               items: const [
//       //                 DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
//       //                 DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
//       //               ],
//       //               onChanged: (v) => setState(() => widget.job.payFrequency = v ?? 'weekly'),
//       //             ),
//       //           ),
//       //
//       //           // Last paycheque: date picker (read-only)
//       //           SizedBox(
//       //             width: fieldW,
//       //             child: TextField(
//       //               controller: lastPayCtl,
//       //               readOnly: true,
//       //               decoration: const InputDecoration(
//       //                 labelText: 'Last paycheque',
//       //                 hintText: 'YYYY-MM-DD',
//       //                 isDense: true,
//       //                 suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
//       //               ),
//       //               onTap: () async {
//       //                 final existing = lastPayCtl.text.trim();
//       //                 final initial = (existing.isNotEmpty) ? DateTime.tryParse(existing) ?? DateTime.now() : DateTime.now();
//       //
//       //                 final picked = await showDatePicker(
//       //                   context: context,
//       //                   initialDate: initial,
//       //                   firstDate: DateTime(2020, 1, 1),
//       //                   lastDate: DateTime(2035, 12, 31),
//       //                   helpText: 'Select last paycheque date',
//       //                   builder: (ctx, child) => Theme(
//       //                     data: Theme.of(ctx).copyWith(
//       //                       colorScheme: Theme.of(ctx).colorScheme.copyWith(
//       //                             primary: const Color(0xFF16A34A),
//       //                           ),
//       //                     ),
//       //                     child: child!,
//       //                   ),
//       //                 );
//       //                 if (picked != null) {
//       //                   lastPayCtl.text = picked.toIso8601String().split('T').first;
//       //                   setState(() {});
//       //                 }
//       //               },
//       //             ),
//       //           ),
//       //         ],
//       //       );
//       //     }),
//       //
//       //     const SizedBox(height: 16),
//       //     const Divider(),
//       //     const SizedBox(height: 8),
//       //
//       //     Text(
//       //       'Stat pay',
//       //       style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
//       //     ),
//       //     const SizedBox(height: 8),
//       //
//       //     // Only the multiplier here (individual stat dates are set per-shift)
//       //     TextField(
//       //       controller: statMultCtl,
//       //       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//       //       decoration: const InputDecoration(
//       //         labelText: 'Multiplier',
//       //         hintText: 'e.g. 1.5',
//       //         isDense: true,
//       //       ),
//       //     ),
//       //
//       //     const SizedBox(height: 12),
//       //     Row(children: [
//       //       FilledButton.icon(
//       //         onPressed: () {
//       //           widget.job.name = nameCtl.text.trim();
//       //           widget.job.wage = double.tryParse(wageCtl.text) ?? widget.job.wage;
//       //           widget.job.lastPaychequeIso = lastPayCtl.text.trim().isEmpty ? null : lastPayCtl.text.trim();
//       //           widget.job.statMultiplier = double.tryParse(statMultCtl.text) ?? widget.job.statMultiplier;
//       //
//       //           final ctrl = Get.find<AppController>();
//       //           final i = ctrl.jobs.indexWhere((e) => e.id == widget.job.id);
//       //           if (i >= 0) ctrl.jobs[i] = widget.job;
//       //         },
//       //         icon: const Icon(Icons.save),
//       //         label: const Text('Save'),
//       //       ),
//       //       const Spacer(),
//       //       TextButton.icon(
//       //         onPressed: () => Get.find<AppController>().removeJob(widget.job.id),
//       //         icon: const Icon(Icons.delete_outline),
//       //         label: const Text('Delete Job'),
//       //       ),
//       //     ]),
//       //   ]),
//       // ),
//     );
//   }
// }

class CardFields extends StatelessWidget {
  final String? title;
  final String? subTitle;

  CardFields({this.title, this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: title,
          fontSize: .015,
          color: ProjectColors.whiteColor,
          fontWeight: FontWeight.bold,
        ),
        textWidget(
          text: subTitle,
          fontSize: .015,
          color: ProjectColors.whiteColor,
        ),
      ],
    );
  }
}
