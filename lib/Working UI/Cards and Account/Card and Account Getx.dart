import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/Payment Method Model.dart';
import '../../models/TextForm.dart';
import '../Constants.dart';
import '../Shared Preferences.dart';

class CardsAndAccount extends GetxController {
  RxList<TextForm> creditCard = [
    TextForm(title: "Card Number", controller: TextEditingController(text: "")),
    TextForm(title: "Expiry Date", controller: TextEditingController(text: "")),
    TextForm(title: "Card Holder Name", controller: TextEditingController(text: "")),
    TextForm(title: "Cvv Code", controller: TextEditingController(text: "")),
    TextForm(title: "Bank Name", controller: TextEditingController(text: "")),
    TextForm(title: "Credit Limit", controller: TextEditingController(text: "")),
    TextForm(title: "Credit Limit Used", controller: TextEditingController(text: "")),
    TextForm(title: "Last Bill Date", controller: TextEditingController(text: "")),
  ].obs;
  RxList<TextForm> bankAccount = [
    TextForm(title: "Bank Name", controller: TextEditingController(text: "")),
    TextForm(title: "Nick Name", controller: TextEditingController(text: "")),
    TextForm(title: "Account Type", controller: TextEditingController(text: "")),
    TextForm(title: "Balance", controller: TextEditingController(text: "")),
  ].obs;

  final List<String> accounts = const [
    "Checking",
    "Savings",
    "Cash",
  ];
  RxList<String>? accountTypes = ['Card', 'Bank'].obs;
  RxString? activeAccountTypes = 'Card'.obs;
  RxBool? setDefaultPayment = false.obs;
  Rx<PaymentMethodsResponse> paymentModel = const PaymentMethodsResponse(status: "200", message: "ok", creditCards: [], bankAccounts: []).obs;
  RxList<CreditCardModel> cards = <CreditCardModel>[].obs;
  final Rxn<CreditCardModel> selectedCard = Rxn<CreditCardModel>();
  RxList<BankAccountModel> banks = <BankAccountModel>[].obs;
  final Rxn<BankAccountModel> selectedBank = Rxn<BankAccountModel>();
  Rx<ButtonState> state = Rx<ButtonState>(ButtonState.loading);

  // ========= CRUD PUBLIC APIS =========

  Future<void> loadPaymentMethods() async {
    cards.clear();
    banks.clear();
    setDefaultPayment!.value = false;
    for (var files in creditCard) {
      files.controller.text = '';
    }
    for (var files in bankAccount) {
      files.controller.text = '';
    }
    final data = await _loadPaymentModel();
    paymentModel.value = data;
    state.value = ButtonState.init;
    state.refresh();
    cards.assignAll(data.creditCards);
    banks.assignAll(data.bankAccounts);

    cards.refresh();
    banks.refresh();
    setDefaultPayment!.refresh();
  }

  // ---------- ADD CARD ----------
  Future<PaymentMethodsResponse> addCardFromUI() async {
    final data = await _loadPaymentModel();

    if (creditCard.sublist(0, 8).any((test) => test.controller.text.isEmpty)) {
      showSnackBar("Missing Info", "Please complete all required fields.");
      return data;
    } else if (creditCard[0].controller.text.length != 16) {
      showSnackBar("Invalid Card Number", "Enter a valid 16-digit card number.");
      return data;
    } else if (creditCard[3].controller.text.length != 3) {
      showSnackBar("Invalid CVV", "Enter a valid 3-digit CVV.");
      return data;
    }

    final id = "cc_${DateTime.now().millisecondsSinceEpoch}";
    final now = DateTime.now().millisecondsSinceEpoch;

    final item = CreditCardModel(
      id: id,
      bankName: creditCard[4].controller.text.trim(),
      cardNumber: _safeMasked(creditCard[0].controller.text), // store masked, not full
      expiryDate: creditCard[1].pickedDate,
      cardHolderName: creditCard[2].controller.text.isEmpty == true ? null : creditCard[2].controller.text,
      cvvCode: creditCard[3].controller.text, // never store
      creditLimit: toDouble(creditCard[5].controller.text),
      creditLimitUsed: toDouble(creditCard[6].controller.text),
      lastBillDate: creditCard[7].pickedDate,
      isDefault: setDefaultPayment!.value,
      createdAtMs: now,
    );

    final list = data.creditCards.toList();
    list.add(item);

    // one default per list
    final updatedCards = setDefaultPayment!.value ? _setDefaultCard(list, id) : list;

    final updated = data.copyWith(
      creditCards: updatedCards,
      message: "card added",
    );

    paymentModel.value = updated;
    cards.assignAll(updated.creditCards);

    await _savePaymentModel(updated);

    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () {
      showSnackBar("Success", "Card added.");
    });

    return updated;
  }

  // ---------- EDIT CARD ----------
  Future<PaymentMethodsResponse> editCardFromUI({
    required CreditCardModel current,
    required String bankName,
    required String cardNumber,
    required DateTime expiryDate,
    String? cardHolderName,
    String? creditLimit,
    String? creditLimitUsed,
    bool? isDefault,
  }) async {
    final data = await _loadPaymentModel();
    final list = data.creditCards.toList();

    final idx = list.indexWhere((x) => x.id == current.id);
    if (idx < 0) return data;

    final updatedItem = current.copyWith(
      bankName: bankName.trim().isEmpty ? current.bankName : bankName.trim(),
      cardNumber: cardNumber.trim().isEmpty ? current.cardNumber : _safeMasked(cardNumber),
      expiryDate: expiryDate,
      cardHolderName: cardHolderName?.trim().isEmpty == true ? null : cardHolderName?.trim(),
      creditLimit: toDouble(creditLimit) ?? current.creditLimit,
      creditLimitUsed: toDouble(creditLimitUsed) ?? current.creditLimitUsed,
      isDefault: isDefault ?? current.isDefault,
    );

    list[idx] = updatedItem;

    final updatedCards = (updatedItem.isDefault) ? _setDefaultCard(list, updatedItem.id) : list;

    final updated = data.copyWith(
      creditCards: updatedCards,
      message: "card updated",
    );

    paymentModel.value = updated;
    cards.assignAll(updated.creditCards);

    await _savePaymentModel(updated);

    showSnackBar("Success", "Card updated.");
    return updated;
  }

  // ---------- DELETE CARD ----------
  Future<PaymentMethodsResponse> deleteCard({required String id}) async {
    final data = await _loadPaymentModel();
    final list = data.creditCards.toList();

    list.removeWhere((x) => x.id == id);

    final updated = data.copyWith(
      creditCards: list,
      message: "card removed",
    );

    paymentModel.value = updated;
    cards.assignAll(updated.creditCards);

    await _savePaymentModel(updated);

    showSnackBar("Success", "Card removed.");
    return updated;
  }

  // ---------- SET DEFAULT CARD ----------
  Future<PaymentMethodsResponse> setDefaultCard({required String id}) async {
    final data = await _loadPaymentModel();
    final list = _setDefaultCard(data.creditCards.toList(), id);

    final updated = data.copyWith(
      creditCards: list,
      message: "default card set",
    );

    paymentModel.value = updated;
    cards.assignAll(updated.creditCards);

    await _savePaymentModel(updated);

    showSnackBar("Updated", "Default card set.");
    return updated;
  }

  // ---------- ADD BANK ----------
  Future<PaymentMethodsResponse> addBankFromUI() async {
    final data = await _loadPaymentModel();

    if (bankAccount.sublist(0, 3).any((test) => test.controller.text.isEmpty)) {
      showSnackBar("Missing Info", "Please complete all required fields.");
      return data;
    }

    final id = "ba_${DateTime.now().millisecondsSinceEpoch}";
    final now = DateTime.now().millisecondsSinceEpoch;

    final item = BankAccountModel(
      id: id,
      bankName: bankAccount[0].controller.text,
      nickName: bankAccount[1].controller.text,
      accountType: bankAccount[2].controller.text,
      balance: toDouble(bankAccount[3].controller.text),
      isDefault: setDefaultPayment!.value,
      createdAtMs: now,
    );

    final list = data.bankAccounts.toList();
    list.add(item);

    final updatedBanks = setDefaultPayment!.value ? _setDefaultBank(list, id) : list;

    final updated = data.copyWith(
      bankAccounts: updatedBanks,
      message: "bank added",
    );

    paymentModel.value = updated;
    banks.assignAll(updated.bankAccounts);

    await _savePaymentModel(updated);

    Get.back();
    Future.delayed(const Duration(milliseconds: 200), () {
      showSnackBar("Success", "Bank account added.");
    });

    return updated;
  }

  // ---------- EDIT BANK ----------
  // ---------- EDIT BANK ----------
  Future<PaymentMethodsResponse> editBankFromUI({required BankAccountModel current, bool? isDefault}) async {
    final data = await _loadPaymentModel();
    final list = data.bankAccounts.toList();

    final idx = list.indexWhere((x) => x.id == current.id);
    if (idx < 0) return data;

    // update only the selected one (keep your fields same)
    final updatedItem = current.copyWith(
      bankName: current.bankName,
      nickName: current.nickName,
      accountType: current.accountType,
      balance: current.balance,
      isDefault: isDefault ?? current.isDefault,
    );

    list[idx] = updatedItem;

    // ✅ force everyone else default=false
    final updatedBanks = list.map((b) {
      if (b.id == updatedItem.id) {
        // keep whatever you decided for the updated one
        return b.copyWith(isDefault: updatedItem.isDefault);
      }
      // everyone else becomes false
      return b.copyWith(isDefault: false);
    }).toList();

    final updated = data.copyWith(
      bankAccounts: updatedBanks,
      message: "bank updated",
    );

    state.value = ButtonState.loading;
    state.refresh();

    paymentModel.value = updated;
    banks.assignAll(updated.bankAccounts);

    await _savePaymentModel(updated);

    showSnackBar("Success", "Bank updated.");
    return updated;
  }

  // ---------- DELETE BANK ----------
  Future<PaymentMethodsResponse> deleteBank({required String id}) async {
    final data = await _loadPaymentModel();
    final list = data.bankAccounts.toList();

    list.removeWhere((x) => x.id == id);

    final updated = data.copyWith(
      bankAccounts: list,
      message: "bank removed",
    );
    banks.assignAll(updated.bankAccounts);
    state.value = ButtonState.loading;
    paymentModel.value = updated;
    banks.assignAll(updated.bankAccounts);

    await _savePaymentModel(updated);

    showSnackBar("Success", "Bank removed.");
    return updated;
  }

  // ---------- SET DEFAULT BANK ----------
  Future<PaymentMethodsResponse> setDefaultBank({required String id}) async {
    final data = await _loadPaymentModel();
    final list = _setDefaultBank(data.bankAccounts.toList(), id);

    final updated = data.copyWith(
      bankAccounts: list,
      message: "default bank set",
    );

    paymentModel.value = updated;
    banks.assignAll(updated.bankAccounts);

    await _savePaymentModel(updated);

    showSnackBar("Updated", "Default bank set.");
    return updated;
  }

  // ========= LOAD / SAVE =========

  Future<PaymentMethodsResponse> _loadPaymentModel() async {
    final saved = await getLocalData('savedPaymentMethods') ?? '';
    if (saved.isEmpty) {
      return const PaymentMethodsResponse(
        status: "200",
        message: "ok",
        creditCards: [],
        bankAccounts: [],
      );
    }
    return PaymentMethodsResponse.fromJson(jsonDecode(saved));
  }

  Future<void> _savePaymentModel(PaymentMethodsResponse m) async {
    await saveLocalData('savedPaymentMethods', jsonEncode(m.toJson()));
    Future.delayed(const Duration(milliseconds: 500), () {
      loadPaymentMethods();
    });
  }

  // ========= HELPERS =========

  List<CreditCardModel> _setDefaultCard(List<CreditCardModel> list, String id) {
    return list.map((x) => x.copyWith(isDefault: x.id == id)).toList();
  }

  List<BankAccountModel> _setDefaultBank(List<BankAccountModel> list, String id) {
    return list.map((x) => x.copyWith(isDefault: x.id == id)).toList();
  }

  // store masked form (don’t keep full number)
  String _safeMasked(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return input.trim();

    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits.padLeft(4, '0');
    return "0000 **** **** $last4";
  }
}
