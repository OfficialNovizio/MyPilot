
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/debt_controller.dart';
import '../../models/debt.dart';
import '../../utils/money.dart';
import 'dart:math';

class DebtHome extends StatelessWidget {
  const DebtHome({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtController>();
    return Obx(() {
      final total = c.debts.fold<double>(0,(a,b)=>a+b.principal);
      final plan = c.computePlan();
      final m = plan.months;
      final payoff = plan.payoffDate;
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _kpi('Total balance', money(total))),
                  Expanded(child: _kpi('Monthly budget', money(c.monthlyBudget.value))),
                  Expanded(child: _kpi('To payoff', m>0 ? '$m mo' : '—')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DonutByDebt(),
          const SizedBox(height: 8),
          _BalanceProjection(),
        ],
      );
    });
  }

  Widget _kpi(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    ],
  );
}

class _DonutByDebt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtController>();
    return Obx(() {
      final total = c.debts.fold<double>(0,(a,b)=>a+b.principal);
      final sections = <PieChartSectionData>[];
      final colors = [Colors.blue, Colors.teal, Colors.purple, Colors.orange, Colors.pink, Colors.indigo];
      for (int i=0;i<c.debts.length;i++) {
        final d = c.debts[i];
        if (d.principal<=0) continue;
        sections.add(PieChartSectionData(
          value: d.principal,
          color: colors[i % colors.length],
          title: '',
          radius: 54,
        ));
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Balance by account', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 16/7,
                child: PieChart(PieChartData(centerSpaceRadius: 48, sectionsSpace: 1, sections: sections)),
              ),
              Wrap(spacing: 12, children: [
                for (int i=0;i<c.debts.length;i++)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, color: colors[i % colors.length]), const SizedBox(width: 6),
                    Text('${c.debts[i].name} ${money(c.debts[i].principal)}')
                  ])
              ])
            ],
          ),
        ),
      );
    });
  }
}

class _BalanceProjection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtController>();
    return Obx(() {
      final plan = c.computePlan();
      var points = plan.rows.asMap().entries.map((e){
        final sum = e.value.balances.values.fold<double>(0,(a,b)=>a+b);
        return FlSpot(e.key.toDouble(), sum);
      }).toList();
      if (points.isEmpty) {
        points = [const FlSpot(0,0)];
      }
      final maxY = points.map((e)=>e.y).fold<double>(0,(m,v)=>v>m?v:m)*(1.1);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Projected balance (aggregate)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 16/7,
                child: LineChart(LineChartData(
                  minX: 0, maxX: points.length.toDouble(),
                  minY: 0, maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: points,
                      color: Colors.greenAccent,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    )
                  ],
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                )),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtController>();
    return Obx(() => ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final d in c.debts) Card(
          child: ListTile(
            title: Text(d.name),
            subtitle: Text('${d.type.name.toUpperCase()} • APR ${d.apr.toStringAsFixed(2)}% • Due ${d.dueDay}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(d.principal), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Min ${money(d.minPayment)}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditDebt(existing: d))),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditDebt())),
          icon: const Icon(Icons.add),
          label: const Text('Add debt'),
        )
      ],
    ));
  }
}

class AddEditDebt extends StatefulWidget {
  final dynamic existing;
  const AddEditDebt({super.key, this.existing});
  @override
  State<AddEditDebt> createState() => _AddEditDebtState();
}

class _AddEditDebtState extends State<AddEditDebt> {
  final nameCtl = TextEditingController();
  final balCtl = TextEditingController(text: '1000');
  final aprCtl = TextEditingController(text: '19.99');
  final minCtl = TextEditingController(text: '50');
  final dueCtl = TextEditingController(text: '15');
  DebtType type = DebtType.revolving;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    if (d!=null) {
      nameCtl.text = d.name;
      balCtl.text  = d.principal.toStringAsFixed(2);
      aprCtl.text  = d.apr.toStringAsFixed(2);
      minCtl.text  = d.minPayment.toStringAsFixed(2);
      dueCtl.text  = d.dueDay.toString();
      type = d.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtController>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing==null? 'Add debt' : 'Edit debt')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          DropdownButtonFormField<DebtType>(value: type, items: [
            for (final t in DebtType.values) DropdownMenuItem(value: t, child: Text(t.name)),
          ], onChanged: (v)=>setState(()=>type=v??type), decoration: const InputDecoration(labelText: 'Type')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: balCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Balance'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: aprCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'APR %'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: minCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Min payment / mo'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: dueCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Due day (1..28)'))),
          ]),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final d = DebtAccount(
                id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtl.text.trim().isEmpty ? 'Debt' : nameCtl.text.trim(),
                type: type,
                principal: double.tryParse(balCtl.text) ?? 0,
                apr: double.tryParse(aprCtl.text) ?? 0,
                minPayment: double.tryParse(minCtl.text) ?? 0,
                dueDay: int.tryParse(dueCtl.text) ?? 1,
              );
              c.addOrUpdate(d);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtController>();
    return Obx(() {
      final plan = c.computePlan();
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Strategy & budget', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: [
                    SegmentedButton<Strategy>(
                      segments: const [
                        ButtonSegment(value: Strategy.snowball, label: Text('Snowball'), icon: Icon(Icons.bubble_chart_outlined)),
                        ButtonSegment(value: Strategy.avalanche, label: Text('Avalanche'), icon: Icon(Icons.terrain_outlined)),
                      ],
                      selected: {c.strategy.value},
                      onSelectionChanged: (s)=>c.strategy.value = s.first,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly budget: ${money(c.monthlyBudget.value)}'),
                          Slider(min: 50, max: 2000, divisions: 195, value: c.monthlyBudget.value, onChanged: (v)=>c.monthlyBudget.value=v),
                        ],
                      ),
                    )
                  ]),
                  const SizedBox(height: 8),
                  Text('Estimated payoff in ${plan.months} months • total interest ${money(plan.interest)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children:[
            FilledButton.icon(onPressed:() async {final csv=_toCsv(plan.rows); await Clipboard.setData(ClipboardData(text: csv)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));}, icon: const Icon(Icons.download_outlined), label: const Text('Export CSV')),
          ]),
          const SizedBox(height:8),
          _PlanTable(plan.rows),
        ],
      );
    });
  }
}

class _PlanTable extends StatelessWidget {
  final List<PlanRow> rows;
  const _PlanTable(this.rows);

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox();
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Month')),
            for (final id in rows.first.payments.keys) DataColumn(label: Text('Pay ${id.substring(0,4)}')),
            const DataColumn(label: Text('Interest')),
            const DataColumn(label: Text('Total')),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text('${r.month.year}-${r.month.month.toString().padLeft(2,'0')}')),
                for (final id in r.payments.keys) DataCell(Text(money(r.payments[id] ?? 0))),
                DataCell(Text(money(r.totalInterest))),
                DataCell(Text(money(r.totalPayment))),
              ]),
          ],
        ),
      ),
    );
  }
}

class DebtSettingsScreen extends StatelessWidget {
  const DebtSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DebtController>();
    return Obx(() => ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Budget helper', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Current monthly budget: ${money(c.monthlyBudget.value)}'),
            const SizedBox(height: 6),
            const Text('Tip: set your safe monthly surplus here. (Integration with pay calendar can adjust this automatically.)'),
          ]),
        ))
      ],
    ));
  }
}


String _toCsv(List<PlanRow> rows) {
  if (rows.isEmpty) return '';
  final ids = rows.first.payments.keys.toList();
  final buf = StringBuffer();
  buf.writeln(['month', ...ids.map((e)=>'pay_$e'), 'interest', 'total'].join(','));
  for (final r in rows) {
    final line = [
      '${r.month.year}-${r.month.month.toString().padLeft(2,'0')}',
      ...ids.map((id)=>r.payments[id]!.toStringAsFixed(2)),
      r.totalInterest.toStringAsFixed(2),
      r.totalPayment.toStringAsFixed(2),
    ].join(',');
    buf.writeln(line);
  }
  return buf.toString();
}
