import 'package:emptyproject/models/shift.dart';
import 'package:flutter/material.dart';

class LineChartCardModel {
  final String title;
  final String totalText;
  final String changeText;
  final List<String> xLabels;
  final List<double> values;
  final double height;
  final Color color;

  const LineChartCardModel({
    required this.title,
    required this.totalText,
    required this.changeText,
    required this.xLabels,
    required this.values,
    this.height = 160,
    this.color = const Color(0xFF22C55E),
  }) : assert(xLabels.length == values.length, 'xLabels and values must have same length');

  factory LineChartCardModel.fromJson(Map<String, dynamic> json) {
    final int colorValue = (json['color'] as num?)?.toInt() ?? 0xFF22C55E;

    return LineChartCardModel(
      title: (json['title'] as String?) ?? '',
      totalText: (json['totalText'] as String?) ?? '',
      changeText: (json['changeText'] as String?) ?? '',
      xLabels: List<String>.from(json['xLabels'] ?? const []),
      values: (json['values'] as List? ?? const []).map((e) => (e as num).toDouble()).toList(),
      height: (json['height'] as num?)?.toDouble() ?? 160,
      color: Color(colorValue),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'totalText': totalText,
        'changeText': changeText,
        'xLabels': xLabels,
        'values': values,
        'height': height,
        'color': color.value, // ✅ int like 0xFF22C55E
      };
}

/// ---------------------------
/// VIEW MODEL (what UI needs)
/// ---------------------------

class DepositInsightsVM {
  String? monthLabel; // "December"
  bool? isCurrentMonth; // true => MTD + projection allowed
  int? jobCount; // 1 or more
  double? monthTotal; // 630
  double? monthChangePct; // 16 (vs prev month), null => N/A
  double? efficiency; // 28.64 ($/hr)
  double? efficiencyChangePct; // 6 (vs prev), null => N/A
  List<ShiftDay>? bestDayLabel; // "Fri, Dec 15" or "Best week: Dec 11–17"
  double? bestDayEarned; // 190
  String? bestWeekLabel; // 190
  double? bestWeekEarned; // 190
  int? workedDays; // 22
  int? daysInMonth; // 31
  String? topSourceName; // "DoorDash"
  double? topSourceValue; // 62
  double? topSourceSharePct; // 62
  double? projectedMonthEnd; // 2100
  List<String>? microLabels; // ["Sat","Sun","Mon","Tue","Wed"]
  List<double>? microValues; // [..] for small bars; can be empty

  DepositInsightsVM({
    this.monthLabel,
    this.isCurrentMonth,
    this.jobCount,
    this.monthTotal,
    this.monthChangePct,
    this.efficiency,
    this.efficiencyChangePct,
    this.bestDayLabel,
    this.bestDayEarned,
    this.workedDays,
    this.daysInMonth,
    this.topSourceName,
    this.topSourceSharePct,
    this.topSourceValue,
    this.projectedMonthEnd,
    this.bestWeekLabel, // 190
    this.bestWeekEarned,
    this.microLabels = const [],
    this.microValues = const [],
  });

  bool get isMultiJob => jobCount! > 1;
}

/// ---------------------------
/// BestDayResult (what UI needs)
/// ---------------------------

class DepositInsightsResult {
  final List<DateTime> bestDayDates;
  final double bestDayEarned;

  final String bestWeekLabel; // "7 - 13"
  final double bestWeekEarned;

  final int workedDays;
  final int daysInMonth;

  final String topSourceName;
  final double topSourceSharePct;

  const DepositInsightsResult({
    required this.bestDayDates,
    required this.bestDayEarned,
    required this.bestWeekLabel,
    required this.bestWeekEarned,
    required this.workedDays,
    required this.daysInMonth,
    required this.topSourceName,
    required this.topSourceSharePct,
  });
}
