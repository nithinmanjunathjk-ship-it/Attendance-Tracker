import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/providers/attendance_provider.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _subjectId;
  String? _status; // null = all

  AttendanceHistoryParams get _params =>
      AttendanceHistoryParams(subjectId: _subjectId, status: _status);

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final historyAsync = ref.watch(historyProvider(_params));

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Present'),
                    selected: _status == AttendanceStatus.present,
                    onSelected: (_) =>
                        setState(() => _status = AttendanceStatus.present),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Absent'),
                    selected: _status == AttendanceStatus.absent,
                    onSelected: (_) =>
                        setState(() => _status = AttendanceStatus.absent),
                  ),
                  if (subjects.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                    const SizedBox(width: 16),
                    ...subjects.map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(s.subjectName),
                            selected: _subjectId == s.id,
                            onSelected: (_) => setState(
                              () => _subjectId = _subjectId == s.id ? null : s.id,
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load history: $e')),
              data: (records) {
                if (records.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No records found',
                    subtitle: 'Try changing your filters or mark some attendance.',
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (notif) {
                    if (notif.metrics.pixels >= notif.metrics.maxScrollExtent - 200) {
                      ref.read(historyProvider(_params).notifier).loadMore(_params);
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(historyProvider(_params)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = records[i];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              r.isPresent ? Icons.check_circle : Icons.cancel,
                              color: r.isPresent ? AppColors.success : AppColors.danger,
                            ),
                            title: Text(r.subjectName ?? 'Subject'),
                            subtitle: Text(
                              '${DateFormat('dd MMM yyyy').format(r.classDate)} · '
                              'Class ${r.classNumber}',
                            ),
                            trailing: Text(
                              r.isPresent ? 'Present' : 'Absent',
                              style: TextStyle(
                                color: r.isPresent ? AppColors.success : AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
