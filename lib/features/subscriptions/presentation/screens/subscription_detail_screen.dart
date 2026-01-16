import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/subscription.dart';
import '../providers/subscription_provider.dart';

class SubscriptionDetailScreen extends ConsumerWidget {
  final String subscriptionId;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionByIdProvider(subscriptionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription Details'),
        actions: [
          subscriptionAsync.when(
            data: (sub) => sub != null
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) =>
                        _handleMenuAction(context, ref, value, sub),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (sub.isActive)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Mark Cancelled'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: AppColors.error),
                            SizedBox(width: 12),
                            Text('Delete',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: subscriptionAsync.when(
        data: (subscription) {
          if (subscription == null) {
            return const Center(
              child: Text('Subscription not found'),
            );
          }
          return _buildContent(context, ref, subscription);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(subscriptionByIdProvider(subscriptionId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, Subscription subscription) {
    final daysUntil = subscription.daysUntilNextCharge;
    final urgencyColor = daysUntil != null
        ? AppColors.getUrgencyColor(daysUntil)
        : AppColors.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Status badge
                if (!subscription.isActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Cancelled',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),

                // Name
                Text(
                  subscription.subscriptionName,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (subscription.billingEntity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subscription.billingEntity!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],

                const SizedBox(height: 24),

                // Amount
                Text(
                  subscription.formattedAmount,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                Text(
                  subscription.billingCycle.displayName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                // Next charge
                if (subscription.nextChargeDate != null && subscription.isActive) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: urgencyColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, color: urgencyColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _formatNextCharge(
                              subscription.nextChargeDate!, daysUntil),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: urgencyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Confidence score
                if (subscription.confidenceScore != null) ...[
                  const SizedBox(height: 16),
                  _buildConfidenceIndicator(context, subscription.confidenceScore!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details section
          _buildSection(
            context,
            'Details',
            [
              if (subscription.paymentMethod != null)
                _buildDetailRow(
                  context,
                  'Payment Method',
                  subscription.paymentMethod!,
                  Icons.credit_card_outlined,
                ),
              if (subscription.startDate != null)
                _buildDetailRow(
                  context,
                  'Start Date',
                  DateFormat('MMMM d, yyyy').format(subscription.startDate!),
                  Icons.calendar_today_outlined,
                ),
              if (subscription.cancellationDeadline != null)
                _buildDetailRow(
                  context,
                  'Cancellation Deadline',
                  DateFormat('MMMM d, yyyy')
                      .format(subscription.cancellationDeadline!),
                  Icons.warning_amber_outlined,
                ),
            ],
          ),

          if (subscription.renewalTerms != null ||
              subscription.cancellationPolicy != null) ...[
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Terms',
              [
                if (subscription.renewalTerms != null)
                  _buildTextBlock(
                    context,
                    'Renewal Terms',
                    subscription.renewalTerms!,
                  ),
                if (subscription.cancellationPolicy != null)
                  _buildTextBlock(
                    context,
                    'Cancellation Policy',
                    subscription.cancellationPolicy!,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context, double score) {
    final isHigh = score >= 0.8;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isHigh ? Icons.verified : Icons.info_outline,
          size: 16,
          color: isHigh ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: 4),
        Text(
          isHigh ? 'AI Verified' : 'Review Recommended',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isHigh ? AppColors.success : AppColors.warning,
              ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final filteredChildren = children.where((w) => w is! SizedBox).toList();
    if (filteredChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: filteredChildren,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(BuildContext context, String label, String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatNextCharge(DateTime date, int? daysUntil) {
    if (daysUntil == null) return DateFormat('MMMM d, yyyy').format(date);
    if (daysUntil == 0) return 'Renews today';
    if (daysUntil == 1) return 'Renews tomorrow';
    if (daysUntil <= 7) return 'Renews in $daysUntil days';
    return 'Renews ${DateFormat('MMMM d').format(date)}';
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Subscription subscription,
  ) async {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit coming soon')),
        );
        break;
      case 'cancel':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mark as Cancelled?'),
            content: Text(
              'This will mark "${subscription.subscriptionName}" as cancelled.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(subscriptionNotifierProvider.notifier)
              .cancelSubscription(subscription.id);
          if (context.mounted) {
            ref.invalidate(subscriptionByIdProvider(subscriptionId));
          }
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Subscription?'),
            content: Text(
              'Are you sure you want to delete "${subscription.subscriptionName}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(subscriptionNotifierProvider.notifier)
              .deleteSubscription(subscription.id);
          if (context.mounted) {
            context.pop();
          }
        }
        break;
    }
  }
}
