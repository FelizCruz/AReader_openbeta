import 'package:flutter_test/flutter_test.dart';

import 'package:arcreader_custom/main.dart';

void main() {
  testWidgets('ArcReaderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ArcReaderApp());
    expect(find.text('ArcReader Developer Dashboard'), findsOneWidget);
  });
}
