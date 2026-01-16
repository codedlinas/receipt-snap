import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum EmptyStateType {
  noSubscriptions,
  noUpcoming,
  noNotifications,
  error,
  noResults,
}

class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? customIcon;

  const EmptyState({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration container
          _buildIllustration(config),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            title ?? config.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Message
          Text(
            message ?? config.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(_getActionIcon(), size: 18),
              label: Text(actionLabel!),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIllustration(_EmptyStateConfig config) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: config.iconColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decoration
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: config.iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: config.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Main icon
          Icon(
            customIcon ?? config.icon,
            size: 64,
            color: config.iconColor,
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    switch (type) {
      case EmptyStateType.noSubscriptions:
        return Icons.document_scanner_outlined;
      case EmptyStateType.noUpcoming:
        return Icons.add_rounded;
      case EmptyStateType.noNotifications:
        return Icons.notifications_outlined;
      case EmptyStateType.error:
        return Icons.refresh_rounded;
      case EmptyStateType.noResults:
        return Icons.search_rounded;
    }
  }

  _EmptyStateConfig _getConfig() {
    switch (type) {
      case EmptyStateType.noSubscriptions:
        return _EmptyStateConfig(
          icon: Icons.receipt_long_outlined,
          iconColor: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(0.08),
          title: 'No subscriptions yet',
          message: 'Scan your first receipt or screenshot to start tracking your subscriptions automatically',
        );
      case EmptyStateType.noUpcoming:
        return _EmptyStateConfig(
          icon: Icons.celebration_outlined,
          iconColor: AppColors.accent,
          backgroundColor: AppColors.accent.withOpacity(0.08),
          title: 'All caught up!',
          message: 'No upcoming renewals in the next 7 days. Enjoy your peace of mind!',
        );
      case EmptyStateType.noNotifications:
        return _EmptyStateConfig(
          icon: Icons.notifications_none_outlined,
          iconColor: AppColors.warning,
          backgroundColor: AppColors.warning.withOpacity(0.08),
          title: 'No notifications',
          message: 'We\'ll notify you before your subscriptions renew',
        );
      case EmptyStateType.error:
        return _EmptyStateConfig(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          backgroundColor: AppColors.error.withOpacity(0.08),
          title: 'Something went wrong',
          message: 'We couldn\'t load your data. Please check your connection and try again.',
        );
      case EmptyStateType.noResults:
        return _EmptyStateConfig(
          icon: Icons.search_off_outlined,
          iconColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          title: 'No results found',
          message: 'Try adjusting your search or filters',
        );
    }
  }
}

class _EmptyStateConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String message;

  _EmptyStateConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.message,
  });
}
