import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/app.dart';
import 'package:{{project_name}}/errors/app_exception.dart';
import 'package:{{project_name}}/l10n/app_localizations.dart';
import 'package:{{project_name}}/mvvm/base_view.dart';
import 'package:{{project_name}}/mvvm/base_view_model.dart';
import 'package:{{project_name}}/pages/alert/alert_page.dart';
import 'package:{{project_name}}/pages/alert/alert_view_model.dart';

void main() {
  test('template currently supports English localization only', () {
    expect(AppLocalizations.supportedLocales, [const Locale('en')]);
  });

  testWidgets('home page opens alert through sealed AppPage', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Flutter MVVM Template'), findsOneWidget);
    expect(find.text('Product Preview'), findsOneWidget);

    await tester.tap(find.text('Show alert'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Hello from MVVM'), findsOneWidget);
  });

  testWidgets('raw alert renders without app localization delegates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlertPage(
          viewModelProvider: () => AlertViewModel(
            title: const .raw('Raw title'),
            content: const .raw('Server body'),
          )..addAction(const .raw('Close')),
        ),
      ),
    );

    expect(find.text('Raw title'), findsOneWidget);
    expect(find.text('Server body'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('tracked error localizes fallback title and keeps raw body', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ErrorPage(viewModelProvider: () => _ErrorViewModel()),
      ),
    );

    await tester.tap(find.text('Emit error'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Server failure'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('tracked error displays its custom title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ErrorPage(
          viewModelProvider: () => _ErrorViewModel(title: 'Request failed'),
        ),
      ),
    );

    await tester.tap(find.text('Emit error'));
    await tester.pumpAndSettle();

    expect(find.text('Request failed'), findsOneWidget);
    expect(find.text('Server failure'), findsOneWidget);
  });

  testWidgets('input alert resolves labels and parameterized toast lazily', (
    tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Show input alert'));
    await tester.pumpAndSettle();

    expect(find.text('Project name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'demo_app');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Submitted: demo_app'), findsOneWidget);
    await EasyLoading.dismiss(animation: false);
    await tester.pump();
  });

  testWidgets('action sheet resolves localized labels', (tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Show action sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Choose an action'), findsOneWidget);
    expect(find.text('Normal action'), findsOneWidget);
    expect(find.text('Destructive action'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('home page opens product preview from floating button', (
    tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Product Preview'));
    await tester.pumpAndSettle();

    expect(find.text('Product Preview'), findsOneWidget);
    expect(find.text('Sample UI'), findsOneWidget);

    await tester.tap(find.text('Sample UI'));
    await tester.pumpAndSettle();

    expect(find.text('Product Preview Area'), findsOneWidget);
    expect(find.text('Mock content'), findsOneWidget);
  });
}

abstract class _ErrorViewModelInput {
  void emitError();
}

abstract class _ErrorViewModelType extends AppBaseViewModel
    implements _ErrorViewModelInput {}

class _ErrorViewModel extends _ErrorViewModelType {
  _ErrorViewModel({this.title});

  final String? title;

  @override
  void emitError() {
    errorTracker.onError(
      GeneralAppException(title: title, message: 'Server failure'),
    );
  }
}

class _ErrorPage extends AppBaseStatefulPage<_ErrorViewModelType> {
  const _ErrorPage({required super.viewModelProvider});

  @override
  State<_ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState
    extends AppBaseStatefulPageState<_ErrorViewModelType, _ErrorPage> {
  @override
  Widget createWidget2(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: viewModel.emitError,
          child: const Text('Emit error'),
        ),
      ),
    );
  }
}
