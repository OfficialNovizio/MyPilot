import 'package:emptyproject/BaseScreen.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/Expense%20Model%20V2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Cards and Account/Cards.dart';
import '../../Constant UI.dart';
import '../../Constants.dart';

class NewExpense extends StatelessWidget {
  bool? isEditing;

  NewExpense({this.isEditing = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BaseScreen(
        title: isEditing! ? 'Current Expense' : 'New Expense',
        body: Padding(
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
                // -------------------- Expense Type and Essential --------------------
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textWidget(text: 'Expense Type', fontSize: .015, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
                        SizedBox(height: height * .008),
                        segmentedToggle(
                          cWidth: .45,
                          options: ['Spent', 'Planned'],
                          selectedIndex: expenseV2.selectedMode.value == ExpenseMode.spent ? 0 : 1,
                          onChanged: (i, v) {
                            expenseV2.selectedMode.value = v;
                            expenseV2.selectedMode.refresh();
                            expenseV2.controllers[8].controller.text = v;
                            print(expenseV2.controllers[8].controller.text);
                          },
                        ),
                      ],
                    ),
                    Spacer(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        textWidget(text: 'Is Essential', fontSize: .015, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
                        SizedBox(height: height * .008),
                        segmentedToggle(
                          cWidth: .45,
                          options: ['Yes', 'No'],
                          selectedIndex: expenseV2.isEssential.value ? 0 : 1,
                          onChanged: (i, v) {
                            expenseV2.isEssential.value = (i == 0);
                            expenseV2.isEssential.refresh();
                            expenseV2.controllers[6].controller.text = v;
                            print(expenseV2.controllers[6].controller.text);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: height * .02),
                textWidget(text: 'Expense Details', fontSize: .015, fontWeight: FontWeight.w600, color: ProjectColors.whiteColor),
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
                        title: 'Amount',
                        hintText: '\$',
                        controller: debtV2.controllers[0].controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * .01),
                Row(
                  children: [
                    Expanded(
                      child: DarkTextField(
                        title: 'Frequency',
                        hintText: 'Select',
                        trailing: Icon(Icons.arrow_circle_down_rounded, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                        onTap: () {
                          callBottomSheet(child: ExpenseOptions(), title: 'Frequencies');
                        },
                      ),
                    ),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: DarkTextField(
                        title: 'Date',
                        hintText: 'Select',
                        trailing: Icon(Icons.calendar_month_rounded, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                        onTap: () async {
                          final res = await AppPicker.pick(
                            mode: PickerMode.date,
                            title: "Transaction Date",
                          );
                          if (res != null) {
                            expenseV2.controllers[5].controller.text = formatDate(res.dateTime!);
                            expenseV2.controllers[5].pickedDate = res.dateTime!;
                            expenseV2.controllers.refresh();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * .01),
                Row(
                  children: [
                    Expanded(
                      child: DarkTextField(
                        title: 'Linked Account',
                        hintText: debtV2.selectedAccount.value == null ? 'Select' : debtV2.selectedAccount.value!.name,
                        onTap: () {
                          Get.to(() => PaymentMethodsScreen(callingFrom: 'Expense'));
                        },
                        trailing: Icon(Icons.account_balance_outlined, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                      ),
                    ),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: DarkTextField(
                        title: 'Category',
                        hintText: expenseV2.controllers[3].controller.text.isEmpty ? "Select" : expenseV2.controllers[3].controller.text,
                        onTap: () {
                          callBottomSheet(child: ExpenseOptions(showCategories: true), title: 'Categories');
                        },
                        trailing: Icon(Icons.category_outlined, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * .01),
                DarkTextField(
                  title: 'Description',
                  hintText: expenseV2.controllers[3].controller.text.isEmpty ? "Description" : expenseV2.controllers[3].controller.text,
                  controller: expenseV2.controllers[2].controller,
                ),
                SizedBox(height: height * .02),
                Center(
                  child: normalButton(
                    title: 'Save to My expenses',
                    callback: () {
                      if (isEditing!) {
                        expenseV2.editExpenseFromUI();
                      } else {
                        expenseV2.addExpenseFromUI();
                      }
                    },
                    bColor: ProjectColors.greenColor,
                    cWidth: .7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpenseOptions extends StatelessWidget {
  final bool? showCategories;
  ExpenseOptions({this.showCategories = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: showCategories!
          ? expenseV2.categories
              .map(
                (x) => ListTile(
                  title: textWidget(
                    text: x,
                    fontSize: .015,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(.9),
                  ),
                  leading: Icon(expenseV2.categoryIcon(x), color: ProjectColors.whiteColor.withOpacity(0.75)),
                  onTap: () {
                    expenseV2.controllers[3].controller.text = x;
                    expenseV2.controllers.refresh();
                    Get.back();
                  },
                ),
              )
              .toList()
          : expenseV2.frequencies
              .map(
                (x) => ListTile(
                  title: textWidget(
                    text: x,
                    fontSize: .015,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(.9),
                  ),
                  onTap: () {
                    expenseV2.controllers[7].controller.text = x;
                    expenseV2.controllers.refresh();
                    Get.back();
                  },
                ),
              )
              .toList(),
    );
  }
}
