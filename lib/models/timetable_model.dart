import 'package:flutter/material.dart';

class TimetableModel {
  final String id;
  final String userId;
  final String subjectId;
  final int dayOfWeek; // 1 = Monday ... 7 = Sunday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? room;
  final DateTime createdAt;

  // Joined display fields.
  final String? subjectName;
  final String? facultyName;

  const TimetableModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.createdAt,
    this.subjectName,
    this.facultyName,
  });

  static TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  factory TimetableModel.fromJson(
    Map<String, dynamic> json, {
    String? subjectName,
    String? facultyName,
  }) {
    return TimetableModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: _parseTime(json['start_time'] as String),
      endTime: _parseTime(json['end_time'] as String),
      room: json['room'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      subjectName:
          subjectName ?? (json['subjects']?['subject_name'] as String?),
      facultyName:
          facultyName ?? (json['subjects']?['faculty_name'] as String?),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'subject_id': subjectId,
        'day_of_week': dayOfWeek,
        'start_time': formatTimeOfDay(startTime),
        'end_time': formatTimeOfDay(endTime),
        'room': room,
      };
}
