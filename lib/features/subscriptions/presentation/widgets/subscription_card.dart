import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/subscription.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntil = subscription.daysUntilNextCharge;
    final urgencyColor = daysUntil != null
        ? AppColors.getUrgencyColor(daysUntil)
        : AppColors.textTertiary;
    final categoryColor = AppColors.getCategoryColor(subscription.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: subscription.isUrgent
                ? urgencyColor.withOpacity(0.3)
                : AppColors.border,
            width: subscription.isUrgent ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Top row: Logo, name, price
            Row(
              children: [
                // Logo/Avatar
                _buildLogo(categoryColor),
                const SizedBox(width: 14),

                // Name and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subscription.subscriptionName,
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!subscription.isActive) ...[
                            const SizedBox(width: 8),
                            _buildStatusBadge(context, 'Paused'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCategoryChip(context, subscription.category),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            subscription.billingCycle.displayName,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      subscription.formattedAmount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subscription.billingCycle == BillingCycle.yearly)
                      Text(
                        '${(subscription.amount / 12).toStringAsFixed(2)}/mo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                  ],
                ),
              ],
            ),

            // Bottom section: Progress and next charge
            if (subscription.isActive &&
                subscription.nextChargeDate != null) ...[
              const SizedBox(height: 16),
              _buildProgressSection(context, daysUntil, urgencyColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Color categoryColor) {
    // Get the first letter of subscription name for avatar
    final initial = subscription.subscriptionName.isNotEmpty
        ? subscription.subscriptionName[0].toUpperCase()
        : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.2),
            categoryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: categoryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: categoryColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String? category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category ?? 'Other',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildProgressSection(
      BuildContext context, int? daysUntil, Color urgencyColor) {
    // Calculate progress through billing cycle
    double progress = 0.7; // Default, would calculate from startDate
    if (daysUntil != null && subscription.billingCycle == BillingCycle.monthly) {
      progress = 1 - (daysUntil / 30).clamp(0, 1);
    } else if (daysUntil != null &&
        subscription.billingCycle == BillingCycle.yearly) {
      progress = 1 - (daysUntil / 365).clamp(0, 1);
    }

    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              daysUntil != null && daysUntil <= 7
                  ? urgencyColor
                  : AppColors.primary.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Bottom info row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatNextCharge(subscription.nextChargeDate!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            if (daysUntil != null) _buildDaysBadge(context, daysUntil, urgencyColor),
          ],
        ),
      ],
    );
  }

  String _formatNextCharge(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  Widget _buildDaysBadge(BuildContext context, int days, Color color) {
    String text;
    IconData? icon;
    
    if (days == 0) {
      text = 'Today';
      icon = Icons.notification_important_outlined;
    } else if (days == 1) {
      text = 'Tomorrow';
      icon = Icons.schedule_outlined;
    } else if (days <= 7) {
      text = '$days days';
      icon = Icons.schedule_outlined;
    } else {
      text = '$days days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: days <= 3
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && days <= 7) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
