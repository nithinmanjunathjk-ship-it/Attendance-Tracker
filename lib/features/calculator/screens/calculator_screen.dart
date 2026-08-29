import 'package:attendx/core/theme/app_theme.dart';
import 'package:attendx/core/utils/attendance_calculator.dart';
import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _presentController = TextEditingController(text: '0');
  final _totalController = TextEditingController(text: '0');
  double _target = 75;
  int _projectAttendK = 5;
  int _projectMissK = 2;

  @override
  void dispose() {
    _presentController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  int get _present => int.tryParse(_presentController.text) ?? 0;
  int get _total => int.tryParse(_totalController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final present = _present.clamp(0, 1 << 30);
    final total = _total.clamp(0, 1 << 30);
    final validTotal = total < present ? present : total;

    final current = AttendanceCalculator.currentPercentage(
        present: present, total: validTotal);
    final needed = AttendanceCalculator.classesNeededForTarget(
      present: present,
      total: validTotal,
      targetPercentage: _target,
    );
    final missable = AttendanceCalculator.maxClassesMissable(
      present: present,
      total: validTotal,
      targetPercentage: _target,
    );
    final projectedAttend = AttendanceCalculator.projectedAfterAttending(
      present: present,
      total: validTotal,
      k: _projectAttendK,
    );
    final projectedMiss = AttendanceCalculator.projectedAfterMissing(
      present: present,
      total: validTotal,
      k: _projectMissK,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Calculator')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _presentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Present'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total classes'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Target: ${_target.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _target,
              min: 50,
              max: 100,
              divisions: 50,
              label: '${_target.toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _target = v),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppColors.primary.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '${current.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.forPercentage(current),
                          ),
                    ),
                    const Text('Current attendance'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _ResultTile(
              icon: Icons.trending_up_rounded,
              title: 'Classes needed to reach target',
              value: needed.alreadyMet
                  ? 'Already met 🎉'
                  : needed.unreachable
                      ? 'Not reachable'
                      : '${needed.classesNeeded}',
            ),
            _ResultTile(
              icon: Icons.trending_down_rounded,
              title: 'Max classes you can miss',
              value: missable.cannotMissAny ? '0' : '${missable.maxMissable}',
            ),
            const SizedBox(height: 20),
            Text('Projections', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('If I attend the next')),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true),
                            controller: TextEditingController(text: '$_projectAttendK'),
                            onChanged: (v) => setState(
                                () => _projectAttendK = int.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('classes'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '→ ${projectedAttend.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.forPercentage(projectedAttend),
                      ),
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Expanded(child: Text('If I miss the next')),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true),
                            controller: TextEditingController(text: '$_projectMissK'),
                            onChanged: (v) => setState(
                                () => _projectMissK = int.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('classes'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '→ ${projectedMiss.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.forPercentage(projectedMiss),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ResultTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}
