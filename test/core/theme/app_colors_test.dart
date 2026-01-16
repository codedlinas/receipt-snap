import 'package:flutter_test/flutter_test.dart';
import 'package:receiptsnap/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('getUrgencyColor returns urgencyHigh for 1-3 days', () {
      expect(AppColors.getUrgencyColor(1), AppColors.urgencyHigh);
      expect(AppColors.getUrgencyColor(2), AppColors.urgencyHigh);
      expect(AppColors.getUrgencyColor(3), AppColors.urgencyHigh);
    });

    test('getUrgencyColor returns urgencyMedium for 4-7 days', () {
      expect(AppColors.getUrgencyColor(4), AppColors.urgencyMedium);
      expect(AppColors.getUrgencyColor(5), AppColors.urgencyMedium);
      expect(AppColors.getUrgencyColor(6), AppColors.urgencyMedium);
      expect(AppColors.getUrgencyColor(7), AppColors.urgencyMedium);
    });

    test('getUrgencyColor returns urgencyLow for 8+ days', () {
      expect(AppColors.getUrgencyColor(8), AppColors.urgencyLow);
      expect(AppColors.getUrgencyColor(30), AppColors.urgencyLow);
      expect(AppColors.getUrgencyColor(100), AppColors.urgencyLow);
    });
  });
}
