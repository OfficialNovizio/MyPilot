import 'package:emptyproject/models/job.dart';

class Shift {
  String? id;
  String? jobId;
  String? date; // YYYY-MM-DD
  String? start; // HH:mm
  String? end; // HH:mm
  String? breakMin;
  String? notes;
  bool? isStat; // NEW

  Shift({
    this.id,
    this.jobId,
    this.date,
    this.start,
    this.end,
    this.breakMin,
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
        breakMin: j['breakMin'] as String,
        notes: j['notes'] as String?,
        isStat: (j['isStat'] ?? false) as bool, // NEW
      );
}

class ShiftModel {
  int? status;
  String? message;
  List<ShiftMonth>? data;

  ShiftModel({this.status, this.message, this.data});

  ShiftModel.fromJson(Map<String, dynamic>? json) {
    status = json?['status'];
    message = json?['message'];
    final list = json?['data'] as List?;
    if (list != null) {
      data = <ShiftMonth>[];
      for (final v in list) {
        data!.add(ShiftMonth.fromJson(v is Map<String, dynamic> ? v : null));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['status'] = status;
    m['message'] = message;
    if (data != null) m['data'] = data!.map((e) => e.toJson()).toList();
    return m;
  }
}

class ShiftMonth {
  String? month;
  List<ShiftDay>? dates;

  ShiftMonth({this.month, this.dates});

  ShiftMonth.fromJson(Map<String, dynamic>? json) {
    month = json?['month'];
    final list = json?['dates'] as List?;
    if (list != null) {
      dates = <ShiftDay>[];
      for (final v in list) {
        dates!.add(ShiftDay.fromJson(v is Map<String, dynamic> ? v : null));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['month'] = month;
    if (dates != null) m['dates'] = dates!.map((e) => e.toJson()).toList();
    return m;
  }
}

class ShiftDay {
  String? date; // "YYYY-MM-DD" (keep String for simplicity)
  List<AllShifts>? data; // shifts for that day

  ShiftDay({this.date, this.data});

  ShiftDay.fromJson(Map<String, dynamic>? json) {
    date = json?['date'];
    final list = json?['data'] as List?;
    if (list != null) {
      data = <AllShifts>[];
      for (final v in list) {
        data!.add(AllShifts.fromJson(v is Map<String, dynamic> ? v : null));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['date'] = date;
    if (data != null) m['data'] = data!.map((e) => e.toJson()).toList();
    return m;
  }
}

class AllShifts {
  String? id;
  String? date; // "YYYY-MM-DD"
  String? start;
  String? end;
  String? breakMin; // if you actually add numbers, make this int
  String? notes;
  JobData? jobFrom; // nested object
  bool? isStat;
  String? totalHours;

  AllShifts({
    this.id,
    this.date,
    this.start,
    this.end,
    this.breakMin,
    this.notes,
    this.jobFrom,
    this.isStat = false,
    this.totalHours,
  });

  AllShifts.fromJson(Map<String, dynamic>? json) {
    id = json?['id'];
    date = json?['date'];
    start = json?['start'];
    end = json?['end'];
    breakMin = json?['breakMin'];
    notes = json?['notes'];
    totalHours = json?['totalHours'];

    final jf = json?['jobFrom'];
    if (jf is Map<String, dynamic>) {
      jobFrom = JobData.fromJson(jf); // ✅ convert Map → JobData
    } else if (jf is JobData) {
      jobFrom = jf; // rare, but safe
    } else {
      jobFrom = null; // unknown type → drop
    }

    isStat = json?['isStat'];
    totalHours = json?['totalHours'];
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['id'] = id;
    m['date'] = date;
    m['start'] = start;
    m['end'] = end;
    m['breakMin'] = breakMin;
    m['notes'] = notes;
    if (jobFrom != null) m['jobFrom'] = jobFrom!.toJson(); // ✅ emit Map
    m['isStat'] = isStat;
    m['totalHours'] = totalHours;
    return m;
  }
}
