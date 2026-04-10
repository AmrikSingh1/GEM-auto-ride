import 'package:flutter_test/flutter_test.dart';
import 'package:gem_auto_ride/main.dart';

void main() {
  testWidgets('GEM app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GemApp());
    expect(find.text('GEM'), findsOneWidget);
  });
}
