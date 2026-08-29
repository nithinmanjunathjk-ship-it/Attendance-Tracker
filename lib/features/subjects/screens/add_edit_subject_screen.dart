import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/models/subject_model.dart';
import 'package:attendx/providers/subject_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddEditSubjectScreen extends ConsumerStatefulWidget {
  final SubjectModel? subject;
  const AddEditSubjectScreen({super.key, this.subject});

  bool get isEditing => subject != null;

  @override
  ConsumerState<AddEditSubjectScreen> createState() =>
      _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends ConsumerState<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _facultyController;
  late final TextEditingController _creditsController;
  late double _target;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    _nameController = TextEditingController(text: s?.subjectName ?? '');
    _codeController = TextEditingController(text: s?.subjectCode ?? '');
    _facultyController = TextEditingController(text: s?.facultyName ?? '');
    _creditsController = TextEditingController(text: (s?.credits ?? 0).toString());
    _target = s?.targetPercentage ?? 75.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _facultyController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final userId = SupabaseService.currentUserId!;
    final now = DateTime.now();

    try {
      if (widget.isEditing) {
        final updated = widget.subject!.copyWith(
          subjectName: _nameController.text.trim(),
          subjectCode: _codeController.text.trim(),
          facultyName: _facultyController.text.trim(),
          credits: int.tryParse(_creditsController.text) ?? 0,
          targetPercentage: _target,
        );
        await ref.read(subjectsProvider.notifier).editSubject(updated);
      } else {
        final newSubject = SubjectModel(
          id: '',
          userId: userId,
          subjectName: _nameController.text.trim(),
          subjectCode: _codeController.text.trim(),
          facultyName: _facultyController.text.trim(),
          credits: int.tryParse(_creditsController.text) ?? 0,
          targetPercentage: _target,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(subjectsProvider.notifier).addSubject(newSubject);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save subject: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Subject' : 'Add Subject'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Subject name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Subject name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Subject code'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _facultyController,
                  decoration: const InputDecoration(labelText: 'Faculty name'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _creditsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Credits'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Target attendance: ${_target.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _target,
                  min: 50,
                  max: 100,
                  divisions: 50,
                  label: '${_target.toStringAsFixed(0)}%',
                  onChanged: (v) => setState(() => _target = v),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.isEditing ? 'Save Changes' : 'Add Subject'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
