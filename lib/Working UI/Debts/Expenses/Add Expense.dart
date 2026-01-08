import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Cards and Account/Cards.dart';
import '../../Constant UI.dart';
import '../../Constants.dart';

class NewExpense extends StatelessWidget {
  NewExpense({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: ProjectColors.pureBlackColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .02),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          height: height * .045,
                          width: height * .045,
                          decoration: BoxDecoration(
                            color: ProjectColors.whiteColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ProjectColors.blackColor.withOpacity(.06),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(Icons.chevron_left_rounded, color: ProjectColors.blackColor, size: height * .03),
                        ),
                      ),
                      SizedBox(width: width * .2),
                      textWidget(
                        text: 'New Expense',
                        fontSize: .03,
                        fontWeight: FontWeight.bold,
                        color: ProjectColors.whiteColor,
                      ),
                    ],
                  ),
                  SizedBox(height: height * .02),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .02),
                    decoration: BoxDecoration(
                      color: ProjectColors.whiteColor.withOpacity(.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ProjectColors.whiteColor.withOpacity(.06)),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: width * .01),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: width * .5,
                        child: TextField(
                          controller: expense.controllers[1].controller,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: ProjectColors.whiteColor,
                            fontSize: height * .05,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (changed) {
                            expense.controllers[1].controller.text = changed;
                          },
                          cursorColor: ProjectColors.whiteColor,
                          decoration: InputDecoration(
                            hint: textWidget(
                              text: 'Name',
                              textAlign: TextAlign.start,
                              color: ProjectColors.whiteColor,
                              fontSize: .05,
                              fontWeight: FontWeight.bold,
                            ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width * .4,
                        child: TextField(
                          controller: expense.controllers[0].controller,
                          onChanged: (changed) {
                            expense.controllers[0].controller.text = changed;
                          },
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: ProjectColors.whiteColor,
                            fontSize: height * .025,
                            fontWeight: FontWeight.bold,
                          ),
                          cursorColor: ProjectColors.whiteColor,
                          keyboardType: TextInputType.numberWithOptions(signed: true),
                          decoration: InputDecoration(
                            hint: textWidget(
                              text: 'Amount',
                              textAlign: TextAlign.end,
                              color: ProjectColors.whiteColor,
                              fontSize: .025,
                              fontWeight: FontWeight.bold,
                            ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * .02),
                  Column(
                    children: [
                      _infoCard(
                        children: [
                          GestureDetector(
                            onTap: () {
                              expense.showFrequencies.value = !expense.showFrequencies.value;
                            },
                            child: _kvRow('Frequency',
                                expense.controllers[7].controller.text.isEmpty ? "Choose Frequency" : expense.controllers[7].controller.text),
                          ),
                          Visibility(
                            visible: expense.showFrequencies.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: expense.frequencies
                                  .map(
                                    (t) => Padding(
                                      padding: EdgeInsets.only(top: height * .01),
                                      child: GestureDetector(
                                        onTap: () {
                                          expense.controllers[7].controller.text = t;
                                          expense.showFrequencies.value = !expense.showFrequencies.value;
                                        },
                                        child: textWidget(
                                          text: t,
                                          fontSize: .016,
                                          fontWeight: FontWeight.w600,
                                          color: ProjectColors.whiteColor.withOpacity(.55),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          _divider(),
                          GestureDetector(
                            onTap: () {
                              AppDatePicker.pickDate().then((onValue) {
                                if (onValue != null) {
                                  expense.controllers[5].controller.text = formatDate(onValue);
                                  expense.controllers[5].pickedDate = onValue;
                                  expense.controllers.refresh();
                                }
                              });
                            },
                            child: _kvRow(
                              'Billing day',
                              expense.controllers[5].controller.text.isEmpty ? "Select Date" : expense.controllers[5].controller.text,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * .014),
                      _infoCard(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (_) => SizedBox(
                                  height: height * .9,
                                  child: Popup(
                                    color: ProjectColors.blackColor,
                                    title: "Cards & Accounts",
                                    body: PaymentMethodsScreen(),
                                  ),
                                ),
                              );
                            },
                            child: _kvRow(
                              'Card/Account',
                              expense.controllers[4].controller.text.isEmpty ? "Select Account" : expense.controllers[4].controller.text,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * .014),
                      _infoCard(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: height * .004),
                            child: Row(
                              children: [
                                Expanded(
                                  child: textWidget(
                                    text: 'Is Essential',
                                    fontSize: .016,
                                    fontWeight: FontWeight.w600,
                                    color: ProjectColors.whiteColor.withOpacity(.55),
                                  ),
                                ),
                                segmentedToggle(
                                  options: ['Yes', 'No'],
                                  selectedIndex: expense.isEssential.value ? 0 : 1,
                                  onChanged: (i, v) {
                                    expense.isEssential.value = (i == 0);
                                    expense.isEssential.refresh();
                                    expense.controllers[6].controller.text = v;
                                    print(expense.controllers[6].controller.text);
                                  },
                                ),
                              ],
                            ),
                          ),
                          _divider(),
                          GestureDetector(
                            onTap: () {
                              expense.showCategories.value = !expense.showCategories.value;
                            },
                            child: _kvRow('Category',
                                expense.controllers[3].controller.text.isEmpty ? "Pick Category" : expense.controllers[3].controller.text),
                          ),
                          Visibility(
                            visible: expense.showCategories.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: expense.categories
                                  .map(
                                    (t) => Padding(
                                      padding: EdgeInsets.only(top: height * .01),
                                      child: GestureDetector(
                                        onTap: () {
                                          expense.controllers[3].controller.text = t;
                                          expense.showCategories.value = !expense.showCategories.value;
                                        },
                                        child: textWidget(
                                          text: t,
                                          fontSize: .016,
                                          fontWeight: FontWeight.w600,
                                          color: ProjectColors.whiteColor.withOpacity(.55),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * .014),
                      _infoCard(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: textWidget(
                                  text: 'Note',
                                  fontSize: .016,
                                  fontWeight: FontWeight.w600,
                                  color: ProjectColors.whiteColor.withOpacity(.55),
                                ),
                              ),
                              SizedBox(
                                width: width * .5,
                                height: height * .04,
                                child: TextField(
                                  controller: expense.controllers[2].controller,
                                  onChanged: (changed) {
                                    expense.controllers[2].controller.text = changed;
                                  },
                                  style: TextStyle(
                                    color: ProjectColors.whiteColor,
                                    fontSize: height * .015,
                                  ),
                                  textAlign: TextAlign.end,
                                  decoration: InputDecoration(
                                    hint: textWidget(text: 'Description', textAlign: TextAlign.end, color: ProjectColors.whiteColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: ProjectColors.whiteColor.withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: ProjectColors.whiteColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: height * .02),
                      normalButton(
                        title: 'Save to My expenses',
                        callback: () {
                          expense.addExpenseFromUI();
                        },
                        invertColors: true,
                        bColor: ProjectColors.greenColor,
                        cWidth: .7,
                      ),
                      SizedBox(height: height * .01),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return DarkCard(
      child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: children),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * .006),
      child: Row(
        children: [
          Expanded(
            child: textWidget(
              text: k,
              fontSize: .016,
              fontWeight: FontWeight.w600,
              color: ProjectColors.whiteColor.withOpacity(.55),
            ),
          ),
          textWidget(
            text: v,
            fontSize: .018,
            fontWeight: FontWeight.w700,
            color: ProjectColors.whiteColor,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: height * .0012,
      margin: EdgeInsets.symmetric(vertical: height * .006),
      color: ProjectColors.whiteColor.withOpacity(.06),
    );
  }
}
