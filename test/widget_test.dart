import 'package:flutter_test/flutter_test.dart';
import 'package:itlg_mobile/main.dart';

void main() {
  testWidgets('ITLG app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ITLGApp());

    // Verify app starts and shows the navigation shell and title.
    expect(find.text('ITLG Mobile'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Presensi'), findsOneWidget);
  });
}
