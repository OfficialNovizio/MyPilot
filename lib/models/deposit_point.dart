// lib/models/deposit_point.dart
class DepositPoint {
  final DateTime date;       // deposit date
  final double starbucks;    // est. net for Starbucks on this date
  final double superstore;   // est. net for Superstore on this date

  const DepositPoint(this.date, this.starbucks, this.superstore);

  double get total => starbucks + superstore;

  DepositPoint copyWith({
    DateTime? date,
    double? starbucks,
    double? superstore,
  }) =>
      DepositPoint(
        date ?? this.date,
        starbucks ?? this.starbucks,
        superstore ?? this.superstore,
      );
}
