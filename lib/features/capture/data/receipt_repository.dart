import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/subscription.dart';
import '../../../shared/models/extraction_result.dart';

class ProcessReceiptResponse {
  final bool success;
  final String? receiptId;
  final Subscription? subscription;
  final ExtractionResult? extraction;
  final bool requiresReview;
  final String? error;

  const ProcessReceiptResponse({
    required this.success,
    this.receiptId,
    this.subscription,
    this.extraction,
    this.requiresReview = false,
    this.error,
  });

  factory ProcessReceiptResponse.fromJson(Map<String, dynamic> json) {
    return ProcessReceiptResponse(
      success: json['success'] as bool? ?? false,
      receiptId: json['receipt_id'] as String?,
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'] as Map<String, dynamic>)
          : null,
      extraction: json['extracted'] != null
          ? ExtractionResult.fromJson(json['extracted'] as Map<String, dynamic>)
          : null,
      requiresReview: json['requires_review'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}

class ReceiptRepository {
  final SupabaseClient _client;

  ReceiptRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Process a receipt image through the edge function
  Future<ProcessReceiptResponse> processReceipt({
    required String imageBase64,
    String? filename,
    String? mimeType,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'process-receipt',
        body: {
          'image_base64': imageBase64,
          'filename': filename ?? 'receipt.jpg',
          'mime_type': mimeType ?? 'image/jpeg',
        },
      );

      if (response.status == 200 && response.data != null) {
        return ProcessReceiptResponse.fromJson(
            response.data as Map<String, dynamic>);
      }

      return ProcessReceiptResponse(
        success: false,
        error: 'Server error: ${response.status}',
      );
    } catch (e) {
      debugPrint('Error processing receipt: $e');
      return ProcessReceiptResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create subscription manually from extraction result
  Future<Subscription?> createSubscriptionFromExtraction(
    ExtractionResult extraction,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('subscriptions')
          .insert({
            'user_id': userId,
            'subscription_name': extraction.subscriptionName,
            'billing_entity': extraction.billingEntity,
            'amount': extraction.amount,
            'currency': extraction.currency,
            'billing_cycle': extraction.billingCycle.toJson(),
            'start_date':
                extraction.startDate?.toIso8601String().split('T')[0],
            'next_charge_date':
                extraction.nextChargeDate?.toIso8601String().split('T')[0],
            'payment_method': extraction.paymentMethod,
            'renewal_terms': extraction.renewalTerms,
            'cancellation_policy': extraction.cancellationPolicy,
            'cancellation_deadline':
                extraction.cancellationDeadline?.toIso8601String().split('T')[0],
            'confidence_score': extraction.confidenceScore,
            'user_verified': true,
          })
          .select()
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      return null;
    }
  }

  /// Update subscription with user edits
  Future<Subscription?> updateSubscriptionFromExtraction(
    String subscriptionId,
    ExtractionResult extraction,
  ) async {
    try {
      final response = await _client
          .from('subscriptions')
          .update({
            'subscription_name': extraction.subscriptionName,
            'billing_entity': extraction.billingEntity,
            'amount': extraction.amount,
            'currency': extraction.currency,
            'billing_cycle': extraction.billingCycle.toJson(),
            'start_date':
                extraction.startDate?.toIso8601String().split('T')[0],
            'next_charge_date':
                extraction.nextChargeDate?.toIso8601String().split('T')[0],
            'payment_method': extraction.paymentMethod,
            'renewal_terms': extraction.renewalTerms,
            'cancellation_policy': extraction.cancellationPolicy,
            'cancellation_deadline':
                extraction.cancellationDeadline?.toIso8601String().split('T')[0],
            'user_verified': true,
          })
          .eq('id', subscriptionId)
          .select()
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      return null;
    }
  }
}
