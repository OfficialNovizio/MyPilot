import 'dart:convert';


enum ExpenseType { fixed, variable, subscription, bill }

enum ExpenseFrequency { perPaycheque, weekly, monthly, quarterly, yearly }

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', ''));
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _toBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  final s = v.toString().toLowerCase().trim();
  if (s == "true" || s == "1" || s == "yes") return true;
  if (s == "false" || s == "0" || s == "no") return false;
  return fallback;
}

class ExpensesResponse {
  final String status;
  final String message;

  final MonthlySummary? monthSummary;
  final PaydayBuffer? paydayBuffer;

  final List<ExpenseItem> expenses; // your fixed/variable/subscription/bill list
  final InsightsModel? insights; // safe-to-spend + next move + leaks/spikes
  final List<AutomationRule> rules; // automation rules list

  const ExpensesResponse({
    required this.status,
    required this.message,
    this.monthSummary,
    this.paydayBuffer,
    this.insights,
    this.rules = const [],
    this.expenses = const [],
  });

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "monthSummary": monthSummary?.toJson(),
        "paydayBuffer": paydayBuffer?.toJson(),
        "insights": insights?.toJson(),
        "rules": rules.map((e) => e.toJson()).toList(),
        "expenses": expenses.map((e) => e.toJson()).toList(),
      };

  factory ExpensesResponse.fromJson(Map<String, dynamic> json) {
    final expRaw = json["expenses"];
    final rulesRaw = json["rules"];

    return ExpensesResponse(
      status: (json["status"] ?? "").toString(),
      message: (json["message"] ?? "").toString(),
      monthSummary: json["monthSummary"] is Map ? MonthlySummary.fromJson(Map<String, dynamic>.from(json["monthSummary"])) : null,
      paydayBuffer: json["paydayBuffer"] is Map ? PaydayBuffer.fromJson(Map<String, dynamic>.from(json["paydayBuffer"])) : null,
      insights: json["insights"] is Map ? InsightsModel.fromJson(Map<String, dynamic>.from(json["insights"])) : null,
      rules: rulesRaw is List ? rulesRaw.map((e) => AutomationRule.fromJson(Map<String, dynamic>.from(e))).toList() : <AutomationRule>[],
      expenses: expRaw is List ? expRaw.map((e) => ExpenseItem.fromJson(Map<String, dynamic>.from(e))).toList() : <ExpenseItem>[],
    );
  }

  // local storage helpers
  String encode() => jsonEncode(toJson());

  static ExpensesResponse decode(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return ExpensesResponse.fromJson(map);
    } catch (_) {}
    return const ExpensesResponse(status: "200", message: "ok");
  }
}

class ExpenseItem {
  final String id;

  final String name; // Rent / Phone Plan
  final double amount; // 1500
  final String? notes; // optional

  final String category;
  final String? accountId; // link to your card/bank list
  final String? accountName; // link to your card/bank list

  final int dateMs; // expense date
  final int? dueDay; // for monthly bills: 1..31 (like “Due 1st”)

  final bool isEssential; // essential toggle
  final String frequency; // monthly / weekly / one_time etc (string)

  final bool isActive; // allow disabling recurring
  final int createdAtMs;

  const ExpenseItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.accountName,
    this.notes,
    required this.category,
    this.accountId,
    required this.dateMs,
    this.dueDay,
    required this.isEssential,
    required this.frequency,
    this.isActive = true,
    required this.createdAtMs,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "amount": amount,
        "notes": notes,
        "category": category,
        "accountId": accountId,
        "accountName": accountName,
        "dateMs": dateMs,
        "dueDay": dueDay,
        "isEssential": isEssential,
        "frequency": frequency,
        "isActive": isActive,
        "createdAtMs": createdAtMs,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      amount: _toDouble(json["amount"]) ?? 0,
      notes: json["notes"]?.toString(),
      category: (json["category"] ?? "").toString(),
      accountId: json["accountId"]?.toString(),
      accountName: json["accountName"]?.toString(),
      dateMs: _toInt(json["dateMs"]) ?? 0,
      dueDay: _toInt(json["dueDay"]),
      isEssential: _toBool(json["isEssential"]),
      frequency: (json["frequency"] ?? "").toString(),
      isActive: _toBool(json["isActive"], fallback: true),
      createdAtMs: _toInt(json["createdAtMs"]) ?? 0,
    );
  }
}

class PaydayBuffer {
  final double amount; // $430
  final String tag; // Safe / Tight / High risk (string)
  final double? deltaMonth; // -$320 this month

  const PaydayBuffer({required this.amount, required this.tag, this.deltaMonth});

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "tag": tag,
        "deltaMonth": deltaMonth,
      };

  factory PaydayBuffer.fromJson(Map<String, dynamic> json) => PaydayBuffer(
        amount: _toDouble(json["amount"]) ?? 0,
        tag: (json["tag"] ?? "").toString(),
        deltaMonth: _toDouble(json["deltaMonth"]),
      );
}

class MonthlySummary {
  final double fixed;
  final double variable;
  final double total;
  final String? note; // “Based on your monthly & per-paycheque expenses”

  const MonthlySummary({
    required this.fixed,
    required this.variable,
    required this.total,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        "fixed": fixed,
        "variable": variable,
        "total": total,
        "note": note,
      };

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        fixed: _toDouble(json["fixed"]) ?? 0,
        variable: _toDouble(json["variable"]) ?? 0,
        total: _toDouble(json["total"]) ?? 0,
        note: json["note"]?.toString(),
      );
}

class InsightsModel {
  final SafeToSpend safeToSpend;
  final NextBestMove? nextBestMove;
  final List<LeakOrSpike> leaksAndSpikes;

  final ForecastRisk? forecastRisk;
  final CutsChecklist? cutsChecklist;

  const InsightsModel({
    required this.safeToSpend,
    this.nextBestMove,
    this.leaksAndSpikes = const [],
    this.forecastRisk,
    this.cutsChecklist,
  });

  Map<String, dynamic> toJson() => {
        "safeToSpend": safeToSpend.toJson(),
        "nextBestMove": nextBestMove?.toJson(),
        "leaksAndSpikes": leaksAndSpikes.map((e) => e.toJson()).toList(),
        "forecastRisk": forecastRisk?.toJson(),
        "cutsChecklist": cutsChecklist?.toJson(),
      };

  factory InsightsModel.fromJson(Map<String, dynamic> json) {
    final ls = json["leaksAndSpikes"];
    return InsightsModel(
      safeToSpend: SafeToSpend.fromJson(Map<String, dynamic>.from(json["safeToSpend"] ?? {})),
      nextBestMove: json["nextBestMove"] is Map ? NextBestMove.fromJson(Map<String, dynamic>.from(json["nextBestMove"])) : null,
      leaksAndSpikes: ls is List ? ls.map((e) => LeakOrSpike.fromJson(Map<String, dynamic>.from(e))).toList() : <LeakOrSpike>[],
      forecastRisk: json["forecastRisk"] is Map ? ForecastRisk.fromJson(Map<String, dynamic>.from(json["forecastRisk"])) : null,
      cutsChecklist: json["cutsChecklist"] is Map ? CutsChecklist.fromJson(Map<String, dynamic>.from(json["cutsChecklist"])) : null,
    );
  }
}

class SafeToSpend {
  final double amount; // $299
  final int untilDateMs; // “until 1/8”
  final double expectedIncome;
  final double billsDue;
  final double debtMinimums;
  final double bufferTarget;

  const SafeToSpend({
    required this.amount,
    required this.untilDateMs,
    required this.expectedIncome,
    required this.billsDue,
    required this.debtMinimums,
    required this.bufferTarget,
  });

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "untilDateMs": untilDateMs,
        "expectedIncome": expectedIncome,
        "billsDue": billsDue,
        "debtMinimums": debtMinimums,
        "bufferTarget": bufferTarget,
      };

  factory SafeToSpend.fromJson(Map<String, dynamic> json) => SafeToSpend(
        amount: _toDouble(json["amount"]) ?? 0,
        untilDateMs: _toInt(json["untilDateMs"]) ?? 0,
        expectedIncome: _toDouble(json["expectedIncome"]) ?? 0,
        billsDue: _toDouble(json["billsDue"]) ?? 0,
        debtMinimums: _toDouble(json["debtMinimums"]) ?? 0,
        bufferTarget: _toDouble(json["bufferTarget"]) ?? 0,
      );
}

class NextBestMove {
  final String title; // “Reserve $300 for Car Loan”
  final String description;
  final double actionAmount; // 300
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

  factory NextBestMove.fromJson(Map<String, dynamic> json) => NextBestMove(
        title: (json["title"] ?? "").toString(),
        description: (json["description"] ?? "").toString(),
        actionAmount: _toDouble(json["actionAmount"]) ?? 0,
        dueDateMs: _toInt(json["dueDateMs"]) ?? 0,
      );
}

class LeakOrSpike {
  final String kind; // "recurring" | "spike"
  final String title; // “New recurring: Month • $14.99/mo”
  final String subtitle; // details
  final String? confidence; // “High”
  final int createdAtMs;

  const LeakOrSpike({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.confidence,
    required this.createdAtMs,
  });

  Map<String, dynamic> toJson() => {
        "kind": kind,
        "title": title,
        "subtitle": subtitle,
        "confidence": confidence,
        "createdAtMs": createdAtMs,
      };

  factory LeakOrSpike.fromJson(Map<String, dynamic> json) => LeakOrSpike(
        kind: (json["kind"] ?? "").toString(),
        title: (json["title"] ?? "").toString(),
        subtitle: (json["subtitle"] ?? "").toString(),
        confidence: json["confidence"]?.toString(),
        createdAtMs: _toInt(json["createdAtMs"]) ?? 0,
      );
}

class ForecastRisk {
  final String level; // High / Tight / Safe
  final String title; // “Forecast risk”
  final String description; // “Jan 2–5 is tight…”
  final List<String> actions; // ["Move", "Cut"]

  const ForecastRisk({
    required this.level,
    required this.title,
    required this.description,
    this.actions = const [],
  });

  Map<String, dynamic> toJson() => {
        "level": level,
        "title": title,
        "description": description,
        "actions": actions,
      };

  factory ForecastRisk.fromJson(Map<String, dynamic> json) => ForecastRisk(
        level: (json["level"] ?? "").toString(),
        title: (json["title"] ?? "").toString(),
        description: (json["description"] ?? "").toString(),
        actions: (json["actions"] is List) ? (json["actions"] as List).map((e) => e.toString()).toList() : <String>[],
      );
}

class CutsChecklist {
  final String title; // “Save $50 fastest”
  final String tag; // “Tight”
  final List<String> bullets;

  const CutsChecklist({
    required this.title,
    required this.tag,
    this.bullets = const [],
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "tag": tag,
        "bullets": bullets,
      };

  factory CutsChecklist.fromJson(Map<String, dynamic> json) => CutsChecklist(
        title: (json["title"] ?? "").toString(),
        tag: (json["tag"] ?? "").toString(),
        bullets: (json["bullets"] is List) ? (json["bullets"] as List).map((e) => e.toString()).toList() : <String>[],
      );
}

class AutomationRule {
  final String id;
  final String title; // “Keep buffer ≥ $200”
  final String description; // “Blocks extra payments when tight.”
  final bool enabled;
  final int createdAtMs;

  const AutomationRule({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    required this.createdAtMs,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "enabled": enabled,
        "createdAtMs": createdAtMs,
      };

  factory AutomationRule.fromJson(Map<String, dynamic> json) => AutomationRule(
        id: (json["id"] ?? "").toString(),
        title: (json["title"] ?? "").toString(),
        description: (json["description"] ?? "").toString(),
        enabled: _toBool(json["enabled"], fallback: true),
        createdAtMs: _toInt(json["createdAtMs"]) ?? 0,
      );
}
