import 'package:rxdart/rxdart.dart';

import '../../l10n/display_text.dart';
import '../../mvvm/base_view_model.dart';

abstract class InputAlertViewModelInput {
  void onInputText(String value);

  Future<void> onClickOk();

  void onClickCancel();
}

abstract class InputAlertViewModelOutput {
  DisplayText? get title;

  DisplayText? get content;

  DisplayText? get hint;

  String get initialValue;

  DisplayText get cancelText;

  DisplayText get okText;

  DisplayText? get errorMessage;

  ValueStream<bool> get isDoneEnabled;
}

abstract class InputAlertViewModelType extends AppBaseViewModel
    implements InputAlertViewModelInput, InputAlertViewModelOutput {}

class InputAlertViewModel extends InputAlertViewModelType {
  factory InputAlertViewModel({
    DisplayText? title,
    DisplayText? content,
    DisplayText? hint,
    String initialValue = '',
    bool allowEmpty = false,
    DisplayText? cancelText,
    DisplayText? okText,
    DisplayText? errorMessage,
    Future<void> Function(String value)? onSubmitted,
  }) {
    return InputAlertViewModel._(
      title: title,
      content: content,
      hint: hint,
      initialValue: initialValue,
      allowEmpty: allowEmpty,
      cancelText: cancelText ?? .localized((strings) => strings.commonCancel),
      okText: okText ?? .localized((strings) => strings.commonOk),
      errorMessage: errorMessage,
      onSubmitted: onSubmitted,
    );
  }

  InputAlertViewModel._({
    required this._title,
    required this._content,
    required this._hint,
    required this._initialValue,
    required this._allowEmpty,
    required this._cancelText,
    required this._okText,
    required this._errorMessage,
    required this._onSubmitted,
  });

  final DisplayText? _title;
  final DisplayText? _content;
  final DisplayText? _hint;
  final String _initialValue;
  final bool _allowEmpty;
  final DisplayText _cancelText;
  final DisplayText _okText;
  final DisplayText? _errorMessage;
  final Future<void> Function(String value)? _onSubmitted;
  final _isDoneEnabled = BehaviorSubject<bool>.seeded(false);

  String _inputContent = '';

  @override
  void initState() {
    super.initState();
    _inputContent = _initialValue;
    _updateDoneEnabled();
  }

  @override
  void onInputText(String value) {
    _inputContent = value.trim();
    _updateDoneEnabled();
  }

  @override
  Future<void> onClickOk() async {
    await _submitInput();
  }

  @override
  void onClickCancel() {
    pop();
  }

  Future<void> _submitInput() async {
    await _onSubmitted?.call(_inputContent);
    pop(_inputContent);
  }

  void _updateDoneEnabled() {
    _isDoneEnabled.add(_allowEmpty || _inputContent.trim().isNotEmpty);
  }

  @override
  DisplayText? get title => _title;

  @override
  DisplayText? get content => _content;

  @override
  DisplayText? get hint => _hint;

  @override
  String get initialValue => _initialValue;

  @override
  DisplayText get cancelText => _cancelText;

  @override
  DisplayText get okText => _okText;

  @override
  DisplayText? get errorMessage => _errorMessage;

  @override
  ValueStream<bool> get isDoneEnabled => _isDoneEnabled.stream;

  @override
  void dispose() {
    _isDoneEnabled.close();
    super.dispose();
  }
}
