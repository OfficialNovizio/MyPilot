// import 'package:emptyproject/BaseScreen.dart';
// import 'package:emptyproject/Working%20UI/Controllers.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../models/Debt Model.dart';
// import '../../../Constant UI.dart';
// import '../../../Constants.dart';
// import '../Credit Card Debt/Payment Schedule.dart';
// import '../Credit Card Debt/Payoff Plan.dart';
// import '../Credit Card Debt/Record Payment.dart';
//
// // ----------------------------
// // DEBT DETAIL SCREEN
// // ----------------------------
//
// class DebtDetailScreen extends StatefulWidget {
//   const DebtDetailScreen({super.key});
//
//   @override
//   State<DebtDetailScreen> createState() => _DebtDetailScreenState();
// }
//
// class _DebtDetailScreenState extends State<DebtDetailScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await debtV2.buildScheduleAndSave(months: 120);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BaseScreen(
//       body: Obx(() {
//         final d = debtV2.selectedDebt.value;
//         if (d == null) {
//           return Center(
//             child: textWidget(
//               text: "No debt selected",
//               color: ProjectColors.whiteColor.withOpacity(.7),
//               fontSize: .018,
//               fontWeight: FontWeight.w700,
//             ),
//           );
//         }
//
//         final paid = (d.initialBalance - d.balance).clamp(0, 1e12);
//         final pct = d.initialBalance <= 0 ? 0.0 : (paid / d.initialBalance).clamp(0.0, 1.0);
//
//         return SingleChildScrollView(
//           padding: EdgeInsets.symmetric(vertical: height * .01),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _HeroCard(debt: d, pct: pct),
//               SizedBox(height: height * .01),
//               _SectionLabel("Actions"),
//               SizedBox(height: height * .01),
//               AddContent(
//                 title: "Payment Schedule",
//                 subTitle: "Upcoming payments & due dates",
//                 callback: () => Get.to(() => const DebtPaymentScheduleScreen()),
//                 icon: Icons.calendar_month_rounded,
//               ),
//               SizedBox(height: height * .01),
//               AddContent(
//                 icon: Icons.add_circle_outline_rounded,
//                 title: "Record Payment",
//                 subTitle: "Log a payment and update progress",
//                 callback: () => Get.to(() => const DebtRecordPaymentScreen()),
//               ),
//               SizedBox(height: height * .01),
//               AddContent(
//                 title: "View Payoff Plan",
//                 subTitle: "Projection + debt-free date",
//                 callback: () => Get.to(() => const DebtPayoffPlanScreen()),
//                 icon: Icons.calendar_month_rounded,
//               ),
//               SizedBox(height: height * .01),
//               _SectionLabel("Details"),
//               SizedBox(height: height * .01),
//               DarkCard(
//                 child: Column(
//                   children: [
//                     _DetailRow(label: "Type", value: d.type),
//                     divider(),
//                     _DetailRow(label: "APR", value: d.apr == 0 ? "0%" : "${d.apr.toStringAsFixed(1)}%"),
//                     divider(),
//                     _DetailRow(label: "Min Payment", value: money(d.minPayment)),
//                     divider(),
//                     // _DetailRow(
//                     //     label: "Due Day",
//                     //     value: d.dueDayOfMonth == null ? "None" : "${d.dueDayOfMonth}${DebtDetailScreen._suffix(d.dueDayOfMonth!)}"),
//                     divider(),
//                     _DetailRow(label: "Secured", value: d.secured ? "Yes" : "No"),
//                     divider(),
//                     _DetailRow(label: "Fixed Installment", value: d.fixedInstallment ? "Yes" : "No"),
//                     if (d.notes.trim().isNotEmpty) ...[
//                       divider(),
//                       _DetailRow(label: "Notes", value: d.notes.trim(), multiline: true),
//                     ],
//                   ],
//                 ),
//               ),
//               SizedBox(height: height * .01),
//               _SectionLabel("Recent Activity"),
//               SizedBox(height: height * .01),
//               _RecentPaymentsCard(payments: debtV2.payments),
//               SizedBox(height: height * .03),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }
//
// // ----------------------------
// // PIECES
// // ----------------------------
//
// class _HeroCard extends StatelessWidget {
//   final DebtItem debt;
//   final double pct;
//
//   const _HeroCard({required this.debt, required this.pct});
//
//   @override
//   Widget build(BuildContext context) {
//     final paid = (debt.initialBalance - debt.balance).clamp(0, 1e12);
//     final paidText = "${(pct * 100).round()}% paid";
//     final paidLine = "${money(paid.toDouble())} of ${money(debt.initialBalance)}";
//
//     return DarkCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 height: height * .05,
//                 width: height * .05,
//                 decoration: BoxDecoration(
//                   color: ProjectColors.whiteColor.withOpacity(.10),
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: ProjectColors.whiteColor.withOpacity(.12)),
//                 ),
//                 child: Icon(Icons.credit_card_rounded, color: ProjectColors.whiteColor.withOpacity(.85)),
//               ),
//               SizedBox(width: width * .03),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     textWidget(
//                       text: debt.name,
//                       fontSize: .022,
//                       fontWeight: FontWeight.w900,
//                       color: ProjectColors.whiteColor,
//                     ),
//                     SizedBox(height: height * .006),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .004),
//                       decoration: BoxDecoration(
//                         color: ProjectColors.whiteColor.withOpacity(.08),
//                         borderRadius: BorderRadius.circular(999),
//                         border: Border.all(color: ProjectColors.whiteColor.withOpacity(.10)),
//                       ),
//                       child: textWidget(
//                         text: debt.type,
//                         fontSize: .014,
//                         fontWeight: FontWeight.w800,
//                         color: ProjectColors.whiteColor.withOpacity(.8),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           SizedBox(height: height * .016),
//
//           textWidget(
//             text: money(debt.balance),
//             fontSize: .04,
//             fontWeight: FontWeight.w900,
//             color: ProjectColors.whiteColor,
//           ),
//
//           SizedBox(height: height * .006),
//           Row(
//             children: [
//               textWidget(
//                 text: paidText,
//                 fontSize: .016,
//                 fontWeight: FontWeight.w800,
//                 color: ProjectColors.whiteColor.withOpacity(.75),
//               ),
//               SizedBox(width: width * .02),
//               textWidget(
//                 text: "($paidLine)",
//                 fontSize: .015,
//                 fontWeight: FontWeight.w700,
//                 color: ProjectColors.whiteColor.withOpacity(.55),
//               ),
//             ],
//           ),
//
//           SizedBox(height: height * .014),
//
//           ClipRRect(
//             borderRadius: BorderRadius.circular(999),
//             child: LinearProgressIndicator(
//               value: pct,
//               minHeight: 8,
//               backgroundColor: ProjectColors.whiteColor.withOpacity(0.10),
//               valueColor: const AlwaysStoppedAnimation(ProjectColors.greenColor),
//             ),
//           ),
//
//           SizedBox(height: height * .012),
//
//           // quick “next” row
//           Row(
//             children: [
//               Icon(Icons.bolt_rounded, color: ProjectColors.yellowColor.withOpacity(.9), size: height * .02),
//               SizedBox(width: width * .02),
//               // Expanded(
//               //   child: textWidget(
//               //     text:
//               //         "Next: ${money(debt.minPayment)} • Due ${debt.dueDayOfMonth == null ? "None" : "${debt.dueDayOfMonth}${DebtDetailScreen._suffix(debt.dueDayOfMonth!)}"}",
//               //     fontSize: .016,
//               //     fontWeight: FontWeight.w700,
//               //     color: ProjectColors.whiteColor.withOpacity(.75),
//               //   ),
//               // ),
//               textWidget(
//                 text: debt.apr == 0 ? "0% APR" : "${debt.apr.toStringAsFixed(1)}% APR",
//                 fontSize: .015,
//                 fontWeight: FontWeight.w800,
//                 color: ProjectColors.whiteColor.withOpacity(.55),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _SectionLabel extends StatelessWidget {
//   final String text;
//   const _SectionLabel(this.text);
//
//   @override
//   Widget build(BuildContext context) {
//     return textWidget(
//       text: text,
//       fontSize: .02,
//       fontWeight: FontWeight.w900,
//       color: ProjectColors.whiteColor,
//     );
//   }
// }
//
// class _DetailRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool multiline;
//
//   const _DetailRow({
//     required this.label,
//     required this.value,
//     this.multiline = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
//       children: [
//         Expanded(
//           child: textWidget(
//             text: label,
//             fontSize: .016,
//             fontWeight: FontWeight.w700,
//             color: ProjectColors.whiteColor.withOpacity(.55),
//           ),
//         ),
//         SizedBox(width: width * .03),
//         Expanded(
//           child: textWidget(
//             text: value,
//             textAlign: TextAlign.end,
//             fontSize: .016,
//             fontWeight: FontWeight.w900,
//             color: ProjectColors.whiteColor.withOpacity(.85),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _RecentPaymentsCard extends StatelessWidget {
//   final List<DebtPayment> payments;
//   const _RecentPaymentsCard({required this.payments});
//
//   @override
//   Widget build(BuildContext context) {
//     if (payments.isEmpty) {
//       return DarkCard(
//         child: Row(
//           children: [
//             Icon(Icons.receipt_long_rounded, color: ProjectColors.whiteColor.withOpacity(.55), size: height * .022),
//             SizedBox(width: width * .03),
//             Expanded(
//               child: textWidget(
//                 text: "No payments recorded yet.",
//                 color: ProjectColors.whiteColor.withOpacity(.65),
//                 fontSize: .016,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     final showCount = payments.length > 4 ? 4 : payments.length;
//
//     return DarkCard(
//       child: Column(
//         children: [
//           for (int i = 0; i < showCount; i++) ...[
//             GestureDetector(
//               onTap: () {
//                 debtV2.deletePayment(payments[i].id);
//               },
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         textWidget(
//                           text: "${payments[i].date.month}/${payments[i].date.day}/${payments[i].date.year}",
//                           fontSize: .015,
//                           fontWeight: FontWeight.w700,
//                           color: ProjectColors.whiteColor.withOpacity(.55),
//                         ),
//                         SizedBox(height: height * .004),
//                         textWidget(
//                           text: payments[i].note.trim().isEmpty ? "Payment" : "Payment • ${payments[i].note}",
//                           fontSize: .017,
//                           fontWeight: FontWeight.w900,
//                           color: ProjectColors.whiteColor,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Spacer(),
//                   textWidget(
//                     text: "Tap to remove",
//                     fontSize: .014,
//                     fontWeight: FontWeight.w700,
//                     color: ProjectColors.whiteColor.withOpacity(.35),
//                   ),
//                   SizedBox(width: width * .03),
//                   textWidget(
//                     text: "-${money(payments[i].amount)}",
//                     fontSize: .018,
//                     fontWeight: FontWeight.w900,
//                     color: ProjectColors.greenColor.withOpacity(.9),
//                   ),
//                 ],
//               ),
//             ),
//             if (i != showCount - 1) divider(),
//           ],
//
//           // Optional “+ more” footer if there are more than 4
//           if (payments.length > 4) ...[
//             divider(),
//             SizedBox(height: height * .01),
//             Row(
//               children: [
//                 Icon(Icons.more_horiz_rounded, color: ProjectColors.whiteColor.withOpacity(.35), size: height * .022),
//                 SizedBox(width: width * .02),
//                 Expanded(
//                   child: textWidget(
//                     text: "+ ${payments.length - 4} more payments",
//                     fontSize: .015,
//                     fontWeight: FontWeight.w700,
//                     color: ProjectColors.whiteColor.withOpacity(.45),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
//
// // ----------------------------
// // PLACEHOLDERS (replace with real screens)
// // ----------------------------
