import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.setup();
  runApp(const App());
}
