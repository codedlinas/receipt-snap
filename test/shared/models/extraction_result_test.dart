import 'package:flutter_test/flutter_test.dart';
import 'package:receiptsnap/shared/models/extraction_result.dart';
import 'package:receiptsnap/shared/models/subscription.dart';

void main() {
  group('ExtractionResult', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'subscription_name': 'Netflix',
        'billing_entity': 'Netflix Inc.',
        'amount': 15.99,
        'currency': 'USD',
        'billing_cycle': 'monthly',
        'start_date': '2026-01-01',
        'next_charge_date': '2026-02-01',
        'payment_method': 'Visa ****1234',
        'renewal_terms': 'Auto-renews monthly',
        'cancellation_policy': 'Cancel anytime',
        'cancellation_deadline': '2026-01-25',
        'confidence_score': 0.92,
        'raw_text': 'Netflix subscription receipt...',
      };

      final result = ExtractionResult.fromJson(json);

      expect(result.subscriptionName, 'Netflix');
      expect(result.billingEntity, 'Netflix Inc.');
      expect(result.amount, 15.99);
      expect(result.currency, 'USD');
      expect(result.billingCycle, BillingCycle.monthly);
      expect(result.startDate, DateTime(2026, 1, 1));
      expect(result.nextChargeDate, DateTime(2026, 2, 1));
      expect(result.paymentMethod, 'Visa ****1234');
      expect(result.confidenceScore, 0.92);
    });

    test('fromJson handles null/missing fields', () {
      final json = {
        'subscription_name': 'Test',
        'amount': 10.0,
        'confidence_score': 0.5,
      };

      final result = ExtractionResult.fromJson(json);

      expect(result.subscriptionName, 'Test');
      expect(result.billingEntity, isNull);
      expect(result.nextChargeDate, isNull);
      expect(result.currency, 'USD'); // Default
      expect(result.billingCycle, BillingCycle.unknown);
    });

    test('isHighConfidence returns true for score >= 0.8', () {
      final highConfidence = const ExtractionResult(
        subscriptionName: 'Test',
        amount: 10.0,
        confidenceScore: 0.85,
      );

      final exactThreshold = const ExtractionResult(
        subscriptionName: 'Test',
        amount: 10.0,
        confidenceScore: 0.80,
      );

      expect(highConfidence.isHighConfidence, true);
      expect(exactThreshold.isHighConfidence, true);
    });

    test('isHighConfidence returns false for score < 0.8', () {
      final lowConfidence = const ExtractionResult(
        subscriptionName: 'Test',
        amount: 10.0,
        confidenceScore: 0.79,
      );

      expect(lowConfidence.isHighConfidence, false);
    });

    test('requiresReview is inverse of isHighConfidence', () {
      final highConfidence = const ExtractionResult(
        subscriptionName: 'Test',
        amount: 10.0,
        confidenceScore: 0.90,
      );

      final lowConfidence = const ExtractionResult(
        subscriptionName: 'Test',
        amount: 10.0,
        confidenceScore: 0.50,
      );

      expect(highConfidence.requiresReview, false);
      expect(lowConfidence.requiresReview, true);
    });

    test('toJson serializes correctly', () {
      final result = const ExtractionResult(
        subscriptionName: 'Spotify',
        billingEntity: 'Spotify AB',
        amount: 9.99,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        confidenceScore: 0.95,
        rawText: 'Raw OCR text',
      );

      final json = result.toJson();

      expect(json['subscription_name'], 'Spotify');
      expect(json['billing_entity'], 'Spotify AB');
      expect(json['amount'], 9.99);
      expect(json['billing_cycle'], 'monthly');
      expect(json['confidence_score'], 0.95);
    });

    test('copyWith creates modified copy', () {
      final original = const ExtractionResult(
        subscriptionName: 'Original',
        amount: 10.0,
        confidenceScore: 0.5,
      );

      final modified = original.copyWith(
        subscriptionName: 'Modified',
        amount: 20.0,
        confidenceScore: 0.9,
      );

      expect(modified.subscriptionName, 'Modified');
      expect(modified.amount, 20.0);
      expect(modified.confidenceScore, 0.9);
      expect(original.subscriptionName, 'Original'); // Original unchanged
    });
  });
}
