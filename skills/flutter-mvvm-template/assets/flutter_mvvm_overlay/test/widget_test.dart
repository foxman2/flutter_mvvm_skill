import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/app.dart';

void main() {
  testWidgets('home page opens alert through sealed AppPage', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Flutter MVVM Template'), findsOneWidget);
    expect(find.text('Product Preview'), findsOneWidget);

    await tester.tap(find.text('Show alert'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Hello from MVVM'), findsOneWidget);
  });

  testWidgets('home page opens product preview from floating button', (
    tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Product Preview'));
    await tester.pumpAndSettle();

    expect(find.text('Product Preview'), findsOneWidget);
    expect(find.text('Sample UI'), findsOneWidget);
  });
}
