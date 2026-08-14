import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/app.dart';
import 'package:{{project_name}}/app_container.dart';

void main() {
  testWidgets('app initializes and renders', (tester) async {
    await AppContainer.setup();
    await tester.pumpWidget(const App());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home toast entry shows a toast', (tester) async {
    await AppContainer.setup();
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Show toast'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Hello from Toast'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
  });
}
