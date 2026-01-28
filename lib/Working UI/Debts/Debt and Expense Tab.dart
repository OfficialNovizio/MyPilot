import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Constant UI.dart';

class DebtBody extends StatefulWidget {
  const DebtBody({super.key});
  @override
  State<DebtBody> createState() => _DebtBodyState();
}

class _DebtBodyState extends State<DebtBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: width,
        height: height * .88,
        child: SingleChildScrollView(
          child: Column(children: [
            SegmentTabs(
              cWidth: .8,
              borderOpacity: 0.1,
              value: debt.activeShift!.value,
              highlightValue: debt.activeShift!.value,
              padding: EdgeInsets.zero,
              onChanged: (value) {
                debt.changeDebtTabs(value);
                debt.activeShift!.value = value;
              },
              items: debt.debtStats,
            ),
            debt.shiftScreen!.value
          ]),
        ),
      ),
    );
  }
}
