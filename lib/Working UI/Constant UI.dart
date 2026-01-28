import 'dart:ui';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/Projection Model.dart';
import 'Controllers.dart';
import 'Shift/Shift Getx.dart';

void callBottomSheet({required Widget child, String? title, bool isScrollControlled = true}) {
  Get.bottomSheet(
    DarkCard(
      color: ProjectColors.blackColor,
      opacity: 1,
      borderColor: ProjectColors.whiteColor,
      borderOpacity: .1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Center(
              child: Container(
                height: height * .005,
                width: width * .25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: ProjectColors.greenColor,
                ),
              ),
            ),
            SizedBox(height: height * .015),
            Center(
              child: textWidget(
                text: title,
                fontSize: .02,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor,
              ),
            ),
            SizedBox(height: height * .012),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: height * .015),
            child: child,
          ),
        ],
      ),
    ),
    isScrollControlled: isScrollControlled,
  );
}

class DarkTextField extends StatelessWidget {
  final String title;

  // Editable mode
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int maxLines;

  // Picker/display mode
  final String? value; // show when controller == null
  final String? hintText;
  final VoidCallback? onTap; // if not null => acts like a tile picker
  final void Function(String value)? onChanged;

  // Slots
  final Widget? trailing;
  final Widget? leading;

  // Optional
  final bool enabled;

  // ✅ NEW
  final double? tileHeight; // e.g. height * 0.085
  final Color? backgroundColor; // override default bg

  const DarkTextField({
    super.key,
    required this.title,
    this.controller,
    this.keyboardType,
    this.prefixText,
    this.maxLines = 1,
    this.value,
    this.hintText,
    this.onTap,
    this.onChanged,
    this.trailing,
    this.leading,
    this.enabled = true,

    // ✅ NEW
    this.tileHeight,
    this.backgroundColor,
  });

  bool get _isPicker => onTap != null;
  bool get _isTextField => controller != null;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? ProjectColors.backgroundColor;
    final borderColor = ProjectColors.whiteColor.withOpacity(0.05);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: width * 0.02),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // ✅ helps when fixed height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: title,
                color: ProjectColors.whiteColor.withOpacity(0.55),
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: height * 0.006),
              _isTextField ? _buildBoldTextField() : _buildBoldValue(),
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: width * 0.02),
          trailing!,
        ],
      ],
    );

    final pad = EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.008);

    return GestureDetector(
      onTap: (!enabled || !_isPicker) ? null : onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          alignment: Alignment.center, // ✅ center content vertically
          padding: pad,
          decoration: BoxDecoration(
            color: bg, // ✅ NEW
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildBoldValue() {
    final v = (value ?? '').trim();
    final isEmpty = v.isEmpty;

    return textWidget(
      text: isEmpty ? (hintText ?? '') : v,
      color: isEmpty ? ProjectColors.whiteColor.withOpacity(0.6) : ProjectColors.whiteColor,
      fontWeight: FontWeight.w800,
    );
  }

  Widget _buildBoldTextField() {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: TextStyle(
        fontSize: height * 0.015,
        color: ProjectColors.whiteColor,
        fontFamily: 'poppins',
        fontWeight: FontWeight.w800,
      ),
      cursorColor: ProjectColors.yellowColor,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: height * 0.015,
          color: ProjectColors.whiteColor.withOpacity(0.45),
          fontFamily: 'poppins',
          fontWeight: FontWeight.w600,
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          fontSize: height * 0.015,
          color: ProjectColors.whiteColor,
          fontFamily: 'poppins',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DateField({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.012),
        decoration: BoxDecoration(
          color: const Color(0xff1c1c1c),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            textWidget(
              text: label,
              fontSize: 0.018,
              color: ProjectColors.whiteColor,
            ),
            const Spacer(),
            Icon(
              Icons.calendar_today_outlined,
              size: height * 0.018,
              color: ProjectColors.blackColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class BigFormField extends StatelessWidget {
  const BigFormField({
    super.key,
    required this.form,
    this.textAlign = TextAlign.start,
    this.fontScale = .016, // fontSize = height * fontScale
    this.fontWeight = FontWeight.bold,
    this.maxLines = 1,
    this.color,
    this.cursorColor,
  });

  final TextForm form; // <-- your model: TextForm(title, controller)
  final TextAlign textAlign;
  final double fontScale;
  final FontWeight fontWeight;
  final int maxLines;
  final Color? color;
  final Color? cursorColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: form.controller,
      textAlign: textAlign,
      maxLines: maxLines,
      style: TextStyle(
        color: color ?? ProjectColors.whiteColor,
        fontSize: height * fontScale,
        fontWeight: fontWeight,
      ),
      cursorColor: cursorColor ?? ProjectColors.whiteColor,
      decoration: InputDecoration(
        hint: textWidget(
          text: form.title,
          textAlign: textAlign,
          color: ProjectColors.whiteColor,
          fontSize: fontScale,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class PriorityRow extends StatelessWidget {
  final GoalPriority selected;
  final ValueChanged<GoalPriority> onChanged;

  const PriorityRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, GoalPriority p, Color color) {
      final isSelected = selected == p;

      return GestureDetector(
        onTap: () => onChanged(p), // ✅ return selected value
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.03,
            vertical: height * 0.008,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: height * 0.012,
                height: height * 0.012,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: width * 0.012),
              textWidget(
                text: label,
                fontSize: 0.015,
                color: ProjectColors.whiteColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: 'Priority',
          fontSize: 0.016,
          color: ProjectColors.whiteColor.withOpacity(0.6),
        ),
        SizedBox(height: height * 0.008),
        Row(
          children: [
            pill('High', GoalPriority.high, Colors.redAccent),
            SizedBox(width: width * 0.02),
            pill('Medium', GoalPriority.medium, Colors.orangeAccent),
            SizedBox(width: width * 0.02),
            pill('Low', GoalPriority.low, Colors.greenAccent),
          ],
        ),
      ],
    );
  }
}


Widget segmentedToggle({
  required List<String> options,
  required int selectedIndex,
  required void Function(int index, String value) onChanged,
  double pillPadding = .01,
  double verticalPadding = .009,
  double itemWidthFactor = .2, // each item width = width * this
  Color bgColor = ProjectColors.backgroundColor,
  Color activeColor = ProjectColors.greenColor,
  Color textColor = ProjectColors.whiteColor,
  double fontSize = .015,
  cWidth = 1.0,
}) {
  assert(options.isNotEmpty, 'options cannot be empty');
  assert(selectedIndex >= 0 && selectedIndex < options.length, 'selectedIndex out of range');

  return Container(
    width: width * cWidth,
    padding: EdgeInsets.all(width * pillPadding),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(options.length, (i) {
        final selected = i == selectedIndex;

        return GestureDetector(
          onTap: () => onChanged(i, options[i]),
          child: Container(
            width: width * itemWidthFactor,
            padding: EdgeInsets.symmetric(vertical: height * verticalPadding),
            decoration: BoxDecoration(
              color: selected ? activeColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: textWidget(
              text: options[i],
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: selected ? activeColor : textColor,
            ),
          ),
        );
      }),
    ),
  );
}

class EmptyInsightsScreen extends StatelessWidget {
  String? title;
  String? subTitle;
  String? btnTitle;
  VoidCallback? callback;
  bool? showButton;

  EmptyInsightsScreen({this.title, this.subTitle, this.btnTitle = "Add shift", this.callback, this.showButton = true});

  @override
  Widget build(BuildContext context) {
    final VoidCallback onTap = callback ??
        () {
          shift.changeShiftTabs('Calendar');
          shift.activeShift!.value = 'Calendar';
          shift.activeShift!.refresh();
        };
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * .08),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * .82),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slightly above true center
              SizedBox(height: height * .04),

              textWidget(
                text: title,
                fontSize: .03,
                fontWeight: FontWeight.w700,
                color: ProjectColors.whiteColor,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: height * .012),

              textWidget(
                text: subTitle,
                fontSize: .017,
                fontWeight: FontWeight.w500,
                color: ProjectColors.whiteColor.withOpacity(.55),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: height * .03),

              // Primary CTA
              Visibility(
                visible: showButton!,
                child: normalButton(
                  title: btnTitle,
                  cWidth: 1.0,
                  cHeight: .055,
                  fSize: .018,
                  invertColors: false,
                  bColor: ProjectColors.greenColor,
                  callback: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddContent extends StatelessWidget {
  String? title;
  String? subTitle;
  VoidCallback? callback;
  Color? color;
  IconData? icon;

  AddContent({this.title, this.subTitle, this.callback, this.icon = Icons.add, this.color});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: GestureDetector(
        onTap: callback,
        child: Row(
          children: [
            Container(
              width: height * .05,
              height: height * .05,
              decoration: BoxDecoration(
                color: ProjectColors.whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ProjectColors.whiteColor),
            ),
            SizedBox(width: width * .02),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: title, fontSize: .02, color: ProjectColors.whiteColor, fontWeight: FontWeight.bold),
                  SizedBox(height: height * .005),
                  textWidget(text: subTitle, color: ProjectColors.whiteColor),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ProjectColors.whiteColor),
          ],
        ),
      ),
    );
  }
}

class MonthPill extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const MonthPill({required this.label, required this.onPrev, required this.onNext, required this.canGoNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProjectColors.pureBlackColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPrev,
            child: Icon(Icons.chevron_left, size: height * .028, color: ProjectColors.whiteColor),
          ),
          SizedBox(width: width * .01),
          textWidget(text: label, fontSize: .018, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
          SizedBox(width: width * .01),
          GestureDetector(
            onTap: canGoNext ? onNext : null,
            child: Icon(
              Icons.chevron_right,
              size: height * .028,
              color: canGoNext ? ProjectColors.whiteColor : ProjectColors.whiteColor.withOpacity(.25),
            ),
          ),
        ],
      ),
    );
  }
}

class SegmentTabs extends StatelessWidget {
  SegmentTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.highlightValue,
    this.padding,
    this.bgOpacity = 0.1,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: width * cWidth!,
        decoration: BoxDecoration(
          color: ProjectColors.whiteColor.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(40),
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
  final Color? borderColor;
  final double? opacity;
  final double? borderOpacity;
  const DarkCard({
    required this.child,
    this.color = ProjectColors.whiteColor,
    this.opacity = .1,
    this.borderColor = ProjectColors.whiteColor,
    this.borderOpacity = .15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .01),
      decoration: BoxDecoration(
        color: color!.withOpacity(opacity!),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor!.withOpacity(borderOpacity!)),
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
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: height * .02),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: height * .005,
                            width: width * .2,
                            decoration: BoxDecoration(color: ProjectColors.whiteColor, borderRadius: BorderRadius.circular(20)),
                          ),
                          SizedBox(height: height * .01),
                          textWidget(
                            text: title!,
                            fontSize: .025,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.center,
                            color: color == ProjectColors.whiteColor ? ProjectColors.pureBlackColor : ProjectColors.whiteColor,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * .02),
                      child: body,
                    ),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}

class PickShiftTime extends StatelessWidget {
  final int columnIndex;
  const PickShiftTime({super.key, this.columnIndex = 0});

  bool _isBreak(ShiftController shift) => (shift.newShiftColumns?[columnIndex].title ?? '').toLowerCase().contains('break');

  DateTime _seed(ShiftController shift) {
    final d = shift.selectedDay!.value;
    return DateTime(d.year, d.month, d.day, 9, 0);
  }

  DateTime _readTimeOrSeed(ShiftController shift, DateTime seed) {
    final t = (shift.newShiftColumns?[columnIndex].controller.text ?? '').trim();
    if (t.isEmpty) return seed;

    // expects: "yyyy-MM-dd hh:mm a" (your existing)
    try {
      final dt = DateFormat('hh:mm a').parse(t);
      return DateTime(seed.year, seed.month, seed.day, dt.hour, dt.minute);
    } catch (_) {
      return seed;
    }
  }

  int _readBreakOrDefault(ShiftController shift) {
    final t = (shift.newShiftColumns?[columnIndex].controller.text ?? '').trim();
    if (t.isEmpty) return 0;
    return int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  void _write(ShiftController shift, {DateTime? time, int? breakMin}) {
    final col = shift.newShiftColumns![columnIndex];

    if (breakMin != null) {
      col.controller.text = breakMin.toString(); // ✅ store minutes
      col.pickedDate = null;
    } else if (time != null) {
      col.controller.text = DateFormat('hh:mm a').format(time);
      col.pickedDate = time;
    }

    shift.newShiftColumns!.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isBreak = _isBreak(shift);
    final seed = _seed(shift);

    final initialTime = isBreak ? null : _readTimeOrSeed(shift, seed);
    final initialBreak = isBreak ? _readBreakOrDefault(shift) : 0;

    return SizedBox(
      height: height * .6, // ✅ compact
      child: Popup(
        color: ProjectColors.blackColor,
        title: isBreak ? 'Set break (minutes)' : 'Set time',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassV2(
              body: CupertinoTheme(
                data: CupertinoTheme.of(navigatorKey.currentContext!).copyWith(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: ProjectColors.whiteColor,
                      fontSize: height * .025,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: SizedBox(
                  height: height * .28,
                  child: isBreak
                      ? CupertinoPicker(
                          itemExtent: 36,
                          scrollController: FixedExtentScrollController(
                            initialItem: (initialBreak / 5).round().clamp(0, 36), // 0..180 step 5
                          ),
                          onSelectedItemChanged: (i) {
                            final m = i * 5;
                            _write(shift, breakMin: m);
                          },
                          children: List.generate(
                            37, // 0..180
                            (i) => Center(
                              child: textWidget(
                                text: '${(i * 5)}',
                                fontSize: 0.02,
                                color: ProjectColors.whiteColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: false,
                          minuteInterval: 1,
                          initialDateTime: initialTime,
                          onDateTimeChanged: (dt) {
                            final fixed = DateTime(seed.year, seed.month, seed.day, dt.hour, dt.minute);
                            _write(shift, time: fixed);
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: height * .02),
              child: Center(
                child: normalButton(
                  title: "Save",
                  bColor: ProjectColors.greenColor,
                  cWidth: .8,
                  loading: false,
                  callback: () {
                    Get.back();
                  },
                ),
              ),
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
    String title = "Select Date",
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
          color: ProjectColors.pureBlackColor,
          title: title,
          body: SizedBox(
            height: height * .5,
            child: Column(
              children: [
                Glass(
                  body: SizedBox(
                    height: height * .3,
                    child: CupertinoTheme(
                      data: CupertinoTheme.of(navigatorKey.currentContext!).copyWith(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: ProjectColors.whiteColor,
                            fontSize: height * .025,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        backgroundColor: Colors.transparent,
                        initialDateTime: temp,
                        minimumDate: safeMin,
                        maximumDate: safeMax,
                        onDateTimeChanged: (val) => temp = val,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: height * .02),
                  child: Center(
                    child: normalButton(
                      title: "Save",
                      bColor: ProjectColors.greenColor,
                      cWidth: .8,
                      loading: false,
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

class Glass extends StatelessWidget {
  Widget? body;
  double? blur;
  double? radius;
  Glass({this.body, this.blur = 20, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius!),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x66FFFFFF), // top highlight
                Color(0x22FFFFFF), // mid
                Color(0x11000000), // subtle dark edge
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: body,
        ),
      ),
    );
  }
}

class GlassV2 extends StatelessWidget {
  Widget? body;
  Color? glassColor;

  GlassV2({this.body, this.glassColor = ProjectColors.whiteColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.01),
      padding: EdgeInsets.all(width * 0.02),
      decoration: BoxDecoration(
        color: glassColor!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassColor!.withOpacity(0.15)),
      ),
      child: body,
    );
  }
}

enum PickerMode { date, time, minutes, dayOfMonth }

class PickerResult {
  final DateTime? dateTime;
  final int? minutes;

  const PickerResult({this.dateTime, this.minutes});

  bool get isCancelled => dateTime == null && minutes == null;
}

class AppPicker {
  AppPicker._();

  /// One function for Date / Time / Minutes / Day-of-month.
  ///
  /// Returns:
  /// - PickerMode.date      -> PickerResult(dateTime: yyyy-mm-dd)
  /// - PickerMode.time      -> PickerResult(dateTime: seedDate with picked hh:mm)
  /// - PickerMode.minutes   -> PickerResult(minutes: int)
  /// - PickerMode.dayOfMonth-> PickerResult(minutes: int)  // (reusing minutes field as "day")
  static Future<PickerResult?> pick({
    required PickerMode mode,

    // common
    String title = "Select",
    Color sheetColor = ProjectColors.blackColor,

    // date params
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,

    // time params
    DateTime? seedDate, // day to attach time to
    DateTime? initialTime,

    // minutes params
    int initialMinutes = 0,
    int minMinutes = 0,
    int maxMinutes = 180,
    int stepMinutes = 5,

    // days
    int initialDay = 15,
    int minDay = 1,
    int maxDay = 31,
  }) async {
    final now = DateTime.now();

    // ----- date safety -----
    final DateTime safeMin = minDate ?? now;
    final DateTime safeMax = maxDate ?? DateTime(now.year + 5);

    DateTime dateTemp = initialDate ?? safeMin;
    if (dateTemp.isBefore(safeMin)) dateTemp = safeMin;
    if (dateTemp.isAfter(safeMax)) dateTemp = safeMax;

    // ----- time seed -----
    final DateTime seed = seedDate ?? DateTime(now.year, now.month, now.day, 9, 0);

    DateTime timeTemp = initialTime ?? DateTime(seed.year, seed.month, seed.day, 9, 0);
    timeTemp = DateTime(seed.year, seed.month, seed.day, timeTemp.hour, timeTemp.minute);

    // ----- minutes & day -----
    int minutesTemp = initialMinutes.clamp(minMinutes, maxMinutes);
    int dayTemp = initialDay.clamp(minDay, maxDay);

    PickerResult? result;

    await showCupertinoModalPopup(
      context: navigatorKey.currentContext!,
      barrierColor: ProjectColors.blackColor.withOpacity(0.5),
      builder: (ctx) {
        return Popup(
          color: sheetColor,
          title: title,
          body: SizedBox(
            height: height * .5,
            child: Column(
              children: [
                DarkCard(
                  child: SizedBox(
                    height: height * .3,
                    child: CupertinoTheme(
                      data: CupertinoTheme.of(navigatorKey.currentContext!).copyWith(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: ProjectColors.whiteColor,
                            fontSize: height * .025,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: _pickerBody(
                        mode: mode,

                        // date
                        safeMin: safeMin,
                        safeMax: safeMax,
                        dateTemp: dateTemp,
                        onDateChanged: (v) => dateTemp = v,

                        // time
                        seed: seed,
                        timeTemp: timeTemp,
                        onTimeChanged: (v) => timeTemp = v,

                        // minutes
                        minutesTemp: minutesTemp,
                        onMinutesChanged: (v) => minutesTemp = v,
                        minMinutes: minMinutes,
                        maxMinutes: maxMinutes,
                        stepMinutes: stepMinutes,

                        // day-of-month
                        dayTemp: dayTemp,
                        onDayChanged: (v) => dayTemp = v, // ✅ FIX: update outer variable
                        minDay: minDay,
                        maxDay: maxDay,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: height * .02),
                  child: Center(
                    child: normalButton(
                      title: "Save",
                      bColor: ProjectColors.greenColor,
                      cWidth: .8,
                      loading: false,
                      callback: () {
                        if (mode == PickerMode.minutes) {
                          result = PickerResult(minutes: minutesTemp);
                        } else if (mode == PickerMode.time) {
                          result = PickerResult(
                            dateTime: DateTime(seed.year, seed.month, seed.day, timeTemp.hour, timeTemp.minute),
                          );
                        } else if (mode == PickerMode.dayOfMonth) {
                          result = PickerResult(minutes: dayTemp); // reuse minutes field as int day
                        } else {
                          result = PickerResult(
                            dateTime: DateTime(dateTemp.year, dateTemp.month, dateTemp.day),
                          );
                        }
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

  static Widget _pickerBody({
    required PickerMode mode,

    // date
    required DateTime safeMin,
    required DateTime safeMax,
    required DateTime dateTemp,
    required void Function(DateTime) onDateChanged,

    // time
    required DateTime seed,
    required DateTime timeTemp,
    required void Function(DateTime) onTimeChanged,

    // minutes
    required int minutesTemp,
    required void Function(int) onMinutesChanged,
    required int minMinutes,
    required int maxMinutes,
    required int stepMinutes,

    // day-of-month
    required int dayTemp,
    required void Function(int) onDayChanged,
    required int minDay,
    required int maxDay,
  }) {
    if (mode == PickerMode.dayOfMonth) {
      final count = (maxDay - minDay) + 1;
      final initialIndex = (dayTemp - minDay).clamp(0, count - 1);

      return CupertinoPicker(
        itemExtent: 36,
        scrollController: FixedExtentScrollController(initialItem: initialIndex),
        onSelectedItemChanged: (i) => onDayChanged(minDay + i), // ✅ FIX
        children: List.generate(
          count,
          (i) => Center(
            child: textWidget(
              text: '${minDay + i}',
              fontSize: 0.02,
              color: ProjectColors.whiteColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (mode == PickerMode.date) {
      return CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        backgroundColor: Colors.transparent,
        initialDateTime: dateTemp,
        minimumDate: safeMin,
        maximumDate: safeMax,
        onDateTimeChanged: onDateChanged,
      );
    }

    if (mode == PickerMode.time) {
      return CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        use24hFormat: false,
        minuteInterval: 1,
        initialDateTime: timeTemp,
        onDateTimeChanged: (dt) => onTimeChanged(
          DateTime(seed.year, seed.month, seed.day, dt.hour, dt.minute),
        ),
      );
    }

    // minutes picker
    final steps = ((maxMinutes - minMinutes) / stepMinutes).floor();
    final initialIndex = ((minutesTemp - minMinutes) / stepMinutes).round().clamp(0, steps);

    return CupertinoPicker(
      itemExtent: 36,
      scrollController: FixedExtentScrollController(initialItem: initialIndex),
      onSelectedItemChanged: (i) => onMinutesChanged(minMinutes + (i * stepMinutes)),
      children: List.generate(
        steps + 1,
        (i) => Center(
          child: textWidget(
            text: '${minMinutes + (i * stepMinutes)}',
            fontSize: 0.02,
            color: ProjectColors.whiteColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
