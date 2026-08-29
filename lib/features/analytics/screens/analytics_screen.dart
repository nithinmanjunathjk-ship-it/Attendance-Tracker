import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/widgets/empty_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final overall = ref.watch(overallAttendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load analytics: $e')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No data yet',
              subtitle: 'Add subjects and mark attendance to see analytics.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Present vs Absent',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: overall.total == 0
                            ? const Center(child: Text('No records yet'))
                            : PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    PieChartSectionData(
                                      value: overall.present.toDouble(),
                                      color: AppColors.success,
                                      title: '${overall.present}',
                                      radius: 54,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: overall.absent.toDouble(),
                                      color: AppColors.danger,
                                      title: '${overall.absent}',
                                      radius: 54,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subject Comparison',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            maxY: 100,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= subjects.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final name = subjects[i].subjectName;
                                    final short = name.length > 6
                                        ? '${name.substring(0, 6)}…'
                                        : name;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(short, style: const TextStyle(fontSize: 10)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < subjects.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: subjects[i].attendancePercentage,
                                      color: AppColors.forPercentage(
                                          subjects[i].attendancePercentage),
                                      width: 18,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Text('Overall attendance: ${overall.percentage.toStringAsFixed(1)}%'),
                      Text('Total classes recorded: ${overall.total}'),
                      Text('Subjects tracked: ${subjects.length}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
