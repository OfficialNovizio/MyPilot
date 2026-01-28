enum BnplPlanType { payIn4, payMonthly, payIn3, payIn6, other }

enum RepaymentMethodType {
  debitCard,
  creditCard,
  bankAccountPAD, // pre-authorized debit / direct debit
  applePay,
  googlePay,
  prepaidCard, // if explicitly supported
  other,
}

class RepaymentRules {
  /// Some providers allow bank/PAD only for scheduled payments,
  /// but require a debit/credit card for the first payment.
  final bool firstPaymentRequiresCard;

  /// Some providers allow credit cards only for certain parts (e.g., down payment).
  final bool creditCardAllowedForScheduledPayments;

  /// Notes like "prepaid cards not accepted" or "AMEX not accepted".
  final String notes;

  const RepaymentRules({
    required this.firstPaymentRequiresCard,
    required this.creditCardAllowedForScheduledPayments,
    required this.notes,
  });
}

class BnplPlan {
  final BnplPlanType? type;

  /// Typical installment count (Pay-in-4 = 4), if known.
  final int? installments;

  /// Typical cadence (e.g., "biweekly", "monthly", "6 weeks"), if known.
  final String? cadence;

  /// Whether plan can be 0% (many Pay-in-4 are 0% if on time).
  final bool? canBeZeroApr;

  BnplPlan({
    this.type,
    this.installments,
    this.cadence,
    this.canBeZeroApr,
  });
}

class BnplProvider {
  final String id; // stable internal id e.g. "klarna_ca"
  final String name; // "Klarna"
  final String market; // "CA"
  final String website; // official site/help page
  final List<BnplPlan> plans; // pay-in-4, monthly, etc.
  final List<RepaymentMethodType> supportedRepaymentMethods;
  final RepaymentRules rules;

  /// Optional: provider is active/available in your market right now.
  final bool isActiveInMarket;

  const BnplProvider({
    required this.id,
    required this.name,
    required this.market,
    required this.website,
    required this.plans,
    required this.supportedRepaymentMethods,
    required this.rules,
    required this.isActiveInMarket,
  });
}
