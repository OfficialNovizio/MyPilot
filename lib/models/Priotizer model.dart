import 'dart:convert';

import 'package:emptyproject/models/Projection%20Model.dart';

enum TaskSection { must, atRisk, ifTime, completed }

enum TaskStatus { pending, inProgress, completed }

class PrioritizerModel {
  int? status;
  String? message;
  List<Task>? data;

  PrioritizerModel({
    this.status,
    this.message,
    this.data,
  });

  factory PrioritizerModel.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List?;
    return PrioritizerModel(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: list == null ? <Task>[] : list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList() ?? [],
    };
  }
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.description,
    required this.section,
    required this.hardDeadline,
    this.softDeadline,
    this.priority = GoalPriority.medium,
    this.status = TaskStatus.pending,
  });

  String id;
  String title;
  String? description;
  TaskSection section;
  DateTime hardDeadline;
  DateTime? softDeadline;
  GoalPriority priority;
  TaskStatus status;

  // ====== DISPLAY HELPERS ======

  String get hardDeadlineText => '${hardDeadline.day}/${hardDeadline.month}/${hardDeadline.year}';

  String? get softDeadlineText {
    if (softDeadline == null) return null;
    return 'Soft: ${softDeadline!.day}/${softDeadline!.month}';
  }

  bool get isCompleted => status == TaskStatus.completed;

  Task copyWith({
    String? title,
    String? description,
    TaskSection? section,
    DateTime? hardDeadline,
    DateTime? softDeadline,
    GoalPriority? priority,
    TaskStatus? status,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      section: section ?? this.section,
      hardDeadline: hardDeadline ?? this.hardDeadline,
      softDeadline: softDeadline ?? this.softDeadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }

  // ====== JSON ======

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      section: TaskSection.values.firstWhere(
        (e) => e.name == json['section'],
        orElse: () => TaskSection.ifTime,
      ),
      hardDeadline: DateTime.parse(json['hardDeadline'] as String),
      softDeadline: json['softDeadline'] != null ? DateTime.parse(json['softDeadline'] as String) : null,
      priority: GoalPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => GoalPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'section': section.name,
      'hardDeadline': hardDeadline.toIso8601String(),
      'softDeadline': softDeadline?.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
    };
  }
}
