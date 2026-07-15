import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/app.dart';
import 'package:{{project_name}}/services/app_services.dart';

void main() {
  testWidgets('app initializes and renders', (tester) async {
    await AppServices.setup();
    await tester.pumpWidget(const App());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
