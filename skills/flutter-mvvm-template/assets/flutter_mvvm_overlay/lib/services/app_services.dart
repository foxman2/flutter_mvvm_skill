import 'api/api_service.dart';
import 'api/api_service_config.dart';

class AppServices {
  const AppServices._();

  static Future<void> setup() async {
    ApiService.shared.setup(
      const ApiServiceConfig(
        baseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: ''),
        enableLog: bool.fromEnvironment('API_ENABLE_LOG', defaultValue: false),
      ),
    );
  }
}
