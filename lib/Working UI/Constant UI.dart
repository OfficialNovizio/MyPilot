import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Popup extends StatelessWidget {
  final Widget? body;
  final String? title;
  Popup({this.body, this.title = ''});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          transitionBetweenRoutes: false,
          middle: textWidget(
            text: title!,
            fontSize: .025,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.white,
          leading: Padding(
            padding: EdgeInsets.only(top: height * .01),
            child: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: textWidget(
                text: "close",
                fontSize: .02,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * .02),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(width: width, child: body),
          ),
        ),
      ),
    );
  }
}

class MyFormField extends StatelessWidget {
  final TextForm form;
  final bool? textInputDone;
  final bool? needSuffix;
  final bool? needCustomPadding;
  final bool? needDigitKeyboard;
  final bool? needLengthRestrict;
  final bool? needBorder;
  final bool? obscureText;
  final bool? enable;
  final EdgeInsetsGeometry? padding;
  final String? Function(String?)? validator;

  MyFormField({
    required this.form,
    this.textInputDone,
    this.validator,
    this.needSuffix,
    this.needCustomPadding = false,
    this.padding = EdgeInsets.zero,
    this.needDigitKeyboard = false,
    this.needLengthRestrict = false,
    this.needBorder = false,
    this.enable = true,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: needCustomPadding == true
          ? padding!
          : EdgeInsets.fromLTRB(
              width * .15,
              height * .02,
              width * .15,
              0,
            ),
      child: TextFormField(
        controller: form.controller,
        validator: validator,
        enabled: enable,
        obscureText: obscureText == false ? false : true,
        inputFormatters: needLengthRestrict! ? [LengthLimitingTextInputFormatter(4)] : [],
        keyboardType: needDigitKeyboard! ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: form.title,
          labelStyle: TextStyle(
            fontFamily: "poppins",
            fontSize: height * .018,
            color: form.controller.text.isEmpty ? ProjectColors.blackColor.withOpacity(0.7) : ProjectColors.blackColor,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: form.controller.text.isEmpty ? ProjectColors.blackColor.withOpacity(0.7) : ProjectColors.blackColor,
              width: 1,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: ProjectColors.blackColor,
              width: 1,
            ),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: ProjectColors.errorColor,
              width: 1,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: textInputDone == false ? TextInputAction.next : TextInputAction.done,
        style: TextStyle(
          fontFamily: "poppins",
          fontSize: height * .018,
          color: ProjectColors.blackColor,
        ),
      ),
    );
  }
}

class UniversalChoiceChips<T> extends StatelessWidget {
  const UniversalChoiceChips({
    super.key,
    required this.items,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.keyOf,
    this.enabled = true,
    this.spacing = 8,
    this.runSpacing = 8,
    this.wrapAlignment = WrapAlignment.start,
    this.padding,
    this.selectedColor,
    this.unselectedColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.avatarOf,
    this.chipSide,
    this.clipBehavior = Clip.none,
  });

  /// Items to render as chips.
  final Iterable<T> items;

  /// Turn an item into a visible label.
  final String Function(T) labelOf;

  /// Currently selected item (or null for “none”).
  final T? value;

  /// Called when the user picks a chip.
  final ValueChanged<T> onChanged;

  /// Extracts a stable identity key for comparison & ValueKey.
  /// If omitted, equality uses `==`. Pass this if your model doesn’t override ==/hashCode.
  final Object Function(T)? keyOf;

  /// Global enable/disable.
  final bool enabled;

  /// Layout / style.
  final double spacing;
  final double runSpacing;
  final WrapAlignment wrapAlignment;
  final EdgeInsetsGeometry? padding;

  /// Colors & styles (fallback to ChipTheme).
  final Color? selectedColor;
  final Color? unselectedColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;

  /// Optional avatar per chip.
  final Widget Function(T)? avatarOf;

  /// Optional border/side for each chip.
  final BorderSide? chipSide;

  final Clip clipBehavior;

  // --------- Convenience factories ---------

  /// From a List<T>
  factory UniversalChoiceChips.fromList({
    Key? key,
    required List<T> items,
    required String Function(T) labelOf,
    required T? value,
    required ValueChanged<T> onChanged,
    Object Function(T)? keyOf,
    bool enabled = true,
    double spacing = 8,
    double runSpacing = 8,
  }) {
    return UniversalChoiceChips<T>(
      key: key,
      items: items,
      labelOf: labelOf,
      value: value,
      onChanged: onChanged,
      keyOf: keyOf,
      enabled: enabled,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  /// From a Map<T,String> (keys are items, value is label).
  factory UniversalChoiceChips.fromMap({
    Key? key,
    required Map<T, String> map,
    required T? value,
    required ValueChanged<T> onChanged,
    Object Function(T)? keyOf,
    bool enabled = true,
    double spacing = 8,
    double runSpacing = 8,
  }) {
    return UniversalChoiceChips<T>(
      key: key,
      items: map.keys,
      labelOf: (t) => map[t] ?? t.toString(),
      value: value,
      onChanged: onChanged,
      keyOf: keyOf,
      enabled: enabled,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  bool _isSelected(T item) {
    if (value == null) return false;
    if (keyOf != null) {
      final a = keyOf!(item);
      final b = keyOf!(value as T);
      return a == b;
    }
    return value == item;
  }

  @override
  Widget build(BuildContext context) {
    final chipTheme = ChipTheme.of(context);

    return Wrap(
      alignment: wrapAlignment,
      spacing: spacing,
      runSpacing: runSpacing,
      clipBehavior: clipBehavior,
      children: items.map((item) {
        final selected = _isSelected(item);
        final identity = keyOf?.call(item) ?? item as Object;

        final bgSelected = selectedColor ?? chipTheme.selectedColor ?? Theme.of(context).colorScheme.primary.withOpacity(.18);
        final bgUnselected = unselectedColor ?? chipTheme.backgroundColor;
        final lblSelected = selectedLabelStyle ??
            chipTheme.labelStyle?.copyWith(color: Theme.of(context).colorScheme.onPrimary) ??
            TextStyle(color: Theme.of(context).colorScheme.primary);
        final lblUnselected = unselectedLabelStyle ?? chipTheme.labelStyle;

        return ChoiceChip(
          key: ValueKey(identity),
          label: textWidget(text: labelOf(item), fontSize: .015, color: ProjectColors.pureBlackColor),
          selected: selected,
          onSelected: enabled ? (_) => onChanged(item) : null,
          backgroundColor: ProjectColors.whiteColor,
          shadowColor: Colors.transparent,
          avatarBorder: Border.all(color: Colors.transparent),
          disabledColor: ProjectColors.pureBlackColor,
          selectedColor: ProjectColors.greenColor,
          labelStyle: selected ? lblSelected : lblUnselected,
          avatar: avatarOf?.call(item),
          side: chipSide,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        );
      }).toList(),
    );
  }
}

class CupertinoTimePickerField extends StatefulWidget {
  const CupertinoTimePickerField({
    super.key,
    required this.value, // current time (nullable)
    required this.onChanged, // gets TimeOfDay? (null if cancelled)
    this.placeholder = 'Select time',
    this.minuteInterval = 1, // must divide 60
    this.use24h, // null -> follow device
    this.icon,
    this.doneText = 'Done',
    this.cancelText = 'Cancel',
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String placeholder;
  final int minuteInterval;
  final bool? use24h;
  final IconData? icon;
  final String doneText;
  final String cancelText;

  @override
  State<CupertinoTimePickerField> createState() => _CupertinoTimePickerFieldState();
}

class _CupertinoTimePickerFieldState extends State<CupertinoTimePickerField> {
  @override
  Widget build(BuildContext context) {
    final use24h = widget.use24h ?? MediaQuery.of(context).alwaysUse24HourFormat;
    final display = widget.value == null ? widget.placeholder : _fmt(widget.value!, context, use24h);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        DateTime temp = _toToday(widget.value ?? const TimeOfDay(hour: 9, minute: 0));
        final picked = await showCupertinoModalPopup<TimeOfDay?>(
          context: context,
          builder: (_) => Material(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toolbar
                  Container(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => Navigator.pop(context, null),
                          child: Text(widget.cancelText),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => Navigator.pop(context, TimeOfDay.fromDateTime(temp)),
                          child: Text(widget.doneText, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  // Picker
                  SizedBox(
                    height: 216,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: use24h,
                      minuteInterval: widget.minuteInterval,
                      initialDateTime: temp,
                      onDateTimeChanged: (dt) => temp = dt,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );

        widget.onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (widget.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(widget.icon, size: 18, color: CupertinoColors.inactiveGray),
              ),
            Expanded(
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.value == null ? CupertinoColors.placeholderText.resolveFrom(context) : CupertinoColors.label.resolveFrom(context),
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(CupertinoIcons.clock, size: 18, color: CupertinoColors.inactiveGray),
          ],
        ),
      ),
    );
  }

  // === tiny local utils ===
  static DateTime _toToday(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  static String _fmt(TimeOfDay t, BuildContext ctx, bool use24h) {
    if (use24h) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return t.format(ctx);
  }
}

class TimePicker extends StatefulWidget {
  String? updatedValue;
  TimePicker({this.updatedValue = ''});
  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  @override
  Widget build(BuildContext context) {
    return Popup(
      title: 'Select Date',
      body: SizedBox(
        height: height * .5,
        child: Column(
          children: [
            SizedBox(
              height: height * .4,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                minuteInterval: 1,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (dt) {
                  widget.updatedValue = DateFormat('HH:mm').format(dt);
                },
              ),
            ),
            normalButton(
              title: "Done",
              cWidth: .4,
              callback: () {},
            ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> pickCupertinoDateTime(
  BuildContext context, {
  required DateTime baseDate, // date part you want to keep (e.g., selected day)
  DateTime? initialTime, // if null, uses 09:00 on baseDate
  int minuteInterval = 1,
  bool? use24h = false,
  bool minutesOnly = false,
  int minuteStep = 1, // for minutesOnly (must divide 60)
}) async {
  // seed time
  final seed = initialTime ?? DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);

  if (minutesOnly) {
    // pick only minutes; keep hour from seed
    final pickedMin = await _pickMinutesCupertino(
      context,
      initial: seed.minute,
      step: minuteStep,
    );
    if (pickedMin == null) return null;
    return DateTime(baseDate.year, baseDate.month, baseDate.day, seed.hour, pickedMin);
  }

  final use24 = use24h ?? MediaQuery.of(context).alwaysUse24HourFormat;
  DateTime temp = seed;

  final picked = await showCupertinoModalPopup<DateTime?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toolbar
            Row(
              children: [
                CupertinoButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                CupertinoButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime(baseDate.year, baseDate.month, baseDate.day, temp.hour, temp.minute),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            // Time wheel
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                minuteInterval: minuteInterval,
                use24hFormat: false,
                initialDateTime: seed,
                onDateTimeChanged: (dt) {
                  temp = dt;
                  print(dt);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );

  return picked; // DateTime? with your baseDate's Y-M-D and picked H:M
}

/// Optional: formatter if you need a display string (e.g., "2025-11-10 09:10 AM")
String? formatDateTime(DateTime? dt, {String pattern = 'yyyy-MM-dd hh:mm a', String? locale}) {
  if (dt == null) return null;
  return DateFormat(pattern, locale).format(dt);
}

// ---------- minutes-only wheel ----------
Future<int?> _pickMinutesCupertino(
  BuildContext context, {
  required int initial,
  int step = 1,
  String doneText = 'Done',
  String cancelText = 'Cancel',
}) async {
  final s = (step <= 0 || 60 % step != 0) ? 1 : step;
  final values = [for (int m = 0; m < 60; m += s) m];
  int idx = (initial ~/ s).clamp(0, values.length - 1);
  int tempIndex = idx;

  return showCupertinoModalPopup<int>(
    context: context,
    builder: (_) => Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(cancelText),
                ),
                const Spacer(),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context, values[tempIndex]),
                  child: Text(doneText, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(initialItem: idx),
                onSelectedItemChanged: (i) => tempIndex = i,
                children: List.generate(values.length, (i) => Center(child: Text(values[i].toString().padLeft(2, '0')))),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
// -------- minutes-only picker (single wheel) --------
//
// Future<int?> _pickMinutesCupertino(
//   BuildContext context, {
//   required int initial,
//   int step = 1, // must divide 60
//   String doneText = 'Done',
//   String cancelText = 'Cancel',
// }) async {
//   final s = (step <= 0 || 60 % step != 0) ? 1 : step;
//   final values = [for (int m = 0; m < 60; m += s) m];
//   int idx = (initial ~/ s).clamp(0, values.length - 1);
//   int tempIndex = idx;
//
//   return showCupertinoModalPopup<int>(
//     context: context,
//     builder: (_) => Material(
//       color: ProjectColors.whiteColor,
//       child: SafeArea(
//         top: false,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 CupertinoButton(
//                   onPressed: () => Navigator.pop(context, null),
//                   child: textWidget(text: cancelText, fontSize: .018, color: ProjectColors.pureBlackColor),
//                 ),
//                 const Spacer(),
//                 CupertinoButton(
//                   onPressed: () => Navigator.pop(context, values[tempIndex]),
//                   child: textWidget(text: doneText, fontSize: .018, color: ProjectColors.pureBlackColor),
//                 ),
//               ],
//             ),
//             SizedBox(
//               height: height * .4, // keep your sizing scheme
//               child: CupertinoPicker(
//                 itemExtent: 32,
//                 scrollController: FixedExtentScrollController(initialItem: idx),
//                 onSelectedItemChanged: (i) => tempIndex = i,
//                 children: List<Widget>.generate(
//                   values.length,
//                   (i) => Center(
//                     child: textWidget(
//                       text: values[i].toString().padLeft(2, '0'),
//                       fontSize: .02,
//                       color: ProjectColors.pureBlackColor,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
//
// // tiny local util
// DateTime _toToday(TimeOfDay t) {
//   final now = DateTime.now();
//   return DateTime(now.year, now.month, now.day, t.hour, t.minute);
// }
