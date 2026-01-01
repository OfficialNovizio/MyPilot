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
    // account.loadSavedJobs();
    // shift.loadShifts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: ColoredBox(
          color: ProjectColors.pureBlackColor,
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(height: height * .02),
                SegmentTabs(
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
        ),
      ),
    );
  }
}
