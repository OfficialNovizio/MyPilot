import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Shift/Projection/Projection.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'Controllers.dart';
import 'Shift/Shift Getx.dart';

class SegmentTabs extends StatelessWidget {
  SegmentTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.highlightValue,
    this.padding,
    this.bgOpacity = 0.05,
    this.borderOpacity = 0.07,
    this.thumbOpacity = 0.10,
    this.cWidth = 1.0,
  });

  /// selected item label (must exist in items)
  final String value;

  /// callback gives selected label
  final ValueChanged<String> onChanged;

  /// labels for tabs
  final List<String> items;

  /// optional: which label should use green highlight when active
  final String? highlightValue;

  /// optional outer padding
  final EdgeInsets? padding;

  final double bgOpacity;
  final double borderOpacity;
  final double thumbOpacity;
  final double? cWidth;

  @override
  Widget build(BuildContext context) {
    // Map each label to itself for Cupertino control
    final Map<String, Widget> children = {
      for (final label in items)
        label: _SegItem(
          text: label,
          active: value == label,
          highlight: highlightValue == label,
        ),
    };

    return Container(
      width: width * cWidth!,
      decoration: BoxDecoration(
        color: ProjectColors.whiteColor.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ProjectColors.whiteColor.withOpacity(borderOpacity)),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: value,
        thumbColor: ProjectColors.greenColor.withOpacity(thumbOpacity),
        backgroundColor: Colors.transparent,
        padding: EdgeInsetsGeometry.symmetric(vertical: height * .001),
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
        children: children,
      ),
    );
  }
}

class _SegItem extends StatelessWidget {
  const _SegItem({
    required this.text,
    required this.active,
    this.highlight = false,
  });

  final String text;
  final bool active;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = highlight ? ProjectColors.lightGreenColor : ProjectColors.whiteColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.008),
      child: Center(
        child: textWidget(
          text: text,
          fontSize: 0.016,
          fontWeight: FontWeight.w800,
          color: active ? activeColor : ProjectColors.whiteColor.withOpacity(0.55),
          fontFamily: "poppins",
        ),
      ),
    );
  }
}

class DarkCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const DarkCard({required this.child, this.color = ProjectColors.blackColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: width * .02,
        vertical: height * .018,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class Popup extends StatelessWidget {
  final Widget? body;
  final String? title;
  final Color? color;
  Popup({this.body, this.title = '', this.color = ProjectColors.whiteColor});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      child: CupertinoPageScaffold(
        backgroundColor: color,
        navigationBar: CupertinoNavigationBar(
          transitionBetweenRoutes: false,
          middle: textWidget(
            text: title!,
            fontSize: .025,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
            color: color == ProjectColors.whiteColor ? ProjectColors.pureBlackColor : ProjectColors.whiteColor,
          ),
          backgroundColor: color,
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
                color: color == ProjectColors.whiteColor ? ProjectColors.pureBlackColor : ProjectColors.whiteColor,
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

// class TimePicker extends StatefulWidget {
//   String? updatedValue;
//   TimePicker({this.updatedValue = ''});
//   @override
//   State<TimePicker> createState() => _TimePickerState();
// }
//
// class _TimePickerState extends State<TimePicker> {
//   @override
//   Widget build(BuildContext context) {
//     return Popup(
//       title: 'Select Date',
//       body: SizedBox(
//         height: height * .5,
//         child: Column(
//           children: [
//             SizedBox(
//               height: height * .4,
//               child:  CupertinoDatePicker(
//                 mode: CupertinoDatePickerMode.time,
//                 use24hFormat: false,
//                 minuteInterval: 1,
//                 initialDateTime: DateTime.now(),
//                 onDateTimeChanged: (dt) {
//                   widget.updatedValue = DateFormat('HH:mm').format(dt);
//                 },
//               ),
//             ),
//             normalButton(
//               title: "Done",
//               cWidth: .4,
//               callback: () {},
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
class PickShiftTime extends StatelessWidget {
  final int columnIndex;
  const PickShiftTime({super.key, this.columnIndex = 0});

  bool _isBreak(ShiftController shift) => shift.newShiftColumns![columnIndex].title == 'Unpaid break time';

  DateTime _defaultSeed(ShiftController shift) {
    final d = shift.selectedDay!.value;
    return DateTime(d.year, d.month, d.day, 9, 0);
  }

  DateTime _parseOrDefault(ShiftController shift) {
    final text = shift.newShiftColumns![columnIndex].controller.text.trim();
    if (text.isEmpty) return _defaultSeed(shift);

    final isBreak = _isBreak(shift);
    final format = isBreak ? DateFormat('yyyy-MM-dd HH:mm:ss.SSS') : DateFormat('yyyy-MM-dd hh:mm a');

    final dt = format.parse(text);
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  void _setText(ShiftController shift, DateTime dt) {
    final isBreak = _isBreak(shift);
    final format = isBreak ? DateFormat('yyyy-MM-dd HH:mm:ss.SSS') : DateFormat('yyyy-MM-dd hh:mm a');

    shift.newShiftColumns![columnIndex].controller.text = format.format(dt);
    shift.newShiftColumns!.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isBreak = _isBreak(shift);
    final seed = _parseOrDefault(shift);

    return SizedBox(
      height: height * .5,
      child: Popup(
        title: 'Pick Shift Timing',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height * .35,
              child: isBreak
                  ? CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: seed.minute.clamp(0, 59),
                      ),
                      onSelectedItemChanged: (m) {
                        // break stored as date with only minutes used
                        final dt = DateTime(seed.year, seed.month, seed.day, 0, m);
                        _setText(shift, dt);
                      },
                      children: List.generate(
                        60,
                        (m) => Center(child: Text(m.toString().padLeft(2, '0'))),
                      ),
                    )
                  : CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      minuteInterval: 1,
                      use24hFormat: false,
                      initialDateTime: seed,
                      onDateTimeChanged: (dt) {
                        final updated = DateTime(seed.year, seed.month, seed.day, dt.hour, dt.minute);
                        _setText(shift, updated);
                      },
                    ),
            ),
            SizedBox(height: height * .01),
            normalButton(
              title: 'Done',
              cWidth: .4,
              callback: Get.back,
            ),
          ],
        ),
      ),
    );
  }
}

class AppDatePicker {
  AppDatePicker._();

  /// Returns picked DateTime or null if user cancels.
  static Future<DateTime?> pickDate({
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String title = "Pick date",
    Color sheetColor = ProjectColors.blackColor,
  }) async {
    final now = DateTime.now();
    final DateTime safeMin = minDate ?? now;
    final DateTime safeMax = maxDate ?? DateTime(now.year + 5);

    DateTime temp = initialDate ?? safeMin;
    if (temp.isBefore(safeMin)) temp = safeMin;
    if (temp.isAfter(safeMax)) temp = safeMax;

    DateTime? result;

    await showCupertinoModalPopup(
      context: navigatorKey.currentContext!,
      barrierColor: ProjectColors.blackColor.withOpacity(0.5),
      builder: (ctx) {
        return Popup(
          color: ProjectColors.whiteColor,
          title: title,
          body: SizedBox(
            height: height * .5,
            child: Column(
              children: [
                SizedBox(
                  height: height * .4,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    backgroundColor: ProjectColors.whiteColor,
                    initialDateTime: temp,
                    minimumDate: safeMin,
                    maximumDate: safeMax,
                    onDateTimeChanged: (val) => temp = val,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: height * .04),
                  child: Center(
                    child: normalButton(
                      title: "Done",
                      bColor: ProjectColors.greenColor,
                      cWidth: .5,
                      loading: false,
                      invertColors: true,
                      callback: () {
                        result = temp;
                        Get.back();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result;
  }
}
