// import 'package:flutter/material.dart';
//
// /// Minimal Apple-ish dark Prioritizer screen (no external deps).
// /// - 4 parts: Summary, Must, At Risk, If Time
// /// - Clean typography + subtle surfaces
// /// - Primary CTA only on top "Must Do" item
// ///
// /// Plug into MaterialApp(theme: ThemeData.dark()) or use the theme below.
// class Prioritize extends StatelessWidget {
//   const Prioritize({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = _darkAppleLikeTheme();
//     return Theme(
//       data: theme,
//       child: Scaffold(
//         backgroundColor: theme.colorScheme.surface,
//         body: SafeArea(
//           child: CustomScrollView(
//             slivers: [
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
//                 sliver: SliverToBoxAdapter(
//                   child: _Header(
//                     title: "Today’s Priorities",
//                     subtitle: "Soft + hard deadlines prioritized.",
//                     onMore: () {},
//                   ),
//                 ),
//               ),
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
//                 sliver: SliverToBoxAdapter(
//                   child: _SummaryCard(
//                     completed: 0,
//                     total: 3,
//                     nextDeadlineLabel: "Next deadline",
//                     nextDeadlineValue: "2:30 PM",
//                     focusLabel: "Total focus time",
//                     focusValue: "3h 10m",
//                     pills: const [
//                       _PillData(label: "Must", value: "1", tone: _Tone.danger),
//                       _PillData(label: "At risk", value: "1", tone: _Tone.warn),
//                       _PillData(label: "If time", value: "1", tone: _Tone.neutral),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Part 2 — MUST
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
//                 sliver: SliverToBoxAdapter(
//                   child: _SectionHeader(
//                     icon: Icons.priority_high_rounded,
//                     title: "Must Do",
//                     trailing: TextButton(
//                       onPressed: () {},
//                       child: const Text("See all"),
//                     ),
//                   ),
//                 ),
//               ),
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
//                 sliver: SliverToBoxAdapter(
//                   child: _TaskCard(
//                     title: "Finish project report",
//                     metaTop: "Due in 6 hours",
//                     metaBottom: "Due Today, 2:30 PM • Est. 1h 30m • Pending",
//                     description: "Finalize the report and send it to the client.",
//                     tone: _Tone.danger,
//                     primaryActionLabel: "Start",
//                     onPrimaryAction: () {},
//                     onDetails: () {},
//                     showStatusChip: true,
//                     statusText: "Pending",
//                     prominent: true,
//                   ),
//                 ),
//               ),
//
//               // Part 3 — AT RISK
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
//                 sliver: SliverToBoxAdapter(
//                   child: _SectionHeader(
//                     icon: Icons.warning_amber_rounded,
//                     title: "At Risk",
//                     subtitle: "Approaching deadlines — do soon",
//                   ),
//                 ),
//               ),
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
//                 sliver: SliverToBoxAdapter(
//                   child: _TaskCard(
//                     title: "Review marketing plan",
//                     metaTop: "Due in 12 hours",
//                     metaBottom: "Due Today, 8:30 PM • Est. 45m • Pending",
//                     tone: _Tone.warn,
//                     onDetails: () {},
//                     trailingIconOnly: true,
//                   ),
//                 ),
//               ),
//
//               // Part 4 — IF TIME
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
//                 sliver: SliverToBoxAdapter(
//                   child: _SectionHeader(
//                     icon: Icons.schedule_rounded,
//                     title: "If Time",
//                     subtitle: "Nice-to-do after urgent work",
//                   ),
//                 ),
//               ),
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
//                 sliver: SliverToBoxAdapter(
//                   child: _TaskCard(
//                     title: "Organize desk and files",
//                     metaTop: "Soft deadline passed",
//                     metaBottom: "Est. 30m • Pending",
//                     tone: _Tone.neutral,
//                     onDetails: () {},
//                     trailingIconOnly: true,
//                   ),
//                 ),
//               ),
//
//               // Bonus info card (like your “Focus Block Suggestion”)
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
//                 sliver: SliverToBoxAdapter(
//                   child: _InfoCard(
//                     title: "Focus Block Suggestion",
//                     subtitle: "25 minutes of deep work free at 9:30 AM",
//                     icon: Icons.auto_awesome_rounded,
//                   ),
//                 ),
//               ),
//
//               // Bottom CTA
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
//                 sliver: SliverToBoxAdapter(
//                   child: SizedBox(
//                     height: 50,
//                     child: FilledButton.icon(
//                       onPressed: () {},
//                       icon: const Icon(Icons.add_rounded),
//                       label: const Text("Add Task"),
//                       style: FilledButton.styleFrom(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /* ----------------------------- THEME ----------------------------- */
//
// ThemeData _darkAppleLikeTheme() {
//   const bg = Color(0xFF0B0D10);
//   const surface = Color(0xFF11141A);
//   const surface2 = Color(0xFF151A22);
//   const text = Color(0xFFE8EAF0);
//   const subtext = Color(0xFF9AA3B2);
//
//   final scheme = const ColorScheme.dark(
//     surface: bg,
//     onSurface: text,
//     primary: Color(0xFF2D6BFF), // iOS-ish blue accent
//     onPrimary: Colors.white,
//     secondary: Color(0xFF2D6BFF),
//     onSecondary: Colors.white,
//   );
//
//   return ThemeData(
//     colorScheme: scheme,
//     scaffoldBackgroundColor: bg,
//     useMaterial3: true,
//     textTheme: const TextTheme(
//       headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15, color: text),
//       titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text),
//       titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text),
//       bodyMedium: TextStyle(fontSize: 14, height: 1.3, color: text),
//       bodySmall: TextStyle(fontSize: 12.5, height: 1.3, color: subtext),
//       labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//     ),
//     cardTheme: const CardThemeData(
//       color: surface,
//       elevation: 0,
//       margin: EdgeInsets.zero,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.all(Radius.circular(22)),
//       ),
//     ),
//     dividerTheme: const DividerThemeData(color: Color(0x1AFFFFFF), thickness: 1),
//     filledButtonTheme: FilledButtonThemeData(
//       style: FilledButton.styleFrom(
//         backgroundColor: scheme.primary,
//         foregroundColor: scheme.onPrimary,
//         textStyle: const TextStyle(fontWeight: FontWeight.w600),
//       ),
//     ),
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: const Color(0xFF8EA6FF),
//         textStyle: const TextStyle(fontWeight: FontWeight.w600),
//       ),
//     ),
//     iconTheme: const IconThemeData(color: Color(0xFFB8C0D0)),
//     extensions: const <ThemeExtension<dynamic>>[
//       _SurfacePalette(
//         card: surface,
//         card2: surface2,
//         subtleBorder: Color(0x18FFFFFF),
//         subtext: subtext,
//       ),
//     ],
//   );
// }
//
// @immutable
// class _SurfacePalette extends ThemeExtension<_SurfacePalette> {
//   final Color card;
//   final Color card2;
//   final Color subtleBorder;
//   final Color subtext;
//
//   const _SurfacePalette({
//     required this.card,
//     required this.card2,
//     required this.subtleBorder,
//     required this.subtext,
//   });
//
//   @override
//   _SurfacePalette copyWith({Color? card, Color? card2, Color? subtleBorder, Color? subtext}) {
//     return _SurfacePalette(
//       card: card ?? this.card,
//       card2: card2 ?? this.card2,
//       subtleBorder: subtleBorder ?? this.subtleBorder,
//       subtext: subtext ?? this.subtext,
//     );
//   }
//
//   @override
//   _SurfacePalette lerp(ThemeExtension<_SurfacePalette>? other, double t) {
//     if (other is! _SurfacePalette) return this;
//     return _SurfacePalette(
//       card: Color.lerp(card, other.card, t)!,
//       card2: Color.lerp(card2, other.card2, t)!,
//       subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
//       subtext: Color.lerp(subtext, other.subtext, t)!,
//     );
//   }
// }
//
// /* ----------------------------- WIDGETS ----------------------------- */
//
// class _Header extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final VoidCallback onMore;
//
//   const _Header({
//     required this.title,
//     required this.subtitle,
//     required this.onMore,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title, style: t.headlineMedium),
//               const SizedBox(height: 6),
//               Text(subtitle, style: t.bodySmall?.copyWith(color: palette.subtext)),
//             ],
//           ),
//         ),
//         IconButton(
//           onPressed: onMore,
//           icon: const Icon(Icons.more_horiz_rounded),
//           style: IconButton.styleFrom(
//             backgroundColor: palette.card,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _SummaryCard extends StatelessWidget {
//   final int completed;
//   final int total;
//   final String nextDeadlineLabel;
//   final String nextDeadlineValue;
//   final String focusLabel;
//   final String focusValue;
//   final List<_PillData> pills;
//
//   const _SummaryCard({
//     required this.completed,
//     required this.total,
//     required this.nextDeadlineLabel,
//     required this.nextDeadlineValue,
//     required this.focusLabel,
//     required this.focusValue,
//     required this.pills,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     final t = Theme.of(context).textTheme;
//
//     final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
//
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             _ProgressRing(
//               progress: progress,
//               centerTop: "$completed",
//               centerBottom: "of $total\nCompleted",
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: pills.map((p) => _MiniPill(data: p)).toList(),
//                   ),
//                   const SizedBox(height: 12),
//                   Text("$nextDeadlineLabel:  $nextDeadlineValue", style: t.bodySmall?.copyWith(color: palette.subtext)),
//                   const SizedBox(height: 4),
//                   Text("$focusLabel:  $focusValue", style: t.bodySmall?.copyWith(color: palette.subtext)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _ProgressRing extends StatelessWidget {
//   final double progress;
//   final String centerTop;
//   final String centerBottom;
//
//   const _ProgressRing({
//     required this.progress,
//     required this.centerTop,
//     required this.centerBottom,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     final t = Theme.of(context).textTheme;
//
//     return SizedBox(
//       width: 86,
//       height: 86,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           CircularProgressIndicator(
//             value: 1,
//             strokeWidth: 7,
//             color: palette.subtleBorder,
//           ),
//           CircularProgressIndicator(
//             value: progress,
//             strokeWidth: 7,
//           ),
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(centerTop, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
//               Text(centerBottom, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: palette.subtext)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _SectionHeader extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String? subtitle;
//   final Widget? trailing;
//
//   const _SectionHeader({
//     required this.icon,
//     required this.title,
//     this.subtitle,
//     this.trailing,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     return Row(
//       children: [
//         Icon(icon, size: 20),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title, style: t.titleLarge),
//               if (subtitle != null) ...[
//                 const SizedBox(height: 2),
//                 Text(subtitle!, style: t.bodySmall?.copyWith(color: palette.subtext)),
//               ],
//             ],
//           ),
//         ),
//         if (trailing != null) trailing!,
//       ],
//     );
//   }
// }
//
// class _TaskCard extends StatelessWidget {
//   final String title;
//   final String metaTop;
//   final String metaBottom;
//   final String? description;
//   final _Tone tone;
//   final String? primaryActionLabel;
//   final VoidCallback? onPrimaryAction;
//   final VoidCallback? onDetails;
//
//   /// If true: only show a small trailing play icon (lightweight action).
//   final bool trailingIconOnly;
//
//   /// More prominence for the top priority card.
//   final bool prominent;
//
//   final bool showStatusChip;
//   final String statusText;
//
//   const _TaskCard({
//     required this.title,
//     required this.metaTop,
//     required this.metaBottom,
//     this.description,
//     required this.tone,
//     this.primaryActionLabel,
//     this.onPrimaryAction,
//     this.onDetails,
//     this.trailingIconOnly = false,
//     this.prominent = false,
//     this.showStatusChip = false,
//     this.statusText = "Pending",
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     final t = Theme.of(context).textTheme;
//
//     final accent = _toneAccent(tone, context);
//
//     return Card(
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(22),
//           border: Border.all(color: palette.subtleBorder),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Title row
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: t.titleMedium?.copyWith(
//                         fontSize: prominent ? 18 : 16,
//                         fontWeight: prominent ? FontWeight.w800 : FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                   if (trailingIconOnly)
//                     _TrailingIconButton(onPressed: onDetails)
//                   else if (primaryActionLabel != null)
//                     _PrimaryPillButton(
//                       label: primaryActionLabel!,
//                       onPressed: onPrimaryAction,
//                       background: accent,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // Meta top (e.g., Due in 6 hours)
//               Text(metaTop, style: t.bodySmall?.copyWith(color: accent)),
//               const SizedBox(height: 6),
//
//               // Meta bottom
//               Text(metaBottom, style: t.bodySmall?.copyWith(color: palette.subtext)),
//               if (description != null) ...[
//                 const SizedBox(height: 10),
//                 Divider(color: palette.subtleBorder),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         description!,
//                         style: t.bodySmall?.copyWith(color: palette.subtext),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     if (showStatusChip)
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: palette.card2,
//                           borderRadius: BorderRadius.circular(999),
//                           border: Border.all(color: palette.subtleBorder),
//                         ),
//                         child: Text(
//                           statusText,
//                           style: t.bodySmall?.copyWith(color: palette.subtext),
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _TrailingIconButton extends StatelessWidget {
//   final VoidCallback? onPressed;
//   const _TrailingIconButton({this.onPressed});
//
//   @override
//   Widget build(BuildContext context) {
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     return IconButton(
//       onPressed: onPressed,
//       icon: const Icon(Icons.play_arrow_rounded),
//       style: IconButton.styleFrom(
//         backgroundColor: palette.card2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       ),
//     );
//   }
// }
//
// class _PrimaryPillButton extends StatelessWidget {
//   final String label;
//   final VoidCallback? onPressed;
//   final Color background;
//
//   const _PrimaryPillButton({
//     required this.label,
//     required this.onPressed,
//     required this.background,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return FilledButton.icon(
//       onPressed: onPressed,
//       icon: const Icon(Icons.play_arrow_rounded, size: 18),
//       label: Text(label),
//       style: FilledButton.styleFrom(
//         backgroundColor: background,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
//       ),
//     );
//   }
// }
//
// class _InfoCard extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//
//   const _InfoCard({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     final t = Theme.of(context).textTheme;
//
//     return Card(
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(22),
//           border: Border.all(color: palette.subtleBorder),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: palette.card2,
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: palette.subtleBorder),
//                 ),
//                 child: Icon(icon, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title, style: t.titleMedium),
//                     const SizedBox(height: 4),
//                     Text(subtitle, style: t.bodySmall?.copyWith(color: palette.subtext)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /* ----------------------------- PILLS ----------------------------- */
//
// enum _Tone { danger, warn, neutral }
//
// class _PillData {
//   final String label;
//   final String value;
//   final _Tone tone;
//
//   const _PillData({required this.label, required this.value, required this.tone});
// }
//
// class _MiniPill extends StatelessWidget {
//   final _PillData data;
//   const _MiniPill({required this.data});
//
//   @override
//   Widget build(BuildContext context) {
//     final palette = Theme.of(context).extension<_SurfacePalette>()!;
//     final t = Theme.of(context).textTheme;
//
//     final accent = _toneAccent(data.tone, context);
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: palette.card2,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: palette.subtleBorder),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 8),
//           Text("${data.label}: ", style: t.bodySmall?.copyWith(color: palette.subtext)),
//           Text(data.value, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
//         ],
//       ),
//     );
//   }
// }
//
// Color _toneAccent(_Tone tone, BuildContext context) {
//   switch (tone) {
//     case _Tone.danger:
//       return const Color(0xFFFF5A5F); // soft red
//     case _Tone.warn:
//       return const Color(0xFFFFC34D); // amber
//     case _Tone.neutral:
//       return Theme.of(context).colorScheme.primary; // blue accent
//   }
// }
