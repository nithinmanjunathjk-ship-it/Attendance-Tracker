import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/core/errors/app_exceptions.dart';
import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/models/subject_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class SubjectRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = SupabaseService.currentUserId;
    if (id == null) throw const AuthException('Not authenticated.');
    return id;
  }

  /// Fetches all subjects for the current user along with present/absent
  /// counts computed from `attendance_records`.
  Future<List<SubjectModel>> fetchSubjects() async {
    final subjectsRaw = await _client
        .from(AppConstants.tableSubjects)
        .select()
        .eq('user_id', _userId)
        .order('created_at');

    final attendanceRaw = await _client
        .from(AppConstants.tableAttendance)
        .select('subject_id, status')
        .eq('user_id', _userId);

    final counts = <String, Map<String, int>>{};
    for (final row in attendanceRaw as List) {
      final subjectId = row['subject_id'] as String;
      final status = row['status'] as String;
      counts.putIfAbsent(subjectId, () => {'present': 0, 'absent': 0});
      if (status == AttendanceStatus.present) {
        counts[subjectId]!['present'] = counts[subjectId]!['present']! + 1;
      } else {
        counts[subjectId]!['absent'] = counts[subjectId]!['absent']! + 1;
      }
    }

    return (subjectsRaw as List).map((json) {
      final c = counts[json['id']] ?? const {'present': 0, 'absent': 0};
      return SubjectModel.fromJson(
        json,
        presentCount: c['present'] ?? 0,
        absentCount: c['absent'] ?? 0,
      );
    }).toList();
  }

  Future<SubjectModel> createSubject(SubjectModel subject) async {
    final data = await _client
        .from(AppConstants.tableSubjects)
        .insert(subject.toInsertJson())
        .select()
        .single();
    return SubjectModel.fromJson(data);
  }

  Future<SubjectModel> updateSubject(SubjectModel subject) async {
    final data = await _client
        .from(AppConstants.tableSubjects)
        .update(subject.toInsertJson())
        .eq('id', subject.id)
        .select()
        .single();
    return SubjectModel.fromJson(
      data,
      presentCount: subject.presentCount,
      absentCount: subject.absentCount,
    );
  }

  Future<void> deleteSubject(String subjectId) async {
    await _client.from(AppConstants.tableSubjects).delete().eq('id', subjectId);
  }
}
