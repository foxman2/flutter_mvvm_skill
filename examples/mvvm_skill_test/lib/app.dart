import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'navigation/app_navigator.dart';
import 'navigation/app_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mvvm Skill Test',
      navigatorKey: AppNavigator.navigatorKey,
      navigatorObservers: [AppNavigatorObserver()],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      onGenerateRoute: (_) => null,
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute(
          builder: const HomeAppPage().generateWidgetBuilder(),
          settings: AppNavigator.routeSettingsFor(
            const HomeAppPage(),
            isFullScreen: true,
          ),
        ),
      ],
      builder: EasyLoading.init(),
    );
  }
}
