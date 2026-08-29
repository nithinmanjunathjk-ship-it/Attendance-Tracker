class SubjectModel {
  final String id;
  final String userId;
  final String subjectName;
  final String? subjectCode;
  final String? facultyName;
  final int credits;
  final double targetPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Derived / joined fields (not persisted directly on this table).
  final int presentCount;
  final int absentCount;

  const SubjectModel({
    required this.id,
    required this.userId,
    required this.subjectName,
    this.subjectCode,
    this.facultyName,
    this.credits = 0,
    this.targetPercentage = 75.0,
    required this.createdAt,
    required this.updatedAt,
    this.presentCount = 0,
    this.absentCount = 0,
  });

  int get totalCount => presentCount + absentCount;

  double get attendancePercentage {
    if (totalCount == 0) return 0.0;
    return (presentCount / totalCount) * 100.0;
  }

  factory SubjectModel.fromJson(
    Map<String, dynamic> json, {
    int presentCount = 0,
    int absentCount = 0,
  }) {
    return SubjectModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectName: json['subject_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String?,
      facultyName: json['faculty_name'] as String?,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      targetPercentage:
          (json['target_percentage'] as num?)?.toDouble() ?? 75.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      presentCount: presentCount,
      absentCount: absentCount,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'subject_name': subjectName,
        'subject_code': subjectCode,
        'faculty_name': facultyName,
        'credits': credits,
        'target_percentage': targetPercentage,
      };

  SubjectModel copyWith({
    String? subjectName,
    String? subjectCode,
    String? facultyName,
    int? credits,
    double? targetPercentage,
    int? presentCount,
    int? absentCount,
  }) {
    return SubjectModel(
      id: id,
      userId: userId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      facultyName: facultyName ?? this.facultyName,
      credits: credits ?? this.credits,
      targetPercentage: targetPercentage ?? this.targetPercentage,
      createdAt: createdAt,
      updatedAt: updatedAt,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
    );
  }
}
