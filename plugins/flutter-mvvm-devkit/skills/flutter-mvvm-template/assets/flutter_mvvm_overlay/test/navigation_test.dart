import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/navigation/app_page.dart';
import 'package:{{project_name}}/navigation/app_page_transition.dart';
import 'package:{{project_name}}/navigation/app_route_parser.dart';
import 'package:{{project_name}}/pages/alert/alert_view_model.dart';

void main() {
  test('parameterized AppPage owns route metadata', () {
    final page = AlertAppPage(AlertViewModel(title: 'Hi')..addOkAction());

    expect(page.routeName, '/alert');
    expect(page.defaultTransition, AppPageTransition.alert);
  });

  test('route parser resolves home route', () {
    expect(AppRouteParser.parse('/'), isA<HomeAppPage>());
  });

  test('home route uses normal page transition by default', () {
    const page = HomeAppPage();

    expect(page.defaultTransition, AppPageTransition.push);
  });

  test('product preview route is isolated from business routes', () {
    const page = ProductPreviewAppPage();

    expect(page.routeName, '/product-preview');
    expect(page.defaultTransition, AppPageTransition.push);
  });
}
