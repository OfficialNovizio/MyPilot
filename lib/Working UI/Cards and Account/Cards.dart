import 'package:carousel_slider/carousel_slider.dart';
import 'package:emptyproject/BaseScreen.dart';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/Expense%20Model%20V2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:get/get.dart';

import 'Add Account.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String? callingFrom;

  PaymentMethodsScreen({this.callingFrom = 'Card'});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return BaseScreen(
        title: 'Payment Accounts',
        body: SingleChildScrollView(
          child: cards.state.value == ButtonState.loading
              ? Padding(padding: EdgeInsets.only(top: height * .4), child: loader())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * .02),
                    AddContent(
                      title: 'Add Payment Method',
                      subTitle: 'Track limits, spending, and balances in one place',
                      callback: () {
                        Get.to(() => AddPaymentMethod());
                      },
                    ),
                    SizedBox(height: height * .025),
                    Visibility(
                      visible: cards.cards.isNotEmpty,
                      child: textWidget(
                        text: 'Cards',
                        fontSize: .02,
                        color: ProjectColors.whiteColor.withOpacity(.85),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: height * .012),
                    CarouselSlider(
                      options: CarouselOptions(
                        height: height * .255,
                        viewportFraction: 0.98, // 0.82–0.90 gives side peek
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
                                  if (widget.callingFrom! == 'Expense') {
                                    expenseV2.controllers[4].controller.text = m.bankName!;
                                    expenseV2.selectedAccount!.value = AccountRef(id: m.id, type: m.cardType!, name: m.bankName!);
                                    expenseV2.controllers.refresh();
                                    Get.back();
                                  } else if (widget.callingFrom! == 'Debt') {
                                    debtV2.selectedAccount.value = AccountRef(id: m.id, type: m.cardType!, name: m.bankName!);
                                    debtV2.controllers.refresh();
                                    Get.back();
                                  }
                                },
                                child: CreditCardListTile(
                                  bankName: m.bankName!,
                                  // cardType: 'VISA Platinum',
                                  cardType: m.cardType!,
                                  network: '',
                                  cardNumber: m.cardNumber!,
                                  cardHolder: m.cardHolderName!,
                                  expiry: formatDate(m.expiryDate!),
                                  limit: m.creditLimit!,
                                  available: m.creditLimitUsed!,
                                  onEdit: () {
                                    cards.selectedCard.value = m;
                                    cards.creditCard[0].controller.text = m.cardNumber!;
                                    cards.creditCard[1].controller.text = formatDate(m.expiryDate!);
                                    cards.creditCard[1].pickedDate = m.expiryDate;
                                    cards.creditCard[2].controller.text = m.cardHolderName!;
                                    cards.creditCard[3].controller.text = m.cvvCode!;
                                    cards.creditCard[4].controller.text = m.bankName!;
                                    cards.creditCard[5].controller.text = m.creditLimit.toString();
                                    cards.creditCard[6].controller.text = m.creditLimitUsed.toString();
                                    cards.creditCard[7].controller.text = formatDate(m.statementDate!);
                                    cards.creditCard[7].pickedDate = m.statementDate!;
                                    cards.creditCard[8].controller.text = m.cardType!;
                                    Get.to(() => AddPaymentMethod(isEditing: true, isCardEditing: true));
                                  },
                                  onRemove: () {
                                    cards.deleteCard(id: m.id);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                      // items: cards.cards.map((m) {
                      //   return Builder(
                      //     builder: (context) {
                      //       return Padding(
                      //         padding: EdgeInsets.only(right: width * .02),
                      //         child: GestureDetector(
                      //           onTap: () {
                      //             if (widget.callingFrom! == 'Expense') {
                      //               expenseV2.controllers[4].controller.text = m.bankName!;
                      //               expenseV2.selectedAccount!.value = AccountRef(id: m.id, type: m.cardType!, name: m.bankName!);
                      //               expenseV2.controllers.refresh();
                      //             } else if (widget.callingFrom! == 'Debt') {
                      //               debtV2.selectedAccount.value = AccountRef(id: m.id, type: m.cardType!, name: m.bankName!);
                      //               debtV2.controllers.refresh();
                      //             }
                      //             Get.back();
                      //           },
                      //           child: CreditCardWidget(
                      //             height: height * .25,
                      //             width: width,
                      //             cardNumber: formatCardNo(m.cardNumber!),
                      //             expiryDate: formatDate(m.expiryDate!, type: 'MM/yy'),
                      //             cardHolderName: m.cardHolderName!,
                      //             cvvCode: m.cvvCode!,
                      //             bankName: m.bankName,
                      //             showBackView: false,
                      //             obscureCardNumber: true,
                      //             obscureCardCvv: true,
                      //             isHolderNameVisible: true,
                      //             isSwipeGestureEnabled: false,
                      //             cardBgColor: ProjectColors.brownColor,
                      //             onCreditCardWidgetChange: (CreditCardBrand p1) {},
                      //           ),
                      //         ),
                      //       );
                      //     },
                      //   );
                      // }).toList(),
                    ),
                    SizedBox(height: height * .03),
                    Visibility(
                      visible: cards.banks.isNotEmpty,
                      child: textWidget(
                        text: 'Bank Accounts',
                        fontSize: .02,
                        color: ProjectColors.whiteColor.withOpacity(.85),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: height * .012),
                    Column(
                      children: cards.banks
                          .map(
                            (f) => GestureDetector(
                              onTap: () {
                                if (widget.callingFrom! == 'Expense') {
                                  expenseV2.controllers[4].controller.text = "${f.bankName!} ${f.accountType!}";
                                  expenseV2.selectedAccount!.value = AccountRef(id: f.id, type: f.accountType!, name: f.bankName!);
                                  expenseV2.controllers.refresh();
                                  Get.back();
                                } else if (widget.callingFrom! == 'Debt') {
                                  debtV2.selectedAccount.value = AccountRef(id: f.id, type: f.accountType!, name: f.bankName!);
                                  debtV2.controllers.refresh();
                                  Get.back();
                                }
                              },
                              child: BankAccountCard(
                                bankName: f.bankName!,
                                accountType: f.accountType!,
                                balance: f.balance!,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

class BankAccountCard extends StatelessWidget {
  final String bankName;
  final String accountType;
  final double balance;
  final VoidCallback? onMenuTap;

  const BankAccountCard({
    super.key,
    required this.bankName,
    required this.accountType,
    required this.balance,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Row ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: bankName,
                    fontSize: .03,
                    fontWeight: FontWeight.bold,
                    color: ProjectColors.whiteColor,
                  ),
                  SizedBox(height: height * .004),
                  textWidget(
                    text: accountType,
                    fontSize: .018,
                    color: ProjectColors.whiteColor.withOpacity(0.7),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onMenuTap,
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          SizedBox(height: height * .025),

          // ─── Identifier Row (account number placeholder) ───
          textWidget(
            text: "•••• •••• •••• 2277",
            fontSize: .022,
            color: ProjectColors.whiteColor.withOpacity(0.85),
          ),

          SizedBox(height: height * .025),

          // ─── Balance Section (PRIMARY) ──────────────
          textWidget(
            text: "Balance",
            fontSize: .015,
            color: ProjectColors.whiteColor.withOpacity(0.5),
          ),
          SizedBox(height: height * .004),
          textWidget(
            text: "\$${balance.toStringAsFixed(2)}",
            fontSize: .03,
            fontWeight: FontWeight.w600,
            color: ProjectColors.whiteColor,
          ),
        ],
      ),
    );
  }
}

class CreditCardListTile extends StatefulWidget {
  final String bankName;
  final String cardType; // e.g. VISA Platinum
  final String network; // VISA / MC
  final String cardNumber;
  final String cardHolder;
  final String expiry;
  final double limit;
  final double available;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const CreditCardListTile({
    super.key,
    required this.bankName,
    required this.cardType,
    required this.network,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiry,
    required this.limit,
    required this.available,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  State<CreditCardListTile> createState() => _CreditCardListTileState();
}

class _CreditCardListTileState extends State<CreditCardListTile> {
  bool showFull = false;

  double get usedAmount => (widget.limit - widget.available).clamp(0.0, widget.limit);

  double get progress => widget.limit <= 0 ? 0 : usedAmount / widget.limit;

  String get maskedNumber {
    final raw = widget.cardNumber.replaceAll(RegExp(r'\s'), '');
    final last4 = raw.substring(raw.length - 4);
    return '•••• •••• •••• $last4';
  }

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      color: ProjectColors.backgroundColor,
      opacity: 1,
      borderOpacity: .08,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: height * .01),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textWidget(
                      text: widget.bankName,
                      fontSize: .018,
                      fontWeight: FontWeight.w700,
                      color: ProjectColors.whiteColor,
                    ),
                    SizedBox(height: height * .003),
                    textWidget(
                      text: widget.cardType,
                      fontSize: .014,
                      color: ProjectColors.softText,
                    ),
                  ],
                ),
                Row(
                  children: [
                    textWidget(
                      text: widget.network,
                      fontSize: .018,
                      fontWeight: FontWeight.w800,
                      color: ProjectColors.whiteColor,
                    ),
                    PopupMenuButton<String>(
                      color: ProjectColors.blackColor,
                      icon: Icon(Icons.more_vert, color: ProjectColors.whiteColor),
                      onSelected: (v) {
                        if (v == 'edit') widget.onEdit();
                        if (v == 'remove') widget.onRemove();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: textWidget(
                            text: 'Edit',
                            color: ProjectColors.whiteColor,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: textWidget(
                            text: 'Remove',
                            color: ProjectColors.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: height * .015),

            // ─── CARD NUMBER ──────────────────────
            Row(
              children: [
                Expanded(
                  child: textWidget(
                    text: showFull ? formatCardNo(widget.cardNumber) : maskedNumber,
                    fontSize: .02,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.whiteColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => showFull = !showFull),
                  child: Icon(
                    showFull ? Icons.visibility_off : Icons.visibility,
                    color: ProjectColors.whiteColor.withOpacity(.6),
                    size: height * .022,
                  ),
                ),
              ],
            ),

            SizedBox(height: height * .012),

            // ─── META ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                textWidget(
                  text: widget.cardHolder.toUpperCase(),
                  fontSize: .014,
                  color: ProjectColors.softText,
                ),
                textWidget(
                  text: widget.expiry,
                  fontSize: .014,
                  color: ProjectColors.softText,
                ),
              ],
            ),

            SizedBox(height: height * .015),

            // ─── LIMIT ROW ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                textWidget(
                  text: 'Available: ${money(widget.available)}',
                  fontSize: .015,
                  fontWeight: FontWeight.w700,
                  color: ProjectColors.greenColor,
                ),
                textWidget(
                  text: 'Limit: ${money(widget.limit)}',
                  fontSize: .015,
                  color: ProjectColors.whiteColor.withOpacity(.75),
                ),
              ],
            ),

            SizedBox(height: height * .008),

            // ─── PROGRESS BAR ─────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: height * .006,
                backgroundColor: ProjectColors.whiteColor.withOpacity(.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > .9
                      ? ProjectColors.errorColor
                      : progress > .6
                          ? ProjectColors.yellowColor
                          : ProjectColors.greenColor,
                ),
              ),
            ),
            SizedBox(height: height * .008),
            textWidget(
              text: 'Limit Used: ${money(usedAmount)}',
              fontSize: .015,
              fontWeight: FontWeight.w700,
              color: progress > .9
                  ? ProjectColors.errorColor
                  : progress > .6
                      ? ProjectColors.yellowColor
                      : ProjectColors.greenColor,
            ),
          ],
        ),
      ),
    );
  }
}
