import 'package:flutter_test/flutter_test.dart';
import 'package:receiptsnap/shared/models/subscription.dart';

void main() {
  group('Subscription', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('fromJson creates subscription correctly', () {
      final json = {
        'id': 'test-id-123',
        'user_id': 'user-123',
        'subscription_name': 'Netflix',
        'amount': 15.99,
        'currency': 'USD',
        'billing_cycle': 'monthly',
        'next_charge_date': '2026-01-15',
        'is_active': true,
        'is_deleted': false,
        'confidence_score': 0.92,
        'user_verified': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final subscription = Subscription.fromJson(json);

      expect(subscription.id, 'test-id-123');
      expect(subscription.subscriptionName, 'Netflix');
      expect(subscription.amount, 15.99);
      expect(subscription.currency, 'USD');
      expect(subscription.billingCycle, BillingCycle.monthly);
      expect(subscription.isActive, true);
      expect(subscription.confidenceScore, 0.92);
    });

    test('toJson serializes subscription correctly', () {
      final subscription = Subscription(
        id: 'test-id-123',
        userId: 'user-123',
        subscriptionName: 'Spotify',
        amount: 9.99,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        isActive: true,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      final json = subscription.toJson();

      expect(json['subscription_name'], 'Spotify');
      expect(json['amount'], 9.99);
      expect(json['billing_cycle'], 'monthly');
    });

    test('daysUntilNextCharge calculates correctly for tomorrow', () {
      final tomorrow = today.add(const Duration(days: 1));
      final subscription = Subscription(
        id: 'test-id',
        userId: 'user-id',
        subscriptionName: 'Test',
        amount: 10.0,
        nextChargeDate: tomorrow,
        createdAt: now,
        updatedAt: now,
      );

      expect(subscription.daysUntilNextCharge, 1);
    });

    test('daysUntilNextCharge returns null when no next charge date', () {
      final subscription = Subscription(
        id: 'test-id',
        userId: 'user-id',
        subscriptionName: 'Test',
        amount: 10.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(subscription.daysUntilNextCharge, isNull);
    });

    test('isUrgent returns true for subscriptions within 3 days', () {
      final inTwoDays = today.add(const Duration(days: 2));
      final subscription = Subscription(
        id: 'test-id',
        userId: 'user-id',
        subscriptionName: 'Test',
        amount: 10.0,
        nextChargeDate: inTwoDays,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(subscription.isUrgent, true);
    });

    test('isUrgent returns false for subscriptions more than 3 days away', () {
      final inFiveDays = today.add(const Duration(days: 5));
      final subscription = Subscription(
        id: 'test-id',
        userId: 'user-id',
        subscriptionName: 'Test',
        amount: 10.0,
        nextChargeDate: inFiveDays,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(subscription.isUrgent, false);
    });

    test('formattedAmount returns correct format for USD', () {
      final subscription = Subscription(
        id: 'test-id',
        userId: 'user-id',
        subscriptionName: 'Test',
        amount: 15.99,
        currency: 'USD',
        createdAt: now,
        updatedAt: now,
      );

      expect(subscription.formattedAmount, '\$15.99');
    });

    test('formattedAmount returns correct format for EUR', () {
      final subscription = Subscription(
        id: 'test-id',
        userId: 'user-id',
        subscriptionName: 'Test',
        amount: 12.50,
        currency: 'EUR',
        createdAt: now,
        updatedAt: now,
      );

      expect(subscription.formattedAmount, '€12.50');
    });

    test('copyWith creates new instance with updated values', () {
      final original = Subscription(
        id: 'test-id',
        userId: 'user-id',
        subscriptionName: 'Original',
        amount: 10.0,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        subscriptionName: 'Updated',
        amount: 20.0,
      );

      expect(updated.subscriptionName, 'Updated');
      expect(updated.amount, 20.0);
      expect(updated.id, original.id);
      expect(original.subscriptionName, 'Original'); // Original unchanged
    });
  });

  group('BillingCycle', () {
    test('fromString parses all valid values', () {
      expect(BillingCycle.fromString('weekly'), BillingCycle.weekly);
      expect(BillingCycle.fromString('monthly'), BillingCycle.monthly);
      expect(BillingCycle.fromString('quarterly'), BillingCycle.quarterly);
      expect(BillingCycle.fromString('semi_annual'), BillingCycle.semiAnnual);
      expect(BillingCycle.fromString('annual'), BillingCycle.annual);
      expect(BillingCycle.fromString('one_time'), BillingCycle.oneTime);
      expect(BillingCycle.fromString('unknown'), BillingCycle.unknown);
    });

    test('fromString returns unknown for invalid values', () {
      expect(BillingCycle.fromString('invalid'), BillingCycle.unknown);
      expect(BillingCycle.fromString(null), BillingCycle.unknown);
    });

    test('displayName returns correct labels', () {
      expect(BillingCycle.monthly.displayName, 'Monthly');
      expect(BillingCycle.annual.displayName, 'Annual');
      expect(BillingCycle.semiAnnual.displayName, 'Semi-Annual');
    });

    test('toJson returns correct string values', () {
      expect(BillingCycle.monthly.toJson(), 'monthly');
      expect(BillingCycle.semiAnnual.toJson(), 'semi_annual');
      expect(BillingCycle.oneTime.toJson(), 'one_time');
    });
  });
}
