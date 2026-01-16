import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/subscription.dart';

class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all active subscriptions for the current user
  Future<List<Subscription>> getSubscriptions() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('next_charge_date', ascending: true);

      return (response as List)
          .map((json) => Subscription.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
      return [];
    }
  }

  /// Get subscriptions sorted by urgency (upcoming renewals first)
  Future<List<Subscription>> getUpcomingRenewals() async {
    try {
      final subscriptions = await getSubscriptions();
      
      // Filter active subscriptions with next charge date
      final upcoming = subscriptions
          .where((s) => s.isActive && s.nextChargeDate != null)
          .toList();

      // Sort by next charge date
      upcoming.sort((a, b) {
        if (a.nextChargeDate == null) return 1;
        if (b.nextChargeDate == null) return -1;
        return a.nextChargeDate!.compareTo(b.nextChargeDate!);
      });

      return upcoming;
    } catch (e) {
      debugPrint('Error fetching upcoming renewals: $e');
      return [];
    }
  }

  /// Get a single subscription by ID
  Future<Subscription?> getSubscriptionById(String id) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('id', id)
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      return null;
    }
  }

  /// Create a new subscription
  Future<Subscription?> createSubscription(Subscription subscription) async {
    try {
      final response = await _client
          .from('subscriptions')
          .insert(subscription.toJson()..remove('id'))
          .select()
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      return null;
    }
  }

  /// Update an existing subscription
  Future<Subscription?> updateSubscription(Subscription subscription) async {
    try {
      final response = await _client
          .from('subscriptions')
          .update(subscription.toJson())
          .eq('id', subscription.id)
          .select()
          .single();

      // Create audit log
      await _createAuditLog(subscription.id, 'update', subscription.toJson());

      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      return null;
    }
  }

  /// Soft delete a subscription
  Future<bool> deleteSubscription(String id) async {
    try {
      await _client
          .from('subscriptions')
          .update({'is_deleted': true})
          .eq('id', id);

      await _createAuditLog(id, 'delete', null);

      return true;
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
      return false;
    }
  }

  /// Mark subscription as cancelled
  Future<Subscription?> cancelSubscription(String id) async {
    try {
      final response = await _client
          .from('subscriptions')
          .update({'is_active': false})
          .eq('id', id)
          .select()
          .single();

      await _createAuditLog(id, 'update', {'is_active': false});

      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      return null;
    }
  }

  /// Mark subscription as verified by user
  Future<Subscription?> verifySubscription(String id) async {
    try {
      final response = await _client
          .from('subscriptions')
          .update({'user_verified': true})
          .eq('id', id)
          .select()
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error verifying subscription: $e');
      return null;
    }
  }

  /// Get total monthly spending
  Future<double> getMonthlySpending() async {
    try {
      final subscriptions = await getSubscriptions();
      
      double total = 0;
      for (final sub in subscriptions.where((s) => s.isActive)) {
        switch (sub.billingCycle) {
          case BillingCycle.weekly:
            total += sub.amount * 4.33; // Average weeks per month
            break;
          case BillingCycle.monthly:
            total += sub.amount;
            break;
          case BillingCycle.quarterly:
            total += sub.amount / 3;
            break;
          case BillingCycle.semiAnnual:
            total += sub.amount / 6;
            break;
          case BillingCycle.annual:
            total += sub.amount / 12;
            break;
          default:
            break;
        }
      }

      return total;
    } catch (e) {
      debugPrint('Error calculating monthly spending: $e');
      return 0;
    }
  }

  /// Create audit log entry
  Future<void> _createAuditLog(
    String entityId,
    String action,
    Map<String, dynamic>? newValues,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('audit_logs').insert({
        'user_id': userId,
        'entity_type': 'subscription',
        'entity_id': entityId,
        'action': action,
        'new_values': newValues,
      });
    } catch (e) {
      debugPrint('Error creating audit log: $e');
    }
  }

  /// Stream of subscriptions for real-time updates
  Stream<List<Subscription>> subscriptionsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('next_charge_date', ascending: true)
        .map((list) => list
            .where((json) => json['is_deleted'] != true)
            .map((json) => Subscription.fromJson(json))
            .toList());
  }
}
