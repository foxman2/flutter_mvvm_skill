import 'package:rxdart/rxdart.dart';

import '../../mvvm/base_view_model.dart';

abstract class InputAlertViewModelInput {
  void onInputText(String value);

  Future<void> onClickOk();

  void onClickCancel();
}

abstract class InputAlertViewModelOutput {
  String? get title;

  String? get content;

  String? get hint;

  String get initialValue;

  String get cancelText;

  String get okText;

  String? get errorMessage;

  ValueStream<bool> get isDoneEnabled;
}

abstract class InputAlertViewModelType extends AppBaseViewModel
    implements InputAlertViewModelInput, InputAlertViewModelOutput {}

class InputAlertViewModel extends InputAlertViewModelType {
  factory InputAlertViewModel({
    String? title,
    String? content,
    String? hint,
    String initialValue = '',
    bool allowEmpty = false,
    String cancelText = 'Cancel',
    String okText = 'OK',
    String? errorMessage,
    Future<void> Function(String value)? onSubmitted,
  }) {
    return InputAlertViewModel._(
      title: title,
      content: content,
      hint: hint,
      initialValue: initialValue,
      allowEmpty: allowEmpty,
      cancelText: cancelText,
      okText: okText,
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

  final String? _title;
  final String? _content;
  final String? _hint;
  final String _initialValue;
  final bool _allowEmpty;
  final String _cancelText;
  final String _okText;
  final String? _errorMessage;
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
  String? get title => _title;

  @override
  String? get content => _content;

  @override
  String? get hint => _hint;

  @override
  String get initialValue => _initialValue;

  @override
  String get cancelText => _cancelText;

  @override
  String get okText => _okText;

  @override
  String? get errorMessage => _errorMessage;

  @override
  ValueStream<bool> get isDoneEnabled => _isDoneEnabled.stream;

  @override
  void dispose() {
    _isDoneEnabled.close();
    super.dispose();
  }
}
