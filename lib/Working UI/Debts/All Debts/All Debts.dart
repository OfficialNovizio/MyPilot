import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Shift/Projection/Projection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/Debt Model.dart';
import '../../Controllers.dart';
import '../Debt Dashboard/Add New Debt.dart';
import '../Debt Dashboard/New Data 2.dart';
import '../Debt Dashboard/New Data.dart';
import 'Combined Data Dashboard.dart';

enum PayoffStrategy { snowball, avalanche, hybrid, manual }

class AllDebts extends StatefulWidget {
  const AllDebts({super.key});

  @override
  State<AllDebts> createState() => _AllDebtsState();
}

class _AllDebtsState extends State<AllDebts> {
  PayoffStrategy _strategy = PayoffStrategy.snowball;
  // Mock data (replace with your models/state)
  final List<_DebtItem> _debts = const [
    _DebtItem(title: 'Car Loan', typeLabel: 'Loan', balance: 7500, apr: 4.2, minPayment: 300, dueDay: 15),
    _DebtItem(title: 'Visa', typeLabel: 'Credit Card', balance: 1200, apr: 18.9, minPayment: 30, dueDay: 7),
    _DebtItem(title: 'Personal Loan', typeLabel: 'Friend / IOU', balance: 2300, apr: 0.0, minPayment: 100, dueDay: 20),
  ];

  // Mock allocation for the pay period (replace with your strategy engine output)
  final List<_AllocationRow> _alloc = const [
    _AllocationRow(name: 'Car Loan', min: 300, extra: 150),
    _AllocationRow(name: 'Visa', min: 30, extra: 200),
    _AllocationRow(name: 'Personal Loan', min: 100, extra: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final totalDebt = _debts.fold<double>(0, (s, d) => s + d.balance);
    final paidPct = 0.38; // mock: 38% paid

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * .04),
        InsightCard(
          title: "Payday buffer",
          leftMain: "\$430",
          leftTag: const Tag(text: "Safe", color: ProjectColors.greenColor),
          leftSub: "• -\$320 this month",
          rightWidget: Container(),
          onTap: () async {
            showCupertinoModalPopup(context: context, builder: (_) => NowToPaydayScreen());
          },
        ),
        SizedBox(height: height * .01),
        DarkCard(
          color: ProjectColors.greenColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: "Total Debt", fontSize: .02, fontWeight: FontWeight.bold),
                  SizedBox(height: height * .01),
                  textWidget(text: "\$11,000", fontSize: .04, fontWeight: FontWeight.bold),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  textWidget(text: '${_debts.length} debts', fontSize: .018),
                  SizedBox(height: height * .01),
                  SizedBox(
                    width: width * .3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: paidPct,
                        minHeight: 8,
                        backgroundColor: ProjectColors.pureBlackColor.withOpacity(0.06),
                        valueColor: const AlwaysStoppedAnimation(ProjectColors.pureBlackColor),
                      ),
                    ),
                  ),
                  SizedBox(height: height * .01),
                  textWidget(text: '${(paidPct * 100).round()}% paid', fontSize: .018),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: height * .01),
        DarkCard(
          child: InkWell(
            onTap: () {
              showCupertinoModalPopup(
                  context: context,
                  builder: (_) => AddDebtBottomSheet(
                        onSave: () {},
                      ));
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  width: height * .05,
                  height: height * .05,
                  decoration: BoxDecoration(
                    color: ProjectColors.whiteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add, color: ProjectColors.whiteColor),
                ),
                SizedBox(width: width * .02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textWidget(text: "Add a Debt", fontSize: .02, color: ProjectColors.whiteColor, fontWeight: FontWeight.bold),
                      SizedBox(height: height * .005),
                      textWidget(text: "Credit Card · Loan · BNPL · Other", color: ProjectColors.whiteColor),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: ProjectColors.whiteColor),
              ],
            ),
          ),
        ),
        SizedBox(height: height * .02),
        Padding(
          padding: EdgeInsets.only(left: width * .02),
          child: textWidget(text: 'Your Debts', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: height * .01),
        DarkCard(
          child: Column(
            children: [
              for (int i = 0; i < _debts.length; i++) ...[
                _DebtRow(
                  debt: _debts[i],
                  onTap: () {
                    // TODO: open edit debt
                  },
                ),
                if (i != _debts.length - 1) Divider(height: 1, color: ProjectColors.whiteColor.withOpacity(0.1)),
              ],
            ],
          ),
        ),

        SizedBox(height: height * .02),
        Padding(
          padding: EdgeInsets.only(left: width * .02),
          child: textWidget(text: 'Strategy', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: height * .01),

        // Strategy chips
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StrategyChips(
                selected: _strategy,
                onChanged: (s) => setState(() => _strategy = s),
              ),
              SizedBox(height: height * .01),
              Text(
                _strategyDescription(_strategy),
                style: TextStyle(
                  color: Colors.black.withOpacity(0.60),
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.black.withOpacity(0.06)),
              const SizedBox(height: 12),

              // Pay period allocation
              Row(
                children: [
                  const Text(
                    'Debt pay period:',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6BFF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'This period',
                      style: TextStyle(
                        color: Color(0xFF2F6BFF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              for (int i = 0; i < _alloc.length; i++) ...[
                _AllocationLine(row: _alloc[i]),
                if (i != _alloc.length - 1) Divider(height: 1, color: Colors.black.withOpacity(0.06)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _strategyDescription(PayoffStrategy s) {
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

  String _money(double v) {
    final n = v.round();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return '\$$buf';
  }
}

/// =====================
/// UI WIDGETS
/// =====================

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
}

class _ActionRowCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black.withOpacity(0.70)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.40)),
          ],
        ),
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final _DebtItem debt;
  final VoidCallback onTap;

  const _DebtRow({
    required this.debt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: debt.title, fontWeight: FontWeight.w900, fontSize: .018, color: ProjectColors.whiteColor),
                  SizedBox(height: height * .005),
                  textWidget(text: _money(debt.balance), fontWeight: FontWeight.w900, fontSize: .018, color: ProjectColors.whiteColor),
                  SizedBox(height: height * .005),
                  textWidget(
                    text:
                        'APR ${debt.apr.toStringAsFixed(debt.apr == 0 ? 0 : 1)}% · Min \$${debt.minPayment.toStringAsFixed(0)} · Due ${debt.dueDay}${_suffix(debt.dueDay)}',
                    color: ProjectColors.whiteColor.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            SizedBox(width: width * .05),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: ProjectColors.whiteColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ProjectColors.whiteColor.withOpacity(0.06)),
              ),
              child: textWidget(text: debt.typeLabel, color: ProjectColors.whiteColor.withOpacity(0.70), fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  String _money(double v) {
    final n = v.round();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return '\$$buf';
  }

  String _suffix(int d) {
    if (d >= 11 && d <= 13) return 'th';
    switch (d % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class _StrategyChips extends StatelessWidget {
  final PayoffStrategy selected;
  final ValueChanged<PayoffStrategy> onChanged;

  const _StrategyChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, DebtSortingTypes type) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            debt.debtType.value = type;
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: height * 0.014),
            decoration: BoxDecoration(
              color: debt.debtType.value == type ? ProjectColors.greenColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: textWidget(
              text: label,
              color: debt.debtType.value == type ? ProjectColors.greenColor : ProjectColors.whiteColor,
              fontWeight: debt.debtType.value == type ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: ProjectColors.whiteColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                chip('SnowBall', DebtSortingTypes.snowBall),
                SizedBox(width: width * 0.01),
                chip('Avalanche', DebtSortingTypes.avalanche),
                SizedBox(width: width * 0.01),
                chip('Hybrid', DebtSortingTypes.hybrid),
                SizedBox(width: width * 0.01),
                chip('Manuel', DebtSortingTypes.manuel),
              ],
            ),
          ),
          // SizedBox(height: height * .02),
          // ...priotizer.visibleTasks!.map((f) {
          //   final data = f['type'] == DebtSortingTypes.snowBall
          //       ? priotizer.mustDoTask
          //       : f['type'] == DebtSortingTypes.avalanche
          //           ? priotizer.atRisk
          //           : f['type'] == DebtSortingTypes.hybrid
          //               ? priotizer.completedTask
          //               : priotizer.ifTime;
          //   return f['type'] != priotizer.taskType.value
          //       ? SizedBox()
          //       : Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             textWidget(
          //               text: f['title'],
          //               fontSize: .02,
          //               color: ProjectColors.whiteColor,
          //               fontWeight: FontWeight.w800,
          //             ),
          //             SizedBox(height: height * .01),
          //             textWidget(
          //               text: f['subtitle'],
          //               fontSize: .016,
          //               color: ProjectColors.whiteColor,
          //               needContainer: true,
          //               cWidth: .8,
          //             ),
          //             // ...data.map((items) => TaskBody(task: items)),
          //           ],
          //         );
          // }),
        ],
      ),
    );
  }
}

class _AllocationLine extends StatelessWidget {
  final _AllocationRow row;
  const _AllocationLine({required this.row});

  @override
  Widget build(BuildContext context) {
    final total = row.min + row.extra;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '+ Extra ${row.extra}',
            style: TextStyle(
              color: Colors.black.withOpacity(0.60),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '= \$${total}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// DATA
/// =====================

class _DebtItem {
  final String title;
  final String typeLabel;
  final double balance;
  final double apr;
  final double minPayment;
  final int dueDay;

  const _DebtItem({
    required this.title,
    required this.typeLabel,
    required this.balance,
    required this.apr,
    required this.minPayment,
    required this.dueDay,
  });
}

class _AllocationRow {
  final String name;
  final int min;
  final int extra;

  const _AllocationRow({
    required this.name,
    required this.min,
    required this.extra,
  });
}
