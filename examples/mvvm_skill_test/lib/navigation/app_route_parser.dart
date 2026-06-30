import 'app_page.dart';

abstract final class AppRouteParser {
  static AppPage? parse(String routeString) {
    final uri = Uri.parse(routeString);
    switch (uri.path) {
      case '/':
      case '/home':
        return const HomeAppPage();
      default:
        return null;
    }
  }
}
