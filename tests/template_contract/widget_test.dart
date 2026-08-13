import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/app.dart';
import 'package:{{project_name}}/errors/app_exception.dart';
import 'package:{{project_name}}/l10n/app_localizations.dart';
import 'package:{{project_name}}/mvvm/base_view.dart';
import 'package:{{project_name}}/mvvm/base_view_model.dart';
import 'package:{{project_name}}/pages/alert/alert_page.dart';
import 'package:{{project_name}}/pages/alert/alert_view_model.dart';
import 'package:{{project_name}}/widgets/app_loading_dialog.dart';
import 'package:{{project_name}}/widgets/app_toast.dart';

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

  testWidgets('tracked error without a title only displays its raw body', (
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

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.title, isNull);
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

  testWidgets('tracked error without a message omits alert content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ErrorPage(
          viewModelProvider: () =>
              _ErrorViewModel(title: 'Request failed', message: null),
        ),
      ),
    );

    await tester.tap(find.text('Emit error'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.content, isNull);
    expect(find.text('Request failed'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
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
    AppToastController.shared.dismiss();
    await tester.pump(AppToastController.animationDuration);
  });

  testWidgets('loading blocks taps and closes when tracking ends', (
    tester,
  ) async {
    final viewModel = _PresentationViewModel();
    await tester.pumpWidget(
      MaterialApp(home: _PresentationPage(viewModelProvider: () => viewModel)),
    );

    viewModel.loadingTracker.increment();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(progress.color, Colors.white);
    expect(progress.backgroundColor, const Color(0x4DFFFFFF));
    expect(progress.strokeWidth, 3);
    expect(barrier.color, Colors.black.withValues(alpha: 0.18));
    await tester.tapAt(const Offset(10, 10));
    expect(viewModel.tapCount, 0);

    viewModel.loadingTracker.decrement();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Android back closes loading without popping its page', (
    tester,
  ) async {
    final viewModel = _PresentationViewModel();
    await tester.pumpWidget(
      MaterialApp(home: _PresentationPage(viewModelProvider: () => viewModel)),
    );

    viewModel.loadingTracker.increment();
    viewModel.loadingTracker.increment();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Presentation page'), findsOneWidget);

    viewModel.loadingTracker.decrement();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Presentation page'), findsOneWidget);

    viewModel.loadingTracker.decrement();
    await tester.pump();
    expect(find.text('Presentation page'), findsOneWidget);

    viewModel.loadingTracker.increment();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    viewModel.loadingTracker.decrement();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('page uses native back behavior by default', (tester) async {
    final viewModel = _PresentationViewModel();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      _PresentationPage(viewModelProvider: () => viewModel),
                ),
              ),
              child: const Text('Open page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    expect(find.text('Presentation page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Presentation page'), findsNothing);
    expect(find.text('Open page'), findsOneWidget);
  });

  testWidgets('opt-in back hook can block and then allow page pop', (
    tester,
  ) async {
    final viewModel = _BackHookViewModel();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      _BackHookPage(viewModelProvider: () => viewModel),
                ),
              ),
              child: const Text('Open hooked page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open hooked page'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Hooked page'), findsOneWidget);
    expect(viewModel.popAttempts, 1);

    viewModel.allowPop = true;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Hooked page'), findsNothing);
    expect(find.text('Open hooked page'), findsOneWidget);
    expect(viewModel.popAttempts, 2);
  });

  testWidgets('loading controller aggregates independent owners', (
    tester,
  ) async {
    final controller = AppLoadingDialogController();
    final firstOwner = Object();
    final secondOwner = Object();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                controller.update(
                  owner: firstOwner,
                  isLoading: true,
                  context: context,
                );
                controller.update(
                  owner: secondOwner,
                  isLoading: true,
                  context: context,
                );
              },
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.update(
      owner: firstOwner,
      isLoading: false,
      context: tester.element(find.byType(Scaffold)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.update(
      owner: secondOwner,
      isLoading: false,
      context: tester.element(find.byType(Scaffold)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('toast types render and newer messages replace older ones', (
    tester,
  ) async {
    final viewModel = _PresentationViewModel();
    await tester.pumpWidget(
      MaterialApp(home: _PresentationPage(viewModelProvider: () => viewModel)),
    );

    viewModel.showSuccessMessage(message: const .raw('Saved'));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);

    viewModel.showFailMessage(message: const .raw('Failed'));
    await tester.pump();
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    viewModel.showNormalMessage(message: const .raw('Updated'));
    await tester.pump();
    expect(find.text('Failed'), findsNothing);
    expect(find.text('Updated'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsNothing);
    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.pump(AppToastController.normalMessageDuration);
    await tester.pump(AppToastController.animationDuration);
    expect(find.text('Updated'), findsNothing);
  });

  testWidgets('success toast remains for its two second duration', (
    tester,
  ) async {
    final viewModel = _PresentationViewModel();
    await tester.pumpWidget(
      MaterialApp(home: _PresentationPage(viewModelProvider: () => viewModel)),
    );

    viewModel.showSuccessMessage(message: const .raw('Saved'));
    await tester.pump();
    await tester.pump(
      AppToastController.messageDuration - const Duration(milliseconds: 1),
    );
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(AppToastController.animationDuration);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('toast stays visible while navigating to another page', (
    tester,
  ) async {
    final viewModel = _PresentationViewModel();
    await tester.pumpWidget(
      MaterialApp(home: _PresentationPage(viewModelProvider: () => viewModel)),
    );
    final context = tester.element(find.text('Presentation page'));

    viewModel.showSuccessMessage(message: const .raw('Navigating'));
    await tester.pump();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Second page')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Second page'), findsOneWidget);
    expect(find.text('Navigating'), findsOneWidget);

    AppToastController.shared.dismiss();
    await tester.pump(AppToastController.animationDuration);
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
  _ErrorViewModel({this.title, this.message = 'Server failure'});

  final String? title;
  final String? message;

  @override
  void emitError() {
    errorTracker.onError(GeneralAppException(title: title, message: message));
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

class _PresentationViewModel extends AppBaseViewModel {
  var tapCount = 0;

  void onTap() {
    tapCount += 1;
  }
}

class _PresentationPage extends AppBaseStatefulPage<_PresentationViewModel> {
  const _PresentationPage({required super.viewModelProvider});

  @override
  State<_PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState
    extends
        AppBaseStatefulPageState<_PresentationViewModel, _PresentationPage> {
  @override
  Widget createWidget2(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: viewModel.onTap,
        child: const SizedBox.expand(
          child: Center(child: Text('Presentation page')),
        ),
      ),
    );
  }
}

class _BackHookViewModel extends AppBaseViewModel {
  var allowPop = false;
  var popAttempts = 0;

  @override
  bool get hookBackButton => true;

  @override
  Future<bool> onWillPop() async {
    popAttempts += 1;
    return allowPop;
  }
}

class _BackHookPage extends AppBaseStatefulPage<_BackHookViewModel> {
  const _BackHookPage({required super.viewModelProvider});

  @override
  State<_BackHookPage> createState() => _BackHookPageState();
}

class _BackHookPageState
    extends AppBaseStatefulPageState<_BackHookViewModel, _BackHookPage> {
  @override
  Widget createWidget2(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Hooked page')));
  }
}
