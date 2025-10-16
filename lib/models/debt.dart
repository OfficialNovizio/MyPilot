import 'dart:math';

enum DebtType { installment, revolving, iou }

class DebtAccount {
  String id;
  String name;
  DebtType type;
  double principal; // current balance
  double apr; // annual percentage rate (e.g., 19.99)
  double minPayment; // monthly minimum (installment fixed payment or card minimum)
  int dueDay; // 1..28
  double extraPerMonth;
  String? notes;

  DebtAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.principal,
    required this.apr,
    required this.minPayment,
    required this.dueDay,
    this.extraPerMonth = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'principal': principal,
        'apr': apr,
        'minPayment': minPayment,
        'dueDay': dueDay,
        'extraPerMonth': extraPerMonth,
        'notes': notes,
      };

  static DebtAccount fromJson(Map<String, dynamic> m) => DebtAccount(
        id: m['id'],
        name: m['name'],
        type: DebtType.values[(m['type'] ?? 0) as int],
        principal: (m['principal'] ?? 0).toDouble(),
        apr: (m['apr'] ?? 0).toDouble(),
        minPayment: (m['minPayment'] ?? 0).toDouble(),
        dueDay: (m['dueDay'] ?? 1) as int,
        extraPerMonth: (m['extraPerMonth'] ?? 0).toDouble(),
        notes: m['notes'],
      );
}

class PlanRow {
  DateTime month;
  Map<String, double> payments; // debtId -> payment
  Map<String, double> interest; // debtId -> interest
  Map<String, double> balances; // debtId -> end balance
  double totalPayment;
  double totalInterest;
  PlanRow({
    required this.month,
    required this.payments,
    required this.interest,
    required this.balances,
    required this.totalPayment,
    required this.totalInterest,
  });
}

enum Strategy { snowball, avalanche }

class PlanSummary {
  List<PlanRow> rows;
  int months;
  double interest;
  DateTime? payoffDate;
  PlanSummary({required this.rows, required this.months, required this.interest, this.payoffDate});
}

// naive interest calc: APR/12 * balance; clamp not below zero
double _monthlyRate(double apr) => apr <= 0 ? 0 : (apr / 100.0) / 12.0;

PlanSummary buildPlan({
  required List<DebtAccount> debts,
  required double monthlyBudget,
  Strategy strategy = Strategy.snowball,
  DateTime? start,
}) {
  final startMonth = DateTime((start ?? DateTime.now()).year, (start ?? DateTime.now()).month, 1);
  final ds = [
    for (var d in debts)
      DebtAccount(
          id: d.id,
          name: d.name,
          type: d.type,
          principal: d.principal,
          apr: d.apr,
          minPayment: d.minPayment,
          dueDay: d.dueDay,
          extraPerMonth: d.extraPerMonth,
          notes: d.notes)
  ];

  double totalInterest = 0.0;
  final rows = <PlanRow>[];
  var cur = startMonth;
  int guard = 0;

  List<DebtAccount> order() {
    final list = [...ds.where((d) => d.principal > 0.01)];
    list.sort((a, b) {
      if (strategy == Strategy.snowball) {
        return a.principal.compareTo(b.principal);
      } else {
        return b.apr.compareTo(a.apr);
      }
    });
    return list;
  }

  while (ds.any((d) => d.principal > 0.01) && guard < 600) {
    guard++;
    final pays = <String, double>{};
    final ints = <String, double>{};
    final bals = <String, double>{};

    // minimums first
    double pot = monthlyBudget;
    for (final d in ds) {
      if (d.principal <= 0.01) {
        pays[d.id] = 0;
        continue;
      }
      final minPay = d.minPayment.clamp(0, d.principal);
      pays[d.id] = minPay.toDouble();
      pot -= minPay;
    }
    // distribute extra
    final q = order();
    for (final d in q) {
      if (pot <= 0) break;
      if (d.principal <= 0.01) continue;
      final add = pot.clamp(0, d.principal - pays[d.id]!);
      pays[d.id] = (pays[d.id] ?? 0) + add;
      pot -= add;
    }

    // apply interest & payments
    double monthInterest = 0.0;
    for (final d in ds) {
      final r = _monthlyRate(d.apr);
      final interest = (d.principal * r);
      final pay = (pays[d.id] ?? 0);
      double newBal = (d.principal + interest - pay);
      if (newBal < 0) {
        // overshoot goes nowhere
        newBal = 0;
      }
      d.principal = newBal;
      ints[d.id] = interest;
      bals[d.id] = newBal;
      monthInterest += interest;
    }
    totalInterest += monthInterest;
    rows.add(PlanRow(
      month: cur,
      payments: pays,
      interest: ints,
      balances: bals,
      totalPayment: pays.values.fold(0.0, (a, b) => a + b),
      totalInterest: monthInterest,
    ));
    cur = DateTime(cur.year, cur.month + 1, 1);
  }

  return PlanSummary(
    rows: rows,
    months: rows.length,
    interest: totalInterest,
    payoffDate: rows.isEmpty ? null : DateTime(cur.year, cur.month, 1),
  );
}
