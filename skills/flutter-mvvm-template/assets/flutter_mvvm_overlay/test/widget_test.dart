import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/app.dart';

void main() {
  testWidgets('home page opens alert through sealed AppPage', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Flutter MVVM Template'), findsOneWidget);

    await tester.tap(find.text('Show alert'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Hello from MVVM'), findsOneWidget);
  });
}
