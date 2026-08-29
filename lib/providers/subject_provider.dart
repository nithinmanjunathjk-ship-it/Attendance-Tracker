import 'package:attendx/models/subject_model.dart';
import 'package:attendx/repositories/subject_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository();
});

class SubjectsNotifier extends AsyncNotifier<List<SubjectModel>> {
  @override
  Future<List<SubjectModel>> build() async {
    return ref.watch(subjectRepositoryProvider).fetchSubjects();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addSubject(SubjectModel subject) async {
    final repo = ref.read(subjectRepositoryProvider);
    await repo.createSubject(subject);
    await refresh();
  }

  Future<void> editSubject(SubjectModel subject) async {
    final repo = ref.read(subjectRepositoryProvider);
    await repo.updateSubject(subject);
    await refresh();
  }

  Future<void> removeSubject(String subjectId) async {
    final repo = ref.read(subjectRepositoryProvider);
    await repo.deleteSubject(subjectId);
    await refresh();
  }
}

final subjectsProvider =
    AsyncNotifierProvider<SubjectsNotifier, List<SubjectModel>>(
  SubjectsNotifier.new,
);

/// Subjects sorted below their target percentage — used on the Home tab.
final lowAttendanceSubjectsProvider = Provider<List<SubjectModel>>((ref) {
  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final low = subjects
      .where((s) => s.totalCount > 0 && s.attendancePercentage < s.targetPercentage)
      .toList()
    ..sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));
  return low;
});

/// Aggregate present/absent/total across all subjects — used on Home tab.
final overallAttendanceProvider = Provider<({int present, int absent, int total, double percentage})>(
  (ref) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final present = subjects.fold<int>(0, (sum, s) => sum + s.presentCount);
    final absent = subjects.fold<int>(0, (sum, s) => sum + s.absentCount);
    final total = present + absent;
    final percentage = total == 0 ? 0.0 : (present / total) * 100.0;
    return (present: present, absent: absent, total: total, percentage: percentage);
  },
);
