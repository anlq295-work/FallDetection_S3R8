import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Fall Guard app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FallGuardApp());
    expect(find.text('Fall Guard S3R8'), findsOneWidget);
  });
}
