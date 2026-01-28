import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/Bnpl model.dart';
import '../../../models/Debt Model.dart';
import '../../../models/Expense Model V2.dart';
import '../../../models/TextForm.dart';
import '../../Shared Preferences.dart';
import '../../Constants.dart';

class DebtsController extends GetxController {
  // ---------------- UI FORM ----------------
  final RxList<TextForm> controllers = <TextForm>[
    TextForm(title: "Name", controller: TextEditingController()),
    TextForm(title: "Balance", controller: TextEditingController()),
    TextForm(title: "APR (%)", controller: TextEditingController()),
    TextForm(title: "Minimum Payment", controller: TextEditingController()),
    TextForm(title: "Last Charged", controller: TextEditingController()),
    TextForm(title: "Notes (optional)", controller: TextEditingController()),
    TextForm(title: "Linked Account", controller: TextEditingController()),
  ].obs;

  final RxString selectedDebtType = 'Loan'.obs;
  final RxBool secured = false.obs;
  final RxBool fixedInstallment = false.obs;
  final List<String> debtType = const ['Loan', 'Bnpl'];
  final List<String> strategies = const ['SnowBall', 'Avalanche', 'Hybrid', 'Manuel'];
  final RxString payback = "Monthly".obs;
  final List<String> paybackOptions = const ["Monthly", "Bi-weekly", "Weekly"];
  final RxString loanType = "Auto Loan".obs;
  final List<String> loanTypes = const ["Auto Loan", "Personal Loan", "Student Loan", "Mortgage"];
  final Rx<PayoffStrategy> strategy = PayoffStrategy.snowball.obs;
  final RxDouble extraBudget = 0.0.obs;
  Rxn<BnplProvider> selectedBnpl = Rxn<BnplProvider>();
  Rxn<BnplPlan> selectedBnplPlan = Rxn<BnplPlan>();
  Rxn<AccountRef> selectedAccount = Rxn<AccountRef>();

  final Rx<ButtonState> state = ButtonState.loading.obs;
  List<BnplProvider> bnplProvidersCA = [
    BnplProvider(
      id: "klarna_ca",
      name: "Klarna",
      market: "CA",
      website: "https://www.klarna.com/ca/customer-service/how-can-i-pay/",
      plans: [
        BnplPlan(type: BnplPlanType.payIn4, installments: 4, cadence: "biweekly", canBeZeroApr: true),
        BnplPlan(type: BnplPlanType.payMonthly, installments: null, cadence: "monthly", canBeZeroApr: false),
      ],
      supportedRepaymentMethods: [
        RepaymentMethodType.debitCard,
        RepaymentMethodType.creditCard,
      ],
      rules: RepaymentRules(
        firstPaymentRequiresCard: true,
        creditCardAllowedForScheduledPayments: true,
        notes: "Accepts major debit/credit cards; prepaid and AMEX not accepted (per Klarna CA help).",
      ),
      isActiveInMarket: true,
    ),
    BnplProvider(
      id: "afterpay_ca",
      name: "Afterpay",
      market: "CA",
      website: "https://help.afterpay.com/hc/en-ca/articles/20249507136025-Which-cards-does-Afterpay-accept",
      plans: [
        BnplPlan(type: BnplPlanType.payIn4, installments: 4, cadence: "biweekly", canBeZeroApr: true),
      ],
      supportedRepaymentMethods: [
        RepaymentMethodType.debitCard,
        RepaymentMethodType.creditCard,
        RepaymentMethodType.applePay,
        RepaymentMethodType.googlePay,
      ],
      rules: RepaymentRules(
        firstPaymentRequiresCard: true,
        creditCardAllowedForScheduledPayments: true,
        notes: "Accepts Visa/Mastercard issued in your country; supports Apple Pay/Google Pay; no bank transfer.",
      ),
      isActiveInMarket: true,
    ),
    BnplProvider(
      id: "affirm_ca",
      name: "Affirm",
      market: "CA",
      website: "https://helpcenter.affirm.ca/s/article/add-a-payment-method-ca",
      plans: [
        BnplPlan(type: BnplPlanType.payIn4, installments: 4, cadence: "biweekly", canBeZeroApr: true),
        BnplPlan(type: BnplPlanType.payMonthly, installments: null, cadence: "monthly", canBeZeroApr: false),
      ],
      supportedRepaymentMethods: [
        RepaymentMethodType.debitCard,
        RepaymentMethodType.bankAccountPAD,
        RepaymentMethodType.creditCard, // limited cases
      ],
      rules: RepaymentRules(
        firstPaymentRequiresCard: false,
        creditCardAllowedForScheduledPayments: false,
        notes: "Payments can be debit card or pre-authorized debit; some purchases allow credit card for down payment only.",
      ),
      isActiveInMarket: true,
    ),
    BnplProvider(
      id: "paybright_affirm_ca",
      name: "PayBright (by Affirm)",
      market: "CA",
      website: "https://helpcenter.affirm.ca/ca/s/article/paybright-payments",
      plans: [
        BnplPlan(type: BnplPlanType.payIn4, installments: 4, cadence: "biweekly", canBeZeroApr: true),
        BnplPlan(type: BnplPlanType.payMonthly, installments: null, cadence: "monthly", canBeZeroApr: false),
      ],
      supportedRepaymentMethods: [
        RepaymentMethodType.debitCard,
        RepaymentMethodType.bankAccountPAD,
        RepaymentMethodType.creditCard, // some plans
      ],
      rules: RepaymentRules(
        firstPaymentRequiresCard: false,
        creditCardAllowedForScheduledPayments: false,
        notes: "Affirm/PayBright: debit + PAD widely supported; credit card availability varies by plan type (per PayBright help).",
      ),
      isActiveInMarket: true,
    ),
    BnplProvider(
      id: "sezzle_ca",
      name: "Sezzle",
      market: "CA",
      website: "https://shopper-help.sezzle.com/hc/en-ca/articles/360046901131-How-do-I-add-a-new-payment-method",
      plans: [
        BnplPlan(type: BnplPlanType.payIn4, installments: 4, cadence: "6 weeks", canBeZeroApr: true),
        BnplPlan(type: BnplPlanType.payMonthly, installments: null, cadence: "monthly", canBeZeroApr: false),
      ],
      supportedRepaymentMethods: [
        RepaymentMethodType.debitCard,
        RepaymentMethodType.creditCard,
        RepaymentMethodType.bankAccountPAD,
        RepaymentMethodType.prepaidCard, // Sezzle supports adding prepaid, with constraints
      ],
      rules: RepaymentRules(
        firstPaymentRequiresCard: true,
        creditCardAllowedForScheduledPayments: true,
        notes: "Bank accounts may be used for scheduled installments, but first installment requires a debit/credit card (per Sezzle help).",
      ),
      isActiveInMarket: true,
    ),
  ];

  // ---------------- DATA ----------------
  final Rx<DebtsResponse> debtsModel = const DebtsResponse(status: "200", message: "ok", version: 2, strategy: "snowball", debts: []).obs;

  final Rxn<DebtItem> selectedDebt = Rxn<DebtItem>();

  // ---------------- STORAGE ----------------
  static const String _kSavedDebts = "savedDebts";

  String selectedLabel() {
    switch (strategy.value) {
      case PayoffStrategy.snowball:
        return "SnowBall";
      case PayoffStrategy.avalanche:
        return "Avalanche";
      case PayoffStrategy.hybrid:
        return "Hybrid";
      case PayoffStrategy.manual:
        return "Manuel";
    }
  }

  String planLabel(BnplPlan? plan) {
    // Keep it short + user-facing
    final cadence = (plan!.cadence ?? "").trim();
    switch (plan.type) {
      case BnplPlanType.payIn4:
        return "Pay in 4 (${cadence.isEmpty ? "biweekly" : cadence})";
      case BnplPlanType.payMonthly:
        return "Pay Monthly";
      default:
        return "Plan";
    }
  }

  Future<void> setStrategyFromLabel(String label) async {
    final l = label.trim().toLowerCase();

    final s = l.contains("avalan")
        ? PayoffStrategy.avalanche
        : l.contains("hybr")
            ? PayoffStrategy.hybrid
            : l.contains("man")
                ? PayoffStrategy.manual
                : PayoffStrategy.snowball;

    strategy.value = s;
    await debtsIO(model: debtsModel.value.copyWith(strategy: s.name, message: "strategy updated"));
  }

  String strategyDescription(PayoffStrategy s) {
    switch (s) {
      case PayoffStrategy.snowball:
        return 'Pay smallest balance first for fastest motivation.';
      case PayoffStrategy.avalanche:
        return 'Pay highest APR first to minimize total interest.';
      case PayoffStrategy.hybrid:
        return 'Balance motivation + interest savings using a blended approach.';
      case PayoffStrategy.manual:
        return 'You choose where extra payments go each pay period.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadDebts();
  }

  // ---------------- QUICK GETTERS ----------------
  List<DebtItem> get activeDebts => debtsModel.value.debts.where((d) => d.isActive && d.balance > 0).toList();
  double get totalDebt => activeDebts.fold(0.0, (s, d) => s + d.balance);
  double get totalInitial => activeDebts.fold(0.0, (s, d) => s + (d.initialBalance <= 0 ? d.balance : d.initialBalance));
  double get paidPct {
    final init = totalInitial;
    if (init <= 0) return 0.0;
    return (1.0 - (totalDebt / init)).clamp(0.0, 1.0).toDouble();
  }

  // ---------------- LOAD / SAVE ----------------
  Future<void> loadDebts() async {
    state.value = ButtonState.loading;
    final m = await debtsIO();
    debtsModel.value = m;
    debtsModel.refresh();
    state.value = ButtonState.init;
  }

  Future<DebtsResponse> debtsIO({DebtsResponse? model}) async {
    // SAVE
    if (model != null) {
      await saveLocalData(_kSavedDebts, model.encode());
      return model;
    }
    // LOAD
    final raw = (await getLocalData(_kSavedDebts) ?? "").trim();
    if (raw.isEmpty) {
      return const DebtsResponse(status: "200", message: "ok", version: 2, strategy: "snowball", debts: []);
    }
    return DebtsResponse.decode(raw);
  }

  // ---------------- NAV / SELECT ----------------

  // ---------------- FORM ----------------
  void resetForm() {
    for (final f in controllers) {
      f.controller.clear();
    }
    secured.value = false;
    fixedInstallment.value = false;
    selectedDebtType.value = 'Loan';
    controllers.refresh();
  }

  // ---------------- CRUD: DEBTS ----------------
  Future<void> addDebtFromUI() async {
    final name = controllers[0].controller.text.trim();
    final bal = toDouble(controllers[1].controller.text);
    final apr = toDouble(controllers[2].controller.text) ?? 0.0;
    final minPay = toDouble(controllers[3].controller.text) ?? 0.0;
    final dueDay = int.tryParse(controllers[4].controller.text.trim()) ?? 15;
    final notes = controllers[5].controller.text.trim();

    if (name.isEmpty) return showSnackBar("Missing Info", "Enter debt name.");
    if (bal == null || bal <= 0) return showSnackBar("Invalid Balance", "Enter a valid balance.");
    if (dueDay < 1 || dueDay > 31) return showSnackBar("Invalid Due Day", "Use 1–31.");

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final item = DebtItem(
      id: "db_$nowMs",
      type: selectedDebtType.value,
      name: name,
      balance: bal,
      initialBalance: bal,
      apr: apr < 0 ? 0.0 : apr,
      minPayment: minPay < 0 ? 0.0 : minPay,
      // dueDayOfMonth: dueDay,
      secured: secured.value,
      fixedInstallment: fixedInstallment.value,
      notes: notes,
      isActive: true,
      createdAtMs: nowMs,
      linkedCreditCardId: selectedAccount.value!.id,
      paymentsMade: const [],
      // paymentScheduleOverride: const [],
    );

    await debtsIO(
        model: debtsModel.value.copyWith(
      message: "debt added",
      debts: [...debtsModel.value.debts, item],
    ));

    resetForm();
    Get.back();
    showSnackBar("Success", "Debt added.");
  }

  Future<void> initializeEditingParameters(DebtItem d) async {
    selectedDebt.value = d;
    selectedDebtType.value = d.type;
    secured.value = d.secured;
    fixedInstallment.value = d.fixedInstallment;

    controllers[0].controller.text = d.name;
    controllers[1].controller.text = d.balance.toStringAsFixed(0);
    controllers[2].controller.text = d.apr.toStringAsFixed(d.apr == 0 ? 0 : 1);
    controllers[3].controller.text = d.minPayment.toStringAsFixed(0);
    // controllers[4].controller.text = (d.dueDayOfMonth ?? 15).toString();
    controllers[5].controller.text = d.notes;

    controllers.refresh();
  }

  Future<void> editDebtFromUI() async {
    final cur = selectedDebt.value;
    if (cur == null) return;

    final name = controllers[0].controller.text.trim();
    final bal = toDouble(controllers[1].controller.text);
    final apr = toDouble(controllers[2].controller.text) ?? 0.0;
    final minPay = toDouble(controllers[3].controller.text) ?? 0.0;
    // final dueDay = int.tryParse(controllers[4].controller.text.trim()) ?? (cur.dueDayOfMonth ?? 15);
    final notes = controllers[5].controller.text.trim();

    if (name.isEmpty) return showSnackBar("Missing Info", "Enter debt name.");
    if (bal == null || bal < 0) return showSnackBar("Invalid Balance", "Enter a valid balance.");
    // if (dueDay < 1 || dueDay > 31) return showSnackBar("Invalid Due Day", "Use 1–31.");

    final list = debtsModel.value.debts.toList();
    final idx = list.indexWhere((x) => x.id == cur.id);
    if (idx < 0) return;

    final fixedInitial = (cur.initialBalance <= 0 ? bal : cur.initialBalance);
    final saneInitial = fixedInitial < bal ? bal : fixedInitial;

    list[idx] = cur.copyWith(
      type: selectedDebtType.value,
      name: name,
      balance: bal,
      initialBalance: saneInitial,
      apr: apr < 0 ? 0.0 : apr,
      minPayment: minPay < 0 ? 0.0 : minPay,
      // dueDayOfMonth: dueDay,
      secured: secured.value,
      fixedInstallment: fixedInstallment.value,
      notes: notes,
    );

    await debtsIO(model: debtsModel.value.copyWith(message: "debt updated", debts: list));
    selectedDebt.value = list[idx];
    resetForm();
    Get.back();
    showSnackBar("Success", "Debt updated.");
  }

  Future<void> deleteDebt(String id) async {
    final list = debtsModel.value.debts.toList()..removeWhere((d) => d.id == id);
    await debtsIO(model: debtsModel.value.copyWith(message: "debt deleted", debts: list));
    if (selectedDebt.value?.id == id) selectedDebt.value = null;
    loadDebts();
    showSnackBar("Success", "Debt removed.");
  }

  // ---------------- PAYMENTS (INSIDE DEBT ITEM NOW) ----------------

  Future<void> recordPayment({amount, note, date}) async {
    if (amount.isNaN || amount <= 0) return showSnackBar("Invalid", "Enter a valid payment amount.");
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final newPayment = DebtPayment(
      id: "dp_$nowMs",
      debtId: selectedDebt.value!.id,
      amount: amount.clamp(0.0, 1e12).toDouble(),
      date: date,
      note: note,
      createdAtMs: nowMs,
    );

    final paidList = [...selectedDebt.value!.paymentsMade!, newPayment];
    final totalPaid = paidList.fold(0.0, (s, x) => s + x.amount);
    final start = selectedDebt.value!.initialBalance;
    final newBal = (start - totalPaid);

    selectedDebt.value = selectedDebt.value!.copyWith(balance: newBal, paymentsMade: paidList);
    final list = debtsModel.value.debts.toList();
    final idx = list.indexWhere((x) => x.id == selectedDebt.value!.id);
    list[idx] = selectedDebt.value!;
    print(selectedDebt.value);
    await debtsIO(model: debtsModel.value.copyWith(message: "payment saved", debts: list));
    Get.back();
    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar("Success", "Payment saved.");
    });
  }

  Future<void> deletePayment(String paymentId) async {
    final list = debtsModel.value.debts.toList();
    final idx = list.indexWhere((x) => x.id == selectedDebt.value!.id);
    final newPaidList = selectedDebt.value!.paymentsMade!.toList()..removeWhere((x) => x.id == paymentId);
    final totalPaid = newPaidList.fold(0.0, (x, y) => x + y.amount);
    final start = selectedDebt.value!.initialBalance;
    final newBal = (start - totalPaid);
    selectedDebt.value = selectedDebt.value!.copyWith(balance: newBal, paymentsMade: newPaidList);
    list[idx] = selectedDebt.value!;
    await debtsIO(model: debtsModel.value.copyWith(message: "payment deleted", debts: list));
    Future.delayed(const Duration(milliseconds: 500), () {
      showSnackBar('Success', 'Payment removed from activities');
    });
  }

  // ---------------- SCHEDULE (unchanged logic, just reads overrides from model) ----------------
  double monthlyRate(double aprPct) => aprPct <= 0 ? 0.0 : (aprPct / 100.0) / 12.0;

  int _daysInMonth(int y, int m) {
    final firstNext = (m == 12) ? DateTime(y + 1, 1, 1) : DateTime(y, m + 1, 1);
    return firstNext.subtract(const Duration(days: 1)).day;
  }

  // =======================
// Schedule helpers
// =======================
  String ymKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}";

  DateTime dateWithDayClamped(int y, int m, int day) {
    final dim = _daysInMonth(y, m);
    final safeDay = day.clamp(1, dim);
    return DateTime(y, m, safeDay);
  }

  List<DebtPayment> get payments {
    final list = (selectedDebt.value?.paymentsMade ?? const <DebtPayment>[]);
    final sorted = list.toList()..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }
}
