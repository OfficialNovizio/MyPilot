import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/material.dart';

import '../../Constants.dart';

class DebtDashboard extends StatelessWidget {
  const DebtDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0B0B0B);
    final card = const Color(0xff101010);
    final card2 = const Color(0xFF101010);
    final border = Colors.white.withOpacity(0.06);
    final textMuted = Colors.white.withOpacity(0.70);
    final textFaint = Colors.white.withOpacity(0.50);
    const accent = Color(0xFF2F6BFF);
    const good = Color(0xFF2ECC71);
    const bad = Color(0xFFFF4D4D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * .04),
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                title: 'This Pay Period',
                trailing: _LinkText(
                  label: 'View Details',
                  onTap: () {},
                ),
              ),
              SizedBox(height: height * .01),
              _KeyValueRow(
                label: 'Income',
                value: r'$2,600',
              ),
              SizedBox(height: height * .005),
              _KeyValueRow(
                label: 'Essentials',
                value: r'$1,700',
              ),
              SizedBox(height: height * .005),
              _KeyValueRow(
                label: 'Debt plan',
                value: r'$500',
              ),
              SizedBox(height: height * .005),
              Row(
                children: [
                  Expanded(
                    child: _KeyValueRow(
                      label: 'Surplus',
                      value: r'$400',
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .005),
                    decoration: BoxDecoration(
                      color: good.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: good.withOpacity(0.20)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: height * .02, color: good),
                        SizedBox(width: width * .015),
                        textWidget(text: 'On track', color: good, fontWeight: FontWeight.w700),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: height * .01),
        DarkCard(
          // color: ProjectColors.greenColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                title: 'Bill Timing Risk',
                trailing: _LinkText(
                  label: 'Upcoming',
                  onTap: () {},
                ),
              ),
              textWidget(
                text: 'High',
                fontSize: .03,
                color: ProjectColors.errorColor,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: height * .005),
              textWidget(
                text: '2 bills due before next paycheque',
                fontSize: .018,
                color: ProjectColors.whiteColor,
              ),
            ],
          ),
        ),
        SizedBox(height: height * .01),
        DarkCard(
          color: ProjectColors.greenColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(title: 'This Paycheque Plan', color: ProjectColors.blackColor),
              SizedBox(height: height * .01),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DonutRing(
                    size: 74,
                    stroke: 10,
                    progress: 0.56, // To debt vs buffer visual
                    color: accent,
                    bgColor: Color(0xFF232323),
                  ),
                  SizedBox(width: width * .04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LineItem(
                          label: 'To debt',
                          value: r'$500',
                          labelColor: ProjectColors.pureBlackColor,
                          valueColor: ProjectColors.pureBlackColor,
                        ),
                        SizedBox(height: height * .01),
                        _LineItem(
                          label: 'Buffer',
                          value: r'$400',
                          labelColor: ProjectColors.pureBlackColor,
                          valueColor: ProjectColors.pureBlackColor,
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(width: width * .05),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      textWidget(text: 'Strategy:', fontSize: .018),
                      SizedBox(height: height * .005),
                      textWidget(text: 'Snowball', fontSize: .02, fontWeight: FontWeight.bold),
                      SizedBox(height: height * .005),
                      textWidget(text: '(Car \$300 → Visa \$200)'),
                    ],
                  )
                ],
              ),
              SizedBox(height: height * .015),
              normalButton(title: 'View Strategies', fSize: .018)
            ],
          ),
        ),
        SizedBox(height: height * .015),
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(title: 'Actions'),
              SizedBox(height: height * .01),
              _CheckRow(text: r'Pay $300 to Car Loan (due May 28)', textColor: ProjectColors.whiteColor),
              _CheckRow(text: r'Pay $200 extra to Visa', textColor: ProjectColors.whiteColor),
              _CheckRow(text: r'Set aside $400 buffer', textColor: ProjectColors.whiteColor),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Color? color;

  const _CardHeader({required this.title, this.trailing, this.color = ProjectColors.whiteColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        textWidget(
          text: title,
          fontSize: .025,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _LinkText extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _LinkText({
    required this.label,
    this.color = ProjectColors.greenColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .01),
        child: Row(
          children: [
            textWidget(
              text: label,
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: .015,
            ),
            Icon(Icons.chevron_right, color: color, size: height * .025),
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        textWidget(text: '$label:', color: ProjectColors.whiteColor, fontSize: .018),
        SizedBox(width: width * .015),
        textWidget(text: value, color: ProjectColors.whiteColor, fontSize: .018, fontWeight: FontWeight.bold),
      ],
    );
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;

  const _LineItem({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        textWidget(text: '$label:', fontSize: .018),
        SizedBox(width: width * .02),
        textWidget(text: value, fontSize: .018, fontWeight: FontWeight.bold),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  final Color textColor;

  const _CheckRow({
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: height * .005),
      child: Row(
        children: [
          Container(
            width: height * .022,
            height: height * .022,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ProjectColors.whiteColor.withOpacity(0.20)),
            ),
          ),
          SizedBox(width: width * .02),
          Expanded(
            child: textWidget(text: text, color: textColor, fontWeight: FontWeight.w600, fontSize: .016),
          ),
        ],
      ),
    );
  }
}

/// Simple donut ring using CustomPainter (no extra packages).
class _DonutRing extends StatelessWidget {
  final double size;
  final double stroke;
  final double progress; // 0..1
  final Color color;
  final Color bgColor;

  const _DonutRing({
    required this.size,
    required this.stroke,
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DonutPainter(
        stroke: stroke,
        progress: progress.clamp(0.0, 1.0),
        color: color,
        bgColor: bgColor,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double stroke;
  final double progress;
  final Color color;
  final Color bgColor;

  _DonutPainter({
    required this.stroke,
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final start = -90.0 * 3.141592653589793 / 180.0;
    final sweep = (progress * 360.0) * 3.141592653589793 / 180.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.bgColor != bgColor || oldDelegate.stroke != stroke;
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F6BFF) : Colors.white.withOpacity(0.55);
    return SizedBox(
      width: 74,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          )
        ],
      ),
    );
  }
}
