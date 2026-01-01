import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

import '../../Constants.dart';

// -------------------- SCREEN --------------------

class DebtDashboardV1 extends StatelessWidget {
  const DebtDashboardV1({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(_DebtDashCtrl());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.04),
        _InsightCard(
          title: "Payday buffer",
          leftMain: "\$430",
          leftTag: const _Tag(text: "Safe", color: ProjectColors.greenColor),
          leftSub: "• -\$320 this month",
          rightWidget: _Ring(
            value: 0.78,
            size: height * 0.075,
            stroke: 10,
            centerTop: "\$430",
            centerBottom: "Safe",
            ringColor: ProjectColors.greenColor,
          ),
          onTap: () {},
        ),
        SizedBox(height: height * 0.01),
        _InsightCard(
          title: "Interest burn",
          leftMain: "\$92",
          leftSub: "(Visa \$65)",
          rightWidget: _Ring(
            value: 0.62,
            size: height * 0.075,
            stroke: 10,
            centerTop: "\$92",
            centerBottom: "High",
            ringColor: ProjectColors.yellowColor,
          ),
          onTap: () {},
        ),
        SizedBox(height: height * 0.01),
        GestureDetector(
          child: DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniPillIcon(
                      bg: ProjectColors.yellowColor.withOpacity(0.15),
                      icon: Icons.local_fire_department,
                      iconColor: ProjectColors.yellowColor,
                    ),
                    SizedBox(width: width * 0.025),
                    Expanded(
                      child: textWidget(
                        text: "Due before payday",
                        fontSize: 0.02,
                        fontWeight: FontWeight.w800,
                        color: ProjectColors.whiteColor,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: ProjectColors.whiteColor.withOpacity(0.35),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.012),
                textWidget(
                  text: "Car Loan \$300  in 3 days",
                  fontSize: 0.018,
                  fontWeight: FontWeight.w700,
                  color: ProjectColors.whiteColor.withOpacity(0.9),
                ),
                SizedBox(height: height * 0.006),
                textWidget(
                  text: "Next payday: Jan 5  —  bill due: Jan 2",
                  fontSize: 0.015,
                  color: ProjectColors.whiteColor.withOpacity(0.55),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: height * 0.01),
        DarkCard(
          color: ProjectColors.greenColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: "Payoff timeline",
                fontSize: 0.03,
                fontWeight: FontWeight.w800,
                color: ProjectColors.pureBlackColor,
              ),
              SizedBox(height: height * 0.01),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        textWidget(
                          text: "Debt-free in:",
                          fontSize: 0.016,
                          color: ProjectColors.pureBlackColor.withOpacity(0.6),
                        ),
                        SizedBox(width: width * 0.02),
                        textWidget(
                          text: "${ctrl.monthsFromExtra(ctrl.extra.value)} months",
                          fontSize: 0.018,
                          fontWeight: FontWeight.w900,
                          color: ProjectColors.pureBlackColor,
                        ),
                        const Spacer(),
                        textWidget(
                          text: "+\$${ctrl.extra.value.toInt()}",
                          fontSize: 0.02,
                          fontWeight: FontWeight.w800,
                          color: ProjectColors.pureBlackColor,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        textWidget(
                          text: "Interest saved:",
                          fontSize: 0.016,
                          color: ProjectColors.pureBlackColor.withOpacity(0.6),
                        ),
                        SizedBox(width: width * 0.02),
                        textWidget(
                          text: "\$2,700",
                          fontSize: 0.018,
                          fontWeight: FontWeight.w900,
                          color: ProjectColors.pureBlackColor,
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: ProjectColors.pureBlackColor,
                        inactiveTrackColor: ProjectColors.pureBlackColor.withOpacity(0.12),
                        thumbColor: ProjectColors.pureBlackColor,
                        overlayColor: ProjectColors.pureBlackColor.withOpacity(0.15),
                      ),
                      child: Slider(
                        min: 0,
                        max: 300,
                        divisions: 6,
                        value: ctrl.extra.value,
                        onChanged: (v) => ctrl.extra.value = v,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _MiniLabel("\$0 extra"),
                        _MiniLabel("+\$50"),
                        _MiniLabel("+\$100"),
                        _MiniLabel("+\$200"),
                        _MiniLabel("+\$300"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------- CONTROLLER --------------------

class _DebtDashCtrl extends GetxController {
// 0=Debts, 1=Plan, 2=Insights
  final tab = 2.obs;

// used in payoff timeline demo
  final extra = 50.0.obs;

  int monthsFromExtra(double extraPay) {
// demo logic — replace with real amortization output
// baseline 27 months; higher extra reduces months
    const base = 27;
    final reduction = (extraPay / 50).floor() * 2; // every +$50 => -2 months (mock)
    final result = base - reduction;
    return result < 6 ? 6 : result;
  }
}

// -------------------- UI PARTS --------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onInfo});

  final String title;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        textWidget(
          text: title,
          fontSize: 0.026,
          fontWeight: FontWeight.w900,
          color: ProjectColors.whiteColor,
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onInfo,
          child: Padding(
            padding: EdgeInsets.all(width * 0.01),
            child: Icon(
              Icons.info_outline,
              color: ProjectColors.whiteColor.withOpacity(0.7),
              size: height * 0.026,
            ),
          ),
        ),
      ],
    );
  }
}

class SegmentTabs extends StatelessWidget {
  const SegmentTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.highlightIndex,
    this.padding,
    this.bgOpacity = 0.05,
    this.borderOpacity = 0.07,
    this.thumbOpacity = 0.10,
  });

  /// selected index
  final int value;

  /// callback when a tab is selected
  final ValueChanged<int> onChanged;

  /// labels for tabs in order (index = position)
  final List<String> items;

  /// optional: which tab should use the green highlight when active (e.g. Insights)
  final int? highlightIndex;

  /// optional outer padding
  final EdgeInsets? padding;

  final double bgOpacity;
  final double borderOpacity;
  final double thumbOpacity;

  @override
  Widget build(BuildContext context) {
    // build the Cupertino children map dynamically
    final Map<int, Widget> children = {
      for (int i = 0; i < items.length; i++)
        i: _SegItem(
          text: items[i],
          active: value == i,
          highlight: highlightIndex == i,
        ),
    };

    return Container(
      padding: padding ?? EdgeInsets.all(width * 0.01),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
      ),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: value,
        thumbColor: Colors.white.withOpacity(thumbOpacity),
        backgroundColor: Colors.transparent,
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.leftMain,
    this.leftTag,
    this.leftSub,
    required this.rightWidget,
    this.footer,
    this.onTap,
  });

  final String title;
  final String leftMain;
  final Widget? leftTag;
  final String? leftSub;
  final Widget rightWidget;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                textWidget(
                  text: title,
                  fontSize: 0.03,
                  fontWeight: FontWeight.w800,
                  color: ProjectColors.whiteColor,
                ),
                textWidget(
                  text: "View Insights >",
                  fontSize: .018,
                  color: ProjectColors.greenColor,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        textWidget(
                          text: leftMain,
                          fontSize: 0.045,
                          fontWeight: FontWeight.w900,
                          color: ProjectColors.whiteColor,
                        ),
                        SizedBox(width: width * 0.02),
                        if (leftTag != null) leftTag!,
                      ],
                    ),
                    if (leftSub != null) ...[
                      textWidget(
                        text: leftSub!,
                        fontSize: 0.02,
                        color: ProjectColors.whiteColor.withOpacity(0.55),
                      ),
                    ],
                  ],
                ),
                rightWidget,
              ],
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: card,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.006),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: textWidget(
        text: text,
        fontSize: 0.014,
        fontWeight: FontWeight.w800,
        color: color,
        fontFamily: "poppins",
      ),
    );
  }
}

class _MiniPillIcon extends StatelessWidget {
  const _MiniPillIcon({required this.bg, required this.icon, required this.iconColor});
  final Color bg;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: height * 0.045,
      height: height * 0.045,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Icon(icon, color: iconColor, size: height * 0.022),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return textWidget(
      text: text,
      fontSize: 0.014,
      color: ProjectColors.pureBlackColor,
      fontWeight: FontWeight.w600,
    );
  }
}

// -------------------- RING (fl_chart) --------------------

class _Ring extends StatelessWidget {
  const _Ring({
    required this.value,
    required this.size,
    required this.stroke,
    required this.centerTop,
    required this.centerBottom,
    required this.ringColor,
  });

  final double value; // 0..1
  final double size;
  final double stroke;
  final String centerTop;
  final String centerBottom;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: (size / 2) - stroke,
              sections: [
                PieChartSectionData(
                  value: v * 100,
                  color: ringColor,
                  radius: stroke,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (1 - v) * 100,
                  color: Colors.white.withOpacity(0.10),
                  radius: stroke,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              textWidget(
                text: centerTop,
                fontSize: 0.015,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor,
                fontFamily: "poppins",
              ),
              textWidget(
                text: centerBottom,
                fontSize: 0.012,
                fontWeight: FontWeight.w700,
                color: ProjectColors.whiteColor.withOpacity(0.55),
                fontFamily: "poppins",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
