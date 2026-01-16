import 'package:flutter/foundation.dart';

/// Stub NotificationService - Firebase notifications will be added later
/// when Apple Developer and Google Play Console accounts are set up.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Firebase notifications disabled for now
    // Will be enabled when developer accounts are configured
    debugPrint('NotificationService: Notifications disabled (Firebase not configured)');
  }

  /// Manually refresh FCM token (no-op until Firebase is configured)
  Future<void> refreshToken() async {
    debugPrint('NotificationService: Token refresh skipped (Firebase not configured)');
  }
}
