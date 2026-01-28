import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import '../../../../models/Debt Model.dart';
import 'Credit Debt Card.dart';

class CreditCardDebtLogic {
  List<AprProfileRow> aprProfilesFromDebt(DebtItem d) {
    if (d.type != "creditCard") return const [];

    final dueDay = d.dueDate?.day; // you currently store dueDate as DateTime?

    final rows = <AprProfileRow>[];

    // Purchase profile
    if (d.purchaseApr != null && d.purchaseApr! > 0) {
      rows.add(AprProfileRow(
        title: "Purchase Balance",
        chipText: "Purchase",
        icon: Icons.shopping_cart_outlined,
        apr: d.purchaseApr!,
        minPayment: d.minPayment,
        dueDay: dueDay,
      ));
    }

    // Cash profile
    if (d.cashApr != null && d.cashApr! > 0) {
      rows.add(AprProfileRow(
        title: "Cash Balance",
        chipText: "Cash",
        icon: Icons.attach_money_rounded,
        apr: d.cashApr!,
        minPayment: d.minPayment,
        dueDay: dueDay,
      ));
    }

    // Balance transfer profile
    if (d.balanceTransferApr != null && d.balanceTransferApr! >= 0) {
      rows.add(AprProfileRow(
        title: "Balance Transfer",
        chipText: "Balance Transfer",
        icon: Icons.sync_alt_rounded,
        apr: d.balanceTransferApr!,
        minPayment: d.minPayment,
        dueDay: dueDay,
      ));
    }

    // Fallback: if user didn't set any of the 3 APRs, use d.apr as "Standard"
    if (rows.isEmpty) {
      rows.add(AprProfileRow(
        title: "Card Balance",
        chipText: "Standard",
        icon: Icons.credit_card,
        apr: d.apr,
        minPayment: d.minPayment,
        dueDay: dueDay,
      ));
    }

    return rows;
  }

  List<DateTime> calculateStatementCycle(DateTime statementDate) {
    // Normalize to date-only
    final end = DateTime(statementDate.year, statementDate.month, statementDate.day);

    // Previous month, same day (calendar-safe)
    final year = end.month == 1 ? end.year - 1 : end.year;
    final month = end.month == 1 ? 12 : end.month - 1;

    final lastDayOfPrevMonth = DateTime(year, month + 1, 0).day;
    final day = end.day.clamp(1, lastDayOfPrevMonth);

    final start = DateTime(year, month, day);

    return [start, end];
  }

  /// Payoff plan lines for strategy screen.
  /// - For credit cards: uses A2 minimum rule (2% of balance, with a floor).
  /// - For loans/others: uses stored minPayment (fixed).
  ///
  /// Note: This does not apply "cashApr/purchaseApr" logic. It's just payment allocation.
  List<DebtPlanLine> buildPayoffPlan({double? extra}) {
    final base = debtV2.debtsModel.value.debts.where((d) => d.isActive && d.balance > 0).toList();

    // sort by selected strategy
    switch (debtV2.strategy.value) {
      case PayoffStrategy.snowball:
        base.sort((a, b) => a.balance.compareTo(b.balance));
        break;
      case PayoffStrategy.avalanche:
        base.sort((a, b) => b.apr.compareTo(a.apr));
        break;
      case PayoffStrategy.hybrid:
        double score(DebtItem d) {
          final bal = d.balance.clamp(1.0, 1e12).toDouble();
          return (d.apr * 10.0) + (1000.0 / bal);
        }
        base.sort((a, b) => score(b).compareTo(score(a)));
        break;
      case PayoffStrategy.manual:
        base.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
        break;
    }

    double rem = (extra ?? debtV2.extraBudget.value).clamp(0.0, 1e12).toDouble();
    final lines = <DebtPlanLine>[];

    for (final d in base) {
      // ----- Minimum payment logic -----
      // Credit cards: A2 rule (2% default, $10 default) unless you override it per card.
      // Everything else: use stored minPayment (fixed).
      double min;
      if (d.type == "creditCard") {
        final pct = d.minPct ?? 0.02; // 2% default
        final abs = d.absMinPay ?? 10.0; // $10 default
        final calc = d.balance * pct;
        min = (calc < abs) ? abs : calc;

        // also never exceed balance (min can't be more than what's left)
        min = min.clamp(0.0, d.balance).toDouble();
      } else {
        min = (d.minPayment <= 0 ? 0.0 : d.minPayment).toDouble();
        min = min.clamp(0.0, d.balance).toDouble();
      }

      // ----- Extra allocation -----
      double ex = 0.0;
      if (rem > 0) {
        // avoid allocating more than remaining after min
        final cap = (d.balance - min).clamp(0.0, 1e12).toDouble();
        ex = rem.clamp(0.0, cap).toDouble();
        rem -= ex;
      }

      lines.add(DebtPlanLine(
        id: d.id,
        name: d.name,
        min: min,
        extra: ex,
      ));
    }

    return lines;
  }

  DateTime nextDueDate(DateTime now, int dueDay) {
    final today = DateTime(now.year, now.month, now.day);
    final thisMonthDue = debtV2.dateWithDayClamped(now.year, now.month, dueDay);
    if (!thisMonthDue.isBefore(today)) return thisMonthDue;

    final firstNextMonth = DateTime(now.year, now.month + 1, 1);
    return debtV2.dateWithDayClamped(firstNextMonth.year, firstNextMonth.month, dueDay);
  }

  /// Read planned payment for a month:
  /// - If user override exists for YYYY-MM => use it
  /// - Else fallback to minPayment
  double plannedFor(DateTime dueDate, DebtItem d) {
    final key = debtV2.ymKey(dueDate);
    final overrides = d.plannedPaymentOverrides ?? const <PlannedPaymentOverride>[];

    for (final o in overrides) {
      if (o.yyyymm == key) return o.amount;
    }
    return d.minPayment;
  }

  /// A2 minimum rule (2% default, $10 default) OPTIONAL:
  double requiredMinForMonth(DebtItem d, double startBalance) {
    // If you want dynamic minimums, use these.
    final pct = d.minPct ?? 0.02;
    final abs = d.absMinPay ?? 10.0;
    final minCalc = startBalance * pct;
    return (minCalc < abs) ? abs : minCalc;
  }

  /// Build rows and persist into DebtItem.paymentScheduleRows.
  /// IMPORTANT FIXES vs your version:
  /// - uses dueDayOfMonth (not always 1)
  /// - advances month keeping dueDayOfMonth (not resetting to 1)
  /// - never casts schedule rows into planned overrides
  /// - prevents "0 payment infinite schedule" garbage
  Future<List<DebtScheduleRow>> buildScheduleAndSave({int months = 24, DateTime? now}) async {
    final d = debtV2.selectedDebt.value;
    if (d == null) return const [];

    final dueDay = d.dueDayOfMonth;
    if (dueDay == null || dueDay < 1 || dueDay > 31) {
      // Your UI should show: "Add a Due Day (1-31) to generate a schedule."
      return const [];
    }

    var bal = d.balance;
    if (bal <= 0) return const [];

    // If user hasn't set a min payment and no overrides exist, don't generate.
    final hasOverrides = (d.plannedPaymentOverrides != null && d.plannedPaymentOverrides!.isNotEmpty);
    if (d.minPayment <= 0 && !hasOverrides) return const [];

    final r = debtV2.monthlyRate(d.apr);
    var due = nextDueDate(now ?? DateTime.now(), dueDay);

    final rows = <DebtScheduleRow>[];

    for (int i = 0; i < months && bal > 0.01; i++) {
      final interest = bal * r;

      // Planned payment for this month (override or minPayment)
      var pay = plannedFor(due, d);

      // OPTIONAL: if you want A2 (2% recalculated monthly) to override minPayment:
      // final a2Min = requiredMinForMonth(d, bal);
      // if (pay < a2Min) pay = a2Min;

      // Guardrail: stop if pay is zero (avoid infinite schedules)
      if (pay <= 0) break;

      // Cap payment so we never pay beyond balance + interest
      final cap = bal + interest;
      if (pay > cap) pay = cap;

      final principal = pay - interest; // can be negative if underpaying
      var endBal = bal + interest - pay;
      if (endBal < 0) endBal = 0;

      rows.add(DebtScheduleRow(
        dueDate: due,
        plannedPayment: pay,
        interest: interest,
        principal: principal,
        endBalance: endBal,
      ));

      bal = endBal;

      // Next month's due date, preserving due day
      final firstOfNextMonth = DateTime(due.year, due.month + 1, 1);
      due = debtV2.dateWithDayClamped(firstOfNextMonth.year, firstOfNextMonth.month, dueDay);
    }

    // Persist
    final list = debtV2.debtsModel.value.debts.toList();
    final idx = list.indexWhere((x) => x.id == d.id);
    if (idx < 0) return rows;

    final updated = d.copyWith(paymentScheduleOverride: rows);
    list[idx] = updated;

    final newModel = debtV2.debtsModel.value.copyWith(message: "schedule saved", debts: list);
    await debtV2.debtsIO(model: newModel);

    debtV2.debtsModel.value = newModel;
    debtV2.selectedDebt.value = updated;

    return rows;
  }

  /// Converts schedule rows -> projection totals
  DebtProjection projectionFromSchedule(List<DebtScheduleRow> rows) {
    double paid = 0.0, interest = 0.0;
    int months = 0;

    for (final r in rows) {
      paid += r.plannedPayment;
      interest += r.interest;
      months++;
      if (r.endBalance <= 0.01) break;
    }
    return DebtProjection(months: months, totalPaid: paid, totalInterest: interest);
  }

  /// Update/Reset planned override for a month and rebuild schedule.
  /// amount <= 0 removes override.
  Future<void> setPlannedPaymentOverride(DateTime dueDate, double amount, {int rebuildMonths = 120}) async {
    final d = debtV2.selectedDebt.value;
    if (d == null) return;

    final key = debtV2.ymKey(dueDate);
    final overrides = (d.plannedPaymentOverrides ?? const <PlannedPaymentOverride>[]).toList();

    // remove existing override for month
    overrides.removeWhere((o) => o.yyyymm == key);

    if (amount > 0) {
      overrides.add(PlannedPaymentOverride(yyyymm: key, amount: amount));
    }

    // save overrides into model
    final list = debtV2.debtsModel.value.debts.toList();
    final idx = list.indexWhere((x) => x.id == d.id);
    if (idx < 0) return;

    final updated = d.copyWith(plannedPaymentOverrides: overrides);
    list[idx] = updated;

    final newModel = debtV2.debtsModel.value.copyWith(message: "override saved", debts: list);
    await debtV2.debtsIO(model: newModel);

    debtV2.debtsModel.value = newModel;
    debtV2.selectedDebt.value = updated;

    // rebuild schedule rows
    await buildScheduleAndSave(months: rebuildMonths);
  }
}
