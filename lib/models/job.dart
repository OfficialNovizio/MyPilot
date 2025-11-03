class Job {
  String id;
  String name;
  String colorHex;
  double wage;
  String payFrequency; // 'weekly' | 'biweekly'
  DateTime? lastPaychequeIso; // 'YYYY-MM-DD HH:mm'
  int weekStartDOW; // 1..7 (Mon..Sun)

  double statMultiplier;
  List<String> statDays;

  Job({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.wage,
    required this.payFrequency,
    required this.lastPaychequeIso,
    required this.weekStartDOW,
    required this.statMultiplier,
    required this.statDays,
  });

  factory Job.fromJson(Map<String, dynamic> j) {
    final pf = (j['payFrequency'] as String?) ?? 'weekly';
    final dowRaw = j['weekStartDOW'] is int ? j['weekStartDOW'] as int : 1;
    final dow = (dowRaw >= 1 && dowRaw <= 7) ? dowRaw : 1;
    return Job(
      id: j['id'],
      name: j['name'] ?? 'Job',
      colorHex: (j['colorHex'] as String?) ?? '#16a34a',
      wage: (j['wage'] ?? 0).toDouble(),
      payFrequency: (pf == 'biweekly') ? 'biweekly' : 'weekly',
      lastPaychequeIso: j['lastPaychequeIso'] ?? DateTime.now(),
      weekStartDOW: dow,
      statMultiplier: (j['statMultiplier'] ?? 1.5).toDouble(),
      statDays: (j['statDays'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'wage': wage,
        'payFrequency': payFrequency,
        'lastPaychequeIso': lastPaychequeIso,
        'weekStartDOW': weekStartDOW,
        'statMultiplier': statMultiplier,
        'statDays': statDays,
      };
}
