/// Application configuration
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://qjbiyljcwddywfdtmghi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqYml5bGpjd2RkeXdmZHRtZ2hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NjI2NjAsImV4cCI6MjA4MzUzODY2MH0.LfuqiDko8KmwWVjqLoYOKSPpaccJ1w5d91ZtXECwjL0';

  // API Endpoints
  static const String processReceiptEndpoint = '/functions/v1/process-receipt';
  static const String updateFcmTokenEndpoint = '/functions/v1/update-fcm-token';

  // App Settings
  static const int imageMaxSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int imageQuality = 85;
  static const double confidenceThreshold = 0.8;

  // Notification Settings
  static const int renewalNotificationDays3 = 3;
  static const int renewalNotificationDays1 = 1;
}
