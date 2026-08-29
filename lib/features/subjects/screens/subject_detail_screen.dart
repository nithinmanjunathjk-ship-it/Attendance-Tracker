import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/core/utils/attendance_calculator.dart';
import 'package:attendx/models/subject_model.dart';
import 'package:attendx/providers/attendance_provider.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/widgets/attendance_gauge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final SubjectModel subject;
  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the subject fresh if it changed (e.g. after marking attendance).
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final current = subjects.firstWhere(
      (s) => s.id == subject.id,
      orElse: () => subject,
    );

    final needed = AttendanceCalculator.classesNeededForTarget(
      present: current.presentCount,
      total: current.totalCount,
      targetPercentage: current.targetPercentage,
    );
    final missable = AttendanceCalculator.maxClassesMissable(
      present: current.presentCount,
      total: current.totalCount,
      targetPercentage: current.targetPercentage,
    );

    final historyAsync = ref.watch(
      historyProvider(AttendanceHistoryParams(subjectId: current.id)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(current.subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/subject/edit', extra: current),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete subject?'),
                  content: Text(
                    'This will remove "${current.subjectName}" and all of its '
                    'attendance records.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(subjectsProvider.notifier).removeSubject(current.id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: AttendanceGauge(percentage: current.attendancePercentage)),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatBox(label: 'Present', value: current.presentCount, color: AppColors.success),
              const SizedBox(width: 10),
              _StatBox(label: 'Absent', value: current.absentCount, color: AppColors.danger),
              const SizedBox(width: 10),
              _StatBox(label: 'Total', value: current.totalCount, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target: ${current.targetPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (missable.cannotMissAny)
                    const Text("You can't afford to miss any more classes.")
                  else
                    Text('You can miss up to ${missable.maxMissable} more '
                        'class${missable.maxMissable == 1 ? '' : 'es'} and stay '
                        'on target.'),
                  const SizedBox(height: 6),
                  if (needed.alreadyMet)
                    const Text('Target already met 🎉')
                  else if (needed.unreachable)
                    const Text('Target is not reachable this term.')
                  else
                    Text('Attend ${needed.classesNeeded} more class'
                        '${needed.classesNeeded == 1 ? '' : 'es'} to reach target.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Attendance Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Could not load trend: $e'),
            data: (records) {
              if (records.isEmpty) {
                return const Text('No attendance recorded yet.');
              }
              final ordered = records.reversed.toList();
              double running = 0;
              int total = 0;
              final spots = <FlSpot>[];
              for (var i = 0; i < ordered.length; i++) {
                total++;
                if (ordered[i].isPresent) running++;
                spots.add(FlSpot(i.toDouble(), (running / total) * 100));
              }
              return SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('Recent Records', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          historyAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (records) => Column(
              children: records.take(10).map((r) {
                final present = r.isPresent;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    present ? Icons.check_circle : Icons.cancel,
                    color: present ? AppColors.success : AppColors.danger,
                  ),
                  title: Text(DateFormat('dd MMM yyyy').format(r.classDate)),
                  trailing: Text('Class ${r.classNumber}'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 18)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
