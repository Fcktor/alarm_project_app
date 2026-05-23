import 'package:flutter_test/flutter_test.dart';

import 'package:alarm_object_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Alarm App'), findsOneWidget);
    expect(find.text('Set Test Alarm'), findsOneWidget);
  });
}
