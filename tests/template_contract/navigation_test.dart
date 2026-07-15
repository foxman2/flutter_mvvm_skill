import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/navigation/app_page.dart';
import 'package:{{project_name}}/navigation/app_page_transition.dart';
import 'package:{{project_name}}/pages/alert/alert_page.dart';
import 'package:{{project_name}}/pages/alert/alert_view_model.dart';
import 'package:{{project_name}}/pages/home/home_page.dart';

void main() {
  test('parameterized AppPage owns route metadata', () {
    final page = AlertAppPage(
      AlertViewModel(title: 'Hi')..addAction('OK', isDefault: true),
    );

    expect(page.routeName, '/alert');
    expect(page.defaultTransition, AppPageTransition.alert);
  });

  test('home route uses normal page transition by default', () {
    const page = HomeAppPage();

    expect(page.defaultTransition, AppPageTransition.push);
  });

  testWidgets('home AppPage explicitly selects the default view model', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));

    final widget = const HomeAppPage().generateWidgetBuilder()(context);

    expect(widget, isA<HomePage>());
    expect((widget as HomePage).viewModelProvider, isNull);
  });

  testWidgets('alert AppPage preserves its configured view model instance', (
    tester,
  ) async {
    final viewModel = AlertViewModel(title: 'Hi')
      ..addAction('OK', isDefault: true);
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));

    final widget =
        AlertAppPage(viewModel).generateWidgetBuilder()(context) as AlertPage;

    expect(widget.viewModelProvider!(), same(viewModel));
  });

  test('product preview route is isolated from business routes', () {
    const page = ProductPreviewAppPage();

    expect(page.routeName, '/product-preview');
    expect(page.defaultTransition, AppPageTransition.push);
  });
}
