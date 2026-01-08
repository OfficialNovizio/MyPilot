import 'package:emptyproject/BaseScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Constant UI.dart';
import '../../Constants.dart';
import '../../Controllers.dart';
import '../All Debts/Combined Data Dashboard.dart';

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

// ================== CONTROLLER ==================
class DebtFreeHomeController extends GetxController {
  RxInt modeIndex = 0.obs; // 0 = Safest, 1 = Fastest

  // Fake data (replace with real)
  final String priorityTitle = 'Priority: Visa \$60 minimum due in 16 days';
  final String prioritySubtitle = 'Due before payday • avoid late fee + credit hit';

  final String payday = 'April 5 payday';
  final String minPay = '\$60';
  final String extraPay = '\$200';

  final String debtFreeA = 'June 1, 2025';
  final String debtFreeB = 'Aug 4, 2025';
  final String interestSaved = '~\$400 total interest saved';

  final String ifUnchanged = '+\$130 interest by next payday';

  final String topBurnerName = 'Platinum';
  final String topBurnerMeta = '78% of burn — APR 23.9%';
  final String topBurnerPerDay = '~\$2.10/day';
}

// ================== SCREEN ==================
class ComparisonCardsHomeScreen extends StatelessWidget {
  ComparisonCardsHomeScreen({super.key});

  final c = Get.put(DebtFreeHomeController());
  final ctrl = Get.put(DebtDashCtrl());

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Debt Insights',
      body: Obx(
        () => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * .015),
              segmentedToggle(
                activeColor: ProjectColors.greenColor.withOpacity(0.2),
                options: ['Safest', 'Fastest'],
                selectedIndex: debt.debtResolve!.value == 'Safest' ? 0 : 1,
                onChanged: (i, v) {
                  debt.debtResolve!.value = v;
                },
              ),
              SizedBox(height: height * .012),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .014),
                decoration: BoxDecoration(
                  color: ProjectColors.brownColor, // soft warm banner like the ref
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(.05)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: height * .022, color: Colors.black54),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textWidget(
                            text: c.priorityTitle,
                            fontSize: .0155,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(height: height * .004),
                          textWidget(
                            text: c.prioritySubtitle,
                            fontSize: .013,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.black54, size: height * .028),
                  ],
                ),
              ),
              SizedBox(height: height * .01),
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
              SizedBox(height: height * .01),
              _MinimumCard(),
              SizedBox(height: height * .014),
              _IfUnchangedRow(),
              SizedBox(height: height * .014),
              _TopBurnerRow(),
              SizedBox(height: height * .02),
              SizedBox(height: height * .01),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const _ModeToggle({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * .012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ChipToggle(
              label: 'Safest',
              active: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          SizedBox(width: width * .012),
          Expanded(
            child: _ChipToggle(
              label: 'Fastest',
              active: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChipToggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: height * .012),
        decoration: BoxDecoration(
          color: active ? ProjectColors.greenColor.withOpacity(.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? ProjectColors.greenColor.withOpacity(.35) : Colors.black.withOpacity(.06),
          ),
        ),
        child: Center(
          child: textWidget(
            text: label,
            fontSize: .016,
            fontWeight: FontWeight.w600,
            color: ProjectColors.pureBlackColor,
          ),
        ),
      ),
    );
  }
}

class _MinimumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtFreeHomeController>();

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: textWidget(
                  text: 'Minimum',
                  fontSize: .018,
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.all(width * .01),
                decoration: BoxDecoration(
                  color: ProjectColors.whiteColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.more_horiz, size: height * .02, color: ProjectColors.blackColor),
              ),
            ],
          ),
          SizedBox(height: height * .012),

          // Pay minimum block
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .014),
            decoration: BoxDecoration(
              color: ProjectColors.greenColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ProjectColors.greenColor.withOpacity(.20)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: ProjectColors.greenColor, size: height * .022),
                SizedBox(width: width * .02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(
                        text: 'Pay ${c.minPay} minimum',
                        fontSize: .017,
                        color: ProjectColors.whiteColor,
                        fontWeight: FontWeight.w800,
                      ),
                      SizedBox(height: height * .004),
                      textWidget(
                        text: 'Avoid late fee and credit mark',
                        fontSize: .0135,
                        color: ProjectColors.whiteColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * .01),

          // Payday row
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .013),
            decoration: BoxDecoration(
              color: ProjectColors.whiteColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                textWidget(text: c.payday, fontSize: .0145, fontWeight: FontWeight.w600, color: ProjectColors.pureBlackColor),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.black54, size: height * .026),
              ],
            ),
          ),

          SizedBox(height: height * .01),

          // Pay extra block
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .014),
            decoration: BoxDecoration(
              color: ProjectColors.greenColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ProjectColors.greenColor.withOpacity(.20)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: ProjectColors.greenColor, size: height * .022),
                SizedBox(width: width * .02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(
                        text: 'Pay ${c.extraPay} extra',
                        fontSize: .0165,
                        color: ProjectColors.whiteColor,
                        fontWeight: FontWeight.w800,
                      ),
                      SizedBox(height: height * .004),
                      textWidget(
                        text: 'Speeds up payoff → 3 weeks',
                        fontSize: .0135,
                        color: ProjectColors.whiteColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * .012),

          // Debt-free comparison mini grid
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .014),

            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(text: 'Debt-Free', fontSize: .014, fontWeight: FontWeight.w800, color: ProjectColors.whiteColor),
                      SizedBox(height: height * .004),
                      textWidget(text: c.debtFreeA, fontSize: .0165, fontWeight: FontWeight.w800, color: ProjectColors.whiteColor),
                    ],
                  ),
                ),
                Container(width: 1, height: height * .05, color: ProjectColors.whiteColor),
                SizedBox(width: width * .03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(text: 'Debt-Free', fontSize: .014, fontWeight: FontWeight.w800, color: ProjectColors.whiteColor),
                      SizedBox(height: height * .004),
                      textWidget(text: c.debtFreeB, fontSize: .0165, fontWeight: FontWeight.w800, color: ProjectColors.whiteColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * .01),

          // Interest saved line
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: width * .035, vertical: height * .012),
            decoration: BoxDecoration(
              color: ProjectColors.greenColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ProjectColors.greenColor.withOpacity(.20)),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_outlined, color: ProjectColors.greenColor, size: height * .022),
                SizedBox(width: width * .02),
                Expanded(
                  child: textWidget(
                    text: c.interestSaved,
                    fontSize: .0145,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.whiteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IfUnchangedRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtFreeHomeController>();
    return DarkCard(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(text: 'If unchanged...', fontSize: .0155, fontWeight: FontWeight.w700, color: Colors.black87),
                SizedBox(height: height * .006),
                textWidget(text: c.ifUnchanged, fontSize: .0165, fontWeight: FontWeight.w800),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.black54, size: height * .028),
        ],
      ),
    );
  }
}

class _TopBurnerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtFreeHomeController>();

    return DarkCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              textWidget(text: 'Top Burner', fontSize: .017, fontWeight: FontWeight.w800),
              const Spacer(),
              // small fake bars like the ref (tiny, purely decorative)
              Row(
                children: List.generate(
                  6,
                  (i) => Container(
                    width: width * .02,
                    height: height * (.008 + (i % 3) * .004),
                    margin: EdgeInsets.only(left: width * .008),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: height * .012),
          Row(
            children: [
              // Card badge
              Container(
                width: width * .18,
                height: height * .055,
                decoration: BoxDecoration(
                  color: ProjectColors.blackColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: EdgeInsets.all(width * .02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: width * .028,
                        height: width * .028,
                        decoration: BoxDecoration(
                          color: ProjectColors.greenColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const Spacer(),
                      textWidget(text: 'VISA', fontSize: .0115, color: Colors.white70, fontWeight: FontWeight.w700),
                    ],
                  ),
                ),
              ),
              SizedBox(width: width * .03),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        textWidget(text: c.topBurnerName, fontSize: .0165, fontWeight: FontWeight.w800),
                        const Spacer(),
                        textWidget(
                          text: c.topBurnerPerDay,
                          fontSize: .015,
                          fontWeight: FontWeight.w800,
                          color: ProjectColors.greenColor,
                        ),
                      ],
                    ),
                    SizedBox(height: height * .005),
                    textWidget(
                      text: c.topBurnerMeta,
                      fontSize: .0135,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * .06, vertical: height * .012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _NavIcon(active: true, icon: Icons.home_rounded),
          _NavIcon(active: false, icon: Icons.bar_chart_rounded),
          _NavIcon(active: false, icon: Icons.receipt_long_rounded),
          _NavIcon(active: false, icon: Icons.person_outline_rounded),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final bool active;
  final IconData icon;
  const _NavIcon({required this.active, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * .12,
      height: width * .12,
      decoration: BoxDecoration(
        color: active ? ProjectColors.greenColor.withOpacity(.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: active ? ProjectColors.greenColor : Colors.black45,
        size: height * .028,
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  const _IconCircle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * .11,
      height: width * .11,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Icon(icon, size: height * .026, color: Colors.black54),
    );
  }
}
