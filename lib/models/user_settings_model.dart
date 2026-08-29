import 'package:attendx/core/constants/app_constants.dart';

class UserSettingsModel {
  final String id;
  final String userId;
  final String theme; // light | dark | system
  final double defaultTargetPercentage;
  final bool notificationsEnabled;

  const UserSettingsModel({
    required this.id,
    required this.userId,
    this.theme = AppThemeMode.system,
    this.defaultTargetPercentage = 75.0,
    this.notificationsEnabled = true,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      theme: json['theme'] as String? ?? AppThemeMode.system,
      defaultTargetPercentage:
          (json['default_target_percentage'] as num?)?.toDouble() ?? 75.0,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'theme': theme,
        'default_target_percentage': defaultTargetPercentage,
        'notifications_enabled': notificationsEnabled,
      };

  UserSettingsModel copyWith({
    String? theme,
    double? defaultTargetPercentage,
    bool? notificationsEnabled,
  }) {
    return UserSettingsModel(
      id: id,
      userId: userId,
      theme: theme ?? this.theme,
      defaultTargetPercentage:
          defaultTargetPercentage ?? this.defaultTargetPercentage,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
