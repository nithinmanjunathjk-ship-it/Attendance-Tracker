import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/core/errors/app_exceptions.dart';
import 'package:attendx/core/services/supabase_service.dart';
import 'package:attendx/models/user_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class SettingsRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = SupabaseService.currentUserId;
    if (id == null) throw const AuthException('Not authenticated.');
    return id;
  }

  Future<UserSettingsModel> fetchSettings() async {
    final data = await _client
        .from(AppConstants.tableSettings)
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (data == null) {
      final created = await _client
          .from(AppConstants.tableSettings)
          .insert({'user_id': _userId})
          .select()
          .single();
      return UserSettingsModel.fromJson(created);
    }

    return UserSettingsModel.fromJson(data);
  }

  Future<UserSettingsModel> updateSettings(UserSettingsModel settings) async {
    final data = await _client
        .from(AppConstants.tableSettings)
        .update(settings.toUpdateJson())
        .eq('user_id', _userId)
        .select()
        .single();
    return UserSettingsModel.fromJson(data);
  }
}
