import 'package:flutter/foundation.dart';

import 'services/api/api_service.dart';

class AppContainer {
  AppContainer({required this.apiService});

  final ApiService apiService;

  static AppContainer? _shared;
  static AppContainer? _replacedContainer;

  static AppContainer get shared {
    final container = _shared;
    if (container == null) {
      throw StateError('AppContainer.setup() must be called before use.');
    }
    return container;
  }

  static Future<void> setup() async {
    if (_replacedContainer != null) {
      throw StateError('AppContainer.restore() must be called before setup().');
    }
    _shared = AppContainer(apiService: ApiService());
  }

  @visibleForTesting
  static void replaceForTesting(AppContainer container) {
    if (_replacedContainer != null) {
      throw StateError('AppContainer is already replaced for testing.');
    }
    _replacedContainer = shared;
    _shared = container;
  }

  @visibleForTesting
  static void restore() {
    final container = _replacedContainer;
    if (container == null) {
      throw StateError('AppContainer has not been replaced for testing.');
    }
    _shared = container;
    _replacedContainer = null;
  }
}
