import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/mvvm/dispose_bag.dart';
import 'package:{{project_name}}/mvvm/loading_tracker.dart';

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
}
