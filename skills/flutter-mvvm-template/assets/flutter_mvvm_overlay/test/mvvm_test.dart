import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:{{project_name}}/l10n/app_localizations.dart';
import 'package:{{project_name}}/mvvm/base_view.dart';
import 'package:{{project_name}}/mvvm/base_view_model.dart';
import 'package:{{project_name}}/mvvm/dispose_bag.dart';
import 'package:{{project_name}}/mvvm/loading_tracker.dart';
import 'package:{{project_name}}/navigation/app_page.dart';
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
    tracker.decrement();
    await Future<void>.delayed(Duration.zero);

    expect(states, containsAllInOrder([false, true, false]));
    await sub.cancel();
    tracker.dispose();
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

  test(
    'page can depend on ViewModelType instead of concrete implementation',
    () {
      const page = _StrictPage();
      final viewModel = page.createViewModel();

      expect(viewModel, isA<_StrictViewModelType>());
      expect(viewModel.title, 'Strict MVVM');
    },
  );

  test('localStrings throws before a view model is bound to a page', () {
    final viewModel = _LocalizedViewModel();

    expect(() => viewModel.localStrings, throwsStateError);
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

  testWidgets('localStrings reads current strings from the bound page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _LocalizedPage(),
      ),
    );

    expect(find.text('Flutter MVVM Template'), findsOneWidget);
  });
}

class _NavigationViewModel extends BaseViewModel {}

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

class _StrictPage extends AppBaseStatelessPage<_StrictViewModelType> {
  const _StrictPage() : super(viewModelProvider: _defaultProvider);

  static _StrictViewModelType? _defaultProvider() => null;

  @override
  _StrictViewModelType? defaultViewModel() => _StrictViewModel();

  @override
  Widget createWidget(BuildContext context, _StrictViewModelType viewModel) {
    return Text(viewModel.title);
  }
}

abstract class _LocalizedViewModelOutput {
  String get title;
}

abstract class _LocalizedViewModelType extends AppBaseViewModel
    implements _LocalizedViewModelOutput {}

class _LocalizedViewModel extends _LocalizedViewModelType {
  @override
  String get title => localStrings.homeTemplateTitle;
}

class _LocalizedPage extends AppBaseStatelessPage<_LocalizedViewModelType> {
  const _LocalizedPage() : super(viewModelProvider: _defaultProvider);

  static _LocalizedViewModelType? _defaultProvider() => null;

  @override
  _LocalizedViewModelType? defaultViewModel() => _LocalizedViewModel();

  @override
  Widget createWidget(BuildContext context, _LocalizedViewModelType viewModel) {
    return Text(viewModel.title);
  }
}
