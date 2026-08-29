import 'package:attendx/core/constants/app_constants.dart';

class AttendanceRecordModel {
  final String id;
  final String userId;
  final String subjectId;
  final DateTime classDate;
  final int classNumber;
  final String status; // 'present' | 'absent'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional joined field for display (subject name).
  final String? subjectName;

  const AttendanceRecordModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.classDate,
    this.classNumber = 1,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
  });

  bool get isPresent => status == AttendanceStatus.present;

  factory AttendanceRecordModel.fromJson(
    Map<String, dynamic> json, {
    String? subjectName,
  }) {
    return AttendanceRecordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      classDate: DateTime.parse(json['class_date'] as String),
      classNumber: (json['class_number'] as num?)?.toInt() ?? 1,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      subjectName: subjectName ?? (json['subjects']?['subject_name'] as String?),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'subject_id': subjectId,
        'class_date': classDate.toIso8601String().split('T').first,
        'class_number': classNumber,
        'status': status,
      };
}
