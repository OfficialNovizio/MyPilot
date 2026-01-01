import '../Working UI/Shift/Projection/Projection Getx.dart';

enum GoalType { save, debt, surplus }

enum SavingFrequency { weekly, biweekly, monthly }

enum GoalPriority { high, medium, low }

class ProjectionModel {
  int? status;
  String? message;
  List<GoalItem>? data;

  ProjectionModel({this.status, this.message, this.data});

  ProjectionModel.fromJson(Map<String, dynamic>? json) {
    final s = json?['status'];
    if (s is num) status = s.toInt();

    message = json?['message'];

    final list = json?['data'] as List?;
    if (list != null) {
      data = <GoalItem>[];
      for (final v in list) {
        data!.add(GoalItem.fromJson(v is Map<String, dynamic> ? v : null));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['status'] = status;
    m['message'] = message;
    if (data != null) m['data'] = data!.map((e) => e.toJson()).toList();
    return m;
  }
}

class GoalItem {
  String? id;
  GoalType? type;
  GoalPriority? priority;
  SavingFrequency? frequency;
  String? title;
  double? amount;
  DateTime? targetDate;
  String? description;
  double? requiredPerPeriod;
  int? periodsLeft;

  GoalItem({
    this.id,
    this.type,
    this.priority,
    this.frequency,
    this.title,
    this.amount,
    this.targetDate,
    this.description,
    this.requiredPerPeriod,
    this.periodsLeft,
  });

  GoalItem.fromJson(Map<String, dynamic>? json) {
    id = json?['id'];
    title = json?['title'];
    description = json?['description'];

    final a = json?['amount'];
    if (a is num) amount = a.toDouble();

    final r = json?['requiredPerPeriod'];
    if (r is num) requiredPerPeriod = r.toDouble();

    final p = json?['periodsLeft'];
    if (p is num) periodsLeft = p.toInt();

    final d = json?['targetDate'];
    if (d is String) targetDate = DateTime.tryParse(d);

    final t = json?['type'];
    if (t is String) {
      for (final e in GoalType.values) {
        if (e.name == t) {
          type = e;
          break;
        }
      }
    }

    final pr = json?['priority'];
    if (pr is String) {
      for (final e in GoalPriority.values) {
        if (e.name == pr) {
          priority = e;
          break;
        }
      }
    }

    final f = json?['frequency'];
    if (f is String) {
      for (final e in SavingFrequency.values) {
        if (e.name == f) {
          frequency = e;
          break;
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['id'] = id;
    m['type'] = type?.name;
    m['priority'] = priority?.name;
    m['frequency'] = frequency?.name;
    m['title'] = title;
    m['amount'] = amount;
    m['targetDate'] = targetDate?.toIso8601String();
    m['description'] = description;
    m['requiredPerPeriod'] = requiredPerPeriod;
    m['periodsLeft'] = periodsLeft;
    return m;
  }
}

// ---------- helpers (null-safe + tolerant) ----------

class RequiredPlan {
  final double perPeriod;
  final int periods;
  RequiredPlan(this.perPeriod, this.periods);
}
