import 'package:emptyproject/BaseScreen.dart';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Cards and Account/Cards.dart';
import '../../../Constants.dart';
import 'Bnpl Body.dart';
import 'Loan Body.dart';

class AddDebt extends StatefulWidget {
  final bool? isEditing;
  AddDebt({this.isEditing = false});

  @override
  State<AddDebt> createState() => _AddDebtState();
}

class _AddDebtState extends State<AddDebt> {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.isEditing! ? ' current Debt' : 'New Debt',
      body: Obx(
        () => Padding(
          padding: EdgeInsets.symmetric(vertical: height * .01),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DarkCard(
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: ProjectColors.whiteColor.withOpacity(.7)),
                      SizedBox(width: width * .03),
                      Expanded(
                        child: textWidget(
                          text: "Log expenses to improve cash-flow alerts and debt plan accuracy.",
                          fontSize: .016,
                          color: ProjectColors.whiteColor.withOpacity(.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * .02),

                // -------------------- Debt Type --------------------
                textWidget(text: 'Debt Type', fontSize: .015, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
                SizedBox(height: height * .008),
                segmentedToggle(
                  activeColor: ProjectColors.greenColor,
                  options: debtV2.debtType,
                  cWidth: .45,
                  selectedIndex: (() {
                    final idx = debtV2.debtType.map((e) => e).toList().indexOf(debtV2.selectedDebtType.value);
                    return idx < 0 ? 0 : idx;
                  })(),
                  onChanged: (i, v) {
                    debtV2.selectedDebtType.value = v;
                  },
                ),
                SizedBox(height: height * .02),
                textWidget(text: 'Loan Details', fontSize: .015, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
                SizedBox(height: height * .01),
                Row(
                  children: [
                    Expanded(
                      child: DarkTextField(
                        title: 'Name',
                        hintText: 'Visa / Car Loan',
                        controller: debtV2.controllers[0].controller,
                      ),
                    ),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: DarkTextField(
                        title: 'Linked Account',
                        hintText: debtV2.selectedAccount.value == null ? 'Select' : debtV2.selectedAccount.value!.name,
                        trailing: Icon(Icons.account_balance_outlined, color: ProjectColors.whiteColor.withOpacity(0.75), size: height * 0.022),
                        onTap: () {
                          Get.to(() => PaymentMethodsScreen(callingFrom: 'Debt'));
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * .02),
                debtV2.selectedDebtType.value == 'Loan' ? LoanBody() : BnplBody(),
                // -------------------- Loan Details --------------------

                SizedBox(height: height * .02),

                Center(
                  child: normalButton(
                    title: 'Save to My debts',
                    callback: () {
                      debtV2.addDebtFromUI();
                    },
                    bColor: ProjectColors.greenColor,
                    cWidth: .7,
                  ),
                ),

                SizedBox(height: height * .01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
