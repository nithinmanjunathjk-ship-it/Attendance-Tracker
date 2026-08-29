import 'package:attendx/models/user_settings_model.dart';
import 'package:attendx/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsNotifier extends AsyncNotifier<UserSettingsModel> {
  @override
  Future<UserSettingsModel> build() async {
    return ref.watch(settingsRepositoryProvider).fetchSettings();
  }

  Future<void> updateSettings(UserSettingsModel settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).updateSettings(settings),
    );
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, UserSettingsModel>(
  SettingsNotifier.new,
);
