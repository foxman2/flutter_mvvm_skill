import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

typedef LocalizedTextResolver = String Function(AppLocalizations strings);
typedef LocalizedTextSpanResolver = TextSpan Function(AppLocalizations strings);

sealed class DisplayText {
  const DisplayText();

  const factory DisplayText.raw(String value) = _RawDisplayText;

  const factory DisplayText.localized(LocalizedTextResolver resolver) =
      _LocalizedDisplayText;

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

sealed class DisplayTextSpan {
  const DisplayTextSpan();

  const factory DisplayTextSpan.raw(TextSpan value) = _RawDisplayTextSpan;

  const factory DisplayTextSpan.localized(LocalizedTextSpanResolver resolver) =
      _LocalizedDisplayTextSpan;

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
