import '../../../Cards and Account/Card and Account Getx.dart';
import '../../../Controllers.dart';

enum AprBucketType { purchase, cash, bt, other }

enum CardTxnKind { charge, payment }

class CardTxn {
  final String id;
  final String cardId;
  final CardTxnKind kind;

  /// For charges: purchase/cash/bt
  /// For payments: use `AprBucketType.other`
  final AprBucketType bucket;

  /// Always positive
  final double amount;
  final DateTime date;

  const CardTxn({
    required this.id,
    required this.cardId,
    required this.kind,
    required this.bucket,
    required this.amount,
    required this.date,
  });
}

class AprBucket {
  final AprBucketType type;
  final double apr; // 0 allowed if unknown yet
  final double balance; // >= 0

  const AprBucket({required this.type, required this.apr, required this.balance});

  AprBucket copyWith({AprBucketType? type, double? apr, double? balance}) {
    return AprBucket(
      type: type ?? this.type,
      apr: apr ?? this.apr,
      balance: balance ?? this.balance,
    );
  }
}

class CardDebtPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  const CardDebtPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note = "",
  });
}

/// Example credit card debt container (adapt to your actual model)
class CreditCardDebt {
  final String cardId;

  final DateTime? statementDate;
  final DateTime? dueDate;

  /// User-entered minimum due from statement (baseline truth)
  final double minPaymentBase;

  /// You wanted default true always
  final bool autoMinEnabled;

  /// Bucket balances + APR
  final List<AprBucket> aprBuckets;

  /// Optional
  final List<CardDebtPayment> payments;

  const CreditCardDebt({
    required this.cardId,
    this.statementDate,
    this.dueDate,
    this.minPaymentBase = 0.0,
    this.autoMinEnabled = true,
    this.aprBuckets = const [],
    this.payments = const [],
  });

  CreditCardDebt copyWith({
    DateTime? statementDate,
    DateTime? dueDate,
    double? minPaymentBase,
    bool? autoMinEnabled,
    List<AprBucket>? aprBuckets,
    List<CardDebtPayment>? payments,
  }) {
    return CreditCardDebt(
      cardId: cardId,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      minPaymentBase: minPaymentBase ?? this.minPaymentBase,
      autoMinEnabled: autoMinEnabled ?? this.autoMinEnabled,
      aprBuckets: aprBuckets ?? this.aprBuckets,
      payments: payments ?? this.payments,
    );
  }
}

extension CreditCardDebtLogic on CreditCardDebt {
  /// Ensures purchase/cash/bt buckets always exist (prevents null bugs + makes UI predictable)
  CreditCardDebt ensureDefaultBuckets() {
    AprBucket ensure(AprBucketType t) {
      final idx = aprBuckets.indexWhere((b) => b.type == t);
      if (idx >= 0) return aprBuckets[idx];
      return AprBucket(type: t, apr: 0.0, balance: 0.0);
    }

    final base = <AprBucket>[
      ensure(AprBucketType.purchase),
      ensure(AprBucketType.cash),
      ensure(AprBucketType.bt),
    ];

    // keep any extra buckets if you ever add in future
    for (final b in aprBuckets) {
      if (!base.any((x) => x.type == b.type)) base.add(b);
    }

    return copyWith(aprBuckets: base);
  }

  double get totalBalance => aprBuckets.fold(0.0, (s, b) => s + b.balance);

  /// Adds a charge amount into the selected bucket
  CreditCardDebt applyCharge({required AprBucketType type, required double amount}) {
    if (amount <= 0) return this;

    final d0 = ensureDefaultBuckets();
    final list = d0.aprBuckets.toList();
    final idx = list.indexWhere((b) => b.type == type);

    if (idx < 0) {
      list.add(AprBucket(type: type, apr: 0.0, balance: amount));
    } else {
      final b = list[idx];
      list[idx] = b.copyWith(balance: (b.balance + amount).clamp(0.0, 1e12).toDouble());
    }
    return d0.copyWith(aprBuckets: list);
  }

  /// Payment allocation: highest APR bucket first (good default; consistent + minimizes interest)
  CreditCardDebt applyPayment({required double amount}) {
    if (amount <= 0) return this;

    final d0 = ensureDefaultBuckets();
    final list = d0.aprBuckets.toList();

    final order = List<int>.generate(list.length, (i) => i)..sort((a, b) => list[b].apr.compareTo(list[a].apr));

    double rem = amount;

    for (final i in order) {
      if (rem <= 0) break;
      final b = list[i];
      if (b.balance <= 0) continue;

      final pay = rem.clamp(0.0, b.balance).toDouble();
      list[i] = b.copyWith(balance: (b.balance - pay).clamp(0.0, 1e12).toDouble());
      rem -= pay;
    }

    return d0.copyWith(aprBuckets: list);
  }

  /// Optional statement correction: directly set bucket balances (used only when user provides statement bucket balances)
  CreditCardDebt setBucketBalances({
    double? purchase,
    double? cash,
    double? bt,
  }) {
    final d0 = ensureDefaultBuckets();
    final list = d0.aprBuckets.toList();

    void set(AprBucketType t, double? v) {
      if (v == null) return;
      final idx = list.indexWhere((b) => b.type == t);
      final vv = v.clamp(0.0, 1e12).toDouble();
      if (idx < 0) {
        list.add(AprBucket(type: t, apr: 0.0, balance: vv));
      } else {
        list[idx] = list[idx].copyWith(balance: vv);
      }
    }

    set(AprBucketType.purchase, purchase);
    set(AprBucketType.cash, cash);
    set(AprBucketType.bt, bt);

    return d0.copyWith(aprBuckets: list);
  }
}

extension CardsControllerDebtOps on CardsAndAccount {
  /// Used by your charge flow (you already have applyCardSpend)
  /// This is NEW: reduce used when user pays the card.

  Future<void> applyCardPayment({required String cardId, required double amount}) async {
    if (amount <= 0) return;

    final list = cards.cards; // adjust to your actual list
    final idx = list.indexWhere((c) => c.id == cardId);
    if (idx < 0) return;

    final card = list[idx];
    final limit = card.creditLimit ?? 0.0;
    final used = (card.creditLimitUsed ?? 0.0);

    final newUsed = (used - amount).clamp(0.0, limit > 0 ? limit : 1e12).toDouble();
    list[idx] = card.copyWith(creditLimitUsed: newUsed);

    final updateModel = cards.paymentModel.value.copyWith(creditCards: list, message: "card payment applied");
    await cards.saveAndApply(updateModel);
  }

  /// NEW: user edits credit limit from card screen
  Future<void> updateCardCreditLimit({required String cardId, required double newLimit}) async {
    final list = cards.cards;
    final idx = list.indexWhere((c) => c.id == cardId);
    if (idx < 0) return;

    final card = list[idx];
    final limit = newLimit.clamp(0.0, 1e12).toDouble();
    final used = (card.creditLimitUsed ?? 0.0).clamp(0.0, limit > 0 ? limit : 1e12).toDouble();

    list[idx] = card.copyWith(
      creditLimit: limit,
      creditLimitUsed: used, // clamp so you never exceed new limit
    );

    final updateModel = cards.paymentModel.value.copyWith(creditCards: list, message: "credit limit updated");
    await cards.saveAndApply(updateModel);
  }

  /// NEW: statement refresh updates cycle metadata and optional corrections.
  Future<void> updateCardStatement({
    required String cardId,
    required DateTime statementDate,
    required DateTime dueDate,
    double? creditLimit, // optional
    double? creditLimitUsed, // optional correction
  }) async {
    final list = cards.cards;
    final idx = list.indexWhere((c) => c.id == cardId);
    if (idx < 0) return;

    final card = list[idx];

    final limit = (creditLimit ?? card.creditLimit ?? 0.0).clamp(0.0, 1e12).toDouble();
    final used = (creditLimitUsed ?? card.creditLimitUsed ?? 0.0).clamp(0.0, limit > 0 ? limit : 1e12).toDouble();

    list[idx] = card.copyWith(
      statementDate: statementDate,
      paymentDueDate: dueDate,
      creditLimit: limit,
      creditLimitUsed: used,
    );

    final updateModel = cards.paymentModel.value.copyWith(creditCards: list, message: "statement updated");
    await cards.saveAndApply(updateModel);
  }
}

abstract class CreditCardDebtRepo {
  Future<CreditCardDebt?> load(String cardId);
  Future<void> save(CreditCardDebt debt);
}

abstract class ExpenseRepo {
  Future<void> saveCardTxn(CardTxn txn);
  Future<List<CardTxn>> loadCardTxns(String cardId);
}

class CardDebtService {
  final CardsAndAccount cards;
  final CreditCardDebtRepo debtRepo;
  final ExpenseRepo expenseRepo;

  CardDebtService({
    required this.cards,
    required this.debtRepo,
    required this.expenseRepo,
  });

  // ==========================================================
  // 1) Use this from Expense screen when user pays with card
  // ==========================================================
  Future<bool> postCardCharge({
    required String cardId,
    required AprBucketType bucket, // purchase/cash/bt
    required double amount,
    DateTime? date,
    bool blockIfOverLimit = true,
  }) async {
    if (amount <= 0) return false;

    // A) Update card usage (limit enforcement + used amount)
    // final ok = await cards.applyCardSpend(
    //   cardId: cardId,
    //   amount: amount,
    //   blockIfOverLimit: blockIfOverLimit,
    // );
    // if (!ok) return false;

    // B) Record transaction in ledger (truth of what happened)
    await expenseRepo.saveCardTxn(CardTxn(
      id: "txn_${DateTime.now().millisecondsSinceEpoch}",
      cardId: cardId,
      kind: CardTxnKind.charge,
      bucket: bucket,
      amount: amount,
      date: date ?? DateTime.now(),
    ));

    // C) Update debt buckets
    final d = await debtRepo.load(cardId);
    if (d != null) {
      final updated = d.applyCharge(type: bucket, amount: amount);
      await debtRepo.save(updated);
    }

    return true;
  }

  // ==========================================================
  // 2) Use this when user records a credit card payment
  // ==========================================================
  Future<void> postCardPayment({
    required String cardId,
    required double amount,
    DateTime? date,
    String note = "",
  }) async {
    if (amount <= 0) return;

    // A) Ledger
    await expenseRepo.saveCardTxn(CardTxn(
      id: "pay_${DateTime.now().millisecondsSinceEpoch}",
      cardId: cardId,
      kind: CardTxnKind.payment,
      bucket: AprBucketType.other,
      amount: amount,
      date: date ?? DateTime.now(),
    ));

    // B) Reduce used amount in card snapshot
    await cards.applyCardPayment(cardId: cardId, amount: amount);

    // C) Reduce debt buckets (highest APR first)
    final d = await debtRepo.load(cardId);
    if (d == null) return;

    var updated = d.applyPayment(amount: amount);

    // Optional: keep a payment history inside debt model
    final payList = updated.payments.toList()
      ..add(CardDebtPayment(
        id: "p_${DateTime.now().millisecondsSinceEpoch}",
        amount: amount,
        date: date ?? DateTime.now(),
        note: note,
      ));
    updated = updated.copyWith(payments: payList);

    await debtRepo.save(updated);
  }

  // ==========================================================
  // 3) Use this when new statement comes (monthly refresh)
  //    Supports optional corrections you requested:
  //    - creditLimit
  //    - creditLimitUsed (correction)
  //    - bucket balances (correction)
  // ==========================================================
  Future<void> postNewStatement({
    required String cardId,
    required DateTime statementDate,
    required DateTime dueDate,
    required double minPaymentDue,

    // Optional corrections:
    double? creditLimit,
    double? creditLimitUsed,
    double? purchaseBucketBalance,
    double? cashBucketBalance,
    double? btBucketBalance,
  }) async {
    // A) Update CreditCardModel snapshot
    await cards.updateCardStatement(
      cardId: cardId,
      statementDate: statementDate,
      dueDate: dueDate,
      creditLimit: creditLimit,
      creditLimitUsed: creditLimitUsed,
    );

    // B) Update debt model (min due is critical)
    final d = await debtRepo.load(cardId);
    if (d == null) return;

    var updated = d.copyWith(
      statementDate: statementDate,
      dueDate: dueDate,
      minPaymentBase: minPaymentDue.clamp(0.0, 1e12).toDouble(),
      autoMinEnabled: true, // default always on (your request)
    );

    // C) Optional bucket corrections (only if user provides them)
    final anyBucketCorrection = purchaseBucketBalance != null || cashBucketBalance != null || btBucketBalance != null;

    if (anyBucketCorrection) {
      updated = updated.setBucketBalances(
        purchase: purchaseBucketBalance,
        cash: cashBucketBalance,
        bt: btBucketBalance,
      );
    }

    await debtRepo.save(updated);
  }

  // ==========================================================
  // 4) Use this from Card screen when user edits credit limit
  // ==========================================================
  Future<void> postCreditLimitEdit({
    required String cardId,
    required double newLimit,
  }) async {
    // Only card snapshot needs this.
    await cards.updateCardCreditLimit(cardId: cardId, newLimit: newLimit);
  }

  // ==========================================================
  // 5) Use this when you want to "recalculate from history"
  //    (audit / drift fix)
  // ==========================================================
  Future<void> rebuildDebtFromLedger({required String cardId}) async {
    final d = await debtRepo.load(cardId);
    if (d == null) return;

    final txns = await expenseRepo.loadCardTxns(cardId);
    txns.sort((a, b) => a.date.compareTo(b.date));

    // Start from 0 balances, keep existing APRs
    var rebuilt = d.ensureDefaultBuckets();
    final resetBuckets = rebuilt.aprBuckets.map((b) => b.copyWith(balance: 0.0)).toList();
    rebuilt = rebuilt.copyWith(aprBuckets: resetBuckets);

    for (final t in txns) {
      if (t.kind == CardTxnKind.charge) {
        rebuilt = rebuilt.applyCharge(type: t.bucket, amount: t.amount);
      } else if (t.kind == CardTxnKind.payment) {
        rebuilt = rebuilt.applyPayment(amount: t.amount);
      }
    }

    await debtRepo.save(rebuilt);
  }
}
