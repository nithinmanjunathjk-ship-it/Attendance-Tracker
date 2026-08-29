import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/models/timetable_model.dart';
import 'package:attendx/providers/timetable_provider.dart';
import 'package:attendx/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final int _today = DateTime.now().weekday; // 1 = Monday

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: (_today >= 1 && _today <= 6) ? _today - 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byDay = ref.watch(timetableByDayProvider);
    final loading = ref.watch(timetableProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (var i = 0; i < 6; i++)
              Tab(text: AppConstants.weekDaysShort[i]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/timetable/add'),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                for (var day = 1; day <= 6; day++)
                  _DayView(
                    entries: byDay[day] ?? [],
                    isToday: day == _today,
                  ),
              ],
            ),
    );
  }
}

class _DayView extends ConsumerWidget {
  final List<TimetableModel> entries;
  final bool isToday;
  const _DayView({required this.entries, required this.isToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No classes',
        subtitle: 'Nothing scheduled for this day yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(timetableProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final e = entries[i];
          return Card(
            color: isToday ? AppColors.primary.withOpacity(0.05) : null,
            child: ListTile(
              onTap: () => context.push('/timetable/edit', extra: e),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: const Icon(Icons.schedule, color: AppColors.primary),
              ),
              title: Text(e.subjectName ?? 'Subject'),
              subtitle: Text(
                '${e.startTime.format(context)} - ${e.endTime.format(context)}'
                '${e.room != null && e.room!.isNotEmpty ? ' · Room ${e.room}' : ''}'
                '${e.facultyName != null && e.facultyName!.isNotEmpty ? '\n${e.facultyName}' : ''}',
              ),
              isThreeLine: e.facultyName != null && e.facultyName!.isNotEmpty,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(timetableProvider.notifier).removeEntry(e.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
