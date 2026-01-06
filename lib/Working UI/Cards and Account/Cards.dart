import 'package:carousel_slider/carousel_slider.dart';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:get/get.dart';

class PaymentMethodsScreen extends StatefulWidget {
  PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    cards.loadPaymentMethods();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SingleChildScrollView(
        child: cards.state.value == ButtonState.loading
            ? Padding(padding: EdgeInsets.only(top: height * .4), child: loader())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * .025),
                  textWidget(
                    text: 'Cards',
                    fontSize: .02,
                    color: ProjectColors.whiteColor.withOpacity(.85),
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: height * .012),
                  cards.cards.isEmpty
                      ? emptyHint("No cards added yet.")
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: height * .25,
                            viewportFraction: 0.95, // 0.82–0.90 gives side peek
                            enlargeCenterPage: true,
                            enlargeFactor: 0.1, // keep small so it doesn't eat the peek
                            padEnds: false, // important: shows edge peeks
                            clipBehavior: Clip.none,
                            enableInfiniteScroll: false,
                          ),
                          items: cards.cards.map((m) {
                            return Builder(
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.only(right: width * .02),
                                  child: GestureDetector(
                                    onTap: () {
                                      cards.selectedCard.value = m;
                                      cards.selectedBank.value = null;
                                      expense.controllers[4].controller.text = cards.selectedCard.value!.bankName!;
                                      expense.controllers.refresh();
                                      Get.back();
                                    },
                                    child: CreditCardWidget(
                                      height: height * .25,
                                      width: width,
                                      cardNumber: formatCardNo(m.cardNumber!),
                                      expiryDate: formatDate(m.expiryDate!, type: 'MM/yy'),
                                      cardHolderName: m.cardHolderName!,
                                      cvvCode: m.cvvCode!,
                                      bankName: m.bankName,
                                      showBackView: false,
                                      obscureCardNumber: true,
                                      obscureCardCvv: true,
                                      isHolderNameVisible: true,
                                      isSwipeGestureEnabled: false,
                                      cardBgColor: ProjectColors.brownColor,
                                      onCreditCardWidgetChange: (CreditCardBrand p1) {},
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                  SizedBox(height: height * .03),
                  textWidget(
                    text: 'Bank Accounts',
                    fontSize: .02,
                    color: ProjectColors.whiteColor.withOpacity(.85),
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: height * .012),
                  cards.banks.isEmpty
                      ? emptyHint("No bank accounts added yet.")
                      : Column(
                          children: cards.banks
                              .map((f) => GestureDetector(
                                    onTap: () {
                                      cards.selectedBank.value = f;
                                      cards.selectedCard.value = null;
                                      expense.controllers[4].controller.text =
                                          "${cards.selectedBank.value!.bankName!} ${cards.selectedBank.value!.accountType!}";
                                      expense.controllers.refresh();
                                      Get.back();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: ProjectColors.pureBlackColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: width * .02, vertical: height * .01),
                                      margin: EdgeInsets.symmetric(vertical: height * .004),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              textWidget(
                                                  text: f.bankName, fontSize: .03, fontWeight: FontWeight.bold, color: ProjectColors.whiteColor),
                                              SizedBox(height: height * .02),
                                              textWidget(text: f.accountType, fontSize: .02, color: ProjectColors.whiteColor),
                                              SizedBox(height: height * .005),
                                              textWidget(text: "\$${f.balance.toString()}", fontSize: .02, color: ProjectColors.whiteColor),
                                            ],
                                          ),
                                          Spacer(),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              textWidget(text: f.nickName, fontSize: .02, color: ProjectColors.whiteColor),
                                              // SizedBox(height: height * .02),
                                              // GestureDetector(
                                              //   onTap: () {
                                              //     if (!f.isDefault) {
                                              //       cards.editBankFromUI(current: f, isDefault: true);
                                              //     }
                                              //   },
                                              //   child: Container(
                                              //     decoration: f.isDefault
                                              //         ? BoxDecoration(borderRadius: BorderRadius.circular(20), color: ProjectColors.greenColor)
                                              //         : BoxDecoration(
                                              //             borderRadius: BorderRadius.circular(20),
                                              //             color: Colors.transparent,
                                              //             border: Border.all(color: ProjectColors.yellowColor),
                                              //           ),
                                              //     padding: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .03),
                                              //     child: textWidget(
                                              //       text: 'Default',
                                              //       fontSize: 0.017,
                                              //       fontWeight: FontWeight.w600,
                                              //       color: f.isDefault ? ProjectColors.pureBlackColor : ProjectColors.yellowColor,
                                              //     ),
                                              //   ),
                                              // ),
                                              // SizedBox(height: height * .005),
                                              // GestureDetector(
                                              //   onTap: () {
                                              //     cards.deleteBank(id: f.id);
                                              //   },
                                              //   child: Container(
                                              //     decoration: BoxDecoration(
                                              //       borderRadius: BorderRadius.circular(20),
                                              //       border: Border.all(color: ProjectColors.greenColor),
                                              //     ),
                                              //     padding: EdgeInsets.symmetric(vertical: height * .005, horizontal: width * .02),
                                              //     child: textWidget(
                                              //       text: 'Remove',
                                              //       fontSize: 0.017,
                                              //       fontWeight: FontWeight.w600,
                                              //       color: ProjectColors.whiteColor,
                                              //     ),
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                  SizedBox(height: height * .05),
                  Center(
                    child: outLinedButton(
                      title: 'Add New Card/Account',
                      callback: () {
                        showCupertinoModalPopup(context: context, builder: (_) => callAddAccount());
                      },
                      color: ProjectColors.greenColor,
                      cHeight: .05,
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Widget emptyHint(String t) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * .04),
      decoration: BoxDecoration(
        color: ProjectColors.whiteColor.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProjectColors.whiteColor.withOpacity(.12)),
      ),
      child: textWidget(
        text: t,
        fontSize: .014,
        color: ProjectColors.whiteColor.withOpacity(.65),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget callAddAccount() {
    return SizedBox(
      height: height * .82,
      child: Popup(
        color: ProjectColors.blackColor,
        title: 'Add Payment Method',
        body: Form(
          key: expense.formKey,
          child: SingleChildScrollView(
            child: Obx(() {
              final fields = cards.activeAccountTypes!.value == "Card" ? cards.creditCard.sublist(0, 3) : cards.bankAccount.sublist(0, 4);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * .02),
                  textWidget(
                    text: "Select Type",
                    fontSize: .016,
                    color: ProjectColors.whiteColor,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: height * .012),

                  // ✅ Wrap so it never overflows
                  Wrap(
                    spacing: width * .02,
                    runSpacing: height * .012,
                    children: cards.accountTypes!.map((type) {
                      final isActive = cards.activeAccountTypes!.value == type;
                      return InkWell(
                        onTap: () => cards.activeAccountTypes!.value = type,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .012),
                          decoration: BoxDecoration(
                            color: isActive ? ProjectColors.greenColor : ProjectColors.whiteColor.withOpacity(.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: ProjectColors.whiteColor.withOpacity(.14)),
                          ),
                          child: textWidget(
                            text: type,
                            fontSize: .014,
                            color: isActive ? ProjectColors.pureBlackColor : ProjectColors.whiteColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: height * .02),

                  // fields list
                  ...fields.map((f) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: height * .012),
                      child: f.title == "Account Type"
                          ? DropdownButtonFormField<String>(
                              value: f.controller.text.isEmpty ? null : f.controller.text,
                              items: cards.accounts
                                  .map(
                                    (x) => DropdownMenuItem(
                                      value: x,
                                      child: textWidget(
                                        text: x,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                f.controller.text = v ?? "";
                              },
                              dropdownColor: ProjectColors.whiteColor,
                              iconEnabledColor: ProjectColors.whiteColor.withOpacity(.8),
                              style: TextStyle(
                                color: ProjectColors.whiteColor,
                                fontWeight: FontWeight.w700,
                                fontSize: height * .016,
                              ),
                              decoration: InputDecoration(
                                hintText: f.title,
                                hintStyle: TextStyle(
                                  color: ProjectColors.whiteColor.withOpacity(.35),
                                  fontWeight: FontWeight.w600,
                                  fontSize: height * .015,
                                ),
                                filled: true,
                                fillColor: ProjectColors.whiteColor.withOpacity(.06),
                                contentPadding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .018),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.12)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.25)),
                                ),
                              ),
                            )
                          : TextFormField(
                              onTap: f.title.contains('Date')
                                  ? () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );
                                      if (d != null) {
                                        f.controller.text = formatDate(d);
                                        f.pickedDate = d;
                                      }
                                    }
                                  : null,
                              controller: f.controller,
                              style: TextStyle(
                                color: ProjectColors.whiteColor,
                                fontWeight: FontWeight.w700,
                                fontSize: height * .016,
                              ),
                              decoration: InputDecoration(
                                hintText: f.title,
                                hintStyle: TextStyle(
                                  color: ProjectColors.whiteColor.withOpacity(.35),
                                  fontWeight: FontWeight.w600,
                                  fontSize: height * .015,
                                ),
                                filled: true,
                                fillColor: ProjectColors.whiteColor.withOpacity(.06),
                                contentPadding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .018),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.12)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.25)),
                                ),
                              ),
                            ),
                    );
                  }).toList(),
                  Visibility(
                    visible: cards.activeAccountTypes!.value == 'Card' ? true : false,
                    child: Wrap(
                      spacing: width * .05,
                      children: cards.creditCard
                          .sublist(3, 8)
                          .map(
                            (f) => Padding(
                              padding: EdgeInsets.symmetric(vertical: height * .01),
                              child: SizedBox(
                                width: f.title.contains("Last") ? width : width * .45,
                                child: TextFormField(
                                  onTap: f.title.contains('Date')
                                      ? () async {
                                          final d = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime.now(),
                                          );
                                          if (d != null) {
                                            f.controller.text = formatDate(d);
                                            f.pickedDate = d;
                                          }
                                        }
                                      : null,
                                  controller: f.controller,
                                  style: TextStyle(
                                    color: ProjectColors.whiteColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: height * .016,
                                    fontFamily: 'poppins',
                                  ),
                                  decoration: InputDecoration(
                                    hintText: f.title,
                                    hintStyle: TextStyle(
                                      color: ProjectColors.whiteColor.withOpacity(.35),
                                      fontWeight: FontWeight.w600,
                                      fontSize: height * .015,
                                      fontFamily: 'poppins',
                                    ),
                                    filled: true,
                                    fillColor: ProjectColors.whiteColor.withOpacity(.06),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: width * .04,
                                      vertical: height * .018,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.12)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: ProjectColors.whiteColor.withOpacity(.25)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(height: height * .01),
                  Row(
                    children: [
                      Checkbox(
                        value: cards.setDefaultPayment!.value,
                        onChanged: (v) => cards.setDefaultPayment!.value = v ?? false,
                        side: BorderSide(color: ProjectColors.whiteColor.withOpacity(.3)),
                        activeColor: ProjectColors.whiteColor,
                        checkColor: ProjectColors.pureBlackColor,
                      ),
                      textWidget(
                        text: "Set as default",
                        fontSize: .014,
                        color: ProjectColors.whiteColor.withOpacity(.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),

                  SizedBox(height: height * .02),

                  normalButton(
                    callback: () {
                      if (cards.activeAccountTypes!.value == "Card") {
                        cards.addCardFromUI();
                      } else {
                        cards.addBankFromUI();
                      }
                    },
                    title: "Save ${cards.activeAccountTypes!.value}",
                    bColor: ProjectColors.greenColor,
                    invertColors: true,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
