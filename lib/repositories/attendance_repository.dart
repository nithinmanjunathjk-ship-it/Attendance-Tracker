import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/core/errors/app_exceptions.dart';
import 'package:attendx/core/services/connectivity_service.dart';
import 'package:attendx/core/services/offline_queue_service.dart';
import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/models/attendance_record_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class AttendanceRepository {
  final SupabaseClient _client = SupabaseService.client;
  final OfflineQueueService _queue = OfflineQueueService.instance;

  String get _userId {
    final id = SupabaseService.currentUserId;
    if (id == null) throw const AuthException('Not authenticated.');
    return id;
  }

  /// Marks attendance for a subject/date/class-number.
  ///
  /// If the device is offline, the record is queued locally and will be
  /// synced automatically via [syncPendingQueue] once connectivity returns.
  Future<void> markAttendance({
    required String subjectId,
    required DateTime classDate,
    required int classNumber,
    required String status,
  }) async {
    final record = {
      'user_id': _userId,
      'subject_id': subjectId,
      'class_date': classDate.toIso8601String().split('T').first,
      'class_number': classNumber,
      'status': status,
    };

    final isOnline = await ConnectivityService.instance.checkConnection();
    if (!isOnline) {
      await _queue.enqueue(record);
      return;
    }

    try {
      await _client.from(AppConstants.tableAttendance).upsert(
        record,
        onConflict: 'user_id,subject_id,class_date,class_number',
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DuplicateAttendanceException();
      }
      // Fall back to queueing if the request failed for a network reason.
      await _queue.enqueue(record);
    } catch (_) {
      await _queue.enqueue(record);
    }
  }

  /// Replays any queued offline attendance records against Supabase.
  /// Safe to call repeatedly (e.g. on connectivity restore, or app start).
  Future<int> syncPendingQueue() async {
    final pending = await _queue.getPendingQueue();
    if (pending.isEmpty) return 0;

    var syncedCount = 0;
    for (final record in List<Map<String, dynamic>>.from(pending)) {
      try {
        await _client.from(AppConstants.tableAttendance).upsert(
          record,
          onConflict: 'user_id,subject_id,class_date,class_number',
        );
        await _queue.removeFromQueue(record);
        syncedCount++;
      } catch (_) {
        // Leave in queue, try again next time.
      }
    }
    return syncedCount;
  }

  Future<List<AttendanceRecordModel>> fetchHistory({
    String? subjectId,
    String? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _client
          .from(AppConstants.tableAttendance)
          .select('*, subjects(subject_name)')
          .eq('user_id', _userId);

      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }
      if (fromDate != null) {
        query = query.gte('class_date', fromDate.toIso8601String().split('T').first);
      }
      if (toDate != null) {
        query = query.lte('class_date', toDate.toIso8601String().split('T').first);
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final data = await query
          .order('class_date', ascending: false)
          .order('class_number', ascending: false)
          .range(from, to);

      final list = (data as List).cast<Map<String, dynamic>>();

      // Cache the first page for offline viewing.
      if (page == 0 && subjectId == null && statusFilter == null) {
        await _queue.cacheAttendanceList(_userId, list);
      }

      return list
          .map((json) => AttendanceRecordModel.fromJson(json))
          .toList();
    } catch (e) {
      // Offline fallback — serve cached data if available.
      final cached = await _queue.getCachedAttendanceList(_userId);
      return cached
          .map((json) => AttendanceRecordModel.fromJson(json))
          .toList();
    }
  }

  Future<int> pendingQueueCount() => _queue.pendingCount();

  Stream<List<Map<String, dynamic>>> watchAttendance() {
    return _client
        .from(AppConstants.tableAttendance)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('class_date');
  }
}
