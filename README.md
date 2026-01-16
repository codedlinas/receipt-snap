# Receipt Snap

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B.svg?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A mobile application for Android and iOS that enables users to photograph or upload receipts and screenshots of subscription confirmations, automatically extracting structured payment data using AI.

## Features

- **Camera/Gallery Capture**: Take photos or select images from gallery
- **AI Extraction**: Automatic subscription data extraction using Qwen3 VL 30B vision model via Fireworks.ai
- **Review & Edit**: Review extracted data and make corrections before saving
- **Subscription Tracking**: View all subscriptions sorted by renewal date
- **Push Notifications**: Get reminders 3 days and 1 day before renewals
- **Dark Mode**: Beautiful dark theme optimized for OLED screens

## Tech Stack

- **Frontend**: Flutter 3.19+
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **AI/LLM**: Fireworks.ai (Qwen3 VL 30B A3B Instruct - Vision Model)
- **Push Notifications**: Firebase Cloud Messaging
- **State Management**: Riverpod
- **Navigation**: GoRouter

## How It Works

### LLM Input/Output

**Input Prompt:**
The system sends a receipt image to the vision model with instructions to extract subscription data in a structured JSON format.

**Output:**
```json
{
  "subscription_name": "string",
  "billing_entity": "string | null",
  "amount": "number",
  "currency": "3-letter code (USD, EUR, etc.)",
  "billing_cycle": "weekly|monthly|quarterly|semi_annual|annual|one_time|unknown",
  "start_date": "YYYY-MM-DD | null",
  "next_charge_date": "YYYY-MM-DD | null",
  "payment_method": "string | null",
  "renewal_terms": "string | null",
  "cancellation_policy": "string | null",
  "cancellation_deadline": "YYYY-MM-DD | null",
  "confidence_score": "0.0 to 1.0",
  "raw_text": "OCR text from image"
}
```

## Getting Started

### Prerequisites

- Flutter 3.19.0 or higher
- Dart 3.2.0 or higher
- Supabase account
- Firebase account
- Fireworks.ai account

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/codedlinas/receipt-snap.git
   cd receipt-snap
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new Supabase project at [supabase.com](https://supabase.com)
   - Run the migration in `supabase/migrations/20260108000000_initial_schema.sql`
   - **Create the `receipts` storage bucket** (required for image uploads):
     ```sql
     INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
     VALUES ('receipts', 'receipts', false, 10485760, 
             ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']);
     ```
   - Deploy edge functions:
     ```bash
     supabase functions deploy process-receipt
     supabase functions deploy notify-renewals
     supabase functions deploy update-fcm-token
     ```
   - Set secrets in Supabase dashboard (Settings > Edge Functions > Secrets):
     - `FIREWORKS_API_KEY`: Your Fireworks.ai API key
     - `FIREBASE_PROJECT_ID`: Your Firebase project ID
     - `FIREBASE_CLIENT_EMAIL`: Firebase service account email
     - `FIREBASE_PRIVATE_KEY`: Firebase service account private key

4. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add Android and iOS apps
   - Download `google-services.json` to `android/app/`
   - Download `GoogleService-Info.plist` to `ios/Runner/`
   - Enable Cloud Messaging

5. **Update App Configuration**
   - Edit `lib/core/config/app_config.dart`
   - Replace `supabaseUrl` with your Supabase project URL
   - Replace `supabaseAnonKey` with your anon key

6. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
receipt-snap/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/
│   │   ├── config/               # App configuration
│   │   ├── services/             # Core services (notifications)
│   │   └── theme/                # App theme and colors
│   ├── features/
│   │   ├── auth/                 # Authentication feature
│   │   ├── capture/              # Receipt capture feature
│   │   ├── subscriptions/        # Subscription management
│   │   └── settings/             # App settings
│   └── shared/
│       ├── models/               # Data models
│       └── widgets/              # Shared widgets
├── supabase/
│   ├── migrations/               # Database migrations
│   ├── functions/                # Edge functions
│   │   ├── process-receipt/      # Receipt processing & LLM extraction
│   │   ├── notify-renewals/      # Renewal notification scheduler
│   │   └── update-fcm-token/     # FCM token management
│   └── config.toml               # Supabase configuration
├── test/                         # Unit tests
└── integration_test/             # Integration tests
```

## Edge Functions

### process-receipt
Handles receipt image upload and AI extraction.
- **Input**: `{ image_base64, filename, mime_type }`
- **Output**: `{ success, receipt_id, subscription, extracted, requires_review }`

### notify-renewals
Cron job that sends push notifications for upcoming renewals.

### update-fcm-token
Updates the user's FCM token for push notifications.

## Environment Variables

### Supabase Secrets

Set these in your Supabase dashboard under Settings > Edge Functions > Secrets:

| Variable | Description |
|----------|-------------|
| `FIREWORKS_API_KEY` | API key from Fireworks.ai |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_CLIENT_EMAIL` | Firebase service account email |
| `FIREBASE_PRIVATE_KEY` | Firebase service account private key |

### GitHub Actions Secrets

Set these in your GitHub repository settings:

| Variable | Description |
|----------|-------------|
| `SUPABASE_PROJECT_REF` | Your Supabase project reference |
| `SUPABASE_ACCESS_TOKEN` | Personal access token from Supabase |

## Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

## Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Version History

### v1.0.0 (January 2026)
- Initial release
- Receipt scanning with AI extraction (Qwen3 VL 30B)
- Subscription tracking and management
- Push notifications for renewal reminders
- Dark mode UI

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
