import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../BaseScreen.dart';
import '../../../Constant UI.dart';
import '../../../Constants.dart';
import '../../../Controllers.dart';

class CreditRecordPaymentScreen extends StatefulWidget {
  const CreditRecordPaymentScreen({super.key});

  @override
  State<CreditRecordPaymentScreen> createState() => _DebtRecordPaymentScreenState();
}

class _DebtRecordPaymentScreenState extends State<CreditRecordPaymentScreen> {
  late final TextEditingController amtC;
  late final TextEditingController noteC;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxDouble amtValue = 0.0.obs;

  @override
  void initState() {
    super.initState();
    amtC = TextEditingController();
    noteC = TextEditingController();

    amtC.addListener(() {
      amtValue.value = _parseMoney(amtC.text);
    });
  }

  @override
  void dispose() {
    amtC.dispose();
    noteC.dispose();
    super.dispose();
  }

  // -------------------------
  // Helpers
  // -------------------------

  double _parseMoney(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0.0;

    final parts = cleaned.split('.');
    final safe = parts.length <= 2 ? cleaned : "${parts[0]}.${parts.sublist(1).join()}";
    return double.tryParse(safe) ?? 0.0;
  }

  double _afterPaymentEstimate({required double balance, required double amount}) {
    return (balance - amount).clamp(0.0, 1e12).toDouble();
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(
          text: k,
          fontSize: .014,
          fontWeight: FontWeight.w700,
          color: ProjectColors.whiteColor.withOpacity(.55),
        ),
        SizedBox(height: height * .006),
        textWidget(
          text: v,
          fontSize: .02,
          fontWeight: FontWeight.w900,
          color: ProjectColors.whiteColor,
        ),
      ],
    );
  }

  // -------------------------

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: "Record Payment",
      body: Obx(() {
        final d = debtV2.selectedDebt.value;
        final afterEst = _afterPaymentEstimate(balance: d!.balance, amount: amtValue.value);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: height * .012),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * .01),
              textWidget(
                text: d.name,
                fontSize: .016,
                fontWeight: FontWeight.w700,
                color: ProjectColors.whiteColor.withOpacity(.6),
              ),
              SizedBox(height: height * .01),
              DarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance info
                    Row(
                      children: [
                        Expanded(child: _kv("Balance", money2(d.balance))),
                        Expanded(child: _kv("After (est.)", money2(afterEst))),
                      ],
                    ),

                    SizedBox(height: height * .01),
                    divider(),
                    SizedBox(height: height * .01),

                    // Amount
                    DarkTextField(
                      title: 'Amount',
                      hintText: "e.g. 120",
                      controller: amtC,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    SizedBox(height: height * .01),

                    // Date
                    DarkTextField(
                      title: 'Date',
                      hintText: formatDate(selectedDate.value),
                      onTap: () async {
                        final res = await AppPicker.pick(mode: PickerMode.date, title: "Select Date");
                        if (res != null) {
                          selectedDate.value = res.dateTime!;
                        }
                      },
                      trailing: Icon(Icons.access_time_rounded, size: height * 0.022, color: ProjectColors.whiteColor.withOpacity(0.75)),
                    ),

                    SizedBox(height: height * .01),

                    // Note
                    DarkTextField(
                      title: 'Note',
                      hintText: "e.g. extra payment",
                      controller: noteC,
                    ),
                    SizedBox(height: height * .02),

                    // Save
                    normalButton(
                      title: 'Save Payment',
                      bColor: ProjectColors.greenColor,
                      callback: () async {
                        final amt = amtValue.value;
                        if (amt <= 0) {
                          showSnackBar("Invalid", "Enter a valid amount.");
                          return;
                        }

                        await debtV2.recordPayment(amount: amt, date: selectedDate.value, note: noteC.text);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * .02),
              DarkCard(
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, color: ProjectColors.whiteColor.withOpacity(.55), size: height * .022),
                    SizedBox(width: width * .03),
                    Expanded(
                      child: textWidget(
                        text: "Saving a payment will reduce your balance instantly and update progress everywhere.",
                        fontSize: .015,
                        fontWeight: FontWeight.w700,
                        color: ProjectColors.whiteColor.withOpacity(.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * .03),
            ],
          ),
        );
      }),
    );
  }
}
