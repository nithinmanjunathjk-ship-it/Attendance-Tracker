import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/models/timetable_model.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:attendx/providers/timetable_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddEditTimetableScreen extends ConsumerStatefulWidget {
  final TimetableModel? entry;
  const AddEditTimetableScreen({super.key, this.entry});

  bool get isEditing => entry != null;

  @override
  ConsumerState<AddEditTimetableScreen> createState() =>
      _AddEditTimetableScreenState();
}

class _AddEditTimetableScreenState extends ConsumerState<AddEditTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();

  String? _subjectId;
  int _day = 1;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _saving = false;

  static const _dayLabels = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _subjectId = e.subjectId;
      _day = e.dayOfWeek;
      _start = e.startTime;
      _end = e.endTime;
      _roomController.text = e.room ?? '';
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _subjectId == null) return;
    setState(() => _saving = true);

    final userId = SupabaseService.currentUserId!;

    try {
      if (widget.isEditing) {
        final updated = TimetableModel(
          id: widget.entry!.id,
          userId: userId,
          subjectId: _subjectId!,
          dayOfWeek: _day,
          startTime: _start,
          endTime: _end,
          room: _roomController.text.trim(),
          createdAt: widget.entry!.createdAt,
        );
        await ref.read(timetableProvider.notifier).editEntry(updated);
      } else {
        final entry = TimetableModel(
          id: '',
          userId: userId,
          subjectId: _subjectId!,
          dayOfWeek: _day,
          startTime: _start,
          endTime: _end,
          room: _roomController.text.trim(),
          createdAt: DateTime.now(),
        );
        await ref.read(timetableProvider.notifier).addEntry(entry);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    _subjectId ??= subjects.isNotEmpty ? subjects.first.id : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Class' : 'Add Class'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subjects.isEmpty)
                  const Text('Add a subject first before creating a timetable entry.')
                else
                  DropdownButtonFormField<String>(
                    value: _subjectId,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: subjects
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.subjectName),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _subjectId = v),
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _day,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: [
                    for (var i = 0; i < _dayLabels.length; i++)
                      DropdownMenuItem(value: i + 1, child: Text(_dayLabels[i])),
                  ],
                  onChanged: (v) => setState(() => _day = v ?? 1),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(true),
                        child: Text('Start: ${_start.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(false),
                        child: Text('End: ${_end.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || subjects.isEmpty) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.isEditing ? 'Save Changes' : 'Add Class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
