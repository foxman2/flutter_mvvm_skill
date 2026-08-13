import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// 使用当前本地化资源解析普通文本。
typedef LocalizedTextResolver = String Function(AppLocalizations strings);

/// 使用当前本地化资源解析富文本。
typedef LocalizedTextSpanResolver = TextSpan Function(AppLocalizations strings);

/// 延迟到拥有 [BuildContext] 时再解析的普通展示文本。
sealed class DisplayText {
  const DisplayText();

  const factory DisplayText.raw(String value) = _RawDisplayText;

  const factory DisplayText.localized(LocalizedTextResolver resolver) =
      _LocalizedDisplayText;

  /// 根据当前上下文返回最终展示字符串。
  String resolve(BuildContext context);
}

final class _RawDisplayText extends DisplayText {
  const _RawDisplayText(this.value);

  final String value;

  @override
  String resolve(BuildContext context) => value;
}

final class _LocalizedDisplayText extends DisplayText {
  const _LocalizedDisplayText(this.resolver);

  final LocalizedTextResolver resolver;

  @override
  String resolve(BuildContext context) {
    return resolver(AppLocalizations.of(context)!);
  }
}

/// 延迟到拥有 [BuildContext] 时再解析的富文本。
sealed class DisplayTextSpan {
  const DisplayTextSpan();

  const factory DisplayTextSpan.raw(TextSpan value) = _RawDisplayTextSpan;

  const factory DisplayTextSpan.localized(LocalizedTextSpanResolver resolver) =
      _LocalizedDisplayTextSpan;

  /// 根据当前上下文返回最终富文本。
  TextSpan resolve(BuildContext context);
}

final class _RawDisplayTextSpan extends DisplayTextSpan {
  const _RawDisplayTextSpan(this.value);

  final TextSpan value;

  @override
  TextSpan resolve(BuildContext context) => value;
}

final class _LocalizedDisplayTextSpan extends DisplayTextSpan {
  const _LocalizedDisplayTextSpan(this.resolver);

  final LocalizedTextSpanResolver resolver;

  @override
  TextSpan resolve(BuildContext context) {
    return resolver(AppLocalizations.of(context)!);
  }
}
