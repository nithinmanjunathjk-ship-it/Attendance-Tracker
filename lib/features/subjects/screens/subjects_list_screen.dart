import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/widgets/empty_state.dart';
import 'package:attendx/widgets/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SubjectsListScreen extends ConsumerWidget {
  const SubjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/subject/add'),
        child: const Icon(Icons.add),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load subjects: $e')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              subtitle: 'Tap the + button to add your first subject.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(subjectsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = subjects[i];
                return SubjectCard(
                  subject: s,
                  onTap: () => context.push('/subject/detail', extra: s),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
