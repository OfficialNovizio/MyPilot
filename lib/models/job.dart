class Job {
  int? status;
  String? message;
  List<JobData>? data;

  Job({this.status, this.message, this.data});

  Job.fromJson(Map<String, dynamic>? json) {
    status = json?['status'];
    message = json?['message'];

    final list = json?['data'] as List?;
    if (list != null) {
      data = <JobData>[];
      for (final v in list) {
        data!.add(JobData.fromJson(v is Map<String, dynamic> ? v : null));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class JobData {
  int? id;
  String? jobName;
  String? wageHr;
  String? jobColor;
  DateTime? lastPayChequeDate;
  String? payFrequency;
  String? weekStart;
  String? statPay;

  JobData({
    this.id,
    this.jobName,
    this.wageHr,
    this.jobColor,
    this.lastPayChequeDate,
    this.payFrequency,
    this.weekStart,
    this.statPay,
  });

  JobData.fromJson(Map<String, dynamic>? json) {
    id = json?['id'];
    jobName = json?['Job name'];
    wageHr = json?['Wage/Hr'];
    jobColor = json?['Job color'];

    // ✅ Read either key (new or old), safely
    final rawDate = json?['lastPayChequeDate'] ?? json?['Last pay cheque date'];
    if (rawDate is String && rawDate.trim().isNotEmpty) {
      try {
        lastPayChequeDate = DateTime.parse(rawDate);
      } catch (_) {
        lastPayChequeDate = null;
      }
    } else {
      lastPayChequeDate = null;
    }

    payFrequency = json?['Pay frequency'];
    weekStart = json?['Week start'];
    statPay = json?['Stat pay'];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'Job name': jobName,
      'Wage/Hr': wageHr,
      'Job color': jobColor,

      // ✅ Write ONE key consistently (pick one and stick to it)
      'lastPayChequeDate': lastPayChequeDate?.toIso8601String(),

      'Pay frequency': payFrequency,
      'Week start': weekStart,
      'Stat pay': statPay,
    };
  }
}
