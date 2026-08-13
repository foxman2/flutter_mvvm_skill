import 'app_page.dart';

/// 将外部路由字符串解析为应用支持的强类型页面。
abstract final class AppRouteParser {
  /// 无法识别的路径返回 null，由调用方决定兜底行为。
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
