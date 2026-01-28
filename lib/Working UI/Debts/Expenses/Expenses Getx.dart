// import 'package:emptyproject/Working%20UI/Controllers.dart';
// import 'package:emptyproject/Working%20UI/Cards%20and%20Account/Cards.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_vector_icons/flutter_vector_icons.dart';
// import 'package:get/get.dart';
//
// import '../../../models/Expense Model.dart';
// import '../../../models/TextForm.dart';
// import '../../Constant UI.dart';
// import '../../Constants.dart';
// import '../../Shared Preferences.dart';
// import 'Expense Insight Logic.dart';
//
// String displayText(TextForm data) {
//   final t = data.title;
//   final v = data.controller.text.trim();
//
//   if (t == "Date" && v.isEmpty) return formatDate(DateTime.now());
//   if (t != "Account" && v.isEmpty) return "select $t";
//
//   if (t == "Account") {
//     final card = cards.selectedCard.value;
//     final bank = cards.selectedBank.value;
//
//     final pick = (card?.bankName?.trim().isNotEmpty ?? false)
//         ? card!.bankName!
//         : (bank?.bankName?.trim().isNotEmpty ?? false)
//             ? bank!.bankName!
//             : (bank?.nickName?.trim().isNotEmpty ?? false)
//                 ? bank!.nickName!
//                 : "";
//
//     return pick.isEmpty ? "select $t" : pick;
//   }
//
//   return v.isEmpty ? "select $t" : v;
// }
//
// class ExpensesGetxController extends GetxController {
//   // Text fields using your TextForm model
//   final RxList<TextForm> forms = <TextForm>[].obs;
//   final RxInt selectedWindow = 0.obs;
//   final Rxn<InsightsDeckVM> windows = Rxn<InsightsDeckVM>();
//
//   // Selections
//   final RxString frequency = ''.obs;
//   final RxBool isEssential = true.obs;
//
//   // Date
//   final Rx<DateTime> date = DateTime.now().obs;
//
//   final RxBool isRecurring = false.obs;
//   final RxBool showFrequencies = false.obs;
//   final RxBool showCategories = false.obs;
//   final RxInt dueDay = 1.obs;
//   final RxDouble? totalVariableExpense = 0.0.obs;
//   final RxDouble? totalFixedExpense = 0.0.obs;
//   Rx<ButtonState> state = ButtonState.loading.obs;
//   Rx<InsightsDeckVM>? insights;
//
//   Rx<ExpensesResponse> expensesModel = const ExpensesResponse(status: "200", message: "ok").obs;
//
//   RxList<ExpenseItem> expenses = <ExpenseItem>[].obs;
//   RxList<ExpenseItem> variableExpense = <ExpenseItem>[].obs;
//   RxList<ExpenseItem> fixedExpenses = <ExpenseItem>[].obs;
//   RxList<AutomationRule> rules = <AutomationRule>[].obs;
//   ExpenseItem? selectedExpense;
//
//   MonthlySummary? get monthSummary => expensesModel.value.monthSummary;
//   PaydayBuffer? get paydayBuffer => expensesModel.value.paydayBuffer;
//   // InsightsModel? get insights => expensesModel.value.insights;
//   RxList<TextForm> controllers = [
//     TextForm(title: "Amount", controller: TextEditingController(text: "")),
//     TextForm(title: "Name", controller: TextEditingController(text: "")),
//     TextForm(title: "Notes (optional)", controller: TextEditingController(text: "")),
//     TextForm(title: "Category", controller: TextEditingController(text: "")),
//     TextForm(title: "Account", controller: TextEditingController(text: "")),
//     TextForm(title: "Date", controller: TextEditingController(text: "")),
//     TextForm(title: "Essential", controller: TextEditingController(text: "Yes")),
//     TextForm(title: "Frequency", controller: TextEditingController(text: "")),
//   ].obs;
//
//   final formKey = GlobalKey<FormState>();
//
//   final List<String> categories = const [
//     "Housing",
//     "Utilities",
//     "Internet & Phone",
//     "Groceries",
//     "Transport",
//     "Insurance",
//     "Subscriptions",
//     "Dining & Coffee",
//     "Health",
//     "Shopping",
//     "Entertainment",
//     "Other",
//   ];
//
//   IconData categoryIcon(String? raw) {
//     final s = (raw ?? '').trim().toLowerCase();
//     // normalize some common variants
//     if (s.contains('internet') || s.contains('phone')) return CupertinoIcons.wifi;
//
//     switch (s) {
//       case 'housing':
//         return CupertinoIcons.house_fill;
//
//       case 'utilities':
//         return CupertinoIcons.bolt_fill;
//
//       case 'groceries':
//         return CupertinoIcons.cart_fill;
//
//       case 'transport':
//         return CupertinoIcons.car_fill;
//
//       case 'insurance':
//         return CupertinoIcons.shield_fill;
//
//       case 'subscriptions':
//         return CupertinoIcons.repeat;
//
//       case 'dining & coffee':
//       case 'dining and coffee':
//       case 'dining':
//       case 'coffee':
//         return MaterialIcons.food_bank;
//
//       case 'health':
//         return CupertinoIcons.heart_fill;
//
//       case 'shopping':
//         return CupertinoIcons.bag_fill;
//
//       case 'entertainment':
//         return CupertinoIcons.film_fill;
//
//       case 'other':
//       default:
//         return CupertinoIcons.square_grid_2x2_fill;
//     }
//   }
//
//   final List<String> frequencies = const [
//     "One-time",
//     "Weekly",
//     "Biweekly",
//     "Monthly",
//   ];
//
//   void reset() {
//     frequency.value = '';
//     showFrequencies.value = false;
//     isEssential.value = true;
//     date.value = DateTime.now();
//     isRecurring.value = false;
//     dueDay.value = 1;
//     totalVariableExpense!.value = 0.0;
//     totalFixedExpense!.value = 0.0;
//     variableExpense.clear();
//     fixedExpenses.clear();
//     for (var files in controllers) {
//       if (files.title == 'Essential') {
//         files.controller.text = 'Yes';
//       } else {
//         files.controller.text = '';
//       }
//     }
//   }
//
//   // ========= PUBLIC CRUD =========
//
//   Future<void> loadExpenses() async {
//     reset();
//     final data = await _loadExpensesModel();
//     expensesModel.value = data;
//     expenses.assignAll(data.expenses);
//     rules.assignAll(data.rules);
//     for (var files in expenses) {
//       if (files.frequency == 'One-time') {
//         totalVariableExpense!.value += files.amount;
//         variableExpense.add(files);
//       } else {
//         totalFixedExpense!.value += files.amount;
//         fixedExpenses.add(files);
//       }
//     }
//
//     windows.value = computeInsightsDeckForUpcomingPaydays_PayCycles(
//       expensesData: expensesModel.value,
//       focusedDay: date.value,
//       payCycles: shift.payCycles!, // RxMap<DateTime, PayCell> OR use cycles
//       bufferTarget: 40, // double
//       debtMinimumsWindow: 20, // double
//       now: DateTime.now(),
//     );
//
//     windows.refresh();
//
//     // recomputeAllWindows(overview: overview.overViewShifts!);
//     fixedExpenses.refresh();
//     variableExpense.refresh();
//     totalVariableExpense!.refresh();
//     totalFixedExpense!.refresh();
//     state.value = ButtonState.init;
//     state.refresh();
//   }
//
//   Future<ExpensesResponse> addExpenseFromUI() async {
//     final data = await _loadExpensesModel();
//
//     if (controllers.any((test) => test.controller.text.isEmpty)) {
//       showSnackBar("Missing Info", "Enter empty fields");
//       return data;
//     }
//
//     final now = DateTime.now().millisecondsSinceEpoch;
//
//     final item = ExpenseItem(
//       id: now.toString(),
//       amount: toDouble(controllers[0].controller.text)!,
//       name: controllers[1].controller.text,
//       notes: controllers[2].controller.text,
//       category: controllers[3].controller.text,
//       accountId: cards.selectedCard.value != null ? cards.selectedCard.value!.id : cards.selectedBank.value!.id,
//       accountName: cards.selectedCard.value != null ? cards.selectedCard.value!.bankName : cards.selectedBank.value!.bankName,
//       dateMs: controllers[5].pickedDate!,
//       dueDay: 0,
//       isEssential: isEssential.value,
//       frequency: controllers[7].controller.text,
//       isActive: true,
//       createdAtMs: now,
//     );
//
//     final newList = [...data.expenses, item];
//
//     final updated = ExpensesResponse(
//       status: data.status,
//       message: "expense added",
//       monthSummary: data.monthSummary,
//       paydayBuffer: data.paydayBuffer,
//       insights: data.insights,
//       rules: data.rules,
//       expenses: newList,
//     );
//
//     state.value = ButtonState.loading;
//     state.refresh();
//
//     // expensesModel.value = updated;
//     // expenses.assignAll(updated.expenses);
//
//     await _saveExpensesModel(updated);
//
//     Get.back();
//     Future.delayed(const Duration(milliseconds: 200), () {
//       showSnackBar("Success", "Expense added.");
//     });
//
//     return updated;
//   }
//
//   Future<ExpensesResponse> editExpenseFromUI() async {
//     final data = await _loadExpensesModel();
//     final list = [...data.expenses];
//
//     final idx = list.indexWhere((x) => x.id == selectedExpense!.id);
//     if (idx < 0) return data;
//
//     final updatedItem = ExpenseItem(
//       id: selectedExpense!.id,
//       amount: toDouble(controllers[0].controller.text)!,
//       name: controllers[1].controller.text,
//       notes: controllers[2].controller.text,
//       category: controllers[3].controller.text,
//       accountId: cards.selectedCard.value != null
//           ? cards.selectedCard.value!.id
//           : cards.selectedBank.value != null
//               ? cards.selectedBank.value!.id
//               : selectedExpense!.accountId,
//       accountName: cards.selectedCard.value != null
//           ? cards.selectedCard.value!.bankName
//           : cards.selectedBank.value != null
//               ? cards.selectedBank.value!.bankName
//               : selectedExpense!.accountName,
//       dateMs: controllers[5].pickedDate!,
//       dueDay: 0,
//       isEssential: isEssential.value,
//       frequency: controllers[7].controller.text,
//       isActive: true,
//       createdAtMs: selectedExpense!.createdAtMs,
//     );
//
//     list[idx] = updatedItem;
//
//     final updated = ExpensesResponse(
//       status: data.status,
//       message: "expense updated",
//       monthSummary: data.monthSummary,
//       paydayBuffer: data.paydayBuffer,
//       insights: data.insights,
//       rules: data.rules,
//       expenses: list,
//     );
//
//     state.value = ButtonState.loading;
//     state.refresh();
//
//     // expensesModel.value = updated;
//     // expenses.assignAll(updated.expenses);
//
//     await _saveExpensesModel(updated);
//     Get.back();
//     Future.delayed(const Duration(milliseconds: 500), () {
//       showSnackBar("Success", "Expense updated.");
//     });
//
//     return updated;
//   }
//
//   Future<ExpensesResponse> deleteExpense() async {
//     final data = await _loadExpensesModel();
//     final list = [...data.expenses]..removeWhere((e) => e.id == selectedExpense!.id);
//
//     final updated = ExpensesResponse(
//       status: data.status,
//       message: "expense deleted",
//       monthSummary: data.monthSummary,
//       paydayBuffer: data.paydayBuffer,
//       insights: data.insights,
//       rules: data.rules,
//       expenses: list,
//     );
//
//     state.value = ButtonState.loading;
//     state.refresh();
//
//     // expensesModel.value = updated;
//     // expenses.assignAll(updated.expenses);
//
//     await _saveExpensesModel(updated);
//
//     showSnackBar("Success", "Expense removed.");
//     return updated;
//   }
//
//   Future<ExpensesResponse> toggleExpenseActive({required String id}) async {
//     final data = await _loadExpensesModel();
//     final list = [...data.expenses];
//
//     final idx = list.indexWhere((e) => e.id == id);
//     if (idx < 0) return data;
//
//     final cur = list[idx];
//     list[idx] = ExpenseItem(
//       id: cur.id,
//       name: cur.name,
//       amount: cur.amount,
//       notes: cur.notes,
//       category: cur.category,
//       accountId: cur.accountId,
//       accountName: cur.accountName,
//       dateMs: cur.dateMs,
//       dueDay: cur.dueDay,
//       isEssential: cur.isEssential,
//       frequency: cur.frequency,
//       isActive: !cur.isActive,
//       createdAtMs: cur.createdAtMs,
//     );
//
//     final updated = ExpensesResponse(
//       status: data.status,
//       message: "expense toggled",
//       monthSummary: data.monthSummary,
//       paydayBuffer: data.paydayBuffer,
//       insights: data.insights,
//       rules: data.rules,
//       expenses: list,
//     );
//
//     expensesModel.value = updated;
//     expenses.assignAll(updated.expenses);
//
//     await _saveExpensesModel(updated);
//     return updated;
//   }
//
//   // ========= RULE CRUD (matches your UI “Automation rules”) =========
//
//   Future<ExpensesResponse> addRuleFromUI({
//     required String title,
//     required String description,
//     bool enabled = true,
//   }) async {
//     final data = await _loadExpensesModel();
//
//     if (title.trim().isEmpty) {
//       showSnackBar("Missing Info", "Enter a rule title.");
//       return data;
//     }
//
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final rule = AutomationRule(
//       id: now.toString(),
//       title: title.trim(),
//       description: description.trim(),
//       enabled: enabled,
//       createdAtMs: now,
//     );
//
//     final newRules = [...data.rules, rule];
//
//     final updated = ExpensesResponse(
//       status: data.status,
//       message: "rule added",
//       monthSummary: data.monthSummary,
//       paydayBuffer: data.paydayBuffer,
//       insights: data.insights,
//       rules: newRules,
//       expenses: data.expenses,
//     );
//
//     expensesModel.value = updated;
//     rules.assignAll(updated.rules);
//
//     await _saveExpensesModel(updated);
//     showSnackBar("Success", "Rule added.");
//     return updated;
//   }
//
//   Future<ExpensesResponse> toggleRule({required String id}) async {
//     final data = await _loadExpensesModel();
//     final list = [...data.rules];
//
//     final idx = list.indexWhere((r) => r.id == id);
//     if (idx < 0) return data;
//
//     final cur = list[idx];
//     list[idx] = AutomationRule(
//       id: cur.id,
//       title: cur.title,
//       description: cur.description,
//       enabled: !cur.enabled,
//       createdAtMs: cur.createdAtMs,
//     );
//
//     final updated = ExpensesResponse(
//       status: data.status,
//       message: "rule toggled",
//       monthSummary: data.monthSummary,
//       paydayBuffer: data.paydayBuffer,
//       insights: data.insights,
//       rules: list,
//       expenses: data.expenses,
//     );
//
//     expensesModel.value = updated;
//     rules.assignAll(updated.rules);
//
//     await _saveExpensesModel(updated);
//     return updated;
//   }
//
//   Future<ExpensesResponse> deleteRule({required String id}) async {
//     final data = await _loadExpensesModel();
//     final list = [...data.rules]..removeWhere((r) => r.id == id);
//
//     final updated = ExpensesResponse(
//       status: data.status,
//       message: "rule deleted",
//       monthSummary: data.monthSummary,
//       paydayBuffer: data.paydayBuffer,
//       insights: data.insights,
//       rules: list,
//       expenses: data.expenses,
//     );
//
//     expensesModel.value = updated;
//     rules.assignAll(updated.rules);
//
//     await _saveExpensesModel(updated);
//     showSnackBar("Success", "Rule removed.");
//     return updated;
//   }
//
//   // ========= LOAD / SAVE =========
//
//   Future<ExpensesResponse> _loadExpensesModel() async {
//     final saved = await getLocalData('savedExpenses') ?? '';
//     if (saved.isEmpty) {
//       return const ExpensesResponse(status: "200", message: "ok");
//     }
//     return ExpensesResponse.decode(saved);
//   }
//
//   Future<void> _saveExpensesModel(ExpensesResponse m) async {
//     final recomputed = recomputeInsights(m);
//     await saveLocalData('savedExpenses', recomputed.encode());
//     Future.delayed(const Duration(milliseconds: 500), () {
//       loadExpenses();
//     });
//   }
//
//   ExpensesResponse recomputeInsights(ExpensesResponse data) {
//     final now = DateTime.now().millisecondsSinceEpoch;
//
//     // ---- 1) Month summary (simple version) ----
//     double fixed = 0, variable = 0, total = 0;
//
//     for (final e in data.expenses) {
//       if (e.isActive != true) continue;
//
//       // crude monthly normalization (you can improve later)
//       final monthly = _toMonthly(e.amount, e.frequency);
//
//       total += monthly;
//
//       final cat = e.category.toLowerCase();
//       if (cat.contains("fixed") || cat.contains("bill") || cat.contains("subscription")) {
//         fixed += monthly;
//       } else {
//         variable += monthly;
//       }
//     }
//
//     final monthSummary = MonthlySummary(
//       fixed: fixed,
//       variable: variable,
//       total: total,
//       note: "Based on your monthly & per-paycheque expenses",
//     );
//
//     // ---- 2) Safe-to-spend (needs inputs; use placeholders if missing) ----
//     // You should replace these with your real income module values:
//     final expectedIncome = 0.0;
//     final debtMinimums = 0.0;
//     final bufferTarget = 200.0;
//
//     // bills due until payday: sum expenses that are bills/subscriptions/fixed with dueDay in upcoming window
//     final billsDue = _estimateBillsDueUntilPayday(data.expenses);
//
//     final safe = (expectedIncome - billsDue - debtMinimums - bufferTarget);
//     final safeToSpend = SafeToSpend(
//       amount: safe < 0 ? 0 : safe,
//       untilDateMs: now, // replace with your next payday ms
//       expectedIncome: expectedIncome,
//       billsDue: billsDue,
//       debtMinimums: debtMinimums,
//       bufferTarget: bufferTarget,
//     );
//
//     // ---- 3) Forecast risk tag (very simple) ----
//     final riskLevel = safe >= bufferTarget ? "Safe" : (safe >= 0 ? "Tight" : "High");
//     final paydayBuffer = PaydayBuffer(
//       amount: safe,
//       tag: riskLevel,
//       deltaMonth: null,
//     );
//
//     final forecastRisk = ForecastRisk(
//       level: riskLevel,
//       title: "Forecast risk",
//       description: riskLevel == "Safe"
//           ? "You're on track if spending stays steady."
//           : riskLevel == "Tight"
//               ? "This window is tight—consider a small cut."
//               : "High risk—cash flow may go negative.",
//       actions: const ["Move", "Cut"],
//     );
//
//     // ---- 4) Next best move (optional: rule-based) ----
//     NextBestMove? nextMove;
//     if (riskLevel != "Safe") {
//       nextMove = NextBestMove(
//         title: "Reserve ${bufferTarget.toStringAsFixed(0)} for buffer",
//         description: "Reserve it now so it can’t be spent before payday.",
//         actionAmount: bufferTarget,
//         dueDateMs: now,
//       );
//     }
//
//     final cutsChecklist = CutsChecklist(
//       title: "Save \$50 fastest",
//       tag: riskLevel == "Safe" ? "Ok" : "Tight",
//       bullets: const [
//         "Pause dining out this week",
//         "Cancel/hold subscriptions",
//         "Reduce fuel spending",
//       ],
//     );
//
//     final insights = InsightsModel(
//       safeToSpend: safeToSpend,
//       nextBestMove: nextMove,
//       leaksAndSpikes: const [],
//       forecastRisk: forecastRisk,
//       cutsChecklist: cutsChecklist,
//     );
//
//     return ExpensesResponse(
//       status: data.status,
//       message: data.message,
//       monthSummary: monthSummary,
//       paydayBuffer: paydayBuffer,
//       insights: insights,
//       rules: data.rules,
//       expenses: data.expenses,
//     );
//   }
//
//   double _toMonthly(double amount, String frequency) {
//     final f = frequency.toLowerCase().trim();
//     if (f == "monthly") return amount;
//     if (f == "weekly") return amount * 4.345; // avg weeks/month
//     if (f == "yearly") return amount / 12.0;
//     if (f == "quarterly") return amount / 3.0;
//     if (f == "perpaycheque" || f == "per_paycheque") return amount * 2.0; // assuming 2 paycheques/mo
//     return amount; // fallback
//   }
//
//   double _estimateBillsDueUntilPayday(List<ExpenseItem> items) {
//     // placeholder (you should use next payday & dueDay logic)
//     double sum = 0;
//     for (final e in items) {
//       if (e.isActive != true) continue;
//       final cat = e.category.toLowerCase();
//       if (cat.contains("bill") || cat.contains("subscription") || cat.contains("fixed")) {
//         sum += _toMonthly(e.amount, e.frequency);
//       }
//     }
//     return sum;
//   }
// }
//
//
