import 'dart:convert';
import 'dart:math';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Shared%20Preferences.dart';
import 'package:emptyproject/Working%20UI/Shift/Calendar/Calendar.dart';
import 'package:emptyproject/Working%20UI/Shift/Deposits/Deposit.dart';
import 'package:emptyproject/Working%20UI/Shift/Projection/Projection.dart';
import 'package:emptyproject/models/Overview%20Model.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:emptyproject/models/job.dart';
import 'package:emptyproject/models/shift.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/Debt Model.dart';
import '../../models/debt.dart';
import '../Dashboard/Dashboard.dart';
import 'Debt Dashboard/All Debts.dart';
import 'Expenses/Expenses.dart';

enum debtEnums { dashboard, allDebts, expenses }

class JobDot {
  final Color color;
  const JobDot(this.color);
}

/// ======================= NEW: WEEK STATS MODEL =======================
class WeekStats {
  final int weekIndex; // 1..5
  final DateTime start;
  final DateTime end;
  double hours;
  double pay;

  WeekStats({
    required this.weekIndex,
    required this.start,
    required this.end,
    this.hours = 0,
    this.pay = 0,
  });
}

class DebtController extends GetxController {
  RxString? activeShift = "Debts".obs;
  Rx<Widget>? shiftScreen = Rx<Widget>(AllDebts());
  Rx<DateTime>? selectedDay = DateTime.now().obs;
  RxString? period = 'weekly'.obs;
  RxString? metric = 'net'.obs;
  RxString? baseline = 'last'.obs;
  RxString? debtResolve = 'Safest'.obs;
  Rxn<JobData> selectedJob = Rxn<JobData>();
  RxList<OverviewModel> combinedStats = RxList<OverviewModel>([]);
  Rx<ButtonState> state = Rx<ButtonState>(ButtonState.loading);
  Rx<DebtSortingTypes> debtType = Rx<DebtSortingTypes>(DebtSortingTypes.snowBall);

  Rxn<ShiftModel> shiftModel = Rxn<ShiftModel>();
  Rxn<AllShifts> selectedShift = Rxn<AllShifts>();
  RxList<ShiftMonth>? shifts = RxList<ShiftMonth>([]);
  RxList<AllShifts>? todayShifts = RxList<AllShifts>([]);

  RxList<TextForm>? newShiftColumns = RxList<TextForm>([
    TextForm(title: "Start time", controller: TextEditingController(text: '')),
    TextForm(title: "End time", controller: TextEditingController(text: '')),
    TextForm(title: "Unpaid break time", controller: TextEditingController(text: '')),
    TextForm(title: "Note", controller: TextEditingController(text: '')),
    TextForm(title: "Is this stat day ?", controller: TextEditingController(text: '0')),
  ]);

  RxInt? depositLookBack = 3.obs;
  RxInt? depositLookForward = 3.obs;

  RxDouble? combinedHours = 0.0.obs;
  RxDouble? combinedPay = 0.0.obs;

  // Projection tab
  final projHours = <String, double>{}.obs; // jobId -> hours
  final projScope = 'weekly'.obs; // weekly | biweekly | monthly

  /// ===================================================================
  /// ======================= TABS ======================================
  /// ===================================================================

  RxList<String> debtStats = ["Debts", "Expenses"].obs;

  void changeDebtTabs(String screen) {
    switch (screen) {
      case 'Debts':
        activeShift!.value = 'Debts';
        shiftScreen!.value = AllDebts();
        break;

      case 'Expenses':
        activeShift!.value = 'Expenses';
        shiftScreen!.value = ExpensesScreen();
        break;
    }
    activeShift!.refresh();
  }
}

class DebtInsights {
  final double totalBalance;
  final double totalMinPayment;
  final double weightedApr;
  final double monthlyInterestBurn; // sum(balance * apr/12)
  final double dailyInterestBurn; // monthly/30 (approx)
  final DebtAccount? topBurner;
  final DebtAccount? nextDue;
  final int debtCount;

  final PlanSummary? snowballPlan;
  final PlanSummary? avalanchePlan;

  DebtInsights({
    required this.totalBalance,
    required this.totalMinPayment,
    required this.weightedApr,
    required this.monthlyInterestBurn,
    required this.dailyInterestBurn,
    required this.topBurner,
    required this.nextDue,
    required this.debtCount,
    required this.snowballPlan,
    required this.avalanchePlan,
  });
}

class DebtDashCtrl extends GetxController {
  // state
  final Rx<ButtonState> state = ButtonState.loading.obs;
  final RxList<DebtAccount> debts = <DebtAccount>[].obs;
  final Rxn<DebtInsights> insights = Rxn<DebtInsights>();

  // user knob
  final RxDouble extraBudget = 0.0.obs; // slider in insights screen

  // guard: prevent double-load
  bool _loading = false;

  @override
  void onInit() {
    super.onInit();
    loadDebts();
  }

  /// IMPORTANT: call this before load to avoid stale rx errors.
  void resetRuntimeState() {
    state.value = ButtonState.loading;
    debts.clear();
    insights.value = null;
  }

  Future<void> loadDebts() async {
    if (_loading) return;
    _loading = true;

    resetRuntimeState();

    try {
      // final list = await DebtStorage.read();
      // debts.assignAll(_sanitize(list));
      _recalcInsights();
      state.value = ButtonState.done;
    } catch (e) {
      // if parsing/storage corrupt -> nuke storage to stop crash loops
      // await DebtStorage.clear();
      resetRuntimeState();
      state.value = ButtonState.done;
      showSnackBar('Oops', 'Debt data was corrupted so I reset it.');
    } finally {
      _loading = false;
    }
  }

  Future<void> addDebt(DebtAccount d) async {
    debts.add(d);
    await _persistAndRecalc();
  }

  Future<void> updateDebt(String id, DebtAccount updated) async {
    final idx = debts.indexWhere((x) => x.id == id);
    if (idx < 0) return;
    debts[idx] = updated;
    debts.refresh();
    await _persistAndRecalc();
  }

  Future<void> removeDebt(String id) async {
    debts.removeWhere((x) => x.id == id);
    await _persistAndRecalc();
  }

  Future<void> clearAllDebts() async {
    // await DebtStorage.clear();
    resetRuntimeState();
    state.value = ButtonState.done;
  }

  Future<void> _persistAndRecalc() async {
    debts.assignAll(_sanitize(debts));
    // await DebtStorage.write(debts);
    _recalcInsights();
  }

  List<DebtAccount> _sanitize(List<DebtAccount> list) {
    // clamp + fix invalid due day etc
    return list.map((d) {
      final due = d.dueDay.clamp(1, 28);
      final bal = max(0.0, d.principal);
      final apr = max(0.0, min(99.99, d.apr));
      final minPay = max(0.0, d.minPayment);
      return d.copyWith(dueDay: due, principal: bal, apr: apr, minPayment: minPay);
    }).toList();
  }

  void _recalcInsights() {
    final ds = debts.where((d) => d.principal > 0.01).toList();
    if (ds.isEmpty) {
      insights.value = DebtInsights(
        totalBalance: 0,
        totalMinPayment: 0,
        weightedApr: 0,
        monthlyInterestBurn: 0,
        dailyInterestBurn: 0,
        topBurner: null,
        nextDue: null,
        debtCount: 0,
        snowballPlan: null,
        avalanchePlan: null,
      );
      return;
    }

    final totalBal = ds.fold<double>(0, (s, d) => s + d.principal);
    final totalMin = ds.fold<double>(0, (s, d) => s + d.minPayment);

    double monthlyBurn = 0;
    DebtAccount? top;
    double topMonthly = -1;

    for (final d in ds) {
      final r = (d.apr <= 0) ? 0.0 : (d.apr / 100) / 12.0;
      final m = d.principal * r;
      monthlyBurn += m;
      if (m > topMonthly) {
        topMonthly = m;
        top = d;
      }
    }

    final weightedApr = totalBal <= 0 ? 0 : ds.fold<double>(0, (s, d) => s + (d.apr * d.principal)) / totalBal;

    final nextDue = _nextDueDebt(ds);

    // Payoff plans using your engine
    final budget = max(0.0, totalMin + extraBudget.value);
    final snow = buildPlan(debts: ds, monthlyBudget: budget, strategy: Strategy.snowball);
    final ava = buildPlan(debts: ds, monthlyBudget: budget, strategy: Strategy.avalanche);

    insights.value = DebtInsights(
      totalBalance: totalBal,
      totalMinPayment: totalMin,
      weightedApr: 0.0,
      monthlyInterestBurn: monthlyBurn,
      dailyInterestBurn: monthlyBurn / 30.0,
      topBurner: top,
      nextDue: nextDue,
      debtCount: ds.length,
      snowballPlan: snow,
      avalanchePlan: ava,
    );
  }

  DebtAccount? _nextDueDebt(List<DebtAccount> ds) {
    final now = DateTime.now();
    int daysUntil(int dueDay) {
      final dueThisMonth = DateTime(now.year, now.month, dueDay);
      final due = dueThisMonth.isBefore(DateTime(now.year, now.month, now.day)) ? DateTime(now.year, now.month + 1, dueDay) : dueThisMonth;
      return due.difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    DebtAccount? best;
    int bestDays = 1 << 30;

    for (final d in ds) {
      final dd = d.dueDay.clamp(1, 28);
      final k = daysUntil(dd);
      if (k < bestDays) {
        bestDays = k;
        best = d;
      }
    }
    return best;
  }

  /// Use this for your allocation list UI (min + extra distributed)
  List<Map<String, dynamic>> allocationThisMonth({required bool snowball}) {
    final ds = debts.where((d) => d.principal > 0.01).toList();
    if (ds.isEmpty) return [];

    final totalMin = ds.fold<double>(0, (s, d) => s + d.minPayment);
    final budget = max(0.0, totalMin + extraBudget.value);

    final p = buildPlan(
      debts: ds,
      monthlyBudget: budget,
      strategy: snowball ? Strategy.snowball : Strategy.avalanche,
    );

    if (p.rows.isEmpty) return [];

    final row0 = p.rows.first;
    return ds.map((d) {
      final pay = (row0.payments[d.id] ?? 0.0);
      final minPay = min(d.minPayment, d.principal);
      final extra = max(0.0, pay - minPay);
      return {
        'id': d.id,
        'name': d.name,
        'min': minPay,
        'extra': extra,
      };
    }).toList();
  }

  /// hook slider -> call this
  void setExtra(double v) {
    extraBudget.value = v;
    _recalcInsights();
  }
}
