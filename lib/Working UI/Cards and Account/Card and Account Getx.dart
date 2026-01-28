import 'dart:convert';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Pipeline.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/Payment Method Model.dart';
import '../../models/TextForm.dart';
import '../Constants.dart';
import '../Shared Preferences.dart';

class CardsAndAccount extends GetxController {
  // =========================
  // FORM STATE
  // =========================

  RxList<TextForm> creditCard = <TextForm>[
    TextForm(title: "Card Number", controller: TextEditingController(text: "")),
    TextForm(title: "Expiry Date", controller: TextEditingController(text: "")),
    TextForm(title: "Card Holder Name", controller: TextEditingController(text: "")),
    TextForm(title: "Cvv Code", controller: TextEditingController(text: "")),
    TextForm(title: "Bank Name", controller: TextEditingController(text: "")),
    TextForm(title: "Credit Limit", controller: TextEditingController(text: "")),
    TextForm(title: "Credit Limit Available", controller: TextEditingController(text: "")),
    TextForm(title: "Statement Date", controller: TextEditingController(text: "")),
    TextForm(title: "Card Type", controller: TextEditingController(text: "")),
    TextForm(title: "Payment Due Date", controller: TextEditingController(text: "")),
  ].obs;

  RxList<TextForm> bankAccount = <TextForm>[
    TextForm(title: "Bank Name", controller: TextEditingController(text: "")),
    TextForm(title: "Nick Name", controller: TextEditingController(text: "")),
    TextForm(title: "Account Type", controller: TextEditingController(text: "")),
    TextForm(title: "Balance", controller: TextEditingController(text: "")),
  ].obs;

  // =========================
  // UI STATE
  // =========================

  final List<String> accounts = const ["Checking", "Savings"];
  final List<String> cardType = const ["Visa", "Master Card"];
  RxList<String>? accountTypes = <String>['Card', 'Bank'].obs;
  RxString? activeAccountTypes = 'Card'.obs;
  RxBool? setDefaultPayment = false.obs;

  Rx<ButtonState> state = Rx<ButtonState>(ButtonState.loading);

  // =========================
  // DATA STATE
  // =========================

  Rx<PaymentMethodsResponse> paymentModel = const PaymentMethodsResponse(status: "200", message: "ok", creditCards: [], bankAccounts: []).obs;
  RxList<CreditCardModel> cards = <CreditCardModel>[].obs;
  Rxn<CreditCardModel> selectedCard = Rxn<CreditCardModel>();
  RxList<BankAccountModel> banks = <BankAccountModel>[].obs;
  Rxn<BankAccountModel> selectedBank = Rxn<BankAccountModel>();
  static const String _kSavedPaymentMethods = 'savedPaymentMethods';

  // =========================
  // LIFECYCLE
  // =========================

  @override
  void onInit() {
    super.onInit();
    loadPaymentMethods();
  }

  // =========================
  // LOAD / SAVE (Public)
  // =========================

  Future<void> loadPaymentMethods() async {
    state.value = ButtonState.loading;
    _resetForms();
    setDefaultPayment?.value = false;
    final model = await loadPaymentModel();
    paymentModel.value = model;
    cards.assignAll(model.creditCards);
    banks.assignAll(model.bankAccounts);
    paymentModel.refresh();
    cards.refresh();
    banks.refresh();
    // Pipeline().cardStatusInDebt();
    state.value = ButtonState.init;
  }

  Future<PaymentMethodsResponse> loadPaymentModel() async {
    final saved = await getLocalData(_kSavedPaymentMethods) ?? '';
    if (saved.trim().isEmpty) {
      return const PaymentMethodsResponse(
        status: "200",
        message: "ok",
        creditCards: [],
        bankAccounts: [],
      );
    }
    return PaymentMethodsResponse.fromJson(jsonDecode(saved));
  }

  // =========================
  // CRUD: CARDS
  // =========================

  Future<PaymentMethodsResponse> addCardFromUI() async {
    final data = await loadPaymentModel();

    // all 8 required in your UI
    if (creditCard.any((f) => f.controller.text.trim().isEmpty)) {
      showSnackBar("Missing Info", "Please complete all required fields.");
      return data;
    }

    final rawCard = creditCard[0].controller.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (rawCard.length != 16) {
      showSnackBar("Invalid Card Number", "Enter a valid 16-digit card number.");
      return data;
    }

    final cvv = creditCard[3].controller.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cvv.length != 3) {
      showSnackBar("Invalid CVV", "Enter a valid 3-digit CVV.");
      return data;
    }

    final id = "cc_${DateTime.now().millisecondsSinceEpoch}";
    final now = DateTime.now().millisecondsSinceEpoch;

    final limit = _saneMoney(toDouble(creditCard[5].controller.text) ?? 0.0);
    final used = _saneMoney(toDouble(creditCard[6].controller.text) ?? 0.0);
    final saneUsed = _clampUsedToLimit(used: used, limit: limit);

    final item = CreditCardModel(
      id: id,
      bankName: creditCard[4].controller.text.trim(),
      cardNumber: _safeMasked(creditCard[0].controller.text),
      expiryDate: creditCard[1].pickedDate,
      cardHolderName: creditCard[2].controller.text.trim().isEmpty ? null : creditCard[2].controller.text.trim(),
      cvvCode: creditCard[3].controller.text, // don't store in production
      cardType: creditCard[8].controller.text,
      creditLimit: limit,
      creditLimitUsed: saneUsed,
      statementDate: creditCard[7].pickedDate,
      paymentDueDate: creditCard[9].pickedDate,
      isDefault: false,
      createdAtMs: now,
    );
    print(item.statementDate);

    final list = data.creditCards.toList()..add(item);
    final updatedCards = (setDefaultPayment?.value ?? false) ? _setDefaultCard(list, id) : list;

    final updated = data.copyWith(creditCards: updatedCards, message: "card added");

    await saveAndApply(updated);

    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () => showSnackBar("Success", "Card added."));
    return updated;
  }

  Future<PaymentMethodsResponse> editCardFromUI() async {
    final data = await loadPaymentModel();
    final list = data.creditCards.toList();

    final idx = list.indexWhere((x) => x.id == selectedCard.value!.id);
    if (idx < 0) return data;

    final newLimit = _saneMoney(toDouble(creditCard[5].controller.text)!);
    final newAvailableRaw = _saneMoney(toDouble(creditCard[6].controller.text)!);
    final newAvailable = _clampUsedToLimit(used: newAvailableRaw, limit: newLimit);

    final updatedItem = selectedCard.value!.copyWith(
      bankName: creditCard[4].controller.text.isEmpty ? selectedCard.value!.bankName : creditCard[4].controller.text.trim(),
      cardNumber: creditCard[0].controller.text.isEmpty ? selectedCard.value!.cardNumber : _safeMasked(creditCard[0].controller.text),
      expiryDate: creditCard[1].pickedDate == null ? selectedCard.value!.expiryDate : creditCard[1].pickedDate!,
      cardHolderName: creditCard[2].controller.text.trim().isEmpty ? selectedCard.value!.cardHolderName : creditCard[2].controller.text.trim(),
      creditLimit: newLimit,
      creditLimitUsed: newAvailable,
      isDefault: selectedCard.value!.isDefault,
    );

    list[idx] = updatedItem;
    // final updatedCards = updatedItem.isDefault ? _setDefaultCard(list, updatedItem.id) : list;

    final updated = data.copyWith(creditCards: list, message: "card updated");
    await saveAndApply(updated);

    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () => showSnackBar("Success", "Card updated."));
    return updated;
  }

  Future<PaymentMethodsResponse> deleteCard({required String id}) async {
    final data = await loadPaymentModel();
    final list = data.creditCards.toList()..removeWhere((x) => x.id == id);

    final updated = data.copyWith(creditCards: list, message: "card removed");
    await saveAndApply(updated);
    showSnackBar("Success", "Card removed.");
    return updated;
  }

  Future<PaymentMethodsResponse> setDefaultCard({required String id}) async {
    final data = await loadPaymentModel();
    final list = _setDefaultCard(data.creditCards.toList(), id);

    final updated = data.copyWith(creditCards: list, message: "default card set");
    await saveAndApply(updated);

    showSnackBar("Updated", "Default card set.");
    return updated;
  }

  // =========================
  // CRUD: BANKS
  // =========================

  Future<PaymentMethodsResponse> addBankFromUI() async {
    final data = await loadPaymentModel();

    if (bankAccount.sublist(0, 3).any((f) => f.controller.text.trim().isEmpty)) {
      showSnackBar("Missing Info", "Please complete all required fields.");
      return data;
    }

    final id = "ba_${DateTime.now().millisecondsSinceEpoch}";
    final now = DateTime.now().millisecondsSinceEpoch;

    final item = BankAccountModel(
      id: id,
      bankName: bankAccount[0].controller.text.trim(),
      nickName: bankAccount[1].controller.text.trim(),
      accountType: bankAccount[2].controller.text.trim(),
      balance: _saneMoney(toDouble(bankAccount[3].controller.text) ?? 0.0),
      isDefault: setDefaultPayment?.value ?? false,
      createdAtMs: now,
    );

    final list = data.bankAccounts.toList()..add(item);
    final updatedBanks = (setDefaultPayment?.value ?? false) ? _setDefaultBank(list, id) : list;

    final updated = data.copyWith(bankAccounts: updatedBanks, message: "bank added");
    await saveAndApply(updated);

    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () => showSnackBar("Success", "Bank account added."));
    return updated;
  }

  Future<PaymentMethodsResponse> editBankFromUI({required BankAccountModel current, bool? isDefault}) async {
    final data = await loadPaymentModel();
    final list = data.bankAccounts.toList();

    final idx = list.indexWhere((x) => x.id == current.id);
    if (idx < 0) return data;

    final updatedItem = current.copyWith(isDefault: isDefault ?? current.isDefault);
    list[idx] = updatedItem;

    final updatedBanks =
        list.map((b) => b.id == updatedItem.id ? b.copyWith(isDefault: updatedItem.isDefault) : b.copyWith(isDefault: false)).toList();

    final updated = data.copyWith(bankAccounts: updatedBanks, message: "bank updated");
    await saveAndApply(updated);

    showSnackBar("Success", "Bank updated.");
    return updated;
  }

  Future<PaymentMethodsResponse> deleteBank({required String id}) async {
    final data = await loadPaymentModel();
    final list = data.bankAccounts.toList()..removeWhere((x) => x.id == id);

    final updated = data.copyWith(bankAccounts: list, message: "bank removed");
    await saveAndApply(updated);

    showSnackBar("Success", "Bank removed.");
    return updated;
  }

  Future<PaymentMethodsResponse> setDefaultBank({required String id}) async {
    final data = await loadPaymentModel();
    final list = _setDefaultBank(data.bankAccounts.toList(), id);

    final updated = data.copyWith(bankAccounts: list, message: "default bank set");
    await saveAndApply(updated);

    showSnackBar("Updated", "Default bank set.");
    return updated;
  }

  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // CREDIT CARD ACTIONS
  // (KEEP NAMES, BUT ROUTE THROUGH ONE CORE)
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================
  // ====================================================================================

  double availableCredit(CreditCardModel c) {
    final limit = _saneMoney(c.creditLimit ?? 0);
    final used = _saneMoney(c.creditLimitUsed ?? 0);
    return (limit - used).clamp(0.0, 1e12).toDouble();
  }

  /// Spending on card -> increases used
  Future<double> applyCreditCharge({required String cardId, required double amount}) async {
    final updated = await applyDeltaToCardUsed(
      cardId: cardId,
      deltaUsed: amount,
      blockIfOverLimit: true,
    );
    if (updated == null) return 0.0;
    // return actual applied amount (in case you later decide to clamp)
    return amount;
  }

  /// Paying card -> decreases used
  Future<double> applyCreditPayment({required String cardId, required double amount}) async {
    final updated = await applyDeltaToCardUsed(cardId: cardId, deltaUsed: -amount, blockIfOverLimit: false);
    if (updated == null) return 0.0;
    return amount;
  }

  CreditCardModel? getCardById(String id) => cards.firstWhereOrNull((c) => c.id == id);

  Future<void> replaceAndSaveCard(CreditCardModel updated) async {
    // keep name, but just reuse the save pipeline
    final data = await loadPaymentModel();
    final list = data.creditCards.toList();
    final idx = list.indexWhere((x) => x.id == updated.id);
    if (idx < 0) return;

    // keep used sane vs limit
    final limit = _saneMoney(updated.creditLimit ?? 0.0);
    final used = _clampUsedToLimit(used: _saneMoney(updated.creditLimitUsed ?? 0.0), limit: limit);

    list[idx] = updated.copyWith(creditLimit: limit, creditLimitUsed: used);

    final updatedModel = data.copyWith(creditCards: list, message: "card updated");
    await saveAndApply(updatedModel);
  }

  /// +deltaUsed => spend, -deltaUsed => payment/refund
  /// This is the ONLY function that mutates used + persists.
  Future<CreditCardModel?> applyDeltaToCardUsed({required String cardId, required double deltaUsed, bool blockIfOverLimit = true}) async {
    if (deltaUsed.isNaN || deltaUsed == 0) return getCardById(cardId);

    final data = await loadPaymentModel();
    final list = data.creditCards.toList();
    final idx = list.indexWhere((c) => c.id == cardId);
    if (idx < 0) return null;

    final cur = list[idx];

    final limit = _saneMoney(cur.creditLimit ?? 0.0);
    final used0 = _saneMoney(cur.creditLimitUsed ?? 0.0);

    double used1 = used0 + deltaUsed;

    if (blockIfOverLimit && limit > 0 && used1 > limit) {
      showSnackBar("Card limit reached", "This charge would exceed your credit limit.");
      return null;
    }

    used1 = used1.clamp(0.0, limit > 0 ? limit : 1e12).toDouble();

    final updatedCard = cur.copyWith(creditLimitUsed: used1);
    list[idx] = updatedCard;

    final updatedModel = data.copyWith(creditCards: list, message: "card usage updated");
    await saveAndApply(updatedModel);
    return updatedCard;
  }

  // =========================
  // PRIVATE: SAVE + APPLY
  // =========================

  Future<void> saveAndApply(PaymentMethodsResponse m) async {
    await saveLocalData(_kSavedPaymentMethods, jsonEncode(m.toJson()));
    loadPaymentMethods();
  }

  // =========================
  // HELPERS
  // =========================

  void _resetForms() {
    for (final f in creditCard) {
      f.controller.text = '';
    }
    for (final f in bankAccount) {
      f.controller.text = '';
    }
  }

  List<CreditCardModel> _setDefaultCard(List<CreditCardModel> list, String id) {
    return list.map((x) => x.copyWith(isDefault: x.id == id)).toList();
  }

  List<BankAccountModel> _setDefaultBank(List<BankAccountModel> list, String id) {
    return list.map((x) => x.copyWith(isDefault: x.id == id)).toList();
  }

  double _saneMoney(double v) => v.clamp(0.0, 1e12).toDouble();

  double _clampUsedToLimit({required double used, required double limit}) {
    if (limit <= 0) return _saneMoney(used);
    return used.clamp(0.0, limit).toDouble();
  }

  String _safeMasked(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return input.trim();

    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits.padLeft(4, '0');
    return "0000 **** **** $last4";
  }
}
