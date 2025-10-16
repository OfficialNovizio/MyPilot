import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../models/tax_config.dart';

class SalaryDetailsScreen extends StatelessWidget {
  final DateTime month;
  const SalaryDetailsScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final m = DateTime(month.year, month.month, 1);
    final data = c.monthNetSummary(m);
    final perJob = (data['perJob'] as Map<String, Map<String, double>>);
    final combined = (data['combined'] as Map<String, double>);

    return Scaffold(
      appBar: AppBar(title: Text('Net Salary — ${m.month}/${m.year}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final j in c.jobs)
            _JobNetCard(
              title: j.name,
              color: c.jobColor(j.colorHex),
              rows: perJob[j.id] ?? const {'gross': 0, 'incomeTax': 0, 'cpp': 0, 'ei': 0, 'other': 0, 'fixed': 0, 'net': 0},
              onEdit: () => _editTaxes(c, j.id, month: m),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Text('Combined (All Jobs)', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Gross: \$${(combined['gross'] ?? 0).toStringAsFixed(2)}'),
                  Text('Net:   \$${(combined['net'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _editTaxes(AppController c, String jobId, {required DateTime month}) {
    final cfg = c.taxFor(jobId);

    final incomeCtl = TextEditingController(text: cfg.incomeTaxPct.toStringAsFixed(2));
    final cppCtl = TextEditingController(text: cfg.cppPct.toStringAsFixed(2));
    final eiCtl = TextEditingController(text: cfg.eiPct.toStringAsFixed(2));
    final otherCtl = TextEditingController(text: cfg.otherPct.toStringAsFixed(2));
    final fixedCtl = TextEditingController(text: cfg.fixedMonthly.toStringAsFixed(2));
    final perChequeCtl = TextEditingController(text: cfg.fixedPerCheque.toStringAsFixed(2));

    final j = c.jobs.firstWhere((x) => x.id == jobId);
    final depositYmds = c.depositYmdsForMonth(j, DateTime(month.year, month.month, 1));

    // controllers for one-offs (this month)
    final oneOffCtrls = <String, TextEditingController>{
      for (final y in depositYmds) y: TextEditingController(text: (cfg.oneOffByDepositYmd[y] ?? 0).toStringAsFixed(2)),
    };

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1012),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
                child: Container(height: 4, width: 44, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 12),
            const Text('Edit Tax Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _pctField(incomeCtl, 'Income tax %')),
              const SizedBox(width: 10),
              Expanded(child: _pctField(cppCtl, 'CPP/Pension %')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _pctField(eiCtl, 'EI/Insurance %')),
              const SizedBox(width: 10),
              Expanded(child: _pctField(otherCtl, 'Other %')),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: fixedCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Fixed monthly (\$)', isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: perChequeCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Fixed per cheque (\$)', isDense: true),
            ),
            const SizedBox(height: 14),
            if (depositYmds.isNotEmpty) ...[
              const Text('One-offs for this month', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final y in depositYmds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: oneOffCtrls[y],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Deposit $y (one-off \$)',
                      isDense: true,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
            ],
            FilledButton(
              onPressed: () {
                final map = Map<String, double>.from(cfg.oneOffByDepositYmd);
                for (final y in depositYmds) {
                  final v = double.tryParse(oneOffCtrls[y]!.text) ?? 0.0;
                  if (v <= 0.0) {
                    map.remove(y);
                  } else {
                    map[y] = v;
                  }
                }

                final updated = TaxConfig(
                  jobId: jobId,
                  incomeTaxPct: double.tryParse(incomeCtl.text) ?? cfg.incomeTaxPct,
                  cppPct: double.tryParse(cppCtl.text) ?? cfg.cppPct,
                  eiPct: double.tryParse(eiCtl.text) ?? cfg.eiPct,
                  otherPct: double.tryParse(otherCtl.text) ?? cfg.otherPct,
                  fixedMonthly: double.tryParse(fixedCtl.text) ?? cfg.fixedMonthly,
                  fixedPerCheque: double.tryParse(perChequeCtl.text) ?? cfg.fixedPerCheque,
                  oneOffByDepositYmd: map,
                );
                c.saveTaxConfig(updated);
                Get.back();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _JobNetCard extends StatelessWidget {
  final String title;
  final Color color;
  final Map<String, double> rows;
  final VoidCallback onEdit;
  const _JobNetCard({required this.title, required this.color, required this.rows, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: color, radius: 6),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          ]),
          const SizedBox(height: 8),
          _line('Gross', rows['gross']),
          const Divider(),
          _line('Income tax', rows['incomeTax']),
          _line('CPP/Pension', rows['cpp']),
          _line('EI/Insurance', rows['ei']),
          _line('Other %', rows['other']),
          const Divider(),
          _line('Fixed monthly', rows['fixedMonthly']),
          _line('Fixed per cheque × ${rows['depositCount']?.toInt() ?? 0}', rows['fixedPerChequeTotal']),
          _line('One-offs', rows['oneOffTotal']),
          const Divider(),
          Row(
            children: [
              const Text('Estimated net', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('\$${(rows['net'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _line(String label, double? v) => Row(children: [
        Text(label),
        const Spacer(),
        Text('\$${(v ?? 0).toStringAsFixed(2)}'),
      ]);
}

Widget _pctField(TextEditingController c, String label) => TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
