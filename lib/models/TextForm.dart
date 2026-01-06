import 'package:flutter/material.dart';

class TextForm {
  final TextEditingController controller;
  final String title;
  int? gaveError;
  DateTime? pickedDate;

  TextForm({
    required this.controller,
    required this.title,
    this.gaveError = 0,
    this.pickedDate,
  });

  factory TextForm.fromJson(Map<String, dynamic> map) {
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime? _toDate(dynamic ms) {
      final i = _toInt(ms);
      if (i == null || i <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(i);
    }

    return TextForm(
      controller: TextEditingController(text: (map['text'] ?? '').toString()),
      title: (map['title'] ?? '').toString(),
      gaveError: _toInt(map['gaveError']) ?? 0,
      pickedDate: _toDate(map['pickedDateMs'] ?? map['pickedDate']),
    );
  }

  // Serialize only what’s serializable
  Map<String, dynamic> toMap() => {
        'text': controller.text,
        'title': title,
        'gaveError': gaveError ?? 0,
        'pickedDateMs': pickedDate?.millisecondsSinceEpoch,
      };
}
