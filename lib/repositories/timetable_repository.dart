import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/core/errors/app_exceptions.dart';
import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/models/timetable_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class TimetableRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = SupabaseService.currentUserId;
    if (id == null) throw const AuthException('Not authenticated.');
    return id;
  }

  Future<List<TimetableModel>> fetchTimetable() async {
    final data = await _client
        .from(AppConstants.tableTimetable)
        .select('*, subjects(subject_name, faculty_name)')
        .eq('user_id', _userId)
        .order('day_of_week')
        .order('start_time');

    return (data as List)
        .map((json) => TimetableModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TimetableModel> createEntry(TimetableModel entry) async {
    final data = await _client
        .from(AppConstants.tableTimetable)
        .insert(entry.toInsertJson())
        .select('*, subjects(subject_name, faculty_name)')
        .single();
    return TimetableModel.fromJson(data);
  }

  Future<TimetableModel> updateEntry(TimetableModel entry) async {
    final data = await _client
        .from(AppConstants.tableTimetable)
        .update(entry.toInsertJson())
        .eq('id', entry.id)
        .select('*, subjects(subject_name, faculty_name)')
        .single();
    return TimetableModel.fromJson(data);
  }

  Future<void> deleteEntry(String entryId) async {
    await _client.from(AppConstants.tableTimetable).delete().eq('id', entryId);
  }
}
