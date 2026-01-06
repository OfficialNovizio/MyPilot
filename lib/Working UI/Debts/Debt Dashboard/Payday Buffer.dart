import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Constants.dart';

// -------------------- MODELS --------------------

class RecurringLeak {
  final String merchant; // "Monnth"
  final double amount; // 14.99
  final String frequencyLabel; // "/mo"
  final DateTime detectedAt; // 5 days ago
  final String? categoryChip; // "Subscription"
  final IconData icon; // payment icon
  final Color iconBg; // subtle bg

  RecurringLeak({
    required this.merchant,
    required this.amount,
    required this.frequencyLabel,
    required this.detectedAt,
    this.categoryChip,
    this.icon = Icons.credit_card,
    this.iconBg = const Color(0xFF1B1B1B),
  });
}

class WatchItem {
  final String title; // "Visa interest: ~$2.10/day"
  final String subtitle; // "Pay $50 now (saves ~$15)"
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  WatchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });
}

// -------------------- PUBLIC API --------------------

Future<void> showSpendingLeaksSheet({
  required RecurringLeak leak,
  required List<WatchItem> watchItems,
  VoidCallback? onClose,
  VoidCallback? onMarkSubscription,
  VoidCallback? onViewMerchant,
}) async {
  await showCupertinoModalPopup(
    context: Get.context!,
    barrierDismissible: true,
    builder: (_) {
      return SpendingLeaksSheet(
        leak: leak,
        watchItems: watchItems,
        onClose: onClose,
        onMarkSubscription: onMarkSubscription,
        onViewMerchant: onViewMerchant,
      );
    },
  );
}

// -------------------- SHEET UI --------------------

class SpendingLeaksSheet extends StatelessWidget {
  const SpendingLeaksSheet({
    required this.leak,
    required this.watchItems,
    this.onClose,
    this.onMarkSubscription,
    this.onViewMerchant,
  });

  final RecurringLeak leak;
  final List<WatchItem> watchItems;

  final VoidCallback? onClose;
  final VoidCallback? onMarkSubscription;
  final VoidCallback? onViewMerchant;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SizedBox(
      height: height * .9,
      child: Popup(
        color: ProjectColors.blackColor,
        title: 'Spending leaks',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.01),
            _InnerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: "New recurring charge detected:",
                    fontSize: 0.016,
                    fontWeight: FontWeight.w700,
                    color: ProjectColors.whiteColor.withOpacity(0.75),
                  ),
                  SizedBox(height: height * 0.01),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      textWidget(
                        text: "\$${leak.amount.toStringAsFixed(2)}",
                        fontSize: 0.034,
                        fontWeight: FontWeight.w900,
                        color: ProjectColors.whiteColor,
                      ),
                      SizedBox(width: width * 0.01),
                      Padding(
                        padding: EdgeInsets.only(bottom: height * 0.004),
                        child: textWidget(
                          text: leak.frequencyLabel,
                          fontSize: 0.016,
                          fontWeight: FontWeight.w800,
                          color: ProjectColors.whiteColor.withOpacity(0.65),
                        ),
                      ),
                      const Spacer(),
                      if (leak.categoryChip != null) _Chip(text: leak.categoryChip!),
                    ],
                  ),
                  SizedBox(height: height * 0.006),
                  textWidget(
                    text: "${_daysAgo(leak.detectedAt)} days ago",
                    fontSize: 0.014,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.brownColor.withOpacity(0.90),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.012),

            // Merchant row card
            _TapRowCard(
              icon: leak.icon,
              iconBg: leak.iconBg,
              title: leak.merchant,
              rightText: "\$${leak.amount.toStringAsFixed(2)}",
              onTap: onViewMerchant,
            ),

            SizedBox(height: height * 0.010),

            // Action row
            _TapRowCard(
              icon: Icons.bookmark_add,
              iconBg: Colors.white.withOpacity(0.06),
              title: "Mark as subscription",
              rightText: "",
              onTap: onMarkSubscription ??
                  () {
                    // default: just close
                    Get.back();
                  },
            ),

            SizedBox(height: height * 0.018),

            textWidget(
              text: "Things to watch",
              fontSize: 0.017,
              fontWeight: FontWeight.w900,
              color: ProjectColors.whiteColor.withOpacity(0.55),
            ),

            SizedBox(height: height * 0.012),

            // Watch list
            ...watchItems.map((w) {
              return Padding(
                padding: EdgeInsets.only(bottom: height * 0.010),
                child: _WatchRow(
                  item: w,
                ),
              );
            }).toList(),

            // optional: primary CTA (keep it minimal)
            if (watchItems.isNotEmpty) ...[
              SizedBox(height: height * 0.010),
              normalButton(
                title: "Review all insights",
                cHeight: 0.06,
                cWidth: 1.0,
                bColor: ProjectColors.lightGreenColor,
                invertColors: true,
                callback: () {
                  Get.back();
                  // TODO: navigate to Insights page
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -------------------- SMALL WIDGETS --------------------

class _InnerCard extends StatelessWidget {
  const _InnerCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.006),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: textWidget(
        text: text,
        fontSize: 0.014,
        fontWeight: FontWeight.w800,
        color: ProjectColors.whiteColor.withOpacity(0.80),
      ),
    );
  }
}

class _TapRowCard extends StatelessWidget {
  const _TapRowCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.rightText,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String rightText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.014),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              height: height * 0.042,
              width: height * 0.042,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Icon(icon, color: ProjectColors.whiteColor.withOpacity(0.85), size: height * 0.022),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: textWidget(
                text: title,
                fontSize: 0.016,
                fontWeight: FontWeight.w800,
                color: ProjectColors.whiteColor.withOpacity(0.90),
              ),
            ),
            if (rightText.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(right: width * 0.02),
                child: textWidget(
                  text: rightText,
                  fontSize: 0.016,
                  fontWeight: FontWeight.w900,
                  color: ProjectColors.whiteColor,
                ),
              ),
            Icon(Icons.chevron_right, color: ProjectColors.whiteColor.withOpacity(0.35), size: height * 0.024),
          ],
        ),
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.item});
  final WatchItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.014),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.iconColor, size: height * 0.022),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                    text: item.title,
                    fontSize: 0.015,
                    fontWeight: FontWeight.w800,
                    color: ProjectColors.whiteColor.withOpacity(0.90),
                  ),
                  SizedBox(height: height * 0.006),
                  textWidget(
                    text: item.subtitle,
                    fontSize: 0.014,
                    fontWeight: FontWeight.w600,
                    color: ProjectColors.whiteColor.withOpacity(0.55),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ProjectColors.whiteColor.withOpacity(0.30), size: height * 0.024),
          ],
        ),
      ),
    );
  }
}

// -------------------- HELPERS --------------------

int _daysAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt).inDays;
  return diff < 0 ? 0 : diff;
}
