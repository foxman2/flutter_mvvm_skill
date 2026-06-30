# Flutter MVVM Template Architecture

## Extraction Rules

- Keep template code independent from product-specific services: Firebase, push handling, generated localization, assets, networking clients, and domain managers stay in the app.
- Move cross-project lifecycle code into `mvvm/`: view model binding, dispose handling, loading/error tracking, and base page widgets.
- Put navigation primitives in `navigation/`: page model, navigator, route parser, transition enum, and observer.
- Keep common UI small and replaceable: alert, input alert, action sheet, and bottom sheet are examples, not a full design system.
- Prefer callbacks or view model methods over direct imports from business modules.

## Generated Project Shape

```text
lib/
├── app.dart
├── main.dart
├── mvvm/
├── navigation/
├── pages/
└── widgets/
```

`main.dart` only starts the app. `app.dart` owns `MaterialApp`, navigator observers, theming, and the EasyLoading builder.

## Migration Checklist

1. Identify the existing page enum and all `show(page, param)` call sites.
2. Create sealed page classes matching the existing route names and transitions.
3. Move page-specific parameters into concrete page constructors.
4. Update `BaseViewModel` navigation callbacks to accept `AppPage`.
5. Update the navigator to call `page.generateWidgetBuilder()`.
6. Replace route restoration that depended on `enum.values` with an explicit parser.
7. Run analyzer and route smoke tests after each slice.

## Keep Out Of The Template

- Business pages and domain view models.
- Backend API clients, DTOs, auth/session managers.
- Firebase, push notification, app links, and analytics setup.
- Product assets, generated localization, app-specific themes.
- Platform folders unless the user explicitly wants a full project copy.
