class AprPreset {
  final String issuer; // e.g., "Scotiabank"
  final String productLabel; // e.g., "Typical (many cards)"
  final double purchaseApr; // %
  final double cashApr; // %
  final double balanceApr; // % (often same as cash)
  final String notes; // any caveats (penalty rate, product-specific, etc.)

  const AprPreset({
    required this.issuer,
    required this.productLabel,
    required this.purchaseApr,
    required this.cashApr,
    required this.balanceApr,
    this.notes = "",
  });
}

/// Use these as selectable presets in UI.
/// After selecting, still allow user to edit values.
const List<AprPreset> canadaAprPresets = [
  // -------------------------
  // Big banks / major FIs
  // -------------------------
  AprPreset(
    issuer: "Scotiabank",
    productLabel: "Typical (many cards)",
    purchaseApr: 20.99,
    cashApr: 22.99,
    balanceApr: 22.99,
    notes: "Some cards vary ~19.99–20.99 purchases; low-rate products exist.",
  ),
  AprPreset(
    issuer: "CIBC",
    productLabel: "Typical (many cards)",
    purchaseApr: 20.99,
    cashApr: 22.99,
    balanceApr: 22.99,
    notes: "Some cards can trigger penalty rates after certain behaviors.",
  ),
  AprPreset(
    issuer: "RBC",
    productLabel: "Low Rate (example product)",
    purchaseApr: 12.99,
    cashApr: 12.99,
    balanceApr: 12.99,
    notes: "Product-specific low-rate example.",
  ),
  AprPreset(
    issuer: "TD",
    productLabel: "Low Rate (behavior-sensitive)",
    purchaseApr: 12.99,
    cashApr: 12.99,
    balanceApr: 12.99,
    notes: "Some TD terms mention higher standard rate after repeated missed minimum payments.",
  ),
  AprPreset(
    issuer: "National Bank",
    productLabel: "Typical (example)",
    purchaseApr: 20.99,
    cashApr: 22.99,
    balanceApr: 22.99,
    notes: "Cash/BT may show ~22.xx depending on product.",
  ),
  AprPreset(
    issuer: "Desjardins",
    productLabel: "Flexi Visa (example)",
    purchaseApr: 10.90,
    cashApr: 12.90,
    balanceApr: 12.90,
    notes: "Product-specific example; other cards may be ~20.9 purchase / 21.9 cash.",
  ),
  AprPreset(
    issuer: "Desjardins",
    productLabel: "Typical (other cards)",
    purchaseApr: 20.90,
    cashApr: 21.90,
    balanceApr: 21.90,
    notes: "General example for other Desjardins cards.",
  ),

  // -------------------------
  // Non-bank issuers
  // -------------------------
  AprPreset(
    issuer: "Tangerine",
    productLabel: "Money-Back (example)",
    purchaseApr: 20.95,
    cashApr: 22.95,
    balanceApr: 22.95,
    notes: "Rates may increase after consecutive missed minimum payments (product terms).",
  ),
  AprPreset(
    issuer: "Rogers Bank",
    productLabel: "Typical (example)",
    purchaseApr: 20.99,
    cashApr: 22.99,
    balanceApr: 22.99,
    notes: "May have alternate higher tier depending on product/terms.",
  ),
  AprPreset(
    issuer: "MBNA",
    productLabel: "Low-interest (example)",
    purchaseApr: 10.99,
    cashApr: 24.99,
    balanceApr: 24.99,
    notes: "Product-specific example; cash APR can be much higher than purchase APR.",
  ),
  AprPreset(
    issuer: "Canadian Tire (Triangle Mastercard)",
    productLabel: "Typical (example)",
    purchaseApr: 21.99,
    cashApr: 21.99,
    balanceApr: 21.99,
    notes: "Example terms show 21.99% for many charges (varies by terms/region).",
  ),
];
