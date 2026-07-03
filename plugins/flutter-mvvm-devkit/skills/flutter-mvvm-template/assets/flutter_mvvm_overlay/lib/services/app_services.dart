import 'api/api_service.dart';

class AppServices {
  const AppServices._();

  static Future<void> setup() async {
    ApiService.shared.setup();
  }
}
