
class AppSettings {
  bool weekStartsOnMonday;
  bool overtimeEnabled;
  int overtimeThresholdWeekly;
  AppSettings({
    required this.weekStartsOnMonday,
    required this.overtimeEnabled,
    required this.overtimeThresholdWeekly,
  });
  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    weekStartsOnMonday: (j['weekStartsOnMonday'] ?? true) as bool,
    overtimeEnabled: (j['overtimeEnabled'] ?? true) as bool,
    overtimeThresholdWeekly: (j['overtimeThresholdWeekly'] ?? 40) as int,
  );
  Map<String, dynamic> toJson() => {
    'weekStartsOnMonday': weekStartsOnMonday,
    'overtimeEnabled': overtimeEnabled,
    'overtimeThresholdWeekly': overtimeThresholdWeekly,
  };
}
