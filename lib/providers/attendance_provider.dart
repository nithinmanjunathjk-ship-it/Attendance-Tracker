import 'dart:async';

import 'package:attendx/core/errors/app_exceptions.dart';
import 'package:attendx/core/services/connectivity_service.dart';
import 'package:attendx/models/attendance_record_model.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/repositories/attendance_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Live realtime stream of raw attendance rows for the current user.
/// Any screen watching this (directly or via [attendanceChangeTickProvider])
/// will rebuild whenever attendance changes on the server.
final attendanceStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(attendanceRepositoryProvider).watchAttendance();
});

/// Increments every time the realtime stream emits — cheap dependency for
/// widgets that just need to know "something changed, refetch your
/// aggregate/derived data" without consuming the raw rows themselves.
final attendanceChangeTickProvider = Provider<int>((ref) {
  final stream = ref.watch(attendanceStreamProvider);
  return stream.maybeWhen(
    data: (rows) => rows.length,
    orElse: () => 0,
  );
});

class AttendanceHistoryParams extends Equatable {
  final String? subjectId;
  final String? status;
  const AttendanceHistoryParams({this.subjectId, this.status});

  @override
  List<Object?> get props => [subjectId, status];
}

class HistoryNotifier
    extends FamilyAsyncNotifier<List<AttendanceRecordModel>, AttendanceHistoryParams> {
  int _page = 0;
  bool _hasMore = true;
  static const _pageSize = 20;

  @override
  Future<List<AttendanceRecordModel>> build(AttendanceHistoryParams arg) async {
    // Re-run whenever realtime signals a change.
    ref.watch(attendanceChangeTickProvider);
    _page = 0;
    _hasMore = true;
    final repo = ref.watch(attendanceRepositoryProvider);
    final results = await repo.fetchHistory(
      subjectId: arg.subjectId,
      statusFilter: arg.status,
      page: _page,
      pageSize: _pageSize,
    );
    _hasMore = results.length == _pageSize;
    return results;
  }

  Future<void> loadMore(AttendanceHistoryParams params) async {
    if (!_hasMore) return;
    final repo = ref.read(attendanceRepositoryProvider);
    final current = state.valueOrNull ?? [];
    _page++;
    final more = await repo.fetchHistory(
      subjectId: params.subjectId,
      statusFilter: params.status,
      page: _page,
      pageSize: _pageSize,
    );
    _hasMore = more.length == _pageSize;
    state = AsyncData([...current, ...more]);
  }
}

final historyProvider = AsyncNotifierProvider.family<HistoryNotifier,
    List<AttendanceRecordModel>, AttendanceHistoryParams>(HistoryNotifier.new);

class MarkAttendanceController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> mark({
    required String subjectId,
    required DateTime classDate,
    required int classNumber,
    required String status,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(attendanceRepositoryProvider).markAttendance(
            subjectId: subjectId,
            classDate: classDate,
            classNumber: classNumber,
            status: status,
          );
      state = const AsyncData(null);
      // Refresh derived data.
      ref.invalidate(subjectsProvider);
      return true;
    } on DuplicateAttendanceException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final markAttendanceControllerProvider =
    AsyncNotifierProvider<MarkAttendanceController, void>(
  MarkAttendanceController.new,
);

/// Watches connectivity and automatically flushes the offline queue when
/// the device comes back online.
final syncStatusProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  controller.add(true);

  final sub = ConnectivityService.instance.onStatusChange.listen((online) async {
    controller.add(online);
    if (online) {
      final synced =
          await ref.read(attendanceRepositoryProvider).syncPendingQueue();
      if (synced > 0) {
        ref.invalidate(subjectsProvider);
      }
    }
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  ref.watch(syncStatusProvider);
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.pendingQueueCount();
});
