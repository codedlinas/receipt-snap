import 'subscription.dart';

class ExtractionResult {
  final String subscriptionName;
  final String? billingEntity;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime? startDate;
  final DateTime? nextChargeDate;
  final String? paymentMethod;
  final String? renewalTerms;
  final String? cancellationPolicy;
  final DateTime? cancellationDeadline;
  final double confidenceScore;
  final String rawText;

  const ExtractionResult({
    required this.subscriptionName,
    this.billingEntity,
    required this.amount,
    this.currency = 'USD',
    this.billingCycle = BillingCycle.unknown,
    this.startDate,
    this.nextChargeDate,
    this.paymentMethod,
    this.renewalTerms,
    this.cancellationPolicy,
    this.cancellationDeadline,
    required this.confidenceScore,
    this.rawText = '',
  });

  bool get isHighConfidence => confidenceScore >= 0.8;
  bool get requiresReview => confidenceScore < 0.8;

  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    return ExtractionResult(
      subscriptionName: json['subscription_name'] as String? ?? 'Unknown',
      billingEntity: json['billing_entity'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      billingCycle: BillingCycle.fromString(json['billing_cycle'] as String?),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      nextChargeDate: json['next_charge_date'] != null
          ? DateTime.tryParse(json['next_charge_date'] as String)
          : null,
      paymentMethod: json['payment_method'] as String?,
      renewalTerms: json['renewal_terms'] as String?,
      cancellationPolicy: json['cancellation_policy'] as String?,
      cancellationDeadline: json['cancellation_deadline'] != null
          ? DateTime.tryParse(json['cancellation_deadline'] as String)
          : null,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      rawText: json['raw_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_name': subscriptionName,
      'billing_entity': billingEntity,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle.toJson(),
      'start_date': startDate?.toIso8601String().split('T')[0],
      'next_charge_date': nextChargeDate?.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'renewal_terms': renewalTerms,
      'cancellation_policy': cancellationPolicy,
      'cancellation_deadline':
          cancellationDeadline?.toIso8601String().split('T')[0],
      'confidence_score': confidenceScore,
      'raw_text': rawText,
    };
  }

  ExtractionResult copyWith({
    String? subscriptionName,
    String? billingEntity,
    double? amount,
    String? currency,
    BillingCycle? billingCycle,
    DateTime? startDate,
    DateTime? nextChargeDate,
    String? paymentMethod,
    String? renewalTerms,
    String? cancellationPolicy,
    DateTime? cancellationDeadline,
    double? confidenceScore,
    String? rawText,
  }) {
    return ExtractionResult(
      subscriptionName: subscriptionName ?? this.subscriptionName,
      billingEntity: billingEntity ?? this.billingEntity,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      nextChargeDate: nextChargeDate ?? this.nextChargeDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      renewalTerms: renewalTerms ?? this.renewalTerms,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      cancellationDeadline: cancellationDeadline ?? this.cancellationDeadline,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      rawText: rawText ?? this.rawText,
    );
  }
}
