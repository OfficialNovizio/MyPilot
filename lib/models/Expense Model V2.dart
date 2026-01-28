// expense_models_v2.dart
// ============================================================================
// MODELS (storage + UI contract)
// ----------------------------------------------------------------------------
// Linked with:
// - expenses_getx_controller_v10.dart  (CRUD + persist + reactive state)
// - expense_insight_logic_v10.dart     (reads ExpenseItem fields for insights)
//
// NOTE: This file is pure models + JSON. No GetX required here.
// ============================================================================

import 'dart:convert';

/// Links an expense to one or more user accounts (bank/card/cash).
///
/// Linked with:
/// - ExpensesControllerV2.selectedAccounts (multi-select from UI)
/// - ExpenseItem.accounts (stored inside each expense)
class AccountRef {
  final String? id;
  final String? type; // "card" | "bank" | "cash" | "unknown"
  final String? name;

  const AccountRef({this.id, this.type, this.name});

  Map<String, dynamic> toJson() => {
    if (id != null) "id": id,
    if (type != null) "type": type,
    if (name != null) "name": name,
  };

  factory AccountRef.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const <String, dynamic>{};

    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final typeRaw = s(m["type"]);
    const allowed = {"card", "bank", "cash", "unknown"};
    final type = (typeRaw != null && allowed.contains(typeRaw)) ? typeRaw : null;

    return AccountRef(
      id: s(m["id"]),
      type: type,
      name: s(m["name"]),
    );
  }

  AccountRef copyWith({String? id, String? type, String? name}) => AccountRef(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
  );
}


/// Expense “mode” defines what the item represents.
///
/// Linked with:
/// - History gate counts ONLY spent items
/// - Leaks/spikes uses ONLY spent items
class ExpenseMode {
  /// Real transaction that happened on a date.
  static const spent = "Spent";

  /// Planned/recurring/bill item.
  static const planned = "Planned";
}

/// Frequency options you show in UI.
///
/// Linked with:
/// - add/edit logic maps recurring -> planned, one-time -> spent
class ExpenseFrequency {
  static const oneTime = "One-time";
  static const weekly = "Weekly";
  static const biweekly = "Biweekly";
  static const monthly = "Monthly";
  static bool isRecurring(String f) => f != oneTime;
}

/// One expense record.
///
/// “spent” items should represent actual transactions.
/// “planned” items should represent bills/recurring/budget lines.
class ExpenseItem {
  final String id;
  final double amount;
  final String name;
  final String notes;
  final String category;

  /// Multi-account support
  final List<AccountRef> accounts;

  /// spent: transaction date
  /// planned: anchor date (still useful for ordering)
  final DateTime date;

  /// Monthly planned bills: dueDay 1..28 (0 means missing)
  final int dueDay;

  final bool isEssential;
  final String frequency; // One-time / Weekly / Biweekly / Monthly
  final String mode; // spent / planned
  final bool isActive;
  final int createdAtMs;

  const ExpenseItem({
    required this.id,
    required this.amount,
    required this.name,
    required this.notes,
    required this.category,
    required this.accounts,
    required this.date,
    required this.dueDay,
    required this.isEssential,
    required this.frequency,
    required this.mode,
    required this.isActive,
    required this.createdAtMs,
  });

  ExpenseItem copyWith({
    String? id,
    double? amount,
    String? name,
    String? notes,
    String? category,
    List<AccountRef>? accounts,
    DateTime? date,
    int? dueDay,
    bool? isEssential,
    String? frequency,
    String? mode,
    bool? isActive,
    int? createdAtMs,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      accounts: accounts ?? this.accounts,
      date: date ?? this.date,
      dueDay: dueDay ?? this.dueDay,
      isEssential: isEssential ?? this.isEssential,
      frequency: frequency ?? this.frequency,
      mode: mode ?? this.mode,
      isActive: isActive ?? this.isActive,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "amount": amount,
        "name": name,
        "notes": notes,
        "category": category,
        "accounts": accounts.map((e) => e.toJson()).toList(),
        "dateMs": date.millisecondsSinceEpoch,
        "dueDay": dueDay,
        "isEssential": isEssential,
        "frequency": frequency,
        "mode": mode,
        "isActive": isActive,
        "createdAtMs": createdAtMs,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> j) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? "0").toString()) ?? 0.0;
    }

    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse((v ?? "0").toString()) ?? 0;
    }

    DateTime _toDate(dynamic ms) {
      final x = _toInt(ms);
      return (x <= 0) ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(x);
    }

    // Migration: support old single account fields
    List<AccountRef> _accounts() {
      final aRaw = j["accounts"];
      if (aRaw is List) {
        return aRaw.map((e) => AccountRef.fromJson(Map<String, dynamic>.from(e))).toList();
      }

      final oldId = (j["accountId"] ?? "").toString();
      final oldName = (j["accountName"] ?? "").toString();
      if (oldId.isNotEmpty || oldName.isNotEmpty) {
        return [
          AccountRef(
            id: oldId.isEmpty ? "unknown" : oldId,
            type: "unknown",
            name: oldName.isEmpty ? "Account" : oldName,
          )
        ];
      }
      return [];
    }

    final freq = (j["frequency"] ?? ExpenseFrequency.oneTime).toString();
    final mode = (j["mode"] ?? (ExpenseFrequency.isRecurring(freq) ? ExpenseMode.planned : ExpenseMode.spent)).toString();

    return ExpenseItem(
      id: (j["id"] ?? "").toString(),
      amount: _toDouble(j["amount"]),
      name: (j["name"] ?? "").toString(),
      notes: (j["notes"] ?? "").toString(),
      category: (j["category"] ?? "Other").toString(),
      accounts: _accounts(),
      date: _toDate(j["dateMs"] ?? j["date"] ?? j["createdAtMs"]),
      dueDay: _toInt(j["dueDay"]),
      isEssential: (j["isEssential"] ?? true) == true,
      frequency: freq,
      mode: mode,
      isActive: (j["isActive"] ?? true) == true,
      createdAtMs: _toInt(j["createdAtMs"]),
    );
  }
}

/// Monthly rollup shown in Overview screens.
/// (Not accounting-grade. Honest split.)
class MonthlySummary {
  final double fixedPlanned; // recurring planned (monthly equiv)
  final double variableSpent; // spent transactions total (actual)
  final double total;
  final String note;

  const MonthlySummary({
    required this.fixedPlanned,
    required this.variableSpent,
    required this.total,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        "fixedPlanned": fixedPlanned,
        "variableSpent": variableSpent,
        "total": total,
        "note": note,
      };

  factory MonthlySummary.fromJson(Map<String, dynamic> j) => MonthlySummary(
        fixedPlanned: (j["fixedPlanned"] is num) ? (j["fixedPlanned"] as num).toDouble() : 0.0,
        variableSpent: (j["variableSpent"] is num) ? (j["variableSpent"] as num).toDouble() : 0.0,
        total: (j["total"] is num) ? (j["total"] as num).toDouble() : 0.0,
        note: (j["note"] ?? "").toString(),
      );
}

/// Safe-to-spend breakdown for a pay window.
class SafeToSpend {
  final double amount;
  final int untilDateMs;
  final double expectedIncome;
  final double plannedBills;
  final double plannedRecurring;
  final double spentSoFar;
  final double debtMinimums;
  final double bufferTarget;

  const SafeToSpend({
    required this.amount,
    required this.untilDateMs,
    required this.expectedIncome,
    required this.plannedBills,
    required this.plannedRecurring,
    required this.spentSoFar,
    required this.debtMinimums,
    required this.bufferTarget,
  });

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "untilDateMs": untilDateMs,
        "expectedIncome": expectedIncome,
        "plannedBills": plannedBills,
        "plannedRecurring": plannedRecurring,
        "spentSoFar": spentSoFar,
        "debtMinimums": debtMinimums,
        "bufferTarget": bufferTarget,
      };

  factory SafeToSpend.fromJson(Map<String, dynamic> j) => SafeToSpend(
        amount: (j["amount"] is num) ? (j["amount"] as num).toDouble() : 0.0,
        untilDateMs: (j["untilDateMs"] is int) ? (j["untilDateMs"] as int) : 0,
        expectedIncome: (j["expectedIncome"] is num) ? (j["expectedIncome"] as num).toDouble() : 0.0,
        plannedBills: (j["plannedBills"] is num) ? (j["plannedBills"] as num).toDouble() : 0.0,
        plannedRecurring: (j["plannedRecurring"] is num) ? (j["plannedRecurring"] as num).toDouble() : 0.0,
        spentSoFar: (j["spentSoFar"] is num) ? (j["spentSoFar"] as num).toDouble() : 0.0,
        debtMinimums: (j["debtMinimums"] is num) ? (j["debtMinimums"] as num).toDouble() : 0.0,
        bufferTarget: (j["bufferTarget"] is num) ? (j["bufferTarget"] as num).toDouble() : 0.0,
      );
}

/// A single recommended action.
class NextBestMove {
  final String title;
  final String description;
  final double actionAmount;
  final int dueDateMs;

  const NextBestMove({
    required this.title,
    required this.description,
    required this.actionAmount,
    required this.dueDateMs,
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "description": description,
        "actionAmount": actionAmount,
        "dueDateMs": dueDateMs,
      };

  factory NextBestMove.fromJson(Map<String, dynamic> j) => NextBestMove(
        title: (j["title"] ?? "").toString(),
        description: (j["description"] ?? "").toString(),
        actionAmount: (j["actionAmount"] is num) ? (j["actionAmount"] as num).toDouble() : 0.0,
        dueDateMs: (j["dueDateMs"] is int) ? (j["dueDateMs"] as int) : 0,
      );
}

/// Forecast risk card.
class ForecastRisk {
  final String level; // Safe / Tight / High
  final String title;
  final String description;
  final List<String> actions;

  const ForecastRisk({
    required this.level,
    required this.title,
    required this.description,
    required this.actions,
  });

  Map<String, dynamic> toJson() => {
        "level": level,
        "title": title,
        "description": description,
        "actions": actions,
      };

  factory ForecastRisk.fromJson(Map<String, dynamic> j) => ForecastRisk(
        level: (j["level"] ?? "Safe").toString(),
        title: (j["title"] ?? "Forecast risk").toString(),
        description: (j["description"] ?? "").toString(),
        actions: (j["actions"] is List) ? (j["actions"] as List).map((e) => e.toString()).toList() : const [],
      );
}

/// Cuts checklist card.
class CutsChecklist {
  final String title;
  final String tag;
  final List<String> bullets;

  const CutsChecklist({
    required this.title,
    required this.tag,
    required this.bullets,
  });

  Map<String, dynamic> toJson() => {"title": title, "tag": tag, "bullets": bullets};

  factory CutsChecklist.fromJson(Map<String, dynamic> j) => CutsChecklist(
        title: (j["title"] ?? "").toString(),
        tag: (j["tag"] ?? "").toString(),
        bullets: (j["bullets"] is List) ? (j["bullets"] as List).map((e) => e.toString()).toList() : const [],
      );
}

/// Category summary row.
class LeaksAndSpikesRow {
  final String title;
  final String subtitle;
  final String trailing; // spike/leak/ok

  const LeaksAndSpikesRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  Map<String, dynamic> toJson() => {"title": title, "subtitle": subtitle, "trailing": trailing};

  factory LeaksAndSpikesRow.fromJson(Map<String, dynamic> j) => LeaksAndSpikesRow(
        title: (j["title"] ?? "").toString(),
        subtitle: (j["subtitle"] ?? "").toString(),
        trailing: (j["trailing"] ?? "").toString(),
      );
}

/// Full Insights payload for a pay window.
class InsightsModel {
  final SafeToSpend safeToSpend;
  final NextBestMove? nextBestMove;
  final List<LeaksAndSpikesRow> leaksAndSpikes;
  final ForecastRisk forecastRisk;
  final CutsChecklist cutsChecklist;

  const InsightsModel({
    required this.safeToSpend,
    required this.nextBestMove,
    required this.leaksAndSpikes,
    required this.forecastRisk,
    required this.cutsChecklist,
  });

  Map<String, dynamic> toJson() => {
        "safeToSpend": safeToSpend.toJson(),
        "nextBestMove": nextBestMove?.toJson(),
        "leaksAndSpikes": leaksAndSpikes.map((e) => e.toJson()).toList(),
        "forecastRisk": forecastRisk.toJson(),
        "cutsChecklist": cutsChecklist.toJson(),
      };

  factory InsightsModel.fromJson(Map<String, dynamic> j) => InsightsModel(
        safeToSpend: SafeToSpend.fromJson(Map<String, dynamic>.from(j["safeToSpend"] ?? {})),
        nextBestMove: (j["nextBestMove"] == null) ? null : NextBestMove.fromJson(Map<String, dynamic>.from(j["nextBestMove"])),
        leaksAndSpikes: (j["leaksAndSpikes"] is List)
            ? (j["leaksAndSpikes"] as List).map((e) => LeaksAndSpikesRow.fromJson(Map<String, dynamic>.from(e))).toList()
            : const [],
        forecastRisk: ForecastRisk.fromJson(Map<String, dynamic>.from(j["forecastRisk"] ?? {})),
        cutsChecklist: CutsChecklist.fromJson(Map<String, dynamic>.from(j["cutsChecklist"] ?? {})),
      );
}

/// Your automation rule object.
class AutomationRule {
  final String id;
  final String title;
  final String description;
  final bool enabled;
  final int createdAtMs;

  const AutomationRule({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    required this.createdAtMs,
  });

  AutomationRule copyWith({bool? enabled}) => AutomationRule(
        id: id,
        title: title,
        description: description,
        enabled: enabled ?? this.enabled,
        createdAtMs: createdAtMs,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "enabled": enabled,
        "createdAtMs": createdAtMs,
      };

  factory AutomationRule.fromJson(Map<String, dynamic> j) => AutomationRule(
        id: (j["id"] ?? "").toString(),
        title: (j["title"] ?? "").toString(),
        description: (j["description"] ?? "").toString(),
        enabled: (j["enabled"] ?? true) == true,
        createdAtMs: (j["createdAtMs"] is int) ? (j["createdAtMs"] as int) : 0,
      );
}

/// Root saved object in storage.
class ExpensesResponse {
  final String status;
  final String message;
  final int version;

  final MonthlySummary? monthSummary;

  /// Optional legacy field. Main UI should use deck (from logic) not this.
  final InsightsModel? insights;

  final List<AutomationRule> rules;
  final List<ExpenseItem> expenses;

  const ExpensesResponse({
    required this.status,
    required this.message,
    this.version = 2,
    this.monthSummary,
    this.insights,
    this.rules = const [],
    this.expenses = const [],
  });

  ExpensesResponse copyWith({
    String? status,
    String? message,
    int? version,
    MonthlySummary? monthSummary,
    InsightsModel? insights,
    List<AutomationRule>? rules,
    List<ExpenseItem>? expenses,
  }) {
    return ExpensesResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      version: version ?? this.version,
      monthSummary: monthSummary ?? this.monthSummary,
      insights: insights ?? this.insights,
      rules: rules ?? this.rules,
      expenses: expenses ?? this.expenses,
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "version": version,
        "monthSummary": monthSummary?.toJson(),
        "insights": insights?.toJson(),
        "rules": rules.map((e) => e.toJson()).toList(),
        "expenses": expenses.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  static ExpensesResponse decode(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return const ExpensesResponse(status: "200", message: "ok");
      final j = Map<String, dynamic>.from(data);

      final rulesRaw = j["rules"];
      final expRaw = j["expenses"];

      return ExpensesResponse(
        status: (j["status"] ?? "200").toString(),
        message: (j["message"] ?? "ok").toString(),
        version: (j["version"] is int) ? (j["version"] as int) : 1,
        monthSummary: (j["monthSummary"] == null) ? null : MonthlySummary.fromJson(Map<String, dynamic>.from(j["monthSummary"])),
        insights: (j["insights"] == null) ? null : InsightsModel.fromJson(Map<String, dynamic>.from(j["insights"])),
        rules: (rulesRaw is List) ? rulesRaw.map((e) => AutomationRule.fromJson(Map<String, dynamic>.from(e))).toList() : const [],
        expenses: (expRaw is List) ? expRaw.map((e) => ExpenseItem.fromJson(Map<String, dynamic>.from(e))).toList() : const [],
      );
    } catch (_) {
      return const ExpensesResponse(status: "200", message: "ok");
    }
  }
}
