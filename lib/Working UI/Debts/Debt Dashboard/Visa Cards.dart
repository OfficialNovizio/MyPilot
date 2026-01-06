import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../Constants.dart';

// -------------------- MODEL --------------------

class DebtAccount {
  final String id;
  final String name; // e.g., "Visa Platinum"
  final String type; // "credit" or "loan"
  final double balance;
  final double limit; // for credit cards only (0 if not applicable)
  final double apr; // annual %
  final double minPayment;
  final DateTime dueDate;
  final double? promoApr; // e.g. 0.0
  final DateTime? promoEndDate; // if 0% promo exists
  final DateTime? statementDate; // optional
  final bool? autopayOn; // optional

  DebtAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.limit,
    required this.apr,
    required this.minPayment,
    required this.dueDate,
    this.promoApr,
    this.promoEndDate,
    this.statementDate,
    this.autopayOn,
  });

  bool get isCreditCard => type == "credit" && limit > 0;

  double get utilization => isCreditCard ? (balance / limit).clamp(0.0, 1.0) : 0.0;

  // Daily interest burn approx (simple)
  double get interestPerDay => (balance * (apr / 100)) / 365.0;
}

// -------------------- CONTROLLER --------------------

class DebtsDashCtrl extends GetxController {
  // Top segment tabs (string-based)
  final tab = "Insights".obs;

  // Toggle mode: true=All cards (combined), false=This card
  final allMode = true.obs;

  // Selected card index in horizontal list
  final selectedIndex = 0.obs;

  // Demo data (replace with your real storage)
  final accounts = <DebtAccount>[
    DebtAccount(
      id: "visa_platinum",
      name: "Visa Platinum",
      type: "credit",
      balance: 1200,
      limit: 1700,
      apr: 19.9,
      minPayment: 60,
      dueDate: DateTime(2026, 1, 7),
    ),
    DebtAccount(
      id: "visa_rewards",
      name: "Visa Rewards",
      type: "credit",
      balance: 500,
      limit: 2000,
      apr: 15.9,
      minPayment: 50,
      dueDate: DateTime(2026, 1, 10),
    ),
    DebtAccount(
      id: "car_loan",
      name: "Car Loan",
      type: "loan",
      balance: 8400,
      limit: 0,
      apr: 7.9,
      minPayment: 300,
      dueDate: DateTime(2026, 1, 2),
    ),
  ].obs;

  DebtAccount get selected => accounts[selectedIndex.value];

  // Combined credit utilization across all credit cards
  double get totalUtilizationCombined {
    double totalBal = 0;
    double totalLim = 0;
    for (final a in accounts) {
      if (a.isCreditCard) {
        totalBal += a.balance;
        totalLim += a.limit;
      }
    }
    if (totalLim <= 0) return 0;
    return (totalBal / totalLim).clamp(0.0, 1.0);
  }

  // Highest utilization credit card
  DebtAccount? get highestUtilCard {
    DebtAccount? best;
    double bestU = -1;
    for (final a in accounts) {
      if (!a.isCreditCard) continue;
      if (a.utilization > bestU) {
        bestU = a.utilization;
        best = a;
      }
    }
    return best;
  }

  // Total interest burn per day (all accounts)
  double get totalInterestPerDayAll {
    double sum = 0;
    for (final a in accounts) {
      sum += a.interestPerDay;
    }
    return sum;
  }

  // Interest per day for selected
  double get interestPerDaySelected => selected.interestPerDay;

  // Items due before a given payday date (demo)
  // Replace with your real "nextPayDate" logic
  DateTime get nextPayDate => DateTime(2026, 1, 5);

  List<DebtAccount> get dueBeforePayday {
    final list = accounts.where((a) => a.dueDate.isBefore(nextPayDate)).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  // Recommendation: in combined mode, focus highest utilization if exists, else highest interest/day
  DebtAccount get recommendedTarget {
    final hu = highestUtilCard;
    if (hu != null && hu.utilization >= 0.30) return hu;

    DebtAccount best = accounts.first;
    double bestBurn = -1;
    for (final a in accounts) {
      if (a.interestPerDay > bestBurn) {
        bestBurn = a.interestPerDay;
        best = a;
      }
    }
    return best;
  }

  // Format helpers
  String money(double v) => "\$${v.toStringAsFixed(0)}";
  String money2(double v) => "\$${v.toStringAsFixed(2)}";
  String pct(double v) => "${(v * 100).toStringAsFixed(0)}%";

  int daysUntil(DateTime date) {
    final now = DateTime(2026, 1, 1); // demo stable
    return date.difference(now).inDays;
  }

  double payDownTo30(DebtAccount a) {
    if (!a.isCreditCard) return 0;
    final target = 0.30 * a.limit;
    final needed = a.balance - target;
    return needed > 0 ? needed : 0;
  }

  String utilLabel(DebtAccount a) {
    if (!a.isCreditCard) return "Loan";
    final u = a.utilization;
    if (u >= 0.70) return "High";
    if (u >= 0.30) return "Watch";
    return "Safe";
  }

  Color utilColor(DebtAccount a) {
    if (!a.isCreditCard) return ProjectColors.whiteColor.withOpacity(0.6);
    final u = a.utilization;
    if (u >= 0.70) return ProjectColors.errorColor;
    if (u >= 0.30) return ProjectColors.yellowColor;
    return ProjectColors.greenColor;
  }

  DebtAccount get highestInterestBurn {
    DebtAccount best = accounts.first;
    double bestBurn = -1;
    for (final a in accounts) {
      if (a.interestPerDay > bestBurn) {
        bestBurn = a.interestPerDay;
        best = a;
      }
    }
    return best;
  }

  double get totalMinDueBeforePayday {
    double sum = 0;
    for (final a in dueBeforePayday) {
      sum += a.minPayment;
    }
    return sum;
  }
}

// -------------------- SCREEN --------------------

class VisaCardInsights extends StatelessWidget {
  const VisaCardInsights({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(DebtsDashCtrl());

    return SizedBox(
      height: height * .9,
      child: Popup(
        title: "Visa Card Insights",
        color: ProjectColors.blackColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: height * 0.16,
              child: Obx(
                () => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: ctrl.accounts.length,
                  separatorBuilder: (_, __) => SizedBox(width: width * 0.03),
                  itemBuilder: (context, i) {
                    final a = ctrl.accounts[i];
                    final selected = ctrl.selectedIndex.value == i;

                    return _DebtCard(
                      account: a,
                      isSelected: selected,
                      onTap: () => ctrl.selectedIndex.value = i,
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: height * 0.014),

            // Toggle (All cards / This card) - default All cards
            Obx(
              () => _ModeToggle(
                allMode: ctrl.allMode.value,
                onAll: () => ctrl.allMode.value = true,
                onSingle: () => ctrl.allMode.value = false,
              ),
            ),

            SizedBox(height: height * 0.014),

            // Content below toggle
            Expanded(
              child: Obx(
                () => ctrl.allMode.value ? _CombinedSection(ctrl: ctrl) : _SingleSection(ctrl: ctrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- COMBINED MODE UI --------------------

class _CombinedSection extends StatelessWidget {
  const _CombinedSection({required this.ctrl});
  final DebtsDashCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final highest = ctrl.highestUtilCard;
    final due = ctrl.dueBeforePayday;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total interest burn
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: ProjectColors.yellowColor, size: height * 0.022),
                  SizedBox(width: width * 0.02),
                  textWidget(
                    text: "Total interest burn: ~${ctrl.money2(ctrl.totalInterestPerDayAll)}/day",
                    fontSize: 0.018,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor,
                  ),
                ],
              ),

              SizedBox(height: height * 0.012),

              // Combined utilization + highest card
              Row(
                children: [
                  Icon(Icons.credit_card, color: ProjectColors.whiteColor.withOpacity(0.7), size: height * 0.022),
                  SizedBox(width: width * 0.02),
                  textWidget(
                    text: "${ctrl.pct(ctrl.totalUtilizationCombined)} combined utilization",
                    fontSize: 0.016,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.whiteColor.withOpacity(0.9),
                  ),
                ],
              ),
              if (highest != null) ...[
                SizedBox(height: height * 0.008),
                textWidget(
                  text: "Highest: ${highest.name} ${ctrl.pct(highest.utilization)} (High)",
                  fontSize: 0.015,
                  color: ProjectColors.whiteColor.withOpacity(0.6),
                ),
              ],

              SizedBox(height: height * 0.012),

              // Due before payday (specific)
              if (due.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: ProjectColors.errorColor, size: height * 0.022),
                    SizedBox(width: width * 0.02),
                    textWidget(
                      text: "${due.length} payment(s) due before payday",
                      fontSize: 0.016,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor,
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),
                ...due.take(2).map(
                      (a) => Padding(
                        padding: EdgeInsets.only(bottom: height * 0.006),
                        child: textWidget(
                          text: "• ${a.name} — ${ctrl.money(a.minPayment)} due in ${ctrl.daysUntil(a.dueDate)} days",
                          fontSize: 0.015,
                          color: ProjectColors.whiteColor.withOpacity(0.6),
                        ),
                      ),
                    ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.check_circle, color: ProjectColors.greenColor, size: height * 0.022),
                    SizedBox(width: width * 0.02),
                    textWidget(
                      text: "No payments due before payday",
                      fontSize: 0.016,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor.withOpacity(0.9),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: height * 0.014),

        // Charts row: bar + pie
        Row(
          children: [
            Expanded(
              child: _CardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: "Interest burn/day",
                      fontSize: 0.016,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor.withOpacity(0.85),
                    ),
                    SizedBox(height: height * 0.012),
                    SizedBox(
                      height: height * 0.14,
                      child: _InterestBarChart(accounts: ctrl.accounts),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: _CardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: "Balance share",
                      fontSize: 0.016,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor.withOpacity(0.85),
                    ),
                    SizedBox(height: height * 0.012),
                    SizedBox(
                      height: height * 0.14,
                      child: _BalancePie(accounts: ctrl.accounts),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: height * 0.016),
        SizedBox(height: height * 0.012),
        Row(
          children: [
            Icon(Icons.trending_up, color: ProjectColors.lightGreenColor, size: height * 0.022),
            SizedBox(width: width * 0.02),
            textWidget(
              text: "Highest burn: ${ctrl.highestInterestBurn.name} ~${ctrl.money2(ctrl.highestInterestBurn.interestPerDay)}/day",
              fontSize: 0.015,
              color: ProjectColors.whiteColor.withOpacity(0.65),
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
        SizedBox(height: height * 0.008),
        Row(
          children: [
            textWidget(
              text: "Pay to <30%:",
              fontSize: 0.014,
              color: ProjectColors.whiteColor.withOpacity(0.55),
            ),
            SizedBox(width: width * 0.02),
            textWidget(
              text: "\$2,77",
              fontSize: 0.015,
              fontWeight: FontWeight.w900,
              color: ProjectColors.lightGreenColor,
            ),
            const Spacer(),
            textWidget(
              text: "~\$7.7/day",
              fontSize: 0.014,
              color: ProjectColors.whiteColor.withOpacity(0.55),
            ),
          ],
        ),

        if (ctrl.dueBeforePayday.isNotEmpty) ...[
          SizedBox(height: height * 0.008),
          textWidget(
            text: "Minimums due before payday: ${ctrl.money(ctrl.totalMinDueBeforePayday)}",
            fontSize: 0.015,
            color: ProjectColors.whiteColor.withOpacity(0.65),
            fontWeight: FontWeight.w700,
          ),
        ],

        // Primary CTA (single target even in combined mode)
        normalButton(
          title: "Prioritize ${ctrl.recommendedTarget.name}",
          cHeight: 0.06,
          cWidth: 1.0,
          bColor: ProjectColors.lightGreenColor,
          invertColors: true,
          callback: () {
            // TODO: open insights sheet for ctrl.recommendedTarget
          },
        ),

        SizedBox(height: height * 0.02),
      ],
    );
  }
}

// -------------------- SINGLE MODE UI --------------------

class _SingleSection extends StatelessWidget {
  const _SingleSection({required this.ctrl});
  final DebtsDashCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final a = ctrl.selected;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _CardShell(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(
                text: a.name,
                fontSize: 0.02,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor,
              ),
              SizedBox(height: height * 0.01),
              if (a.isCreditCard) ...[
                Row(
                  children: [
                    textWidget(
                      text: "${ctrl.pct(a.utilization)}",
                      fontSize: 0.03,
                      fontWeight: FontWeight.w900,
                      color: a.utilization >= 0.70 ? ProjectColors.errorColor : ProjectColors.yellowColor,
                    ),
                    SizedBox(width: width * 0.02),
                    textWidget(
                      text: a.utilization >= 0.70 ? "(High)" : "(Watch)",
                      fontSize: 0.018,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor.withOpacity(0.7),
                    ),
                    const Spacer(),
                    textWidget(
                      text: "${ctrl.money(a.balance)} / ${ctrl.money(a.limit)}",
                      fontSize: 0.016,
                      fontWeight: FontWeight.w700,
                      color: ProjectColors.whiteColor.withOpacity(0.8),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),
                _UtilBar(util: a.utilization),
                SizedBox(height: height * 0.012),
                textWidget(
                  text: "Interest burn: ~${ctrl.money2(a.interestPerDay)}/day",
                  fontSize: 0.016,
                  fontWeight: FontWeight.w800,
                  color: ProjectColors.whiteColor.withOpacity(0.9),
                ),
              ] else ...[
                textWidget(
                  text: "Loan balance: ${ctrl.money(a.balance)}",
                  fontSize: 0.02,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor.withOpacity(0.95),
                ),
                SizedBox(height: height * 0.01),
                textWidget(
                  text: "Interest burn: ~${ctrl.money2(a.interestPerDay)}/day",
                  fontSize: 0.016,
                  fontWeight: FontWeight.w800,
                  color: ProjectColors.whiteColor.withOpacity(0.9),
                ),
              ],
              SizedBox(height: height * 0.012),
              textWidget(
                text: "Minimum: ${ctrl.money(a.minPayment)} • Due in ${ctrl.daysUntil(a.dueDate)} days",
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
        SizedBox(height: height * 0.014),
        if (a.isCreditCard) ...[
          SizedBox(height: height * 0.014),
          _CardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(
                  text: "Pay down ~${ctrl.money(ctrl.payDownTo30(a))}",
                  fontSize: 0.02,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
                SizedBox(height: height * 0.006),
                textWidget(
                  text: "to reduce credit score risk (target <30% utilization).",
                  fontSize: 0.015,
                  color: ProjectColors.whiteColor.withOpacity(0.6),
                ),
                SizedBox(height: height * 0.012),
                normalButton(
                  title: "Pay down to <30%",
                  cHeight: 0.06,
                  cWidth: 1.0,
                  bColor: ProjectColors.lightGreenColor,
                  invertColors: true,
                  callback: () {
                    // TODO: open payment flow / set goal / schedule
                  },
                ),
              ],
            ),
          ),
        ],
        normalButton(
          title: a.isCreditCard ? "Pay down to <30%" : "Prioritize payoff",
          cHeight: 0.06,
          cWidth: 1.0,
          bColor: ProjectColors.lightGreenColor,
          invertColors: true,
          callback: () {
            // TODO: action for selected account
          },
        ),
        SizedBox(height: height * 0.02),
      ],
    );
  }
}

// -------------------- WIDGETS --------------------

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  final DebtAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = isSelected ? ProjectColors.lightGreenColor.withOpacity(0.35) : Colors.white.withOpacity(0.08);
    final bg = Colors.white.withOpacity(isSelected ? 0.09 : 0.06);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: width * 0.72,
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                textWidget(
                  text: account.name,
                  fontSize: 0.02,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
                const Spacer(),
                if (account.isCreditCard && account.utilization >= 0.7) _Pill(text: "Priority", color: ProjectColors.lightGreenColor),
              ],
            ),
            SizedBox(height: height * 0.008),

            // balance/limit row
            Row(
              children: [
                textWidget(
                  text: "\$${account.balance.toStringAsFixed(0)}",
                  fontSize: 0.028,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.yellowColor,
                ),
                SizedBox(width: width * 0.02),
                textWidget(
                  text: account.isCreditCard ? "/${account.limit.toStringAsFixed(0)} limit" : "balance",
                  fontSize: 0.015,
                  color: ProjectColors.whiteColor.withOpacity(0.6),
                ),
              ],
            ),

            SizedBox(height: height * 0.01),

            // utilization bar (only for credit)
            if (account.isCreditCard) ...[
              _UtilBar(util: account.utilization),
              SizedBox(height: height * 0.008),
              Row(
                children: [
                  textWidget(
                    text: "${(account.utilization * 100).toStringAsFixed(0)}% Utilization",
                    fontSize: 0.015,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.whiteColor.withOpacity(0.85),
                  ),
                  SizedBox(width: width * 0.02),
                  textWidget(
                    text: account.utilization >= 0.7 ? "(High)" : "",
                    fontSize: 0.015,
                    fontWeight: FontWeight.w700,
                    color: account.utilization >= 0.7 ? ProjectColors.errorColor : ProjectColors.whiteColor.withOpacity(0.6),
                  ),
                ],
              ),
            ] else ...[
              textWidget(
                text: "APR ${account.apr.toStringAsFixed(1)}% • Min ${account.minPayment.toStringAsFixed(0)}",
                fontSize: 0.015,
                color: ProjectColors.whiteColor.withOpacity(0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.allMode,
    required this.onAll,
    required this.onSingle,
  });

  final bool allMode;
  final VoidCallback onAll;
  final VoidCallback onSingle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * 0.012),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onAll,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: height * 0.012),
                decoration: BoxDecoration(
                  color: allMode ? Colors.white.withOpacity(0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      allMode ? Icons.check_circle : Icons.circle_outlined,
                      size: height * 0.022,
                      color: allMode ? ProjectColors.lightGreenColor : ProjectColors.whiteColor.withOpacity(0.45),
                    ),
                    SizedBox(width: width * 0.02),
                    textWidget(
                      text: "All cards",
                      fontSize: 0.016,
                      fontWeight: FontWeight.w800,
                      color: allMode ? ProjectColors.whiteColor : ProjectColors.whiteColor.withOpacity(0.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: width * 0.02),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onSingle,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: height * 0.012),
                decoration: BoxDecoration(
                  color: !allMode ? Colors.white.withOpacity(0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !allMode ? Icons.check_circle : Icons.circle_outlined,
                      size: height * 0.022,
                      color: !allMode ? ProjectColors.lightGreenColor : ProjectColors.whiteColor.withOpacity(0.45),
                    ),
                    SizedBox(width: width * 0.02),
                    textWidget(
                      text: "This card",
                      fontSize: 0.016,
                      fontWeight: FontWeight.w800,
                      color: !allMode ? ProjectColors.whiteColor : ProjectColors.whiteColor.withOpacity(0.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );

    if (onTap == null) return box;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: box,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.006),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: textWidget(
        text: text,
        fontSize: 0.014,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _UtilBar extends StatelessWidget {
  const _UtilBar({required this.util});
  final double util;

  @override
  Widget build(BuildContext context) {
    final u = util.clamp(0.0, 1.0);
    final fillColor = u >= 0.7 ? ProjectColors.errorColor : (u >= 0.3 ? ProjectColors.yellowColor : ProjectColors.greenColor);

    return Container(
      height: height * 0.012,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: u,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor.withOpacity(0.85),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

// -------------------- CHARTS (fl_chart) --------------------

class _InterestBarChart extends StatelessWidget {
  const _InterestBarChart({required this.accounts});
  final List<DebtAccount> accounts;

  @override
  Widget build(BuildContext context) {
    // normalize values
    double maxV = 0.0;
    for (final a in accounts) {
      if (a.interestPerDay > maxV) maxV = a.interestPerDay;
    }
    if (maxV <= 0) maxV = 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxV * 1.2,
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        barGroups: List.generate(accounts.length, (i) {
          final v = accounts[i].interestPerDay;
          final y = v;
          final color = accounts[i].isCreditCard ? ProjectColors.lightGreenColor : ProjectColors.yellowColor;

          return BarChartGroupData(
            x: i,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: y,
                width: 12,
                color: color.withOpacity(0.75),
                borderRadius: BorderRadius.circular(8),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxV * 1.15,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _BalancePie extends StatelessWidget {
  const _BalancePie({required this.accounts});
  final List<DebtAccount> accounts;

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final a in accounts) total += a.balance;
    if (total <= 0) total = 1;

    // 3-tone palette using your colors (no custom new colors)
    final palette = [
      ProjectColors.yellowColor,
      ProjectColors.lightGreenColor,
      ProjectColors.brownColor,
      ProjectColors.purpleColor,
    ];

    return PieChart(
      PieChartData(
        startDegreeOffset: -90,
        sectionsSpace: 2,
        centerSpaceRadius: height * 0.04,
        sections: List.generate(accounts.length, (i) {
          final share = accounts[i].balance / total;
          return PieChartSectionData(
            value: share * 100,
            color: palette[i % palette.length].withOpacity(0.70),
            radius: height * 0.05,
            showTitle: false,
          );
        }),
      ),
    );
  }
}

// -------------------- STRING SEGMENT TABS (YOUR REQUEST) --------------------
// You already asked for String based SegmentTabs earlier.
// Keep this in same file or your widgets folder.

class SegmentTabs extends StatelessWidget {
  const SegmentTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.highlightValue,
    this.padding,
    this.bgOpacity = 0.05,
    this.borderOpacity = 0.07,
    this.thumbOpacity = 0.10,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final List<String> items;
  final String? highlightValue;

  final EdgeInsets? padding;
  final double bgOpacity;
  final double borderOpacity;
  final double thumbOpacity;

  @override
  Widget build(BuildContext context) {
    final Map<String, Widget> children = {
      for (final label in items)
        label: _SegItem(
          text: label,
          active: value == label,
          highlight: highlightValue == label,
        ),
    };

    return Container(
      padding: padding ?? EdgeInsets.all(width * 0.01),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
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
