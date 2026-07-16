import 'package:flutter/material.dart';

import 'app.dart';
import 'app_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppContainer.setup();
  runApp(const App());
}
