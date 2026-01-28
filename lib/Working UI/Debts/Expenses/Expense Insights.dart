import 'package:emptyproject/BaseScreen.dart';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Constants.dart';
import '../../Controllers.dart';

// ------------------------------------------------------------
// ASSUMES YOU ALREADY HAVE:
// - ProjectColors class (your constants)
// - double height = Get.height; double width = Get.width;
// - textWidget(...)
// - normalButton(...)
// ------------------------------------------------------------

// -------------------- DATA MODELS --------------------

class ShiftForecast {
  final DateTime nextPayDate;
  final double hourlyRate; // blended avg
  final double plannedHoursUntilPayday; // scheduled
  final double suggestedExtraHours; // e.g. 8
  final double expectedIncomeUntilPayday; // derived from shifts

  ShiftForecast({
    required this.nextPayDate,
    required this.hourlyRate,
    required this.plannedHoursUntilPayday,
    required this.suggestedExtraHours,
    required this.expectedIncomeUntilPayday,
  });

  double get suggestedIncomeGain => suggestedExtraHours * hourlyRate;
}

class DueItem {
  final String title; // "Car Loan"
  final double amount;
  final DateTime dueDate;

  DueItem({required this.title, required this.amount, required this.dueDate});
}

class DebtAccount {
  final String name;
  final double balance;
  final double limit; // 0 if not credit
  final double apr;
  final double minPayment;
  final DateTime dueDate;
  final DateTime? promoEndDate;
  final bool autopayOn;

  DebtAccount({
    required this.name,
    required this.balance,
    required this.limit,
    required this.apr,
    required this.minPayment,
    required this.dueDate,
    this.promoEndDate,
    this.autopayOn = false,
  });

  bool get isCredit => limit > 0;
  double get utilization => isCredit ? (balance / limit).clamp(0.0, 1.0) : 0.0;
  double get interestPerDay => (balance * (apr / 100.0)) / 365.0;
}

class LeakItem {
  final String merchant;
  final double amountMonthly;
  final int daysAgo;
  final double confidence; // 0..1
  final int matchedCharges;
  final int windowDays;

  LeakItem({
    required this.merchant,
    required this.amountMonthly,
    required this.daysAgo,
    required this.confidence,
    required this.matchedCharges,
    required this.windowDays,
  });

  double get annualCost => amountMonthly * 12.0;

  String get confidenceLabel {
    if (confidence >= 0.80) return "High";
    if (confidence >= 0.55) return "Medium";
    return "Low";
  }
}

class SpikeItem {
  final String merchant;
  final double spikeAmount;
  final String whenLabel;

  SpikeItem({required this.merchant, required this.spikeAmount, required this.whenLabel});
}

class AutomationRule {
  final String title;
  final String subtitle;
  final bool enabled;

  AutomationRule({required this.title, required this.subtitle, required this.enabled});
}

// -------------------- CONTROLLER --------------------

enum PayHealth { safe, tight, risk }

enum ForecastRisk { low, medium, high }

class NowToPaydayCtrl extends GetxController {
  // Replace these with your computed values
  final forecast = ShiftForecast(
    nextPayDate: DateTime.now().add(const Duration(days: 6)),
    hourlyRate: 18.0,
    plannedHoursUntilPayday: 28,
    suggestedExtraHours: 8,
    expectedIncomeUntilPayday: 18.0 * 28,
  ).obs;

  final currentCash = 420.0.obs;
  final bufferTarget = 200.0.obs;

  final bills = <DueItem>[
    DueItem(title: "Car Loan", amount: 300, dueDate: DateTime.now().add(const Duration(days: 2))),
    DueItem(title: "Phone", amount: 65, dueDate: DateTime.now().add(const Duration(days: 5))),
  ].obs;

  final debts = <DebtAccount>[
    DebtAccount(
      name: "Visa Platinum",
      balance: 1200,
      limit: 1700,
      apr: 19.9,
      minPayment: 60,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      promoEndDate: DateTime.now().add(const Duration(days: 17)),
      autopayOn: false,
    ),
    DebtAccount(
      name: "Line of Credit",
      balance: 8400,
      limit: 0,
      apr: 9.9,
      minPayment: 150,
      dueDate: DateTime.now().add(const Duration(days: 7)),
      autopayOn: true,
    ),
  ].obs;

  final leak = LeakItem(
    merchant: "Monnth",
    amountMonthly: 14.99,
    daysAgo: 5,
    confidence: 0.86,
    matchedCharges: 2,
    windowDays: 30,
  ).obs;

  final spike = SpikeItem(merchant: "Walmart", spikeAmount: 95, whenLabel: "this week").obs;

  final rules = <AutomationRule>[
    AutomationRule(title: "Keep buffer ≥ \$200", subtitle: "Blocks extra payments when tight.", enabled: true),
    AutomationRule(title: "If utilization > 50% → pay on payday", subtitle: "Auto-suggests target payment.", enabled: true),
  ].obs;

  // -------------------- CORE MATH --------------------

  double get incomeUntilPayday => forecast.value.expectedIncomeUntilPayday;

  double get billsUntilPayday {
    final n = forecast.value.nextPayDate;
    double sum = 0;
    for (final b in bills) {
      if (_onOrBefore(b.dueDate, n)) sum += b.amount;
    }
    return sum;
  }

  double get minsUntilPayday {
    final n = forecast.value.nextPayDate;
    double sum = 0;
    for (final d in debts) {
      if (_onOrBefore(d.dueDate, n)) sum += d.minPayment;
    }
    return sum;
  }

  double get safeToSpendUntilPayday {
    return currentCash.value + incomeUntilPayday - billsUntilPayday - minsUntilPayday - bufferTarget.value;
  }

  PayHealth get health {
    final v = safeToSpendUntilPayday;
    if (v >= 150) return PayHealth.safe;
    if (v >= 0) return PayHealth.tight;
    return PayHealth.risk;
  }

  Color get healthColor {
    switch (health) {
      case PayHealth.safe:
        return ProjectColors.lightGreenColor;
      case PayHealth.tight:
        return ProjectColors.yellowColor;
      case PayHealth.risk:
        return ProjectColors.errorColor;
    }
  }

  String get healthLabel {
    switch (health) {
      case PayHealth.safe:
        return "Safe";
      case PayHealth.tight:
        return "Tight";
      case PayHealth.risk:
        return "Risk";
    }
  }

  // -------------------- NEXT BEST MOVE --------------------

  DueItem? get mostUrgentDueBeforePayday {
    final n = forecast.value.nextPayDate;
    final list = bills.where((b) => _onOrBefore(b.dueDate, n)).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list.first;
  }

  DebtAccount get dangerDebt {
    final n = forecast.value.nextPayDate;
    DebtAccount best = debts.first;
    double bestScore = -999;

    for (final d in debts) {
      double score = 0;

      if (_onOrBefore(d.dueDate, n)) score += 60;

      if (d.isCredit) {
        if (d.utilization >= 0.70) {
          score += 50;
        } else if (d.utilization >= 0.50) {
          score += 30;
        } else if (d.utilization >= 0.30) {
          score += 15;
        }
      }

      if (d.promoEndDate != null) {
        final days = d.promoEndDate!.difference(DateTime.now()).inDays;
        if (days <= 21) score += 30;
      }

      final dueDays = d.dueDate.difference(DateTime.now()).inDays;
      if (!d.autopayOn && dueDays <= 7) score += 25;

      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }

    return best;
  }

  DebtAccount get drainDebt {
    DebtAccount best = debts.first;
    double bestBurn = -1;
    for (final d in debts) {
      if (d.interestPerDay > bestBurn) {
        bestBurn = d.interestPerDay;
        best = d;
      }
    }
    return best;
  }

  double payDownTo30(DebtAccount d) {
    if (!d.isCredit) return 0;
    final target = 0.30 * d.limit;
    final need = d.balance - target;
    return need > 0 ? need : 0;
  }

  String get nextMoveTitle {
    if (health == PayHealth.risk) return "Hold extra payments";
    final urgent = mostUrgentDueBeforePayday;
    if (urgent != null) return "Reserve ${_money(urgent.amount)} for ${urgent.title}";
    final d = dangerDebt;
    if (d.isCredit && d.utilization >= 0.50) {
      final to30 = payDownTo30(d);
      if (to30 > 0) return "Pay ${_money(to30)} to reach <30%";
    }
    return "Pay extra to ${drainDebt.name}";
  }

  String get nextMoveReason {
    if (health == PayHealth.risk) {
      return "You’re short by ${_money(safeToSpendUntilPayday.abs())}. Paying extra now increases missed-payment risk.";
    }
    final urgent = mostUrgentDueBeforePayday;
    if (urgent != null) {
      final days = urgent.dueDate.difference(DateTime.now()).inDays;
      return "Due in ${days < 0 ? 0 : days} days, before payday. Reserve it so it can’t be spent.";
    }
    final d = dangerDebt;
    if (d.isCredit && d.utilization >= 0.50) {
      return "Utilization is ${_pct(d.utilization)}. Lowering it reduces credit score risk.";
    }
    return "This account burns ~${_money2(drainDebt.interestPerDay)}/day in interest.";
  }

  String get nextMoveCTA {
    if (health == PayHealth.risk) return "See fixes";
    final urgent = mostUrgentDueBeforePayday;
    if (urgent != null) return "Reserve ${_money(urgent.amount)} now";
    final d = dangerDebt;
    if (d.isCredit && d.utilization >= 0.50) {
      final to30 = payDownTo30(d);
      if (to30 > 0) return "Pay ${_money(to30)} now";
    }
    return "Apply extra payment";
  }

  // -------------------- FORECAST RISK (NEW POINT #1) --------------------

  ForecastRisk get forecastRiskLevel {
    final n = forecast.value.nextPayDate;

    // 1) Bill clustering risk: 3+ bills within 4 days (before payday)
    final due = bills.where((b) => _onOrBefore(b.dueDate, n)).toList();
    due.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    bool cluster = false;
    for (int i = 0; i < due.length; i++) {
      final start = due[i].dueDate;
      int count = 1;
      for (int j = i + 1; j < due.length; j++) {
        final diff = due[j].dueDate.difference(start).inDays;
        if (diff <= 4) count++;
      }
      if (count >= 3) {
        cluster = true;
        break;
      }
    }

    // 2) Utilization high on any card
    final utilHigh = debts.any((d) => d.isCredit && d.utilization >= 0.70);

    // 3) Buffer projected to fall below target (based on current snapshot)
    final willBreak = safeToSpendUntilPayday < 0;

    if (willBreak || utilHigh || cluster) return ForecastRisk.high;
    if (health == PayHealth.tight || due.length >= 2) return ForecastRisk.medium;
    return ForecastRisk.low;
  }

  String get forecastRiskLabel {
    switch (forecastRiskLevel) {
      case ForecastRisk.low:
        return "Low";
      case ForecastRisk.medium:
        return "Medium";
      case ForecastRisk.high:
        return "High";
    }
  }

  Color get forecastRiskColor {
    switch (forecastRiskLevel) {
      case ForecastRisk.low:
        return ProjectColors.lightGreenColor;
      case ForecastRisk.medium:
        return ProjectColors.yellowColor;
      case ForecastRisk.high:
        return ProjectColors.errorColor;
    }
  }

  /// Tight window sentence:
  /// “Jan 2–5 is tight (2 bills before pay).”
  String get tightWindowSentence {
    final n = forecast.value.nextPayDate;
    final due = bills.where((b) => _onOrBefore(b.dueDate, n)).toList();
    if (due.isEmpty) return "No bills due before payday.";

    due.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // pick the densest 4-day window
    int bestCount = 1;
    DateTime bestStart = due.first.dueDate;
    DateTime bestEnd = due.first.dueDate;

    for (int i = 0; i < due.length; i++) {
      final start = due[i].dueDate;
      final end = start.add(const Duration(days: 3));
      int count = 0;
      for (final b in due) {
        if (!_before(b.dueDate, start) && !_before(end, b.dueDate)) count++;
      }
      if (count > bestCount) {
        bestCount = count;
        bestStart = start;
        bestEnd = end;
      }
    }

    if (bestCount <= 1) {
      // just mention the next due item
      final first = due.first;
      final days = first.dueDate.difference(DateTime.now()).inDays;
      return "${_md(first.dueDate)}: ${first.title} due in ${days < 0 ? 0 : days} days.";
    }

    return "${_md(bestStart)}–${_md(bestEnd)} is tight ($bestCount bills before pay).";
  }

  /// Buffer-below-target date estimate (simple):
  /// If you want a real day-by-day, you need daily cashflow entries.
  /// For now, show the first due date that creates the tight window.
  DateTime? get bufferBreakDateHint {
    if (health == PayHealth.safe) return null;
    final n = forecast.value.nextPayDate;
    final due = bills.where((b) => _onOrBefore(b.dueDate, n)).toList();
    if (due.isEmpty) return null;
    due.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return due.first.dueDate;
  }

  // Suggest adding hours (NEW: hours language)
  bool get showAddHoursSuggestion => health != PayHealth.safe;

  String get addHoursCopy {
    final f = forecast.value;
    final gain = f.suggestedIncomeGain;
    final newSafe = safeToSpendUntilPayday + gain;
    final hours = f.suggestedExtraHours.toStringAsFixed(0);

    if (newSafe >= 150) return "Add $hours hours next week → +${_money(gain)} → status becomes Safe.";
    if (newSafe >= 0) return "Add $hours hours next week → +${_money(gain)} → turns buffer positive.";
    return "Add $hours hours next week → +${_money(gain)} → still short by ${_money(newSafe.abs())}. Cut spending too.";
  }

  // -------------------- AUTOMATION (NEW POINT #2) --------------------

  List<AutomationRule> get activeRules => rules.where((r) => r.enabled).toList();

  // -------------------- SAVE $50 FASTEST (OPTIONAL POINT #3) --------------------

  bool get showSave50 => health != PayHealth.safe;

  List<String> get save50Suggestions {
    final leakSave = leak.value.amountMonthly;
    return [
      "Pause dining out this week to save ~\$35.",
      "Cancel/hold ${leak.value.merchant} saves ~${_money2(leakSave)} this month.",
      "Reduce fuel spending by \$20 this week.",
    ];
  }

  // -------------------- HELPERS --------------------

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _onOrBefore(DateTime a, DateTime b) => _before(a, b) || _sameDay(a, b);
  bool _before(DateTime a, DateTime b) => a.isBefore(b);

  String _money(double v) => "\$${v.toStringAsFixed(0)}";
  String _money2(double v) => "\$${v.toStringAsFixed(2)}";
  String _pct(double v) => "${(v * 100).toStringAsFixed(0)}%";

  String _md(DateTime d) => "${d.month}/${d.day}";
}

// -------------------- SCREEN --------------------

class NowToPaydayScreen extends StatelessWidget {
  const NowToPaydayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NowToPaydayCtrl());

    return BaseScreen(
      title: 'Insights for Jan',
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: height * 0.012),

            // HEADER (no "close" label)
            Row(
              children: [
                textWidget(
                  text: "Now → Payday",
                  fontSize: 0.028,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
                const Spacer(),
                _Pill(label: ctrl.healthLabel, color: ctrl.healthColor),
              ],
            ),

            SizedBox(height: height * 0.016),
            DarkCard(
              color: ProjectColors.greenColor,
              opacity: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: 'This Month', fontSize: .02, fontWeight: FontWeight.w900),
                  SizedBox(height: height * .01),
                  Row(
                    children: ['Fixed', 'Variable', 'Total']
                        .map(
                          (t) => Padding(
                            padding: EdgeInsets.only(right: width * .1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                textWidget(text: t, fontWeight: FontWeight.w700, fontSize: .018),
                                SizedBox(height: height * .005),
                                textWidget(
                                  text: t == 'Fixed'
                                      ? money(expenseV2.expensesModel.value.monthSummary!.fixedPlanned)
                                      : t == 'Variable'
                                          ? money(expenseV2.expensesModel.value.monthSummary!.variableSpent)
                                          : money(expenseV2.expensesModel.value.monthSummary!.total),
                                  fontWeight: FontWeight.w900,
                                  fontSize: .022,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: height * .01),
                  // SizedBox(
                  //   width: width * .8,
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius.circular(999),
                  //     child: LinearProgressIndicator(
                  //       value: expenseV2.totalFixedExpense!.value + expenseV2.totalVariableExpense!.value <= 0
                  //           ? 0.0
                  //           : (expenseV2.totalFixedExpense!.value / expenseV2.totalFixedExpense!.value + expenseV2.totalVariableExpense!.value)
                  //               .clamp(0.0, 1.0),
                  //       minHeight: 10,
                  //       backgroundColor: ProjectColors.pureBlackColor.withOpacity(0.06),
                  //       valueColor: const AlwaysStoppedAnimation(ProjectColors.pureBlackColor),
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: height * .01),
                  textWidget(text: 'Based on your monthly & per-paycheque expenses', fontSize: .015),
                ],
              ),
            ),
            SizedBox(height: height * 0.016),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: "Safe-to-spend until payday",
                    fontSize: 0.016,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(0.70),
                  ),
                  SizedBox(height: height * 0.008),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      textWidget(
                        text: _moneySigned(ctrl.safeToSpendUntilPayday),
                        fontSize: 0.040,
                        fontWeight: FontWeight.w900,
                        color: ctrl.healthColor,
                      ),
                      SizedBox(width: width * 0.02),
                      Padding(
                        padding: EdgeInsets.only(bottom: height * 0.005),
                        child: textWidget(
                          text: "until ${_md(ctrl.forecast.value.nextPayDate)}",
                          fontSize: 0.015,
                          fontWeight: FontWeight.w700,
                          color: ProjectColors.whiteColor.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.008),

                  // ADDED: clarity line (kills confusion)
                  textWidget(
                    text: "After bills + minimums + buffer (${_money(ctrl.bufferTarget.value)}).",
                    fontSize: 0.014,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.whiteColor.withOpacity(0.55),
                  ),

                  SizedBox(height: height * 0.014),

                  _MiniRow(label: "Expected income", value: _money(ctrl.incomeUntilPayday)),
                  SizedBox(height: height * 0.006),
                  _MiniRow(label: "Bills due", value: _money(ctrl.billsUntilPayday)),
                  SizedBox(height: height * 0.006),
                  _MiniRow(label: "Debt minimums", value: _money(ctrl.minsUntilPayday)),
                  SizedBox(height: height * 0.006),
                  _MiniRow(label: "Buffer target", value: _money(ctrl.bufferTarget.value)),

                  if (ctrl.showAddHoursSuggestion) ...[
                    SizedBox(height: height * 0.012),
                    _HintRow(
                      icon: Icons.schedule,
                      iconColor: ProjectColors.lightGreenColor,
                      text: ctrl.addHoursCopy,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: height * 0.014),

            // 2) NEXT BEST MOVE (button is specific now)
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: "Next best move",
                    fontSize: 0.018,
                    fontWeight: FontWeight.w900,
                    color: ProjectColors.whiteColor,
                  ),
                  SizedBox(height: height * 0.008),
                  textWidget(
                    text: ctrl.nextMoveTitle,
                    fontSize: 0.022,
                    fontWeight: FontWeight.w900,
                    color: ProjectColors.whiteColor.withOpacity(0.92),
                  ),
                  SizedBox(height: height * 0.008),
                  textWidget(
                    text: ctrl.nextMoveReason,
                    fontSize: 0.015,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.whiteColor.withOpacity(0.58),
                  ),
                  SizedBox(height: height * 0.014),
                  normalButton(
                    title: ctrl.nextMoveCTA,
                    cHeight: 0.06,
                    cWidth: 1.0,
                    bColor: ProjectColors.lightGreenColor,
                    invertColors: true,
                    callback: () {
                      // TODO: open correct bottom sheet
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.014),

            // 3) LEAKS & SPIKES (less text, more premium)
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: "Leaks & spikes",
                    fontSize: 0.018,
                    fontWeight: FontWeight.w900,
                    color: ProjectColors.whiteColor,
                  ),
                  SizedBox(height: height * 0.012),
                  _RowTile(
                    icon: Icons.repeat,
                    iconColor: ProjectColors.brownColor,
                    title: "New recurring: ${ctrl.leak.value.merchant} • ${_money2(ctrl.leak.value.amountMonthly)}/mo",
                    subtitle: "~${_money2(ctrl.leak.value.annualCost)}/yr • Confidence: ${ctrl.leak.value.confidenceLabel}",
                    onTap: () {
                      // TODO: open spending leaks sheet (show matched evidence there)
                    },
                  ),
                  SizedBox(height: height * 0.010),
                  _RowTile(
                    icon: Icons.bolt,
                    iconColor: ProjectColors.yellowColor,
                    title: "Spending spike: +${_money(ctrl.spike.value.spikeAmount)} at ${ctrl.spike.value.merchant}",
                    subtitle: "Happened ${ctrl.spike.value.whenLabel}. Tap to tag/split/mark essential.",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.014),

            // 4) MOST RISKY VS MOST EXPENSIVE (tappable affordance)
            Row(
              children: [
                Expanded(
                  child: _GlassCard(
                    child: _DebtMini(
                      label: "Most risky",
                      title: ctrl.dangerDebt.name,
                      subtitle: _dangerSubtitle(ctrl.dangerDebt),
                      accent: ProjectColors.yellowColor,
                      onTap: () {},
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: _GlassCard(
                    child: _DebtMini(
                      label: "Most expensive",
                      title: ctrl.drainDebt.name,
                      subtitle: "Interest burn ~${_money2(ctrl.drainDebt.interestPerDay)}/day",
                      accent: ProjectColors.lightGreenColor,
                      onTap: () {},
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: height * 0.014),

            // 5) FORECAST RISK (NEW POINT #1 REAL)
            ForecastCard(
              model: ForecastCardModel(
                risk: ForecastRisk.high,
                issue: "Jan 2–5 is tight (2 bills before pay).",
                insight: "Move \$300 to buffer or cut \$50 spending.",
                primaryText: "Move",
                onPrimary: () {
                  // TODO: open “Reserve/Schedule” sheet
                },
                secondaryText: "Cut",
                onSecondary: () {
                  // TODO: open “Save \$50 fastest” sheet
                },
              ),
              onTap: () {
                // TODO: open “Forecast detail” sheet
              },
            ),
            if (ctrl.showAddHoursSuggestion) ...[
              SizedBox(height: height * 0.010),
              normalButton(
                title: "Add ${ctrl.forecast.value.suggestedExtraHours.toStringAsFixed(0)} hours plan",
                cHeight: 0.055,
                cWidth: 1.0,
                bColor: Colors.white.withOpacity(0.08),
                invertColors: false,
                callback: () {
                  // TODO: open shift planner / availability suggestion
                },
              ),
            ],
            SizedBox(height: height * 0.014),
            Save50FastCard(
              model: SaveFastModel(
                health: PayHealth.tight,
                title: "Save \$50 fastest",
                subtitle: "Quick cuts to protect your buffer before payday.",
                suggestions: const [
                  "Pause dining out this week saves ~\$35.",
                  "Cancel/hold subscription saves \$14.99.",
                  "Reduce fuel spending by \$20.",
                ],
                ctaText: "Open cuts checklist",
                onCtaTap: () {
                  // TODO: open bottom sheet with checklist + toggles
                },
              ),
            ),
            SizedBox(height: height * 0.014),

            // 6) AUTOMATION RULES (NEW POINT #2)
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      textWidget(
                        text: "Automation rules",
                        fontSize: 0.018,
                        fontWeight: FontWeight.w900,
                        color: ProjectColors.whiteColor,
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          // TODO: open add rule sheet
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.01),
                          child: Icon(
                            Icons.add,
                            color: ProjectColors.lightGreenColor,
                            size: height * 0.026,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.012),

                  // show 1–2 active rules only (low clutter)
                  ...ctrl.activeRules.take(2).map((r) => Padding(
                        padding: EdgeInsets.only(bottom: height * 0.010),
                        child: _RuleRow(rule: r),
                      )),

                  if (ctrl.activeRules.isEmpty)
                    textWidget(
                      text: "No active rules yet. Add one to stop thinking about this.",
                      fontSize: 0.014,
                      fontWeight: FontWeight.w600,
                      color: ProjectColors.whiteColor.withOpacity(0.55),
                    ),

                  if (ctrl.activeRules.length > 2) ...[
                    SizedBox(height: height * 0.004),
                    textWidget(
                      text: "+${ctrl.activeRules.length - 2} more rules",
                      fontSize: 0.014,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor.withOpacity(0.45),
                    ),
                  ],

                  SizedBox(height: height * 0.010),
                  normalButton(
                    title: "Add a rule",
                    cHeight: 0.055,
                    cWidth: 1.0,
                    bColor: ProjectColors.lightGreenColor,
                    invertColors: true,
                    callback: () {
                      // TODO: open add rule sheet
                    },
                  ),
                ],
              ),
            ),

            // 7) SAVE $50 FASTEST (OPTIONAL POINT #3)
            if (ctrl.showSave50) ...[
              SizedBox(height: height * 0.014),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: "Save \$50 fastest",
                      fontSize: 0.018,
                      fontWeight: FontWeight.w900,
                      color: ProjectColors.whiteColor,
                    ),
                    SizedBox(height: height * 0.01),
                    ...ctrl.save50Suggestions.map((s) => Padding(
                          padding: EdgeInsets.only(bottom: height * 0.008),
                          child: _Bullet(s),
                        )),
                    SizedBox(height: height * 0.012),
                    normalButton(
                      title: "Open cuts checklist",
                      cHeight: 0.06,
                      cWidth: 1.0,
                      bColor: Colors.white.withOpacity(0.10),
                      invertColors: false,
                      callback: () {
                        // TODO: open cuts sheet
                      },
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: height * 0.03),
          ],
        ),
      ),
    );
  }
}

// -------------------- UI PARTS --------------------

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.007),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height * 0.01,
            width: height * 0.01,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: width * 0.02),
          textWidget(
            text: label,
            fontSize: 0.014,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        textWidget(
          text: label,
          fontSize: 0.014,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor.withOpacity(0.55),
        ),
        const Spacer(),
        textWidget(
          text: value,
          fontSize: 0.014,
          fontWeight: FontWeight.w900,
          color: ProjectColors.whiteColor.withOpacity(0.90),
        ),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.iconColor, required this.text});
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: height * 0.022),
        SizedBox(width: width * 0.02),
        Expanded(
          child: textWidget(
            text: text,
            fontSize: 0.014,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.014),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: height * 0.024),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: title,
                    fontSize: 0.015,
                    fontWeight: FontWeight.w900,
                    color: ProjectColors.whiteColor.withOpacity(0.92),
                  ),
                  SizedBox(height: height * 0.006),
                  textWidget(
                    text: subtitle,
                    fontSize: 0.014,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.whiteColor.withOpacity(0.55),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ProjectColors.whiteColor.withOpacity(0.30), size: height * 0.024),
          ],
        ),
      ),
    );
  }
}

class _DebtMini extends StatelessWidget {
  const _DebtMini({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              textWidget(
                text: label,
                fontSize: 0.014,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor.withOpacity(0.60),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: ProjectColors.whiteColor.withOpacity(0.30), size: height * 0.022),
            ],
          ),
          SizedBox(height: height * 0.008),
          textWidget(
            text: title,
            fontSize: 0.018,
            fontWeight: FontWeight.w900,
            color: ProjectColors.whiteColor,
          ),
          SizedBox(height: height * 0.006),
          textWidget(
            text: subtitle,
            fontSize: 0.0135,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor.withOpacity(0.55),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});
  final AutomationRule rule;

  @override
  Widget build(BuildContext context) {
    final c = rule.enabled ? ProjectColors.lightGreenColor : ProjectColors.whiteColor.withOpacity(0.35);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.014),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Icon(rule.enabled ? Icons.check_circle : Icons.circle_outlined, color: c, size: height * 0.022),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(
                  text: rule.title,
                  fontSize: 0.015,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor.withOpacity(0.90),
                ),
                SizedBox(height: height * 0.006),
                textWidget(
                  text: rule.subtitle,
                  fontSize: 0.0135,
                  fontWeight: FontWeight.w600,
                  color: ProjectColors.whiteColor.withOpacity(0.55),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: ProjectColors.whiteColor.withOpacity(0.30), size: height * 0.024),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: height * 0.005),
          child: Container(
            height: height * 0.007,
            width: height * 0.007,
            decoration: BoxDecoration(
              color: ProjectColors.whiteColor.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: width * 0.02),
        Expanded(
          child: textWidget(
            text: text,
            fontSize: 0.014,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

// -------------------- COPY HELPERS --------------------

String _money(double v) => "\$${v.toStringAsFixed(0)}";
String _money2(double v) => "\$${v.toStringAsFixed(2)}";

String _moneySigned(double v) {
  if (v >= 0) return "\$${v.toStringAsFixed(0)}";
  return "-\$${v.abs().toStringAsFixed(0)}";
}

String _md(DateTime d) => "${d.month}/${d.day}";

String _dangerSubtitle(DebtAccount d) {
  final dueDays = d.dueDate.difference(DateTime.now()).inDays;
  final dueText = "Due in ${dueDays < 0 ? 0 : dueDays} days";

  if (d.isCredit) {
    final u = (d.utilization * 100).toStringAsFixed(0);
    final utilText = "$u% utilization";
    if (d.promoEndDate != null) {
      final promoDays = d.promoEndDate!.difference(DateTime.now()).inDays;
      if (promoDays <= 21) return "$utilText • 0% ends in ${promoDays < 0 ? 0 : promoDays} days";
    }
    if (!d.autopayOn && dueDays <= 7) return "$dueText • Autopay off";
    return "$dueText • $utilText";
  }

  if (!d.autopayOn && dueDays <= 7) return "$dueText • Autopay off";
  return dueText;
}

class ForecastCardModel {
  final ForecastRisk risk;
  final String issue; // “Jan 2–5 is tight (2 bills before pay).”
  final String insight; // “Move $300 to buffer or cut $50 spending.”
  final String? primaryText; // “Move”
  final VoidCallback? onPrimary;
  final String? secondaryText; // “Cut”
  final VoidCallback? onSecondary;

  const ForecastCardModel({
    required this.risk,
    required this.issue,
    required this.insight,
    this.primaryText,
    this.onPrimary,
    this.secondaryText,
    this.onSecondary,
  });
}

class ForecastCardTheme {
  static String riskLabel(ForecastRisk r) {
    switch (r) {
      case ForecastRisk.low:
        return "Low";
      case ForecastRisk.medium:
        return "Medium";
      case ForecastRisk.high:
        return "High";
    }
  }

  static Color riskColor(ForecastRisk r) {
    switch (r) {
      case ForecastRisk.low:
        return ProjectColors.lightGreenColor;
      case ForecastRisk.medium:
        return ProjectColors.yellowColor;
      case ForecastRisk.high:
        return ProjectColors.errorColor;
    }
  }
}

// ======================= FORECAST CARD =======================

class ForecastCard extends StatelessWidget {
  const ForecastCard({
    super.key,
    required this.model,
    this.onTap,
  });

  final ForecastCardModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final riskC = ForecastCardTheme.riskColor(model.risk);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + chip
            Row(
              children: [
                textWidget(
                  text: "Forecast risk",
                  fontSize: 0.018,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
                const Spacer(),
                _RiskChip(label: ForecastCardTheme.riskLabel(model.risk), color: riskC),
              ],
            ),

            SizedBox(height: height * 0.012),

            // Issue (1 line-ish)
            textWidget(
              text: model.issue,
              fontSize: 0.0155,
              fontWeight: FontWeight.w800,
              color: ProjectColors.whiteColor.withOpacity(0.88),
            ),

            SizedBox(height: height * 0.008),

            // Insight (what to do)
            textWidget(
              text: model.insight,
              fontSize: 0.014,
              fontWeight: FontWeight.w700,
              color: ProjectColors.whiteColor.withOpacity(0.60),
            ),

            SizedBox(height: height * 0.014),

            // Bottom actions: 2 mini pills or 1
            Row(
              children: [
                if (model.primaryText != null)
                  Expanded(
                    child: _MiniPillButton(
                      title: model.primaryText!,
                      fill: Colors.white.withOpacity(0.10),
                      textColor: ProjectColors.whiteColor.withOpacity(0.85),
                      onTap: model.onPrimary,
                    ),
                  ),
                if (model.primaryText != null && model.secondaryText != null) SizedBox(width: width * 0.03),
                if (model.secondaryText != null)
                  Expanded(
                    child: _MiniPillButton(
                      title: model.secondaryText!,
                      fill: Colors.white.withOpacity(0.10),
                      textColor: ProjectColors.whiteColor.withOpacity(0.85),
                      onTap: model.onSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= UI PARTS =======================

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.006),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height * 0.009,
            width: height * 0.009,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: width * 0.02),
          textWidget(
            text: label,
            fontSize: 0.0135,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MiniPillButton extends StatelessWidget {
  const _MiniPillButton({
    required this.title,
    required this.fill,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final Color fill;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: height * 0.052,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: textWidget(
          text: title,
          fontSize: 0.015,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}

class SaveFastModel {
  final PayHealth health;
  final String title;
  final String subtitle;
  final List<String> suggestions; // 3–5 max
  final String ctaText;
  final VoidCallback onCtaTap;

  const SaveFastModel({
    required this.health,
    required this.title,
    required this.subtitle,
    required this.suggestions,
    required this.ctaText,
    required this.onCtaTap,
  });

  bool get shouldShow => health == PayHealth.tight || health == PayHealth.risk;
}

class Save50FastCard extends StatelessWidget {
  const Save50FastCard({super.key, required this.model});
  final SaveFastModel model;

  @override
  Widget build(BuildContext context) {
    if (!model.shouldShow) return const SizedBox.shrink();

    final dangerColor = model.health == PayHealth.risk ? ProjectColors.errorColor : ProjectColors.yellowColor;

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row + state chip
          Row(
            children: [
              textWidget(
                text: model.title,
                fontSize: 0.018,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor,
              ),
              const Spacer(),
              _SmallChip(
                label: model.health == PayHealth.risk ? "Tight" : "Tight",
                color: dangerColor,
              ),
            ],
          ),

          SizedBox(height: height * 0.01),

          textWidget(
            text: model.subtitle,
            fontSize: 0.014,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor.withOpacity(0.60),
          ),

          SizedBox(height: height * 0.014),

          // Bullets (keep super short)
          ...model.suggestions.take(3).map((s) => Padding(
                padding: EdgeInsets.only(bottom: height * 0.010),
                child: _BulletLine(text: s),
              )),

          SizedBox(height: height * 0.010),

          normalButton(
            title: model.ctaText,
            cHeight: 0.06,
            cWidth: 1.0,
            bColor: Colors.white.withOpacity(0.10),
            invertColors: false,
            callback: model.onCtaTap,
          ),
        ],
      ),
    );
  }
}

// ---------- UI parts ----------

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: height * 0.006),
          child: Container(
            height: height * 0.007,
            width: height * 0.007,
            decoration: BoxDecoration(
              color: ProjectColors.whiteColor.withOpacity(0.70),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: width * 0.02),
        Expanded(
          child: textWidget(
            text: text,
            fontSize: 0.014,
            fontWeight: FontWeight.w800,
            color: ProjectColors.whiteColor.withOpacity(0.72),
          ),
        ),
      ],
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});
  final String label;
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
        text: label,
        fontSize: 0.013,
        fontWeight: FontWeight.w900,
        color: color,
      ),
    );
  }
}
