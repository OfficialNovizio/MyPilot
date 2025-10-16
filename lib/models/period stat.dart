class PeriodStat {
  final DateTime start, end;
  final double gross, net, hours, ot;
  final double income, cpp, ei, other, post;
  final double statUplift;
  PeriodStat({
    required this.start, required this.end,
    required this.gross, required this.net, required this.hours, required this.ot,
    required this.income, required this.cpp, required this.ei, required this.other, required this.post,
    required this.statUplift,
  });
}

class MonthBucket {
  final double gross, net, hours, ot;
  final double income, cpp, ei, other, post;
  final double statUplift;
  MonthBucket({
    required this.gross, required this.net, required this.hours, required this.ot,
    required this.income, required this.cpp, required this.ei, required this.other, required this.post,
    required this.statUplift,
  });
}
