import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/models/Debt%20Model.dart';
import 'package:flutter/material.dart';

import '../../../Constants.dart';
import 'Credit Card Logic.dart';

/// Single “multi-APR credit card” UI card (only the card).
/// Drop this anywhere inside your list.
/// Assumes you already have: ProjectColors, textWidget, money(), width, height.

class CreditDebtCard extends StatelessWidget {
  final DebtItem? data;

  CreditDebtCard({this.data});

  @override
  Widget build(BuildContext context) {
    final profiles = CreditCardDebtLogic().aprProfilesFromDebt(data!);

    return DarkCard(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: ProjectColors.whiteColor.withOpacity(.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ProjectColors.whiteColor.withOpacity(.10)),
          ),
          child: Column(
            children: [
              // ---------- Header ----------
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .016),
                child: Row(
                  children: [
                    // icon placeholder (swap with your bank logo widget if you want)
                    Container(
                      height: height * .05,
                      width: height * .05,
                      decoration: BoxDecoration(
                        color: ProjectColors.whiteColor.withOpacity(.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ProjectColors.whiteColor.withOpacity(.10)),
                      ),
                      child: Icon(Icons.credit_card, color: ProjectColors.whiteColor.withOpacity(.85), size: height * .026),
                    ),
                    SizedBox(width: width * .03),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textWidget(
                            text: data!.name,
                            fontSize: .02,
                            fontWeight: FontWeight.w900,
                            color: ProjectColors.whiteColor,
                          ),
                          SizedBox(height: height * .004),
                          textWidget(
                            text: "0 profiles",
                            fontSize: .015,
                            fontWeight: FontWeight.w800,
                            color: ProjectColors.greenColor.withOpacity(.85),
                          ),
                        ],
                      ),
                    ),

                    textWidget(
                      text: money(data!.balance),
                      fontSize: .022,
                      fontWeight: FontWeight.w900,
                      color: ProjectColors.whiteColor,
                    ),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1, color: ProjectColors.whiteColor.withOpacity(.06)),

              // ---------- Profiles ----------
              for (int i = 0; i < profiles.length; i++) ...[
                _AprProfileTile(row: profiles[i]),
                if (i != profiles.length - 1) Divider(height: 1, thickness: 1, color: ProjectColors.whiteColor.withOpacity(.06)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One row inside the card (Purchase/Cash/Balance Transfer)
class _AprProfileTile extends StatelessWidget {
  final AprProfileRow row;
  const _AprProfileTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .013),
      child: Row(
        children: [
          // left icon
          Container(
            height: height * .038,
            width: height * .038,
            decoration: BoxDecoration(
              color: ProjectColors.whiteColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ProjectColors.whiteColor.withOpacity(.10)),
            ),
            child: Icon(row.icon, color: ProjectColors.whiteColor.withOpacity(.8), size: height * .02),
          ),

          SizedBox(width: width * .03),

          // title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(
                  text: row.title,
                  fontSize: .017,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
                SizedBox(height: height * .004),
                textWidget(
                  text: _meta(row),
                  fontSize: .014,
                  fontWeight: FontWeight.w700,
                  color: ProjectColors.whiteColor.withOpacity(.55),
                ),
              ],
            ),
          ),

          // right chip + APR
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Chip(text: row.chipText, trailing: Icons.chevron_right_rounded),
              SizedBox(height: height * .006),
              textWidget(
                text: "${row.apr.toStringAsFixed(2)}%",
                fontSize: .015,
                fontWeight: FontWeight.w900,
                color: ProjectColors.whiteColor.withOpacity(.85),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _meta(AprProfileRow r) {
    final minTxt = r.minPayment == null ? "" : " • Min ${money(r.minPayment!)}";
    final dueTxt = r.dueDay == null ? "" : " • Due ${_suffixDay(r.dueDay!)}";
    final promoTxt = r.promoNote == null || r.promoNote!.trim().isEmpty ? "" : " • ${r.promoNote}";
    return "APR ${r.apr.toStringAsFixed(2)}%$minTxt$dueTxt$promoTxt";
  }

  String _suffixDay(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    switch (d % 10) {
      case 1:
        return '${d}st';
      case 2:
        return '${d}nd';
      case 3:
        return '${d}rd';
      default:
        return '${d}th';
    }
  }
}

/// Small pill chip used on the right (Purchase/Cash/Balance Transfer)
class _Chip extends StatelessWidget {
  final String text;
  final IconData? trailing;

  const _Chip({required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * .03, vertical: height * .006),
      decoration: BoxDecoration(
        color: ProjectColors.greenColor.withOpacity(.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProjectColors.greenColor.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget(
            text: text,
            fontSize: .0135,
            fontWeight: FontWeight.w900,
            color: ProjectColors.greenColor,
          ),
          if (trailing != null) ...[
            SizedBox(width: width * .01),
            Icon(trailing, size: height * .02, color: ProjectColors.greenColor.withOpacity(.85)),
          ],
        ],
      ),
    );
  }
}

/// Data model for each APR “profile” inside the single card.
/// You’ll create 1–3 of these depending on what the card actually has.
class AprProfileRow {
  final String title; // "Purchase Balance", "Cash Balance", "Balance Transfer"
  final String chipText; // "Purchase", "Cash", "Balance Transfer 0.00%"
  final IconData icon;

  final double apr; // 19.99
  final double? minPayment; // optional
  final int? dueDay; // optional (23)
  final String? promoNote; // optional: "(until 9/2024)" or "(Promo)"

  const AprProfileRow({
    required this.title,
    required this.chipText,
    required this.icon,
    required this.apr,
    this.minPayment,
    this.dueDay,
    this.promoNote,
  });
}
