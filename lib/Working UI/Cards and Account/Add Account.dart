import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../BaseScreen.dart';
import '../Constant UI.dart';
import '../Constants.dart';
import '../Controllers.dart';
import '../Pipeline.dart';

class AddPaymentMethod extends StatefulWidget {
  final bool? isEditing;
  final bool? isCardEditing;
  AddPaymentMethod({this.isEditing = false, this.isCardEditing = true});

  @override
  State<AddPaymentMethod> createState() => _AddPaymentMethodState();
}

class _AddPaymentMethodState extends State<AddPaymentMethod> {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.isEditing!
          ? widget.isCardEditing!
              ? 'Card'
              : 'Account'
          : 'New Account',
      body: SingleChildScrollView(
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.isEditing!
                ? widget.isCardEditing!
                    ? [
                        SizedBox(height: height * .02),
                        CardFields(),
                        SizedBox(height: height * .02),
                        normalButton(
                          callback: () {
                            cards.editCardFromUI();
                          },
                          title: "Save ${cards.activeAccountTypes!.value}",
                          bColor: ProjectColors.greenColor,
                        ),
                      ]
                    : [
                        AccountFields(),
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
                      ]
                : [
                    SizedBox(height: height * .02),
                    textWidget(
                      text: "Select Type",
                      fontSize: .016,
                      color: ProjectColors.whiteColor,
                      fontWeight: FontWeight.w800,
                    ),
                    SizedBox(height: height * .012),

                    // ✅ Wrap so it never overflows
                    segmentedToggle(
                      options: cards.accountTypes!,
                      cWidth: .45,
                      selectedIndex: (() {
                        final idx = cards.accountTypes!.map((e) => e).toList().indexOf(cards.activeAccountTypes!.value);
                        return idx < 0 ? 0 : idx;
                      })(),
                      onChanged: (i, v) {
                        cards.activeAccountTypes!.value = v;
                      },
                    ),
                    SizedBox(height: height * .02),
                    cards.activeAccountTypes!.value == 'Card' ? CardFields() : AccountFields(),
                    // fields list
                    SizedBox(height: height * .02),
                    normalButton(
                      callback: () {
                        if (!widget.isEditing!) {
                          if (cards.activeAccountTypes!.value == "Card") {
                            cards.addCardFromUI().then((value) {
                              if (value.message == 'card added') {
                                Future.delayed(const Duration(seconds: 2), () {
                                  Pipeline().cardStatusInDebt();
                                });
                              }
                            });
                          } else {
                            cards.addBankFromUI();
                          }
                        } else {
                          if (widget.isCardEditing!) {
                            cards.editCardFromUI().then((value) {
                              if (value.message == 'card updated') {
                                Future.delayed(const Duration(seconds: 2), () {
                                  Pipeline().updateCardAndAccountStatus(id: cards.selectedCard.value!.id);
                                });
                              }
                            });
                          } else {
                            // cards.editCardFromUI();
                          }
                        }
                      },
                      title: "Save ${cards.activeAccountTypes!.value}",
                      bColor: ProjectColors.greenColor,
                    ),
                  ],
          );
        }),
      ),
    );
  }
}

class CardFields extends StatelessWidget {
  const CardFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(children: [
        ...cards.creditCard.sublist(0, 3).map((f) {
          return Padding(
            padding: EdgeInsets.only(bottom: height * .008),
            child: f.title.contains('Expiry')
                ? DarkTextField(
                    title: 'Expiry Date',
                    hintText: f.controller.text.isEmpty ? 'Select' : f.controller.text,
                    leading: Icon(Icons.calendar_month_rounded, color: ProjectColors.whiteColor.withOpacity(0.75)),
                    onTap: () async {
                      final res = await AppPicker.pick(mode: PickerMode.date, title: "Select Date", minDate: DateTime(2025));
                      if (res != null) {
                        f.controller.text = formatDate(res.dateTime!);
                        f.pickedDate = res.dateTime!;
                        cards.creditCard.refresh();
                      }
                    },
                    trailing: Icon(Icons.arrow_circle_down_outlined, color: ProjectColors.whiteColor.withOpacity(0.75)),
                  )
                : DarkTextField(controller: f.controller, hintText: f.title, title: f.title),
          );
        }).toList(),
        Wrap(
          spacing: width * .02,
          children: cards.creditCard
              .sublist(3, 7)
              .map(
                (f) => Padding(
                  padding: EdgeInsets.symmetric(vertical: height * .004),
                  child: SizedBox(
                    width: (f.title.contains("Last") || f.title.contains("Type")) ? width : width * .47,
                    child: f.title.contains('Available')
                        ? DarkTextField(
                            controller: f.controller,
                            hintText: f.title,
                            title: f.title,
                            onTap: () {
                              showSnackBar(
                                'Available Limit Restricted',
                                'You have outstanding debt. Go to Debt screen to resolve and unlock your available limit.',
                              );
                            },
                          )
                        : DarkTextField(controller: f.controller, hintText: f.title, title: f.title),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: height * .005),
        Row(
          children: [
            Expanded(
              child: DarkTextField(
                title: 'Statement Date',
                hintText: cards.creditCard[7].controller.text.isEmpty ? 'Select' : cards.creditCard[7].controller.text,
                trailing: Icon(Icons.calendar_month_rounded, size: height * .022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                onTap: () async {
                  final res = await AppPicker.pick(mode: PickerMode.date, title: "Select Date", minDate: DateTime(2025));
                  if (res != null) {
                    cards.creditCard[7].controller.text = formatDate(res.dateTime!);
                    cards.creditCard[7].pickedDate = res.dateTime!;
                    cards.creditCard.refresh();
                  }
                },
              ),
            ),
            SizedBox(width: width * .02),
            Expanded(
              child: DarkTextField(
                title: 'Due Date',
                hintText: cards.creditCard[9].controller.text.isEmpty ? 'Select' : cards.creditCard[9].controller.text,
                trailing: Icon(Icons.calendar_month_rounded, size: height * .022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                onTap: () async {
                  final res = await AppPicker.pick(mode: PickerMode.date, title: "Select Date");
                  if (res != null) {
                    cards.creditCard[9].controller.text = formatDate(res.dateTime!);
                    cards.creditCard[9].pickedDate = res.dateTime!;
                    cards.creditCard.refresh();
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: height * .01),
        DarkTextField(
          title: 'Card Type',
          hintText: cards.creditCard[8].controller.text.isEmpty ? 'Select' : cards.creditCard[8].controller.text,
          leading: Icon(Icons.credit_card, color: ProjectColors.whiteColor.withOpacity(0.75)),
          onTap: () async {
            callBottomSheet(child: AccountOptions(showCardOptions: true), title: 'Card Type');
          },
          trailing: Icon(Icons.arrow_circle_down_rounded, color: ProjectColors.whiteColor.withOpacity(0.75)),
        )
      ]),
    );
  }
}

class AccountFields extends StatelessWidget {
  const AccountFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...cards.bankAccount.map((f) {
          return Padding(
            padding: EdgeInsets.only(bottom: height * .008),
            child: f.title == "Account Type"
                ? DarkTextField(
                    title: 'Account Type',
                    hintText: f.controller.text.isEmpty ? 'Select' : f.controller.text,
                    leading: Icon(Icons.account_balance_outlined, color: ProjectColors.whiteColor.withOpacity(0.75)),
                    onTap: () async {
                      callBottomSheet(child: AccountOptions(), title: 'Account Type');
                    },
                    trailing: Icon(Icons.arrow_drop_down_outlined, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                  )
                : f.title.contains('Expiry')
                    ? DarkTextField(
                        title: 'Expiry Date',
                        hintText: f.controller.text.isEmpty ? 'Select' : f.controller.text,
                        leading: Icon(Icons.calendar_month_rounded, color: ProjectColors.whiteColor.withOpacity(0.75)),
                        onTap: () async {
                          final res = await AppPicker.pick(mode: PickerMode.date, title: "Select Date", minDate: DateTime(2025));
                          if (res != null) {
                            f.controller.text = formatDate(res.dateTime!);
                            f.pickedDate = res.dateTime!;
                            cards.creditCard.refresh();
                          }
                        },
                        trailing: Icon(Icons.arrow_circle_right_outlined, color: ProjectColors.whiteColor.withOpacity(0.75)),
                      )
                    : DarkTextField(controller: f.controller, hintText: f.title, title: f.title),
          );
        }).toList(),
      ],
    );
  }
}

class AccountOptions extends StatelessWidget {
  final bool? showCardOptions;
  AccountOptions({this.showCardOptions = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: showCardOptions!
          ? cards.cardType
              .map(
                (x) => ListTile(
                  title: textWidget(
                    text: x,
                    fontSize: .015,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(.9),
                  ),
                  onTap: () {
                    cards.creditCard[8].controller.text = x;
                    cards.creditCard.refresh();
                    Get.back();
                  },
                ),
              )
              .toList()
          : cards.accounts
              .map(
                (x) => ListTile(
                  title: textWidget(
                    text: x,
                    fontSize: .015,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(.9),
                  ),
                  onTap: () {
                    cards.bankAccount[2].controller.text = x;
                    cards.bankAccount.refresh();
                    Get.back();
                  },
                ),
              )
              .toList(),
    );
  }
}
