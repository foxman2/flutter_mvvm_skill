import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'navigation/app_navigator.dart';
import 'navigation/app_page.dart';

/// 应用根组件，集中配置主题、本地化和全局导航器。
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
    );
  }
}
