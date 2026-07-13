---
name: flutter-mvvm-template
description: >-
  创建新的 Flutter MVVM 模板项目并套用 bundled flutter-mvvm-template assets，同时把 Flutter MVVM 开发型 Codex skills 安装为生成项目内的局部 skills。用于用户要求生成、初始化或脚手架化一个全新的 Flutter MVVM app 时；生成前需要确认 app 显示名和原生包名。不用于修改已有应用、新增正式页面/UI/导航/ViewModel、PM UI 原型、API/model 开发、mock API 开发或 Inspector 定位；这些任务应在已生成的 MVVM 项目线程里使用项目局部 flutter-mvvm-feature-dev、flutter-mvvm-pm-ui、flutter-mvvm-api-dev、flutter-mvvm-mock-api-dev、flutter-mvvm-inspector。
---

# Flutter MVVM Template

使用这个 skill 创建新的 Flutter MVVM 模板项目。

## 快速开始

创建新项目时，优先运行 CLI：

```bash
python3 <skill-dir>/scripts/flutter_mvvm.py create --app-name "My App" --package-name com.example.myapp
```

如果已经安装了 CLI，也可以使用：

```bash
flutter-mvvm create --app-name "My App" --package-name com.example.myapp
```

该命令默认在当前目录下创建项目目录，目录名默认从包名最后一段推导。命令会先运行 `flutter create`，再把 `assets/flutter_mvvm_overlay/` 中的 MVVM 模板覆盖到新项目中，并把开发型 skills 安装到生成项目的 `.codex/skills/`。

## 工作流程

1. 创建新项目前，如果用户没有明确给出 app 显示名和原生包名，先询问这两个值。包名指 Android `applicationId` / iOS `PRODUCT_BUNDLE_IDENTIFIER`，例如 `com.example.myapp`。
2. 生成目录默认使用当前工作目录；除非用户明确指定其它输出路径，不传 `--output`。需要指定目录名时才补位置参数 `<project_name>`。
3. 除非用户明确要求手动复制，否则运行 `scripts/flutter_mvvm.py create --app-name "<App Name>" --package-name <package.name>`。
4. 只生成新项目或模板文件，不修改已有 Flutter 应用。
5. 用户要求改造已有 app、新增页面/UI/API/mock 时，说明这个 skill 只负责创建新模板项目；对应开发型 skills 只在已生成的 MVVM 项目 `.codex/skills/` 中局部可见。
6. 生成完成后，报告项目路径和 CLI 输出中的关键结果；如果 `flutter pub get`、`dart format` 或 `flutter analyze` 因本地工具链/网络失败，说明项目文件已经生成。

## 生成内容

- 创建项目时先调用官方 `flutter create`，然后只覆盖 Dart/template 文件。
- app 显示名会同步到 Flutter UI 标题、Android label、iOS display name 和 Web manifest/title。
- 原生包名会同步到 Android namespace/applicationId/MainActivity package，以及 iOS bundle identifier。
- 模板内已包含 MVVM 基类、sealed AppPage 导航、常用弹窗示例、Flutter l10n、Dio ApiService real/mock 示例和 Product Preview 入口；这里不要展开后续开发规范。
- 生成项目内已包含 `.codex/skills/`、`.codex/flutter-mvvm-skills.json` 和 `scripts/update-codex-skills.py`。需要更新局部 skills 时，在生成项目根目录运行 `./scripts/update-codex-skills.py` 获取 `main`，或运行 `./scripts/update-codex-skills.py --version vX.Y.Z` 检出指定 tag；运行环境需要 `python3` 和 `git`。

## CLI 参数

- `<project_name>`：可选；不传时从 package name 最后一段推导。
- `--output`：可选；只在用户指定输出目录时使用。
- `--platforms`：可选；默认 `ios,android,web`。
- `--skip-final-checks`：可选；跳过生成后的 format/analyze。

## 参考资料

- 需要理解生成项目边界或结构时，阅读 `references/architecture.md`。
- 需要说明 sealed page 路由模式时，阅读 `references/sealed-page.md`。

## 资源

- `scripts/flutter_mvvm.py`：项目生成 CLI。
- `scripts/install_cli.sh`：安装 `flutter-mvvm` 命令软链接。
- `assets/flutter_mvvm_overlay/`：复制到新 Flutter 应用中的模板文件。
- `<plugin-root>/project-skills/`：复制到生成项目 `.codex/skills/` 的局部开发 skills。
- `assets/flutter_mvvm_overlay/scripts/update-codex-skills.py`：复制到生成项目 `scripts/` 的 Git sparse-checkout 局部 skills updater。
- `references/architecture.md`：模板边界和生成项目结构。
- `references/sealed-page.md`：sealed page 路由模式和示例。
