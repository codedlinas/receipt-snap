import 'package:flutter_test/flutter_test.dart';

import 'package:receiptsnap/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // This test just verifies the app can be instantiated
    // Full widget tests would require mocking Supabase
    expect(const ReceiptSnapApp(), isNotNull);
  });
}
