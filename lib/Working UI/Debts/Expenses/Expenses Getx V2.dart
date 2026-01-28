// expenses_getx_controller_v10.dart
// ============================================================================
// GETX CONTROLLER (state + storage + CRUD + refreshInsights bridge)
// ----------------------------------------------------------------------------
// Linked with:
// - expense_models_v2.dart          (ExpenseItem + ExpensesResponse storage model)
// - expense_insight_logic_v10.dart  (history gate + deck compute)
//
// REQUIRED external dependencies in YOUR project:
// - getLocalData(key) / saveLocalData(key, value)  (SharedPreferences helpers)
// - showSnackBar(title, msg)                       (UI feedback helper)
// - toDouble(String) -> double?                    (your converter)
// - TextForm model + ButtonState enum              (your UI infra)
//
// IMPORTANT UI RULE:
// - Use gate.allowed to decide if insights should show.
// - If gate.allowed == false => show “Need more data” UI using gate.subtitle.
// ============================================================================

import 'package:emptyproject/Working%20UI/Shared%20Preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import '../../../models/Debt Model.dart';
import '../../../models/Expense Model V2.dart';
import '../../../models/TextForm.dart';
import '../../Constants.dart';
import '../../Controllers.dart';
import 'Expense Insight Logic V2.dart';

class ExpensesControllerV2 extends GetxController {
  // ---------------------------
  // UI FORM STATE
  // ---------------------------

  /// Your UI form fields.
  /// Linked with: addExpenseFromUI()
  RxList<TextForm> controllers = <TextForm>[
    TextForm(title: "Amount", controller: TextEditingController(text: "")),
    TextForm(title: "Name", controller: TextEditingController(text: "")),
    TextForm(title: "Notes (optional)", controller: TextEditingController(text: "")),
    TextForm(title: "Category", controller: TextEditingController(text: "")),
    TextForm(title: "Account", controller: TextEditingController(text: "")), // display only
    TextForm(title: "Date", controller: TextEditingController(text: "")),
    TextForm(title: "Essential", controller: TextEditingController(text: "Yes")),
    TextForm(title: "Frequency", controller: TextEditingController(text: ExpenseFrequency.oneTime)),
    TextForm(title: "Type", controller: TextEditingController(text: '')),
  ].obs;

  final RxBool isEssential = true.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isRecurring = false.obs;
  final RxBool showFrequencies = false.obs;
  final RxBool showCategories = false.obs;
  final RxString selectedMode = ExpenseMode.spent.obs;
  Rxn<AccountRef>? selectedAccount = Rxn<AccountRef>();
  final RxInt dueDay = 0.obs;
  final formKey = GlobalKey<FormState>();

  /// Multi-account selection (real).
  final RxList<AccountRef> selectedAccounts = <AccountRef>[].obs;

  final List<String> categories = const [
    "Housing",
    "Utilities",
    "Internet & Phone",
    "Groceries",
    "Transport",
    "Insurance",
    "Subscriptions",
    "Dining & Coffee",
    "Health",
    "Shopping",
    "Entertainment",
    "Other",
  ];

  final List<String> frequencies = const [
    ExpenseFrequency.oneTime,
    ExpenseFrequency.weekly,
    ExpenseFrequency.biweekly,
    ExpenseFrequency.monthly,
  ];

  Rx<ButtonState> state = ButtonState.loading.obs;

  // ---------------------------
  // DATA STATE
  // ---------------------------

  Rx<ExpensesResponse> expensesModel = const ExpensesResponse(status: "200", message: "ok").obs;
  Rxn<ExpenseItem>? selectedExpense = Rxn<ExpenseItem>();
  RxList<AutomationRule> rules = <AutomationRule>[].obs;

  // ---------------------------
  // INSIGHTS STATE
  // ---------------------------

  /// Gate must be shown when insights are not allowed.
  final Rxn<InsightsGateVM> gate = Rxn<InsightsGateVM>();

  /// Only exists when gate.allowed == true
  final Rxn<InsightsDeckVM> deck = Rxn<InsightsDeckVM>();

  /// Month selection impacts windows shown.
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  /// Automatic buffer target (volatility-based).
  final RxDouble bufferTarget = 0.0.obs;

  /// Debt minimums placeholder (later: link with your DebtController).
  final RxDouble debtMinimumsWindow = 0.0.obs;

  /// Storage key
  static const String _kSavedExpenses = "savedExpenses";

  // ---------------------------
  // LIFECYCLE
  // ---------------------------

  // ---------------------------
  // FORM
  // ---------------------------

  /// Clears the form UI, does NOT touch saved data.
  void resetForm() {
    selectedAccounts.clear();
    isEssential.value = true;
    selectedDate.value = DateTime.now();
    controllers[0].controller.text = "";
    controllers[1].controller.text = "";
    controllers[2].controller.text = "";
    controllers[3].controller.text = "";
    controllers[4].controller.text = "";
    controllers[5].controller.text = "";
    controllers[6].controller.text = "Yes";
    controllers[7].controller.text = ExpenseFrequency.oneTime;
    controllers[8].controller.text = '';
    selectedAccount = Rxn<AccountRef>();
    selectedMode.value = ExpenseMode.spent;
    controllers.refresh();
  }

  /// Set selected accounts from your multi-select UI.
  /// Linked with: ExpenseItem.accounts storage.
  void setSelectedAccounts(List<AccountRef> accounts) {
    selectedAccounts.assignAll(accounts);
    controllers[4].controller.text = accounts.isEmpty ? "" : accounts.map((e) => e.name).join(", ");
  }

  /// If user selected no accounts, fallback to your global selected card/bank.
  /// IMPORTANT: wire this to your CardsAndAccount controller.
  List<AccountRef> _fallbackAccountsIfEmpty(List<AccountRef> picked) {
    if (picked.isNotEmpty) return picked;

    // TODO: connect real fallback here:
    // final c = cards.selectedCard.value;
    // if (c != null) return [AccountRef(id: c.id, type: "card", name: c.bankName ?? "Card")];

    return const [];
  }

  // ---------------------------
  // STORAGE LOAD/SAVE
  // ---------------------------

  /// Loads saved expenses from local storage into reactive state.
  Future<void> loadExpenses() async {
    state.value = ButtonState.loading;
    final data = await _loadExpensesModel();

    expensesModel.value = data;
    rules.assignAll(data.rules);
    // compute helpers
    bufferTarget.value = suggestBufferTarget(data.expenses);
    debtMinimumsWindow.value = 0.0;

    // month summary
    final ms = computeMonthlySummary(data.expenses);
    expensesModel.value = expensesModel.value.copyWith(monthSummary: ms);
    refreshInsights();
    Future.delayed(const Duration(seconds: 2), () {
      state.value = ButtonState.init;
    });
  }

  IconData categoryIcon(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    // normalize some common variants
    if (s.contains('internet') || s.contains('phone')) return CupertinoIcons.wifi;

    switch (s) {
      case 'housing':
        return CupertinoIcons.house_fill;

      case 'utilities':
        return CupertinoIcons.bolt_fill;

      case 'groceries':
        return CupertinoIcons.cart_fill;

      case 'transport':
        return CupertinoIcons.car_fill;

      case 'insurance':
        return CupertinoIcons.shield_fill;

      case 'subscriptions':
        return CupertinoIcons.repeat;

      case 'dining & coffee':
      case 'dining and coffee':
      case 'dining':
      case 'coffee':
        return MaterialIcons.food_bank;

      case 'health':
        return CupertinoIcons.heart_fill;

      case 'shopping':
        return CupertinoIcons.bag_fill;

      case 'entertainment':
        return CupertinoIcons.film_fill;

      case 'other':
      default:
        return CupertinoIcons.square_grid_2x2_fill;
    }
  }

  /// Raw storage read.
  Future<ExpensesResponse> _loadExpensesModel() async {
    final saved = await getLocalData(_kSavedExpenses) ?? "";
    if (saved.trim().isEmpty) {
      return const ExpensesResponse(status: "200", message: "ok", version: 2, rules: [], expenses: []);
    }
    return ExpensesResponse.decode(saved);
  }

  /// Persist + update reactive lists immediately (no delayed reload).
  Future<void> _persist(ExpensesResponse m) async {
    await saveLocalData(_kSavedExpenses, m.encode());

    expensesModel.value = m;
    rules.assignAll(m.rules);

    bufferTarget.value = suggestBufferTarget(m.expenses);
    final ms = computeMonthlySummary(m.expenses);
    expensesModel.value = expensesModel.value.copyWith(monthSummary: ms);

    rules.refresh();
    expensesModel.refresh();
  }

  // ---------------------------
  // CRUD: EXPENSES
  // ---------------------------

  /// Creates an ExpenseItem from UI and saves it.
  /// Mode rule:
  /// - One-time => spent
  /// - Recurring => planned

  Future<void> addExpenseFromUI() async {
    final freq = controllers[7].controller.text.trim();
    if (!frequencies.contains(freq)) {
      showSnackBar("Invalid", "Frequency must be selected from the list.");
      return;
    }

    final mode = selectedMode.value.trim();
    if (mode != ExpenseMode.spent && mode != ExpenseMode.planned) {
      showSnackBar("Invalid", "Select Spent or Planned.");
      return;
    }

    if (controllers[0].controller.text.trim().isEmpty ||
        controllers[1].controller.text.trim().isEmpty ||
        controllers[3].controller.text.trim().isEmpty) {
      showSnackBar("Missing Info", "Amount, Name, and Category are required.");
      return;
    }

    final amt = toDouble(controllers[0].controller.text);
    if (amt == null || amt <= 0) {
      showSnackBar("Invalid Amount", "Enter a valid amount.");
      return;
    }
    if (selectedAccount == null) {
      showSnackBar("Missing Account", "Select at least one account.");
      return;
    }

    // ✅ dueDay required only for PLANNED + MONTHLY
    if (mode == ExpenseMode.planned && freq == ExpenseFrequency.monthly) {
      if (dueDay.value < 1 || dueDay.value > 28) {
        showSnackBar("Missing billing day", "Pick a billing day (1–28) for monthly planned bills.");
        return;
      }
    }

    bool? isCard = cards.cards.any((t) => t.id == selectedAccount!.value!.id);
    if (isCard) {
      cards.applyDeltaToCardUsed(cardId: selectedAccount!.value!.id!, deltaUsed: amt);
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final date = selectedDate.value;

    final item = ExpenseItem(
      id: "ex_$nowMs",
      amount: amt,
      name: controllers[1].controller.text.trim(),
      notes: controllers[2].controller.text.trim(),
      category: controllers[3].controller.text.trim(),
      accounts: [selectedAccount!.value!],
      date: date,
      dueDay: selectedDate.value.day,
      isEssential: isEssential.value,
      frequency: freq,
      mode: mode, // ✅ comes from UI, not frequency
      isActive: true,
      createdAtMs: nowMs,
    );
    print(item);

    final updated = expensesModel.value.copyWith(
      message: "expense added",
      expenses: [...expensesModel.value.expenses, item],
    );

    await _persist(updated);
    Get.back();
    Future.delayed(const Duration(seconds: 1), () async {
      showSnackBar("Success", "Expense added.");
    });
  }

  /// Updates an existing expense by id.
  Future<void> editExpenseFromUI({String? id, int? dueDay}) async {
    final idx = expensesModel.value.expenses.indexWhere((x) => x.id == selectedExpense!.value!.id);
    expensesModel.value.expenses[idx] = ExpenseItem(
      id: selectedExpense!.value!.id,
      amount: toDouble(controllers[0].controller.text)!,
      name: controllers[1].controller.text,
      notes: controllers[2].controller.text,
      category: controllers[3].controller.text,
      dueDay: selectedDate.value.day,
      isEssential: isEssential.value,
      frequency: controllers[7].controller.text,
      isActive: true,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      accounts: [selectedAccount!.value!],
      date: selectedDate.value,
      mode: selectedMode.value,
    );
    expensesModel.refresh();

    await _persist(expensesModel.value.copyWith(message: "expense updated", expenses: expensesModel.value.expenses));
    Get.back();
    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "Expense updated.");
    });
  }

  /// Hard delete.
  Future<void> deleteExpense(String id) async {
    final list = expensesModel.value.expenses.toList()..removeWhere((e) => e.id == id);
    await _persist(expensesModel.value.copyWith(message: "expense deleted", expenses: list));
    showSnackBar("Success", "Expense removed.");
  }

  /// Soft delete (ignore in insights + totals).
  Future<void> toggleExpenseActive(String id) async {
    final list = expensesModel.value.expenses.toList();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    final cur = list[idx];
    list[idx] = cur.copyWith(isActive: !cur.isActive);

    await _persist(expensesModel.value.copyWith(message: "expense toggled", expenses: list));
  }

  /// Sets due day for monthly planned bill for accurate “bills due”.
  Future<void> setMonthlyDueDay({required String id, required int dueDay}) async {
    if (dueDay < 1 || dueDay > 28) {
      showSnackBar("Invalid due day", "Use 1–28 for reliability.");
      return;
    }
    await editExpenseFromUI(id: id, dueDay: dueDay);
  }

  // ---------------------------
  // CRUD: RULES
  // ---------------------------

  Future<void> addRule({
    required String title,
    required String description,
    bool enabled = true,
  }) async {
    if (title.trim().isEmpty) {
      showSnackBar("Missing Info", "Enter a rule title.");
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rule = AutomationRule(
      id: "r_$nowMs",
      title: title.trim(),
      description: description.trim(),
      enabled: enabled,
      createdAtMs: nowMs,
    );
    await _persist(expensesModel.value.copyWith(message: "rule added", rules: [...rules, rule]));
  }

  Future<void> toggleRule(String id) async {
    final list = rules.toList();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return;

    list[idx] = list[idx].copyWith(enabled: !list[idx].enabled);
    await _persist(expensesModel.value.copyWith(message: "rule toggled", rules: list));
  }

  Future<void> deleteRule(String id) async {
    final list = rules.toList()..removeWhere((r) => r.id == id);
    await _persist(expensesModel.value.copyWith(message: "rule deleted", rules: list));
  }

  // ---------------------------
  // INSIGHTS BRIDGE
  // ---------------------------

  /// IMPORTANT: Call this only after your Shift controller has built payCycles.
  ///
  /// Linked with:
  /// - Your Shift controller payCycles (RxMap<DateTime, PayCell>)
  /// - Your Insights screen UI (use gate + deck)
  void refreshInsights({DateTime? now}) {
    final g = buildHistoryGate(expensesModel.value.expenses, minDays: 15, now: now);
    gate.value = g;

    // If gate says no: DO NOT show “fake” insights.
    if (!g.allowed) {
      deck.value = null;
      deck.refresh();
      gate.refresh();
      return;
    }

    final buf = bufferTarget.value <= 0 ? suggestBufferTarget(expensesModel.value.expenses, now: now) : bufferTarget.value;
    bufferTarget.value = buf;

    final d = computeInsightsDeck(
      expenses: expensesModel.value.expenses,
      focusedDay: focusedDay.value,
      payCycles: shift.payCycles!,
      bufferTarget: buf,
      debtMinimumsWindow: debtMinimumsWindow.value,
      now: now,
    );

    deck.value = d;
    deck.refresh();
    gate.refresh();
  }

  /// Convenience for UI: if false => show “Need more data”.
  bool get canShowInsights => (gate.value?.allowed ?? false) && (deck.value != null);
}
