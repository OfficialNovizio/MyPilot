class Shift {
  String id;
  String jobId;
  String date;       // YYYY-MM-DD
  String start;      // HH:mm
  String end;        // HH:mm
  int breakMin;
  String? notes;

  bool isStat; // NEW

  Shift({
    required this.id,
    required this.jobId,
    required this.date,
    required this.start,
    required this.end,
    this.breakMin = 0,
    this.notes,
    this.isStat = false, // NEW default
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'date': date,
    'start': start,
    'end': end,
    'breakMin': breakMin,
    'notes': notes,
    'isStat': isStat, // NEW
  };

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
    id: j['id'] as String,
    jobId: j['jobId'] as String,
    date: j['date'] as String,
    start: j['start'] as String,
    end: j['end'] as String,
    breakMin: (j['breakMin'] ?? 0) as int,
    notes: j['notes'] as String?,
    isStat: (j['isStat'] ?? false) as bool, // NEW
  );
}
