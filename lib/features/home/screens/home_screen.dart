import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/providers/auth_provider.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/providers/timetable_provider.dart';
import 'package:attendx/widgets/attendance_gauge.dart';
import 'package:attendx/widgets/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final overall = ref.watch(overallAttendanceProvider);
    final lowAttendance = ref.watch(lowAttendanceSubjectsProvider);
    final todaysClasses = ref.watch(todaysClassesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(subjectsProvider.notifier).refresh();
            await ref.read(timetableProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SyncStatusBanner(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()} 👋',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profileAsync.valueOrNull?.fullName.split(' ').first ??
                              'there',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      (profileAsync.valueOrNull?.fullName.isNotEmpty ?? false)
                          ? profileAsync.valueOrNull!.fullName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              subjectsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Failed to load: $e'),
                data: (_) => _OverviewCard(
                  percentage: overall.percentage,
                  present: overall.present,
                  absent: overall.absent,
                  total: overall.total,
                ),
              ),
              const SizedBox(height: 28),
              Text("Today's Classes",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (todaysClasses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.beach_access_outlined),
                        SizedBox(width: 12),
                        Text('No classes scheduled for today 🎉'),
                      ],
                    ),
                  ),
                )
              else
                ...todaysClasses.map(
                  (c) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: const Icon(Icons.schedule, color: AppColors.primary),
                      ),
                      title: Text(c.subjectName ?? 'Subject'),
                      subtitle: Text(
                        '${c.startTime.format(context)} - ${c.endTime.format(context)}'
                        '${c.room != null && c.room!.isNotEmpty ? ' · ${c.room}' : ''}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              Text('Low Attendance',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (lowAttendance.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events_outlined, color: AppColors.success),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('All subjects are meeting their target 🎯'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...lowAttendance.map((s) {
                  final needed = _classesToReachTarget(
                    present: s.presentCount,
                    total: s.totalCount,
                    target: s.targetPercentage,
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => context.push('/subject/detail', extra: s),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.forPercentage(s.attendancePercentage)
                                .withOpacity(0.14),
                        child: Text(
                          '${s.attendancePercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forPercentage(s.attendancePercentage),
                          ),
                        ),
                      ),
                      title: Text(s.subjectName),
                      subtitle: Text(
                        needed > 0
                            ? 'Attend $needed more class${needed == 1 ? '' : 'es'} '
                                'to reach ${s.targetPercentage.toStringAsFixed(0)}%'
                            : 'Target currently unreachable this term',
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  int _classesToReachTarget({
    required int present,
    required int total,
    required double target,
  }) {
    // Local mirror of AttendanceCalculator.classesNeededForTarget to avoid
    // importing dart:math heavy utility here — the canonical implementation
    // lives in core/utils/attendance_calculator.dart and is unit-tested.
    final t = target.clamp(0.0, 100.0) / 100.0;
    if (total == 0) return 0;
    final current = present / total;
    if (current >= t || t >= 1.0) return 0;
    final x = (((t * total) - present) / (1 - t)).ceil();
    return x < 0 ? 0 : x;
  }
}

class _OverviewCard extends StatelessWidget {
  final double percentage;
  final int present;
  final int absent;
  final int total;

  const _OverviewCard({
    required this.percentage,
    required this.present,
    required this.absent,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            AttendanceGauge(percentage: percentage, radius: 64, lineWidth: 11),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Overall Attendance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMM').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatChip(label: 'Present', value: present, color: AppColors.success),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Absent', value: absent, color: AppColors.danger),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Total', value: total, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
