import 'package:flutter/foundation.dart';

enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  annual,
  yearly, // Alias for annual
  oneTime,
  unknown;

  String get displayName {
    switch (this) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.semiAnnual:
        return 'Semi-Annual';
      case BillingCycle.annual:
      case BillingCycle.yearly:
        return 'Yearly';
      case BillingCycle.oneTime:
        return 'One-Time';
      case BillingCycle.unknown:
        return 'Unknown';
    }
  }

  static BillingCycle fromString(String? value) {
    switch (value) {
      case 'weekly':
        return BillingCycle.weekly;
      case 'monthly':
        return BillingCycle.monthly;
      case 'quarterly':
        return BillingCycle.quarterly;
      case 'semi_annual':
        return BillingCycle.semiAnnual;
      case 'annual':
      case 'yearly':
        return BillingCycle.annual;
      case 'one_time':
        return BillingCycle.oneTime;
      default:
        return BillingCycle.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case BillingCycle.weekly:
        return 'weekly';
      case BillingCycle.monthly:
        return 'monthly';
      case BillingCycle.quarterly:
        return 'quarterly';
      case BillingCycle.semiAnnual:
        return 'semi_annual';
      case BillingCycle.annual:
      case BillingCycle.yearly:
        return 'annual';
      case BillingCycle.oneTime:
        return 'one_time';
      case BillingCycle.unknown:
        return 'unknown';
    }
  }
}

@immutable
class Subscription {
  final String id;
  final String userId;
  final String? receiptId;
  final String subscriptionName;
  final String? billingEntity;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime? startDate;
  final DateTime? nextChargeDate;
  final DateTime? lastChargeDate;
  final DateTime? cancellationDeadline;
  final String? paymentMethod;
  final String? renewalTerms;
  final String? cancellationPolicy;
  final String? category;
  final bool isActive;
  final bool isDeleted;
  final double? confidenceScore;
  final bool userVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    this.receiptId,
    required this.subscriptionName,
    this.billingEntity,
    required this.amount,
    this.currency = 'USD',
    this.billingCycle = BillingCycle.unknown,
    this.startDate,
    this.nextChargeDate,
    this.lastChargeDate,
    this.cancellationDeadline,
    this.paymentMethod,
    this.renewalTerms,
    this.cancellationPolicy,
    this.category,
    this.isActive = true,
    this.isDeleted = false,
    this.confidenceScore,
    this.userVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      receiptId: json['receipt_id'] as String?,
      subscriptionName: json['subscription_name'] as String,
      billingEntity: json['billing_entity'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      billingCycle: BillingCycle.fromString(json['billing_cycle'] as String?),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      nextChargeDate: json['next_charge_date'] != null
          ? DateTime.parse(json['next_charge_date'] as String)
          : null,
      lastChargeDate: json['last_charge_date'] != null
          ? DateTime.parse(json['last_charge_date'] as String)
          : null,
      cancellationDeadline: json['cancellation_deadline'] != null
          ? DateTime.parse(json['cancellation_deadline'] as String)
          : null,
      paymentMethod: json['payment_method'] as String?,
      renewalTerms: json['renewal_terms'] as String?,
      cancellationPolicy: json['cancellation_policy'] as String?,
      category: json['category'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      confidenceScore: json['confidence_score'] != null
          ? (json['confidence_score'] as num).toDouble()
          : null,
      userVerified: json['user_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'receipt_id': receiptId,
      'subscription_name': subscriptionName,
      'billing_entity': billingEntity,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle.toJson(),
      'start_date': startDate?.toIso8601String().split('T')[0],
      'next_charge_date': nextChargeDate?.toIso8601String().split('T')[0],
      'last_charge_date': lastChargeDate?.toIso8601String().split('T')[0],
      'cancellation_deadline':
          cancellationDeadline?.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'renewal_terms': renewalTerms,
      'cancellation_policy': cancellationPolicy,
      'category': category,
      'is_active': isActive,
      'is_deleted': isDeleted,
      'confidence_score': confidenceScore,
      'user_verified': userVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get days until next charge
  int? get daysUntilNextCharge {
    if (nextChargeDate == null) return null;
    final now = DateTime.now();
    final target = DateTime(
      nextChargeDate!.year,
      nextChargeDate!.month,
      nextChargeDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }

  /// Check if renewal is urgent (within 3 days)
  bool get isUrgent {
    final days = daysUntilNextCharge;
    return days != null && days <= 3 && days >= 0;
  }

  /// Format amount with currency
  String get formattedAmount {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return '$currency ';
    }
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? receiptId,
    String? subscriptionName,
    String? billingEntity,
    double? amount,
    String? currency,
    BillingCycle? billingCycle,
    DateTime? startDate,
    DateTime? nextChargeDate,
    DateTime? lastChargeDate,
    DateTime? cancellationDeadline,
    String? paymentMethod,
    String? renewalTerms,
    String? cancellationPolicy,
    String? category,
    bool? isActive,
    bool? isDeleted,
    double? confidenceScore,
    bool? userVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      receiptId: receiptId ?? this.receiptId,
      subscriptionName: subscriptionName ?? this.subscriptionName,
      billingEntity: billingEntity ?? this.billingEntity,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      nextChargeDate: nextChargeDate ?? this.nextChargeDate,
      lastChargeDate: lastChargeDate ?? this.lastChargeDate,
      cancellationDeadline: cancellationDeadline ?? this.cancellationDeadline,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      renewalTerms: renewalTerms ?? this.renewalTerms,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      userVerified: userVerified ?? this.userVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
