import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/core/errors/app_exceptions.dart';
import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/models/subject_model.dart';
import 'package:attendx/providers/attendance_provider.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/widgets/empty_state.dart';
import 'package:attendx/widgets/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  SubjectModel? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  int _classNumber = 1;
  bool _marking = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _mark(String status) async {
    final subject = _selectedSubject;
    if (subject == null) return;

    setState(() => _marking = true);
    final ok = await ref.read(markAttendanceControllerProvider.notifier).mark(
          subjectId: subject.id,
          classDate: _selectedDate,
          classNumber: _classNumber,
          status: status,
        );
    setState(() => _marking = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == AttendanceStatus.present
                ? 'Marked present for ${subject.subjectName} ✅'
                : 'Marked absent for ${subject.subjectName} ❌',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(markAttendanceControllerProvider).error;
      final message = err is DuplicateAttendanceException
          ? err.message
          : 'Could not mark attendance. It has been queued and will sync '
              'automatically.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load subjects: $e')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              subtitle: 'Add a subject first to start marking attendance.',
              action: ElevatedButton(
                onPressed: () => context.push('/subject/add'),
                child: const Text('Add Subject'),
              ),
            );
          }

          _selectedSubject ??= subjects.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SyncStatusBanner(),
                Text('Subject', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects.map((s) {
                    final selected = _selectedSubject?.id == s.id;
                    return ChoiceChip(
                      label: Text(s.subjectName),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSubject = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('Date & class', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              if (_classNumber > 1) _classNumber--;
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            'Class $_classNumber',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          IconButton(
                            onPressed: () => setState(() => _classNumber++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                if (_selectedSubject != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _selectedSubject!.subjectName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current: ${_selectedSubject!.attendancePercentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _marking
                                      ? null
                                      : () => _mark(AttendanceStatus.present),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('PRESENT'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _marking
                                      ? null
                                      : () => _mark(AttendanceStatus.absent),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.danger,
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('ABSENT'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
