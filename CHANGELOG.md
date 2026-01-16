# Changelog

All notable changes to Receipt Snap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-16

### Added
- Initial release of Receipt Snap
- Receipt scanning via camera or gallery
- AI-powered subscription data extraction using Qwen3 VL 30B vision model (Fireworks.ai)
- Automatic extraction of:
  - Subscription name
  - Billing entity
  - Amount and currency
  - Billing cycle
  - Payment method
  - Renewal terms and cancellation policy
- Confidence score for extraction accuracy
- Review screen for editing extracted data before saving
- Subscription list with sorting by renewal date
- Subscription detail view
- Push notifications for renewal reminders (3 days and 1 day before)
- Dark mode UI optimized for OLED screens
- Supabase backend with:
  - PostgreSQL database
  - User authentication
  - Storage for receipt images
  - Edge functions for processing
- Firebase Cloud Messaging integration

### Technical
- Flutter 3.19+ with Dart 3.2+
- Riverpod for state management
- GoRouter for navigation
- Supabase Edge Functions (Deno)
- Fireworks.ai API integration
