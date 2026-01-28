import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/Working%20UI/Debts/Debt%20Dashboard/Credit%20Card%20Debt/Credit%20Card%20Logic.dart';

import '../models/Debt Model.dart';
import 'Constants.dart';

class Pipeline {
  // =================================================================================
  // =================================================================================
  // Function that changes status of credit card balance and limit from expense screen
  // =================================================================================
  // =================================================================================
  Future<bool> applyCardSpend({required String cardId, required double amount, bool blockIfOverLimit = true}) async {
    bool? allowed = true;
    final list = cards.cards;
    final idx = list.indexWhere((c) => c.id == cardId);
    final card = list[idx];

    final limit = card.creditLimit ?? 0.0;
    final existingUsedAmount = card.creditLimitUsed ?? 0.0;

    double totalUsed = existingUsedAmount + amount;

    if (blockIfOverLimit && limit > 0 && totalUsed > limit) {
      showSnackBar("Card limit reached", "This charge would exceed your credit limit.");
      allowed = false;
    }

    totalUsed = totalUsed.clamp(0.0, limit > 0 ? limit : 1e12).toDouble();

    final updatedCard = card.copyWith(creditLimitUsed: totalUsed);
    list[idx] = updatedCard;

    final updateModel = cards.paymentModel.value.copyWith(creditCards: list, message: "card usage updated");
    await cards.saveAndApply(updateModel);
    await updateCardAndAccountStatus(id: cardId);
    return allowed;
  }

  // ==================================================================================
  // ==================================================================================
  // Function that changes status of bank account balance and limit from expense screen
  // ==================================================================================
  // ==================================================================================
  Future<bool> applyBankAccountSpend({required String cardId, required double amount, bool blockIfOverLimit = true}) async {
    bool? allowed = true;
    final list = cards.banks;
    final idx = list.indexWhere((c) => c.id == cardId);
    final account = list[idx];

    final balanceHad = account.balance ?? 0.0;

    double balanceLeft = balanceHad - amount;

    if (balanceLeft < 0) {
      showSnackBar("Card limit reached", "This charge would exceed your credit limit.");
      allowed = false;
    }

    final updateAccount = account.copyWith(balance: balanceLeft);
    list[idx] = updateAccount;

    final updateModel = cards.paymentModel.value.copyWith(bankAccounts: list, message: "card usage updated");
    await cards.saveAndApply(updateModel);

    await updateCardAndAccountStatus(id: cardId);
    return allowed;
  }

  // ===================================================================================
  // ===================================================================================
  // Function that check that credit cards exist in debt if not add in debt screen
  // ===================================================================================
  // ===================================================================================
  Future<void> cardStatusInDebt() async {
    await debtV2.loadDebts();
    // if (hasDebt) {
    final debts = debtV2.debtsModel.value.debts;
    for (var file in cards.cards) {
      bool? cardExist = debts.any((t) => t.linkedCreditCardId == file.cardNumber!);
      if (!cardExist) {
        var cycle = CreditCardDebtLogic().calculateStatementCycle(file.statementDate!);
        debts.add(
          DebtItem(
            id: "dd_${file.id}",
            type: "creditCard",
            name: "${file.bankName!}/${file.cardType}",
            balance: (file.creditLimit! - file.creditLimitUsed!),
            initialBalance: file.creditLimit!,
            apr: 0.0,
            minPayment: 0.0,
            statementDate: file.statementDate,
            dueDate: file.paymentDueDate,
            secured: false,
            fixedInstallment: false,
            notes: '',
            linkedCreditCardId: file.cardNumber,
            isActive: true,
            createdAtMs: DateTime.now().millisecondsSinceEpoch,
            paymentsMade: [],
            statementCycle: cycle,
          ),
        );
      } else {
        // int? cardIndex = debts.indexWhere((t) => t.linkedCreditCardId == file.cardNumber!);
        // debts[cardIndex] = DebtItem(
        //   id: "dd_cc_${file.id}",
        //   type: "creditCard",
        //   name: file.bankName!,
        //   balance: (file.creditLimit! - file.creditLimitUsed!),
        //   initialBalance: file.creditLimit!,
        //   apr: 0.0,
        //   minPayment: 0.0,
        //   dueDayOfMonth: debtV2.nextDueDateFromCard(file).day,
        //   secured: false,
        //   fixedInstallment: false,
        //   notes: '',
        //   linkedCreditCardId: file.cardNumber,
        //   isActive: true,
        //   createdAtMs: DateTime.now().millisecondsSinceEpoch,
        //   paymentScheduleOverride: [],
        //   paymentsMade: [],
        // );
      }
      print(cardExist);
    }
    await debtV2.debtsIO(
        model: debtV2.debtsModel.value.copyWith(
      message: "credit card added to debt",
      debts: debts,
    ));
    // }
  }

  // =======================================================================================
  // =======================================================================================
  // When expense added this function update card and account status in debt and card screen
  // =======================================================================================
  // =======================================================================================
  Future<void> updateCardAndAccountStatus(
      {required String id, DateTime? now, bool createOnly = false, double? amount = 0.0, double? amountResolve = 0.0}) async {
    final debts = debtV2.debtsModel.value.debts.toList();
    final debtIndex = debts.indexWhere((d) => d.id == "dd_cc_$id");
    final cardIndex = cards.cards.indexWhere((d) => d.id == id);

    final limit = cards.cards[cardIndex].creditLimit;
    final existingUsedAmount = debts[debtIndex].balance;
    // final due = debtV2.nextDueDateFromCard(cards.cards[cardIndex], now: now);
    if (amountResolve == 0.0) {
      // =======================================================================================
      // =======================================================================================
      // This part changes balance in credit card when user made any transaction with card
      // =======================================================================================
      // =======================================================================================
      double totalUsed = existingUsedAmount + amount!;
      debts[debtIndex] = debts[cardIndex].copyWith(
        balance: totalUsed,
        initialBalance: limit,
        // dueDayOfMonth: due.day,
        name: cards.cards[cardIndex].bankName!,
        linkedCreditCardId: cards.cards[cardIndex].cardNumber,
      );
    } else {
      // =======================================================================================
      // =======================================================================================
      // This part changes credit limit when user pay credit card bill
      // =======================================================================================
      // =======================================================================================
      final changedLimit = limit! + amountResolve!;
      debts[debtIndex] = debts[debtIndex].copyWith(
        balance: changedLimit,
        initialBalance: limit,
        // dueDayOfMonth: due.day,
      );
    }

    await debtV2.debtsIO(
      model: debtV2.debtsModel.value.copyWith(
        message: "credit card debt synced",
        debts: debts,
      ),
    );
    return;
  }
}
