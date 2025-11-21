import 'package:flutter/material.dart';

class TextForm {
  final TextEditingController controller;
  final String title;
  int? gaveError;

  TextForm({
    required this.controller,
    required this.title,
    this.gaveError = 0,
  });

  factory TextForm.fromJson(Map<String, dynamic> map) => TextForm(
        controller: TextEditingController(text: (map['text'] ?? '') as String),
        title: (map['title'] ?? '') as String,
        gaveError: (map['gaveError'] as num?)?.toInt() ?? 0,
      );
  // Serialize only what’s serializable
  Map<String, dynamic> toMap() => {
        'text': controller.text,
        'title': title,
        'gaveError': gaveError ?? 0,
      };
}
