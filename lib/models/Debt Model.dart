import 'dart:convert';

enum DebtSortingTypes { snowBall, avalanche, hybrid, manuel }
enum PayoffStrategy { snowball, avalanche, hybrid, manual }

/// ================================
/// DebtsResponse (root persistence)
/// ================================
class DebtsResponse {
  final String status;
  final String message;
  final int version;
  final String strategy;
  final List<DebtItem> debts;

  const DebtsResponse({
    required this.status,
    required this.message,
    this.version = 2,
    this.strategy = "snowball",
    this.debts = const [],
  });

  DebtsResponse copyWith({
    String? status,
    String? message,
    int? version,
    String? strategy,
    List<DebtItem>? debts,
  }) {
    return DebtsResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      version: version ?? this.version,
      strategy: strategy ?? this.strategy,
      debts: debts ?? this.debts,
    );
  }

  Map<String, dynamic> toMap() => {
    "status": status,
    "message": message,
    "version": version,
    "strategy": strategy,
    "debts": debts.map((e) => e.toMap()).toList(),
  };

  static DebtsResponse fromMap(Map<String, dynamic> m) {
    final rawDebts = m["debts"];
    List<DebtItem> parsedDebts = const [];

    if (rawDebts is List) {
      parsedDebts = rawDebts
          .whereType<Map>()
          .map((x) => DebtItem.fromMap(Map<String, dynamic>.from(x)))
          .toList();
    } else if (rawDebts is String && rawDebts.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDebts);
        if (decoded is List) {
          parsedDebts = decoded
              .whereType<Map>()
              .map((x) => DebtItem.fromMap(Map<String, dynamic>.from(x)))
              .toList();
        }
      } catch (_) {
        parsedDebts = const [];
      }
    }

    return DebtsResponse(
      status: (m["status"] ?? "").toString(),
      message: (m["message"] ?? "").toString(),
      version: (m["version"] is num)
          ? (m["version"] as num).toInt()
          : (int.tryParse((m["version"] ?? "").toString()) ?? 2),
      strategy: (m["strategy"] ?? "snowball").toString(),
      debts: parsedDebts,
    );
  }

  String encode() => jsonEncode(toMap());
  static DebtsResponse decode(String raw) =>
      DebtsResponse.fromMap(jsonDecode(raw) as Map<String, dynamic>);
}

/// ================================
/// DebtItem (single debt)
/// ================================
/// ================================
/// DebtItem (single debt) - minimal constructor
/// ================================
class DebtItem {
  // ----- Required (old style) -----
  final String id;
  final String type; // "creditCard" | "loan" | "bnpl" | "other"
  final String name;
  final double balance;
  final double initialBalance;
  final double apr;
  final double minPayment;
  final bool secured;
  final bool fixedInstallment;
  final String notes;
  final bool isActive;
  final int createdAtMs;

  // ----- Optional (old ones) -----
  final DateTime? dueDate;
  final DateTime? statementDate;
  final List<DateTime>? statementCycle;
  final String? linkedCreditCardId;

  final List<DebtPayment>? paymentsMade;

  /// ✅ computed schedule rows (your UI already reads this)
  final List<DebtScheduleRow>? paymentScheduleOverride;

  // ----- NEW (but optional, so you don’t pass them every time) -----

  /// ✅ due day of month for schedule building (1-31)
  /// If null, schedule generator should fallback to dueDate?.day or 1.
  final int? dueDayOfMonth;

  /// ✅ Planned overrides used by plannedFor()
  final List<PlannedPaymentOverride>? plannedPaymentOverrides;

  /// ✅ Minimum payment rule inputs (only used if you want A2 logic)
  final double? minPct;     // default: 0.02
  final double? absMinPay;  // default: 10.0

  /// ✅ Multi-APR buckets (all optional)
  final double purchaseBalance;
  final double cashBalance;
  final double balanceTransferBalance;

  final double purchaseApr;
  final double cashApr;
  final double balanceTransferApr;

  const DebtItem({
    // required (old)
    required this.id,
    required this.type,
    required this.name,
    required this.balance,
    required this.initialBalance,
    required this.apr,
    required this.minPayment,
    required this.secured,
    required this.fixedInstallment,
    required this.notes,
    required this.isActive,
    required this.createdAtMs,

    // optional (old)
    this.dueDate,
    this.statementDate,
    this.statementCycle,
    this.linkedCreditCardId,
    this.paymentsMade,
    this.paymentScheduleOverride,

    // new optional
    this.dueDayOfMonth,
    this.plannedPaymentOverrides,
    this.minPct,
    this.absMinPay,

    // buckets default to 0
    this.purchaseBalance = 0.0,
    this.cashBalance = 0.0,
    this.balanceTransferBalance = 0.0,
    this.purchaseApr = 0.0,
    this.cashApr = 0.0,
    this.balanceTransferApr = 0.0,
  });

  /// For card totals if you want:
  double get bucketsTotal => purchaseBalance + cashBalance + balanceTransferBalance;

  /// Effective APRs fallback to legacy apr
  double get effPurchaseApr => (purchaseApr > 0) ? purchaseApr : apr;
  double get effCashApr => (cashApr > 0) ? cashApr : apr;
  double get effBtApr => (balanceTransferApr > 0) ? balanceTransferApr : apr;

  DebtItem copyWith({
    String? type,
    String? name,
    double? balance,
    double? initialBalance,
    double? apr,
    double? minPayment,

    DateTime? dueDate,
    DateTime? statementDate,
    List<DateTime>? statementCycle,
    String? linkedCreditCardId,

    bool? secured,
    bool? fixedInstallment,
    String? notes,
    bool? isActive,

    List<DebtPayment>? paymentsMade,
    List<DebtScheduleRow>? paymentScheduleOverride,

    int? dueDayOfMonth,
    List<PlannedPaymentOverride>? plannedPaymentOverrides,
    double? minPct,
    double? absMinPay,

    double? purchaseBalance,
    double? cashBalance,
    double? balanceTransferBalance,
    double? purchaseApr,
    double? cashApr,
    double? balanceTransferApr,
  }) {
    return DebtItem(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      apr: apr ?? this.apr,
      minPayment: minPayment ?? this.minPayment,

      dueDate: dueDate ?? this.dueDate,
      statementDate: statementDate ?? this.statementDate,
      statementCycle: statementCycle ?? this.statementCycle,
      linkedCreditCardId: linkedCreditCardId ?? this.linkedCreditCardId,

      secured: secured ?? this.secured,
      fixedInstallment: fixedInstallment ?? this.fixedInstallment,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAtMs: createdAtMs,

      paymentsMade: paymentsMade ?? this.paymentsMade,
      paymentScheduleOverride: paymentScheduleOverride ?? this.paymentScheduleOverride,

      dueDayOfMonth: dueDayOfMonth ?? this.dueDayOfMonth,
      plannedPaymentOverrides: plannedPaymentOverrides ?? this.plannedPaymentOverrides,
      minPct: minPct ?? this.minPct,
      absMinPay: absMinPay ?? this.absMinPay,

      purchaseBalance: purchaseBalance ?? this.purchaseBalance,
      cashBalance: cashBalance ?? this.cashBalance,
      balanceTransferBalance: balanceTransferBalance ?? this.balanceTransferBalance,
      purchaseApr: purchaseApr ?? this.purchaseApr,
      cashApr: cashApr ?? this.cashApr,
      balanceTransferApr: balanceTransferApr ?? this.balanceTransferApr,
    );
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "type": type,
    "name": name,
    "balance": balance,
    "initialBalance": initialBalance,
    "apr": apr,
    "minPayment": minPayment,

    "dueDate": dueDate?.millisecondsSinceEpoch,
    "statementDate": statementDate?.millisecondsSinceEpoch,
    "statementCycle": statementCycle?.map((d) => d.millisecondsSinceEpoch).toList(),
    "secured": secured,
    "fixedInstallment": fixedInstallment,
    "notes": notes,
    "linkedCreditCardId": linkedCreditCardId,
    "isActive": isActive,
    "createdAtMs": createdAtMs,

    "paymentsMade": paymentsMade?.map((e) => e.toMap()).toList(),
    "paymentScheduleOverride": paymentScheduleOverride?.map((e) => e.toMap()).toList(),

    // new optional
    "dueDayOfMonth": dueDayOfMonth,
    "plannedPaymentOverrides": plannedPaymentOverrides?.map((e) => e.toMap()).toList(),
    "minPct": minPct,
    "absMinPay": absMinPay,

    // buckets
    "purchaseBalance": purchaseBalance,
    "cashBalance": cashBalance,
    "balanceTransferBalance": balanceTransferBalance,
    "purchaseApr": purchaseApr,
    "cashApr": cashApr,
    "balanceTransferApr": balanceTransferApr,
  };

  static DebtItem fromMap(Map<String, dynamic> m) {
    final type = (m["type"] ?? "creditCard").toString();
    final legacyBalance = (m["balance"] as num?)?.toDouble() ?? 0.0;
    final legacyApr = (m["apr"] as num?)?.toDouble() ?? 0.0;

    // buckets (if not present, default 0; if card and all missing, migrate legacy balance -> purchaseBalance)
    final pbRaw = (m["purchaseBalance"] as num?)?.toDouble();
    final cbRaw = (m["cashBalance"] as num?)?.toDouble();
    final btRaw = (m["balanceTransferBalance"] as num?)?.toDouble();

    final bucketsAllMissing = (pbRaw == null && cbRaw == null && btRaw == null);
    final purchaseBal = (type == "creditCard" && bucketsAllMissing) ? legacyBalance : (pbRaw ?? 0.0);
    final cashBal = cbRaw ?? 0.0;
    final btBal = btRaw ?? 0.0;

    // if buckets exist, recompute total balance for consistency
    final bucketsExist = !bucketsAllMissing;
    final finalBalance = (type == "creditCard" && bucketsExist) ? (purchaseBal + cashBal + btBal) : legacyBalance;

    // APRs fallback to legacy apr
    final pApr = (m["purchaseApr"] as num?)?.toDouble() ?? legacyApr;
    final cApr = (m["cashApr"] as num?)?.toDouble() ?? legacyApr;
    final btApr = (m["balanceTransferApr"] as num?)?.toDouble() ?? legacyApr;

    return DebtItem(
      id: (m["id"] ?? "").toString(),
      type: type,
      name: (m["name"] ?? "").toString(),
      balance: finalBalance,
      initialBalance: (m["initialBalance"] as num?)?.toDouble() ?? 0.0,
      apr: legacyApr,
      minPayment: (m["minPayment"] as num?)?.toDouble() ?? 0.0,

      dueDate: (m["dueDate"] is num) ? DateTime.fromMillisecondsSinceEpoch((m["dueDate"] as num).toInt()) : null,
      statementDate: (m["statementDate"] is num) ? DateTime.fromMillisecondsSinceEpoch((m["statementDate"] as num).toInt()) : null,
      statementCycle: (m["statementCycle"] is List)
          ? (m["statementCycle"] as List).whereType<num>().map((x) => DateTime.fromMillisecondsSinceEpoch(x.toInt())).toList()
          : null,

      secured: m["secured"] == true,
      fixedInstallment: m["fixedInstallment"] == true,
      notes: (m["notes"] ?? "").toString(),
      linkedCreditCardId: (m["linkedCreditCardId"] as String?)?.trim().isEmpty == true ? null : m["linkedCreditCardId"],
      isActive: m["isActive"] != false,
      createdAtMs: (m["createdAtMs"] as num?)?.toInt() ?? 0,

      paymentsMade: (m["paymentsMade"] is List)
          ? (m["paymentsMade"] as List).whereType<Map>().map((x) => DebtPayment.fromMap(Map<String, dynamic>.from(x))).toList()
          : null,

      paymentScheduleOverride: (m["paymentScheduleOverride"] is List)
          ? (m["paymentScheduleOverride"] as List).whereType<Map>().map((x) => DebtScheduleRow.fromMap(Map<String, dynamic>.from(x))).toList()
          : null,

      // new optional
      dueDayOfMonth: (m["dueDayOfMonth"] as num?)?.toInt(),
      plannedPaymentOverrides: (m["plannedPaymentOverrides"] is List)
          ? (m["plannedPaymentOverrides"] as List).whereType<Map>().map((x) => PlannedPaymentOverride.fromMap(Map<String, dynamic>.from(x))).toList()
          : null,
      minPct: (m["minPct"] as num?)?.toDouble(),
      absMinPay: (m["absMinPay"] as num?)?.toDouble(),

      // buckets
      purchaseBalance: purchaseBal,
      cashBalance: cashBal,
      balanceTransferBalance: btBal,
      purchaseApr: pApr,
      cashApr: cApr,
      balanceTransferApr: btApr,
    );
  }
}

class DebtPayment {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final String note;
  final int createdAtMs;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    required this.note,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() => {
    "id": id,
    "debtId": debtId,
    "amount": amount,
    "date": date.toIso8601String(),
    "note": note,
    "createdAtMs": createdAtMs,
  };

  static DebtPayment fromMap(Map<String, dynamic> m) => DebtPayment(
    id: (m["id"] ?? "").toString(),
    debtId: (m["debtId"] ?? "").toString(),
    amount: (m["amount"] as num?)?.toDouble() ?? 0.0,
    date: DateTime.tryParse((m["date"] ?? "").toString()) ?? DateTime.now(),
    note: (m["note"] ?? "").toString(),
    createdAtMs: (m["createdAtMs"] as num?)?.toInt() ?? 0,
  );
}

class PlannedPaymentOverride {
  final String yyyymm; // "2026-01"
  final double amount;

  const PlannedPaymentOverride({required this.yyyymm, required this.amount});

  Map<String, dynamic> toMap() => {"yyyymm": yyyymm, "amount": amount};

  static PlannedPaymentOverride fromMap(Map<String, dynamic> m) => PlannedPaymentOverride(
    yyyymm: (m["yyyymm"] ?? "").toString(),
    amount: (m["amount"] as num?)?.toDouble() ?? 0.0,
  );
}

class DebtScheduleRow {
  final DateTime dueDate;
  final double plannedPayment;
  final double interest;
  final double principal;
  final double endBalance;

  const DebtScheduleRow({
    required this.dueDate,
    required this.plannedPayment,
    required this.interest,
    required this.principal,
    required this.endBalance,
  });

  Map<String, dynamic> toMap() => {
    "dueDate": dueDate.toIso8601String(),
    "plannedPayment": plannedPayment,
    "interest": interest,
    "principal": principal,
    "endBalance": endBalance,
  };

  static DebtScheduleRow fromMap(Map<String, dynamic> m) => DebtScheduleRow(
    dueDate: DateTime.tryParse((m["dueDate"] ?? "").toString()) ?? DateTime.now(),
    plannedPayment: (m["plannedPayment"] as num?)?.toDouble() ?? 0.0,
    interest: (m["interest"] as num?)?.toDouble() ?? 0.0,
    principal: (m["principal"] as num?)?.toDouble() ?? 0.0,
    endBalance: (m["endBalance"] as num?)?.toDouble() ?? 0.0,
  );
}


/// ================================
/// UI VMs
/// ================================
class DebtProjection {
  final int months;
  final double totalPaid;
  final double totalInterest;

  const DebtProjection({
    required this.months,
    required this.totalPaid,
    required this.totalInterest,
  });
}

class DebtPayoffSummary {
  final int months;
  final double totalInterest;
  final double totalPaid;

  const DebtPayoffSummary({
    required this.months,
    required this.totalInterest,
    required this.totalPaid,
  });
}

class PayoffProjectionVM {
  final double payPerMonth;
  final int months;
  final DateTime debtFreeDate;

  const PayoffProjectionVM({
    required this.payPerMonth,
    required this.months,
    required this.debtFreeDate,
  });
}

class DebtPlanLine {
  final String id;
  final String name;
  final double min;
  final double extra;

  const DebtPlanLine({
    required this.id,
    required this.name,
    required this.min,
    required this.extra,
  });

  double get total => min + extra;
}

enum FinanceEventType { expenseChargedToCard, cardPaymentMade }

class FinanceEvent {
  final FinanceEventType type;
  final String cardId;
  final double amount;
  final DateTime date;
  final String note;

  const FinanceEvent({
    required this.type,
    required this.cardId,
    required this.amount,
    required this.date,
    this.note = "",
  });
}

extension FirstWhereOrNullX<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E e) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
