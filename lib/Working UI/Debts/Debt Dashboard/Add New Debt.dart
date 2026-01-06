import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/material.dart';

import '../../Constants.dart';

class AddDebtFormData {
  final DebtType debtType;
  final String name;
  final double balance;
  final double apr;
  final double minimumPayment;
  final int? dueDayOfMonth;
  final bool secured;
  final bool fixedInstallment;
  final String notes;

  AddDebtFormData({
    required this.debtType,
    required this.name,
    required this.balance,
    required this.apr,
    required this.minimumPayment,
    required this.dueDayOfMonth,
    required this.secured,
    required this.fixedInstallment,
    required this.notes,
  });
}

enum DebtType { creditCard, loan, bnpl, other }

class AddDebtBottomSheet extends StatefulWidget {
  final void Function() onSave;
  const AddDebtBottomSheet({super.key, required this.onSave});

  @override
  State<AddDebtBottomSheet> createState() => _AddDebtBottomSheetState();
}

class _AddDebtBottomSheetState extends State<AddDebtBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  DebtType _type = DebtType.creditCard;

  final _nameC = TextEditingController();
  final _balC = TextEditingController();
  final _aprC = TextEditingController();
  final _minC = TextEditingController();
  final _notesC = TextEditingController();

  int? _dueDay = 15;
  bool _secured = false;
  bool _fixedInstallment = false;

  @override
  void dispose() {
    _nameC.dispose();
    _balC.dispose();
    _aprC.dispose();
    _minC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SizedBox(
      height: height * .9,
      child: Popup(
        color: ProjectColors.blackColor,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            SizedBox(height: height * .012),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(text: 'Debt Type', fontSize: .0135, fontWeight: FontWeight.w600, color: Colors.black54),
                  SizedBox(height: height * .008),
                  _typeTabs(),
                  SizedBox(height: height * .016),
                  textWidget(text: 'Details', fontSize: .0135, fontWeight: FontWeight.w600, color: Colors.black54),
                  SizedBox(height: height * .01),
                  _label('Name'),
                  _input(
                    controller: _nameC,
                    hint: 'Visa / Car Loan',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                  ),
                  SizedBox(height: height * .012),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Balance'),
                            _moneyInput(
                              controller: _balC,
                              hint: '\$',
                              validator: (v) => _validateMoney(v, min: 0.01),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: width * .03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('APR (%)'),
                            _moneyInput(
                              controller: _aprC,
                              hint: '5',
                              isPercent: true,
                              validator: (v) => _validateNumber(v, min: 0, max: 99.99),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * .012),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Minimum Payment'),
                            _moneyInput(
                              controller: _minC,
                              hint: '\$',
                              validator: (v) => _validateMoney(v, min: 0),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: width * .03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Due Day of Month'),
                            _dropdownDay(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * .016),
                  textWidget(text: 'Payment Info', fontSize: .0135, fontWeight: FontWeight.w600, color: Colors.black54),
                  SizedBox(height: height * .01),
                  Row(
                    children: [
                      Expanded(child: _switchRow('Secured', _secured, (v) => setState(() => _secured = v))),
                      SizedBox(width: width * .03),
                      Expanded(child: _switchRow('Fixed Installment', _fixedInstallment, (v) => setState(() => _fixedInstallment = v))),
                    ],
                  ),
                  SizedBox(height: height * .016),
                  _label('Notes'),
                  _input(
                    controller: _notesC,
                    hint: 'Add notes (e.g., 0% promo ends in Feb)',
                    maxLines: 3,
                    validator: (_) => null,
                  ),
                  SizedBox(height: height * .018),
                  _saveButton(),
                  SizedBox(height: height * .01),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.all(width * .01),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: height * .022, color: Colors.black87),
          ),
        ),
        SizedBox(width: width * .02),
        Expanded(
          child: textWidget(
            text: 'Add a Debt',
            fontSize: .022,
            fontWeight: FontWeight.w800,
            color: ProjectColors.pureBlackColor,
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.all(width * .01),
            child: textWidget(
              text: 'Close',
              fontSize: .0145,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeTabs() {
    Widget tab(String label, DebtType t) {
      final active = _type == t;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _type = t),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: height * .012),
            decoration: BoxDecoration(
              color: active ? Colors.black.withOpacity(.06) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(.08)),
            ),
            child: Center(
              child: textWidget(
                text: label,
                fontSize: .0135,
                fontWeight: FontWeight.w700,
                color: ProjectColors.pureBlackColor,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(width * .012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          tab('Credit Card', DebtType.creditCard),
          SizedBox(width: width * .02),
          tab('Loan', DebtType.loan),
          SizedBox(width: width * .02),
          tab('BNPL', DebtType.bnpl),
          SizedBox(width: width * .02),
          tab('Other', DebtType.other),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(bottom: height * .006),
        child: textWidget(text: t, fontSize: .013, fontWeight: FontWeight.w600, color: Colors.black54),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .002),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontSize: height * .015, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black26, fontSize: height * .014),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _moneyInput({
    required TextEditingController controller,
    required String hint,
    bool isPercent = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .002),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        style: TextStyle(fontSize: height * .015, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          prefixText: isPercent ? '' : '',
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black26, fontSize: height * .014),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownDay() {
    final items = List<int>.generate(31, (i) => i + 1);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      padding: EdgeInsets.symmetric(horizontal: width * .04),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _dueDay,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: height * .028),
          items: items
              .map((d) => DropdownMenuItem<int>(
                    value: d,
                    child: textWidget(text: 'Day $d', fontSize: .0145, fontWeight: FontWeight.w700),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _dueDay = v),
        ),
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Expanded(child: textWidget(text: label, fontSize: .014, fontWeight: FontWeight.w700)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ProjectColors.greenColor,
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(.12),
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: height * .016),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;

          final data = AddDebtFormData(
            debtType: _type,
            name: _nameC.text.trim(),
            balance: double.parse(_balC.text.trim()),
            apr: double.parse(_aprC.text.trim()),
            minimumPayment: double.parse(_minC.text.trim().isEmpty ? '0' : _minC.text.trim()),
            dueDayOfMonth: _dueDay,
            secured: _secured,
            fixedInstallment: _fixedInstallment,
            notes: _notesC.text.trim(),
          );

          // widget.onSave(data);
          Navigator.pop(context);
        },
        child: textWidget(text: 'Save Debt', fontSize: .0155, fontWeight: FontWeight.w800),
      ),
    );
  }

  String? _validateMoney(String? v, {double min = 0}) {
    final s = (v ?? '').trim();
    final d = double.tryParse(s);
    if (d == null) return 'Enter a number';
    if (d < min) return 'Must be ≥ $min';
    return null;
  }

  String? _validateNumber(String? v, {double min = 0, double max = 999999}) {
    final s = (v ?? '').trim();
    final d = double.tryParse(s);
    if (d == null) return 'Enter a number';
    if (d < min) return 'Must be ≥ $min';
    if (d > max) return 'Too high';
    return null;
  }
}
