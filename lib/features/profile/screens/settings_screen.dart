import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/providers/settings_provider.dart';
import 'package:attendx/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings: $e')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (_) {
                        ref.read(themeModeProvider.notifier).setThemeMode(AppThemeMode.light);
                        ref.read(settingsProvider.notifier).updateSettings(
                              settings.copyWith(theme: AppThemeMode.light),
                            );
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (_) {
                        ref.read(themeModeProvider.notifier).setThemeMode(AppThemeMode.dark);
                        ref.read(settingsProvider.notifier).updateSettings(
                              settings.copyWith(theme: AppThemeMode.dark),
                            );
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (_) {
                        ref.read(themeModeProvider.notifier).setThemeMode(AppThemeMode.system);
                        ref.read(settingsProvider.notifier).updateSettings(
                              settings.copyWith(theme: AppThemeMode.system),
                            );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Attendance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Default target: '
                          '${settings.defaultTargetPercentage.toStringAsFixed(0)}%'),
                      Slider(
                        value: settings.defaultTargetPercentage,
                        min: 50,
                        max: 100,
                        divisions: 50,
                        label: '${settings.defaultTargetPercentage.toStringAsFixed(0)}%',
                        onChanged: (v) => ref.read(settingsProvider.notifier).updateSettings(
                              settings.copyWith(defaultTargetPercentage: v),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Get reminders about low attendance'),
                  value: settings.notificationsEnabled,
                  onChanged: (v) => ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(notificationsEnabled: v),
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
