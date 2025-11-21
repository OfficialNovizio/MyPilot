// class Job {
//   int? status;
//   String? message;
//   List<JobData>? data;
//
//   Job({this.status, this.message, this.data});
//
//   Job.fromJson(Map<String, dynamic> json) {
//     status = json['status'];
//     message = json['message'];
//     if (json['data'] != null) {
//       data = <JobData>[];
//       json['data'].forEach((v) {
//         data!.add(JobData.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['status'] = status;
//     data['message'] = message;
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class JobData {
//   int? id;
//   String? jobName;
//   String? wageHr;
//   String? jobColor;
//   String? lastPayChequeDate;
//   String? payFrequency;
//   String? weekStart;
//   String? statPay;
//
//   JobData({
//     this.id,
//     this.jobName,
//     this.wageHr,
//     this.jobColor,
//     this.lastPayChequeDate,
//     this.payFrequency,
//     this.weekStart,
//     this.statPay,
//   });
//   JobData.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     jobName = json['Job name'];
//     wageHr = json['Wage/Hr'];
//     jobColor = json['Job color'];
//     lastPayChequeDate = json['Last pay cheque date'];
//     payFrequency = json['Pay frequency'];
//     weekStart = json['Week start'];
//     statPay = json['Stat pay'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['Job name'] = jobName;
//     data['Wage/Hr'] = wageHr;
//     data['Job color'] = jobColor;
//     data['Last pay cheque date'] = lastPayChequeDate;
//     data['Pay frequency'] = payFrequency;
//     data['Week start'] = weekStart;
//     data['Stat pay'] = statPay;
//     return data;
//   }
// }

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
  String? lastPayChequeDate;
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
    lastPayChequeDate = json?['Last pay cheque date'];
    payFrequency = json?['Pay frequency'];
    weekStart = json?['Week start'];
    statPay = json?['Stat pay'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['Job name'] = jobName;
    data['Wage/Hr'] = wageHr;
    data['Job color'] = jobColor;
    data['Last pay cheque date'] = lastPayChequeDate;
    data['Pay frequency'] = payFrequency;
    data['Week start'] = weekStart;
    data['Stat pay'] = statPay;
    return data;
  }
}
