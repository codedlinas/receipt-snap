class NotificationPreferences {
  final bool renewal3d;
  final bool renewal1d;
  final bool weeklySummary;

  const NotificationPreferences({
    this.renewal3d = true,
    this.renewal1d = true,
    this.weeklySummary = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      renewal3d: json['renewal_3d'] as bool? ?? true,
      renewal1d: json['renewal_1d'] as bool? ?? true,
      weeklySummary: json['weekly_summary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'renewal_3d': renewal3d,
      'renewal_1d': renewal1d,
      'weekly_summary': weeklySummary,
    };
  }

  NotificationPreferences copyWith({
    bool? renewal3d,
    bool? renewal1d,
    bool? weeklySummary,
  }) {
    return NotificationPreferences(
      renewal3d: renewal3d ?? this.renewal3d,
      renewal1d: renewal1d ?? this.renewal1d,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String timezone;
  final NotificationPreferences notificationPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.timezone = 'UTC',
    this.notificationPreferences = const NotificationPreferences(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      notificationPreferences: json['notification_preferences'] != null
          ? NotificationPreferences.fromJson(
              json['notification_preferences'] as Map<String, dynamic>)
          : const NotificationPreferences(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'timezone': timezone,
      'notification_preferences': notificationPreferences.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? timezone,
    NotificationPreferences? notificationPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
