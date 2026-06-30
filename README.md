# Flutter MVVM Template

This repository is the source for the `flutter-mvvm-template` Codex skill and plugin.

## Layout

- `.codex-plugin/plugin.json`: Codex plugin manifest.
- `skills/flutter-mvvm-template/`: the skill source loaded by the plugin.
- `skills/flutter-mvvm-template/scripts/flutter_mvvm.py`: project generator CLI.
- `skills/flutter-mvvm-template/assets/flutter_mvvm_overlay/`: files copied over a fresh Flutter project.
- `examples/mvvm_skill_test/`: generated sample project for manual testing.
- `scripts/package_plugin.py`: creates a distributable plugin zip under `dist/`.

## Develop

Edit the skill in `skills/flutter-mvvm-template/`. The local test project in `examples/mvvm_skill_test/` is useful for checking generated Flutter code after template changes.

Useful checks:

```bash
python3 /Users/xiaominliu/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .
flutter analyze examples/mvvm_skill_test
flutter test examples/mvvm_skill_test
```

## Package

Build a plugin archive:

```bash
python3 scripts/package_plugin.py
```

The archive contains `.codex-plugin/`, `skills/`, and `README.md`, and excludes git metadata, examples, generated Flutter caches, and previous archives.

## Use The Generator Directly

```bash
python3 skills/flutter-mvvm-template/scripts/flutter_mvvm.py create my_app --org com.example
```
