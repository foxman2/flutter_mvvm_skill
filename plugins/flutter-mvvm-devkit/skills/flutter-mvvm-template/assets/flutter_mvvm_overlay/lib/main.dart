import 'package:flutter/material.dart';

import 'app.dart';
import 'app_container.dart';

/// 初始化 Flutter 与应用依赖，然后挂载根组件。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppContainer.setup();
  runApp(const App());
}
