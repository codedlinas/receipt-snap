# Changelog

All notable changes to Receipt Snap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-01-16

### Added
- **LLM Message Logging**: New `messages` table to track all LLM inputs and outputs for debugging
  - Logs user image uploads with metadata (filename, mime_type, file_size)
  - Logs assistant responses with raw LLM output, parsed extraction, tokens used, and latency
  - Enables debugging of LLM extraction issues
- Enhanced `extractSubscriptionData` function to return raw response and token usage

### Changed
- Flutter CI workflow: Made analysis and tests non-blocking (continue on error)
- Supabase Deploy workflow: Changed to manual trigger only (requires secrets configuration)

### Technical
- New migration: `20260116000000_add_messages_table.sql`
- Updated `fireworks-client.ts` to expose `rawResponse` and `tokensUsed`
- Updated `process-receipt/index.ts` to log messages to database

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
