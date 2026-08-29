import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists attendance records that were marked while offline so they can
/// be replayed against Supabase once connectivity returns.
///
/// Also caches the last successfully-fetched attendance list per user so
/// the History/Home screens still have something to show while offline.
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const _pendingKey = 'attendx_pending_attendance_queue';
  static const _cacheKeyPrefix = 'attendx_cached_attendance_';

  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> enqueue(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getPendingQueue();
    queue.add(record);
    await prefs.setString(_pendingKey, jsonEncode(queue));
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }

  Future<void> removeFromQueue(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getPendingQueue();
    queue.removeWhere((r) =>
        r['subject_id'] == record['subject_id'] &&
        r['class_date'] == record['class_date'] &&
        r['class_number'] == record['class_number']);
    await prefs.setString(_pendingKey, jsonEncode(queue));
  }

  Future<int> pendingCount() async => (await getPendingQueue()).length;

  Future<void> cacheAttendanceList(
    String userId,
    List<Map<String, dynamic>> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cacheKeyPrefix$userId', jsonEncode(records));
  }

  Future<List<Map<String, dynamic>>> getCachedAttendanceList(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cacheKeyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }
}
