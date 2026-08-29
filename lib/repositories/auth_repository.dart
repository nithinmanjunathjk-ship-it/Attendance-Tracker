import 'package:attendx/core/errors/app_exceptions.dart';
import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => SupabaseService.authStateChanges;

  bool get isAuthenticated => SupabaseService.isAuthenticated;

  User? get currentUser => SupabaseService.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? college,
    String? semester,
    String? section,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final userId = res.user?.id;
      if (userId == null) {
        throw const AuthException('Registration failed. Please try again.');
      }

      // The DB trigger `handle_new_user` already inserts a base profile +
      // settings row. We patch in the extra onboarding fields here.
      await _client.from('profiles').update({
        'college': college,
        'semester': semester,
        'section': section,
      }).eq('id', userId);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw const AuthException('Invalid email or password.');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw const AuthException('Could not send reset email. Please try again.');
    }
  }

  Future<ProfileModel> fetchProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      throw const AuthException('Not authenticated.');
    }
    final data =
        await _client.from('profiles').select().eq('id', userId).single();
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final data = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();
    return ProfileModel.fromJson(data);
  }
}
