import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_skill_test/navigation/app_page.dart';
import 'package:mvvm_skill_test/navigation/app_page_transition.dart';
import 'package:mvvm_skill_test/navigation/app_route_parser.dart';
import 'package:mvvm_skill_test/pages/alert/alert_view_model.dart';

void main() {
  test('parameterized AppPage owns route metadata', () {
    final page = AlertAppPage(AlertViewModel(title: 'Hi')..addOkAction());

    expect(page.routeName, '/alert');
    expect(page.defaultTransition, AppPageTransition.alert);
  });

  test('route parser resolves home route', () {
    expect(AppRouteParser.parse('/'), isA<HomeAppPage>());
  });
}
