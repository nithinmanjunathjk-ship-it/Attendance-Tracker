import 'package:attendx/models/timetable_model.dart';
import 'package:attendx/repositories/timetable_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository();
});

class TimetableNotifier extends AsyncNotifier<List<TimetableModel>> {
  @override
  Future<List<TimetableModel>> build() async {
    return ref.watch(timetableRepositoryProvider).fetchTimetable();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addEntry(TimetableModel entry) async {
    await ref.read(timetableRepositoryProvider).createEntry(entry);
    await refresh();
  }

  Future<void> editEntry(TimetableModel entry) async {
    await ref.read(timetableRepositoryProvider).updateEntry(entry);
    await refresh();
  }

  Future<void> removeEntry(String id) async {
    await ref.read(timetableRepositoryProvider).deleteEntry(id);
    await refresh();
  }
}

final timetableProvider =
    AsyncNotifierProvider<TimetableNotifier, List<TimetableModel>>(
  TimetableNotifier.new,
);

/// Groups the timetable by day_of_week (1-7) for the weekly view.
final timetableByDayProvider = Provider<Map<int, List<TimetableModel>>>((ref) {
  final entries = ref.watch(timetableProvider).valueOrNull ?? [];
  final map = <int, List<TimetableModel>>{};
  for (final e in entries) {
    map.putIfAbsent(e.dayOfWeek, () => []).add(e);
  }
  for (final list in map.values) {
    list.sort((a, b) =>
        (a.startTime.hour * 60 + a.startTime.minute)
            .compareTo(b.startTime.hour * 60 + b.startTime.minute));
  }
  return map;
});

/// Today's classes only, sorted by start time — used on the Home dashboard.
final todaysClassesProvider = Provider<List<TimetableModel>>((ref) {
  final byDay = ref.watch(timetableByDayProvider);
  final todayIso = DateTime.now().weekday; // 1 = Monday ... 7 = Sunday
  return byDay[todayIso] ?? [];
});
