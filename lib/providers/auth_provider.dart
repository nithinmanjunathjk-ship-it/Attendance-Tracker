import 'package:attendx/models/profile_model.dart';
import 'package:attendx/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Emits every time Supabase's auth state changes (sign in / sign out /
/// token refresh). Used by the router to redirect appropriately.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session != null,
    orElse: () => ref.read(authRepositoryProvider).isAuthenticated,
  );
});

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    if (!repo.isAuthenticated) return null;
    return repo.fetchProfile();
  }

  Future<void> updateProfile(ProfileModel profile) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.updateProfile(profile));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(ProfileNotifier.new);
