import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:{{project_name}}/errors/app_exception.dart';
import 'package:{{project_name}}/l10n/app_localizations.dart';
import 'package:{{project_name}}/l10n/display_text.dart';
import 'package:{{project_name}}/mvvm/base_view.dart';
import 'package:{{project_name}}/mvvm/base_view_model.dart';
import 'package:{{project_name}}/mvvm/dispose_bag.dart';
import 'package:{{project_name}}/mvvm/error_tracker.dart';
import 'package:{{project_name}}/mvvm/loading_tracker.dart';
import 'package:{{project_name}}/navigation/app_page.dart';
import 'package:{{project_name}}/pages/action_sheet/action_sheet_view_model.dart';
import 'package:{{project_name}}/pages/alert/alert_view_model.dart';
import 'package:{{project_name}}/pages/input_alert/input_alert_view_model.dart';
import 'package:{{project_name}}/widgets/value_stream_builder.dart';

void main() {
  test('DisposeBag runs registered actions once', () {
    var count = 0;
    final bag = DisposeBag()..add(() => count++);

    bag.dispose();
    bag.dispose();

    expect(count, 1);
  });

  test('LoadingTracker emits loading state', () async {
    final tracker = LoadingTracker();
    final states = <bool>[];
    final sub = tracker.isLoading.listen(states.add);

    tracker.increment();
    tracker.increment();
    tracker.decrement();
    tracker.decrement();
    await Future<void>.delayed(Duration.zero);

    expect(states, [false, true, false]);
    await sub.cancel();
    tracker.dispose();
  });

  test('AppBaseViewModel leaves system back handling enabled by default', () {
    final viewModel = _ToastViewModel();

    expect(viewModel.hookBackButton, isFalse);
  });

  test('GeneralAppException keeps explicit presentation and stack', () {
    final stackTrace = StackTrace.fromString('general exception origin');
    final exception = GeneralAppException(
      title: 'Request failed',
      message: 'Try again later',
      stackTrace: stackTrace,
    );

    expect(exception.title, 'Request failed');
    expect(exception.message, 'Try again later');
    expect(exception.stackTrace, same(stackTrace));
  });

  test('ErrorTracker wraps unknown errors with the captured stack', () async {
    final tracker = ErrorTracker();
    addTearDown(tracker.dispose);
    final stackTrace = StackTrace.fromString('unknown exception origin');
    final emitted = tracker.stream.first;

    tracker.onError(const _TestException('Unknown failure'), stackTrace);

    final exception = await emitted;
    expect(exception, isA<GeneralAppException>());
    expect(exception.message, 'Unknown failure');
    expect(exception.stackTrace, same(stackTrace));
  });

  test('trackError reports and rethrows with the original stack', () async {
    final tracker = ErrorTracker();
    addTearDown(tracker.dispose);
    const error = _TestException('Tracked failure');
    final stackTrace = StackTrace.fromString('tracked exception origin');
    final emitted = tracker.stream.first;

    Object? caughtError;
    StackTrace? caughtStackTrace;
    try {
      await Future<int>.error(error, stackTrace).trackError(tracker);
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStackTrace = stackTrace;
    }

    final exception = await emitted;
    expect(caughtError, same(error));
    expect(caughtStackTrace.toString(), stackTrace.toString());
    expect(exception.message, 'Tracked failure');
    expect(exception.stackTrace.toString(), stackTrace.toString());
  });

  test('consumeError reports the error and returns null', () async {
    final tracker = ErrorTracker();
    addTearDown(tracker.dispose);
    const error = _TestException('Consumed failure');
    final stackTrace = StackTrace.fromString('consumed exception origin');
    final emitted = tracker.stream.first;

    final result = await Future<int>.error(
      error,
      stackTrace,
    ).consumeError(tracker);

    final exception = await emitted;
    expect(result, isNull);
    expect(exception.message, 'Consumed failure');
    expect(exception.stackTrace.toString(), stackTrace.toString());
  });

  testWidgets('ValueStreamBuilder renders seeded value and updates', (
    tester,
  ) async {
    final subject = BehaviorSubject<int>.seeded(1);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueStreamBuilder<int>(
          stream: subject,
          builder: (context, snapshot) {
            return Text('${snapshot.data}');
          },
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);

    subject.add(2);
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    await subject.close();
  });

  test('InputAlertViewModel exposes done state as ValueStream output', () {
    final viewModel = InputAlertViewModel();

    viewModel.initState();

    expect(viewModel.isDoneEnabled.value, isFalse);
    viewModel.onInputText('Project');
    expect(viewModel.isDoneEnabled.value, isTrue);
    viewModel.onInputText('   ');
    expect(viewModel.isDoneEnabled.value, isFalse);

    viewModel.dispose();
  });

  testWidgets('raw DisplayText resolves without localization delegates', (
    tester,
  ) async {
    const DisplayText text = .raw('Server message');
    const DisplayTextSpan span = .raw(TextSpan(text: 'Server rich message'));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => Column(
            children: [
              Text(text.resolve(context)),
              Text.rich(span.resolve(context)),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Server message'), findsOneWidget);
    expect(find.text('Server rich message'), findsOneWidget);
  });

  testWidgets('localized DisplayText resolves only when displayed', (
    tester,
  ) async {
    var resolveCount = 0;
    final DisplayText text = .localized((strings) {
      resolveCount += 1;
      return strings.homeTemplateTitle;
    });
    final DisplayTextSpan span = .localized(
      (strings) => TextSpan(text: strings.homeTemplateDescription),
    );

    expect(resolveCount, 0);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(text.resolve(context)),
              Text.rich(span.resolve(context)),
            ],
          ),
        ),
      ),
    );

    expect(resolveCount, greaterThan(0));
    expect(find.text('Flutter MVVM Template'), findsOneWidget);
    expect(
      find.text(
        'Use sealed AppPage classes as page cases with typed parameters.',
      ),
      findsOneWidget,
    );
  });

  test('toast methods forward DisplayText without resolving it', () {
    final viewModel = _ToastViewModel();
    const DisplayText success = .raw('Success');
    const DisplayText fail = .raw('Fail');
    const DisplayText normal = .raw('Normal');
    DisplayText? capturedSuccess;
    DisplayText? capturedFail;
    DisplayText? capturedNormal;
    viewModel.showSuccessMessageImpl = (message) => capturedSuccess = message;
    viewModel.showFailMessageImpl = (message) => capturedFail = message;
    viewModel.showNormalMessageImpl = (message) => capturedNormal = message;

    viewModel.showSuccessMessage(message: success);
    viewModel.showFailMessage(message: fail);
    viewModel.showNormalMessage(message: normal);

    expect(capturedSuccess, same(success));
    expect(capturedFail, same(fail));
    expect(capturedNormal, same(normal));
  });

  test('alert action returns the resolved title', () {
    final viewModel = AlertViewModel();
    final action = AlertViewAction(const .raw('Raw title'));
    Object? result;
    viewModel.popPageUseRoot = ([value]) => result = value;

    viewModel.onClickAction(action, 'Resolved title');

    expect(result, 'Resolved title');
  });

  test('action sheet action returns the resolved title', () {
    final viewModel = ActionSheetViewModel();
    final action = ActionSheetAction(const .raw('Raw title'));
    Object? result;
    viewModel.popPageUseRoot = ([value]) => result = value;

    viewModel.onClickAction(action, 'Resolved title');

    expect(result, 'Resolved title');
  });

  test('page provider lazily creates its injected view model', () {
    var createCount = 0;
    final page = _StrictPage(
      viewModelProvider: () {
        createCount += 1;
        return _StrictViewModel();
      },
    );

    expect(createCount, 0);
    expect(page.createViewModel(), isA<_StrictViewModelType>());
    expect(createCount, 1);
  });

  test('replaceRoot forwards to bound navigation callback', () async {
    final viewModel = _NavigationViewModel();
    AppPage? capturedPage;
    viewModel.replaceRootPage = (page) {
      capturedPage = page;
      return Future<Object?>.value('done');
    };

    final result = await viewModel.replaceRoot(const HomeAppPage());

    expect(result, 'done');
    expect(capturedPage, isA<HomeAppPage>());
  });
}

class _NavigationViewModel extends BaseViewModel {}

class _ToastViewModel extends AppBaseViewModel {}

abstract class _StrictViewModelInput {
  void rename(String title);
}

abstract class _StrictViewModelOutput {
  String get title;
}

abstract class _StrictViewModelType extends AppBaseViewModel
    implements _StrictViewModelInput, _StrictViewModelOutput {}

class _StrictViewModel extends _StrictViewModelType {
  String _title = 'Strict MVVM';

  @override
  void rename(String title) {
    _title = title;
    makeRebuild();
  }

  @override
  String get title => _title;
}

class _StrictPage extends AppBaseStatefulPage<_StrictViewModelType> {
  const _StrictPage({required super.viewModelProvider});

  @override
  State<_StrictPage> createState() => _StrictPageState();
}

class _StrictPageState
    extends AppBaseStatefulPageState<_StrictViewModelType, _StrictPage> {
  @override
  Widget createWidget2(BuildContext context) {
    return Text(viewModel.title);
  }
}

class _TestException implements Exception {
  const _TestException(this.message);

  final String message;

  @override
  String toString() => message;
}
