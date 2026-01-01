import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Constants.dart';

/// ===============================
/// MODELS
/// ===============================

enum ExpenseType { fixed, variable, subscription, bill }

enum ExpenseFrequency { perPaycheque, weekly, monthly, quarterly, yearly }

class ExpenseModel {
  final String id;
  final String name;
  final double amount;
  final ExpenseType type;
  final ExpenseFrequency frequency;
  final bool isEssential;

  // Optional (handy for bills/subscriptions/fixed)
  final int? dueDay; // 1–31

  // Optional (for list icon mapping)
  final IconData icon;

  const ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.isEssential,
    required this.icon,
    this.dueDay,
  });

  ExpenseModel copyWith({
    String? id,
    String? name,
    double? amount,
    ExpenseType? type,
    ExpenseFrequency? frequency,
    bool? isEssential,
    int? dueDay,
    IconData? icon,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      isEssential: isEssential ?? this.isEssential,
      dueDay: dueDay ?? this.dueDay,
      icon: icon ?? this.icon,
    );
  }
}

/// ===============================
/// SCREEN 1: EXPENSES
/// ===============================

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final List<ExpenseModel> _expenses = [
    const ExpenseModel(
      id: '1',
      name: 'Rent',
      amount: 1500,
      type: ExpenseType.fixed,
      frequency: ExpenseFrequency.monthly,
      dueDay: 1,
      isEssential: true,
      icon: Icons.home_rounded,
    ),
    const ExpenseModel(
      id: '2',
      name: 'Phone Plan',
      amount: 45,
      type: ExpenseType.fixed,
      frequency: ExpenseFrequency.monthly,
      dueDay: 15,
      isEssential: true,
      icon: Icons.phone_iphone_rounded,
    ),
    const ExpenseModel(
      id: '3',
      name: 'Wi-Fi',
      amount: 80,
      type: ExpenseType.fixed,
      frequency: ExpenseFrequency.monthly,
      dueDay: 12,
      isEssential: true,
      icon: Icons.wifi_rounded,
    ),
    const ExpenseModel(
      id: '4',
      name: 'Groceries',
      amount: 150,
      type: ExpenseType.variable,
      frequency: ExpenseFrequency.perPaycheque,
      isEssential: true,
      icon: Icons.shopping_cart_rounded,
    ),
    const ExpenseModel(
      id: '5',
      name: 'Transport',
      amount: 40,
      type: ExpenseType.variable,
      frequency: ExpenseFrequency.perPaycheque,
      isEssential: true,
      icon: Icons.directions_car_rounded,
    ),
    const ExpenseModel(
      id: '6',
      name: 'Eating Out',
      amount: 80,
      type: ExpenseType.variable,
      frequency: ExpenseFrequency.monthly,
      isEssential: false,
      icon: Icons.local_dining_rounded,
    ),
  ];

  // Simple insight mock (wire later)
  final Map<String, int> _insights = const {
    'Groceries': -35, // down
    'Transport': 20, // up
  };

  @override
  Widget build(BuildContext context) {
    final fixed = _sumWhere((e) => e.type == ExpenseType.fixed || e.type == ExpenseType.bill);
    final variable = _sumWhere((e) => e.type == ExpenseType.variable);
    final subs = _sumWhere((e) => e.type == ExpenseType.subscription);
    final total = fixed + variable + subs;

    // progress bar = fixed share of total
    final progress = total <= 0 ? 0.0 : (fixed / total).clamp(0.0, 1.0);

    final fixedList = _expenses.where((e) => e.type == ExpenseType.fixed || e.type == ExpenseType.bill).toList();
    final variableList = _expenses.where((e) => e.type == ExpenseType.variable || e.type == ExpenseType.subscription).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * .04),
        DarkCard(
          color: ProjectColors.greenColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget(text: 'This Month', fontSize: .02, fontWeight: FontWeight.w900),
              SizedBox(height: height * .01),
              Row(
                children: [
                  _MiniStat(title: 'Fixed', value: _money(fixed)),
                  SizedBox(width: width * .1),
                  _MiniStat(title: 'Variable', value: _money(variable)),
                  SizedBox(width: width * .1),
                  _MiniStat(title: 'Total', value: _money(total)),
                ],
              ),
              SizedBox(height: height * .01),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: ProjectColors.pureBlackColor.withOpacity(0.06),
                  valueColor: const AlwaysStoppedAnimation(ProjectColors.pureBlackColor),
                ),
              ),
              SizedBox(height: height * .01),
              textWidget(text: 'Based on your monthly & per-paycheque expenses', fontSize: .018),
            ],
          ),
        ),
        SizedBox(height: height * .01),
        DarkCard(
          child: InkWell(
            onTap: () {},
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
                      textWidget(text: "Add an Expense", fontSize: .02, color: ProjectColors.whiteColor, fontWeight: FontWeight.bold),
                      SizedBox(height: height * .005),
                      textWidget(text: 'Fixed · Variable · Subscription · Bill', color: ProjectColors.whiteColor),
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
          child: textWidget(text: 'Fixed Expenses (Monthly)', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: height * .01),
        DarkCard(
          child: Column(
            children: [
              for (int i = 0; i < fixedList.length; i++) ...[
                _ExpenseRow(
                  expense: fixedList[i],
                  rightText: '${_money(fixedList[i].amount)} / month',
                  onTap: () => _openEditExpense(fixedList[i]),
                ),
                if (i != fixedList.length - 1) Divider(height: 1, color: ProjectColors.whiteColor.withOpacity(0.1)),
              ]
            ],
          ),
        ),
        SizedBox(height: height * .02),
        Padding(
          padding: EdgeInsets.only(left: width * .02),
          child: textWidget(text: 'Variable Expenses', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: height * .01),
        DarkCard(
          child: Column(
            children: [
              for (int i = 0; i < variableList.length; i++) ...[
                _ExpenseRow(
                  expense: variableList[i],
                  rightText: _freqLabel(variableList[i].frequency, variableList[i].amount),
                  onTap: () => _openEditExpense(variableList[i]),
                  insightDelta: _insights[variableList[i].name],
                ),
                if (i != variableList.length - 1) Divider(height: 1, color: ProjectColors.whiteColor.withOpacity(0.1)),
              ]
            ],
          ),
        ),
        SizedBox(height: height * .02),
        // Padding(
        //   padding: EdgeInsets.only(left: width * .02),
        //   child: textWidget(text: 'Spending Insights', color: ProjectColors.whiteColor, fontSize: .025, fontWeight: FontWeight.bold),
        // ),
        // const SizedBox(height: 10),
        // _Card(
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       _InsightLine(title: 'Groceries', delta: _insights['Groceries'] ?? 0),
        //       const SizedBox(height: 8),
        //       _InsightLine(title: 'Transport', delta: _insights['Transport'] ?? 0),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  double _sumWhere(bool Function(ExpenseModel e) test) {
    return _expenses.where(test).fold<double>(0.0, (s, e) => s + e.amount);
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.of(context).push<ExpenseModel>(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (result != null) {
      setState(() {
        _expenses.insert(0, result);
      });
    }
  }

  Future<void> _openEditExpense(ExpenseModel e) async {
    final result = await Navigator.of(context).push<ExpenseModel>(
      MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: e)),
    );
    if (result != null) {
      setState(() {
        final idx = _expenses.indexWhere((x) => x.id == e.id);
        if (idx >= 0) _expenses[idx] = result;
      });
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

  String _freqLabel(ExpenseFrequency f, double amount) {
    switch (f) {
      case ExpenseFrequency.perPaycheque:
        return '${_money(amount)} per paycheque';
      case ExpenseFrequency.weekly:
        return '${_money(amount)} / week';
      case ExpenseFrequency.monthly:
        return '${_money(amount)} / month';
      case ExpenseFrequency.quarterly:
        return '${_money(amount)} / quarter';
      case ExpenseFrequency.yearly:
        return '${_money(amount)} / year';
    }
  }
}

/// ===============================
/// SCREEN 2: ADD / EDIT EXPENSE
/// ===============================

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? existing;

  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final TextEditingController _name;
  late final TextEditingController _amount;

  ExpenseType _type = ExpenseType.variable;
  ExpenseFrequency _frequency = ExpenseFrequency.monthly;
  bool _essential = true;
  int? _dueDay;

  IconData _icon = Icons.receipt_long_rounded;

  @override
  void initState() {
    super.initState();

    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? 'Lunch');
    _amount = TextEditingController(text: e != null ? e.amount.toStringAsFixed(2) : '15.00');

    _type = e?.type ?? ExpenseType.variable;
    _frequency = e?.frequency ?? ExpenseFrequency.monthly;
    _essential = e?.isEssential ?? true;
    _dueDay = e?.dueDay;
    _icon = e?.icon ?? Icons.fastfood_rounded;

    _applyTypeDefaults();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _canSave() ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _canSave() ? const Color(0xFF2F6BFF) : Colors.black.withOpacity(0.30),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // TYPE (segmented)
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _SegmentedType(
                  value: _type,
                  onChanged: (t) {
                    setState(() {
                      _type = t;
                      _applyTypeDefaults();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // DETAILS
          const Text('Details', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _FormRow(
                  label: 'Name',
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g., Rent, Groceries, Netflix',
                    ),
                  ),
                ),
                _thinDivider(),
                _FormRow(
                  label: 'Amount',
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FREQUENCY
          const Text('Frequency', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _TapRow(
                  title: _frequencyTitle(),
                  onTap: _pickFrequency,
                ),
                if (_showsDueDay()) ...[
                  _thinDivider(),
                  _TapRow(
                    title: _dueDay == null ? 'Due day (optional)' : 'Due day: ${_dueDay!}',
                    onTap: _pickDueDay,
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ESSENTIALS TOGGLE
          const Text('Essentials', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Essentials', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Toggle on to include this expense in your\nEssentials while budgeting',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _essential,
                  activeColor: const Color(0xFF2F6BFF),
                  onChanged: (v) => setState(() => _essential = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _showsDueDay() {
    return _type == ExpenseType.fixed || _type == ExpenseType.bill || _type == ExpenseType.subscription;
  }

  void _applyTypeDefaults() {
    // smart defaults (hybrid)
    switch (_type) {
      case ExpenseType.fixed:
      case ExpenseType.bill:
        _frequency = ExpenseFrequency.monthly;
        _essential = true;
        break;
      case ExpenseType.subscription:
        _frequency = ExpenseFrequency.monthly;
        _essential = true;
        break;
      case ExpenseType.variable:
        // variable often per paycheque in your app
        _frequency = ExpenseFrequency.perPaycheque;
        break;
    }
  }

  bool _canSave() {
    final nameOk = _name.text.trim().isNotEmpty;
    final amt = double.tryParse(_amount.text.trim());
    final amtOk = amt != null && amt > 0;
    return nameOk && amtOk;
  }

  void _save() {
    final amt = double.parse(_amount.text.trim());
    final id = widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    // icon guess based on name (simple; replace with category picker later)
    final inferredIcon = _guessIcon(_name.text.trim());

    final model = ExpenseModel(
      id: id,
      name: _name.text.trim(),
      amount: amt,
      type: _type,
      frequency: _frequency,
      isEssential: _essential,
      dueDay: _dueDay,
      icon: inferredIcon,
    );

    Navigator.pop(context, model);
  }

  IconData _guessIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('rent') || n.contains('mortgage')) return Icons.home_rounded;
    if (n.contains('phone')) return Icons.phone_iphone_rounded;
    if (n.contains('wifi') || n.contains('internet')) return Icons.wifi_rounded;
    if (n.contains('groc')) return Icons.shopping_cart_rounded;
    if (n.contains('transport') || n.contains('gas') || n.contains('fuel')) return Icons.directions_car_rounded;
    if (n.contains('eat') || n.contains('lunch') || n.contains('dinner')) return Icons.local_dining_rounded;
    if (n.contains('netflix') || n.contains('spotify') || n.contains('sub')) return Icons.subscriptions_rounded;
    return _icon;
  }

  String _frequencyTitle() {
    switch (_frequency) {
      case ExpenseFrequency.perPaycheque:
        return 'Per paycheque';
      case ExpenseFrequency.weekly:
        return 'Weekly';
      case ExpenseFrequency.monthly:
        return 'Monthly';
      case ExpenseFrequency.quarterly:
        return 'Quarterly';
      case ExpenseFrequency.yearly:
        return 'Yearly';
    }
  }

  Future<void> _pickFrequency() async {
    final picked = await showModalBottomSheet<ExpenseFrequency>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        final items = <ExpenseFrequency>[
          ExpenseFrequency.perPaycheque,
          ExpenseFrequency.weekly,
          ExpenseFrequency.monthly,
          if (_type == ExpenseType.subscription) ExpenseFrequency.quarterly,
          if (_type == ExpenseType.subscription) ExpenseFrequency.yearly,
        ];

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text('Select frequency', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 10),
              for (final f in items)
                ListTile(
                  title: Text(_freqLabel(f)),
                  trailing: f == _frequency ? const Icon(Icons.check, color: Color(0xFF2F6BFF)) : null,
                  onTap: () => Navigator.pop(context, f),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (picked != null) setState(() => _frequency = picked);
  }

  Future<void> _pickDueDay() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text('Select due day', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 10),
              for (int d = 1; d <= 31; d++)
                ListTile(
                  title: Text('$d'),
                  trailing: d == _dueDay ? const Icon(Icons.check, color: Color(0xFF2F6BFF)) : null,
                  onTap: () => Navigator.pop(context, d),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (picked != null) setState(() => _dueDay = picked);
  }

  String _freqLabel(ExpenseFrequency f) {
    switch (f) {
      case ExpenseFrequency.perPaycheque:
        return 'Per paycheque';
      case ExpenseFrequency.weekly:
        return 'Weekly';
      case ExpenseFrequency.monthly:
        return 'Monthly';
      case ExpenseFrequency.quarterly:
        return 'Quarterly';
      case ExpenseFrequency.yearly:
        return 'Yearly';
    }
  }

  Widget _thinDivider() => Divider(height: 1, color: Colors.black.withOpacity(0.06));
}

/// ===============================
/// SMALL COMPONENTS
/// ===============================

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({
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
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(text: title, fontWeight: FontWeight.w700, fontSize: .018),
        SizedBox(height: height * .005),
        textWidget(text: value, fontWeight: FontWeight.w900, fontSize: .025),
      ],
    );
  }
}

class _SlimAddCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SlimAddCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
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
                color: const Color(0xFF2F6BFF).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Color(0xFF2F6BFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
            Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final ExpenseModel expense;
  final String rightText;
  final VoidCallback onTap;
  final int? insightDelta; // optional: +/- vs last period

  const _ExpenseRow({
    required this.expense,
    required this.rightText,
    required this.onTap,
    this.insightDelta,
  });

  @override
  Widget build(BuildContext context) {
    final delta = insightDelta;
    final deltaWidget = delta == null
        ? const SizedBox.shrink()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                delta >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: height * .02,
                color: delta >= 0 ? ProjectColors.greenColor : Colors.blue,
              ),
              const SizedBox(width: 2),
              textWidget(
                text: '\$${delta.abs()}',
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor,
              ),
              const SizedBox(width: 8),
            ],
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .014),
        child: Row(
          children: [
            Container(
              width: height * .04,
              height: height * .04,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(expense.icon, color: ProjectColors.whiteColor.withOpacity(0.70)),
            ),
            SizedBox(width: width * .015),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: expense.name, fontWeight: FontWeight.w900, color: ProjectColors.whiteColor, fontSize: .02),
                  // SizedBox(height: height * .01),
                  textWidget(text: _subLabel(expense), color: ProjectColors.whiteColor, fontSize: 0.018),
                ],
              ),
            ),
            deltaWidget,
            textWidget(text: rightText, color: ProjectColors.whiteColor, fontSize: 0.02),
          ],
        ),
      ),
    );
  }

  String _subLabel(ExpenseModel e) {
    if (e.type == ExpenseType.fixed || e.type == ExpenseType.bill || e.type == ExpenseType.subscription) {
      if (e.dueDay != null) return 'Due ${e.dueDay}${_suffix(e.dueDay!)}';
      return 'Recurring';
    }
    return 'Budget';
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

class _InsightLine extends StatelessWidget {
  final String title;
  final int delta;
  const _InsightLine({required this.title, required this.delta});

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 18,
          color: up ? Colors.green : Colors.blue,
        ),
        const SizedBox(width: 4),
        Text(
          '\$${delta.abs()}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(0.65),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          up ? 'vs last period' : 'vs last period',
          style: TextStyle(color: Colors.black.withOpacity(0.45), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _TapRow({
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _SegmentedType extends StatelessWidget {
  final ExpenseType value;
  final ValueChanged<ExpenseType> onChanged;

  const _SegmentedType({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Cupertino segmented (looks like your mock)
    return CupertinoSegmentedControl<ExpenseType>(
      groupValue: value,
      onValueChanged: onChanged,
      selectedColor: const Color(0xFF2F6BFF),
      unselectedColor: Colors.white,
      borderColor: Colors.black.withOpacity(0.08),
      pressedColor: const Color(0xFF2F6BFF).withOpacity(0.12),
      children: const {
        ExpenseType.fixed: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), child: Text('Fixed')),
        ExpenseType.variable: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), child: Text('Variable')),
        ExpenseType.subscription: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), child: Text('Subscription')),
        ExpenseType.bill: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), child: Text('Bill')),
      },
    );
  }
}
