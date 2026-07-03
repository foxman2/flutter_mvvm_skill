import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ValueStreamBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  const ValueStreamBuilder({
    super.key,
    required ValueStream<T> stream,
    required this.builder,
  }) : _valueStream = stream,
       super(stream: stream);

  final ValueStream<T> _valueStream;
  final AsyncWidgetBuilder<T> builder;

  @override
  AsyncSnapshot<T> initial() {
    if (!_valueStream.hasValue) {
      return AsyncSnapshot<T>.nothing();
    }
    return AsyncSnapshot<T>.withData(ConnectionState.none, _valueStream.value);
  }

  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) {
    return current.inState(ConnectionState.waiting);
  }

  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  @override
  AsyncSnapshot<T> afterError(
    AsyncSnapshot<T> current,
    Object error,
    StackTrace stackTrace,
  ) {
    return AsyncSnapshot<T>.withError(
      ConnectionState.active,
      error,
      stackTrace,
    );
  }

  @override
  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) {
    return current.inState(ConnectionState.done);
  }

  @override
  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) {
    return initial();
  }

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) {
    return builder(context, currentSummary);
  }
}
