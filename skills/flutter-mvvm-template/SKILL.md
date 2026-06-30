---
name: flutter-mvvm-template
description: Create or migrate Flutter apps that use MVVM, reusable base view models/views, common alert/action sheet/bottom sheet UI, and sealed-class page navigation where page cases can carry strongly typed parameters. Use when Codex needs to create a new Flutter MVVM project, run a one-command project generator, extract project-independent MVVM base classes, replace enum page routing with sealed page classes, or plan/perform an existing Flutter project migration to this template.
---

# Flutter MVVM Template

Use this skill to create a Flutter MVVM project or migrate an existing Flutter app toward the bundled architecture.

## Quick Start

For a new project, prefer the CLI:

```bash
python3 <skill-dir>/scripts/flutter_mvvm.py create my_app --org com.example
```

If the CLI has been installed, use:

```bash
flutter-mvvm create my_app --org com.example
```

The command runs `flutter create`, then overlays the MVVM template from `assets/flutter_mvvm_overlay/`.

## Workflow

1. For new projects, run `scripts/flutter_mvvm.py create <project_name>` unless the user asks for a manual copy.
2. For existing projects, inspect `pubspec.yaml`, `lib/mvvm`, `lib/pages`, and the current navigator/page enum before editing.
3. Read `references/architecture.md` when extracting or migrating base classes.
4. Read `references/sealed-page.md` when changing route/page APIs.
5. Do not migrate the current app unless the user explicitly asks; default to creating a reusable template or a new generated project.

## Defaults

- Create projects by calling official `flutter create` first, then overlay only Dart/template files.
- Use `sealed class AppPage` as a page enum with associated values.
- Keep page parameters inside concrete `AppPage` subclasses, not as a global `dynamic param`.
- Keep reusable MVVM infrastructure independent of business assets, Firebase, push, generated localization, and app-specific network APIs.
- Include `rxdart` and `flutter_easyloading` in generated projects.

## Resources

- `scripts/flutter_mvvm.py`: project generator CLI.
- `scripts/install_cli.sh`: installs a `flutter-mvvm` command symlink.
- `assets/flutter_mvvm_overlay/`: files copied over a fresh Flutter app.
- `references/architecture.md`: extraction and migration rules.
- `references/sealed-page.md`: sealed page routing pattern and examples.
