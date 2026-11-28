import 'package:flutter_test/flutter_test.dart';
import 'package:itlg_mobile/main.dart';

void main() {
  testWidgets('ITLG app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ITLGApp());
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Mulai'), findsOneWidget);
  });
}
