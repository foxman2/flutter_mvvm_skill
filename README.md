# Flutter MVVM DevKit

这个仓库是 `flutter-mvvm-devkit` Codex 插件的源码。插件内包含多个 Flutter MVVM 开发 skill，覆盖新项目模板生成、正式功能开发、PM UI 预览、运行中界面源码定位、正式 API 开发和 mock API 开发。

## 目录结构

- `.codex-plugin/plugin.json`：Codex 插件 manifest。
- `.agents/plugins/marketplace.json`：团队内部 GitHub 插件市场入口。
- `plugins/flutter-mvvm-devkit/`：发布给团队安装的插件目录，由同步脚本生成。
- `skills/flutter-mvvm-template/`：创建新 Flutter MVVM 项目的 skill 源码。
- `skills/flutter-mvvm-pm-ui/`：产品经理专用 UI 预览、受限展示层修改和待审核 mock 数据工作流。
- `skills/flutter-mvvm-inspector/`：启动或接入 Flutter debug app，并通过 VM Service Inspector 选择 widget 和定位源码的工作流。
- `skills/flutter-mvvm-feature-dev/`：在已有 Flutter MVVM 项目中创建页面、修改 UI、接导航的 skill 源码。
- `skills/flutter-mvvm-api-dev/`：在已有 Flutter MVVM 项目中新增 API service、model 解析和接口调用的 skill 源码。
- `skills/flutter-mvvm-mock-api-dev/`：在已有 Flutter MVVM 项目中新增临时 mock API、mock service 和 mock-only model 的 skill 源码。
- `skills/flutter-mvvm-template/scripts/flutter_mvvm.py`：项目生成 CLI。
- `skills/flutter-mvvm-template/assets/flutter_mvvm_overlay/`：覆盖到新 Flutter 项目中的模板文件。
- `examples/mvvm_skill_test/`：用于手动验证的生成示例项目。
- `scripts/package_plugin.py`：在 `dist/` 下生成可分发的插件 zip。
- `scripts/sync_marketplace_plugin.py`：把当前插件源码同步到 `plugins/flutter-mvvm-devkit/`，用于 GitHub 团队安装。

## 开发

主要修改 `skills/flutter-mvvm-template/`、`skills/flutter-mvvm-pm-ui/`、`skills/flutter-mvvm-inspector/`、`skills/flutter-mvvm-feature-dev/`、`skills/flutter-mvvm-api-dev/` 和 `skills/flutter-mvvm-mock-api-dev/`。模板改动后，可以用 `examples/mvvm_skill_test/` 这个本地测试项目检查生成后的 Flutter 代码。

常用检查：

```bash
python3 scripts/sync_marketplace_plugin.py
python3 /Users/xiaominliu/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py plugins/flutter-mvvm-devkit
for skill in skills/flutter-mvvm-*; do
  python3 /Users/xiaominliu/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$skill"
done
flutter analyze examples/mvvm_skill_test
flutter test examples/mvvm_skill_test
```

## 打包

生成插件压缩包：

```bash
python3 scripts/package_plugin.py
```

压缩包包含 `.codex-plugin/`、`skills/` 和 `README.md`，并排除 git 元数据、示例项目、Flutter 生成缓存和历史打包产物。

## 团队安装

团队成员通过当前 GitHub 仓库安装内部插件：

```bash
/Applications/Codex.app/Contents/Resources/codex plugin marketplace add https://github.com/foxman2/flutter_mvvm_skill.git --ref main
/Applications/Codex.app/Contents/Resources/codex plugin add flutter-mvvm-devkit@team-internal
```

如果之前安装过旧插件名，先移除旧名字：

```bash
codex plugin remove flutter-mvvm-template
codex plugin add flutter-mvvm-devkit@team-internal
```

插件更新后，团队成员运行：

```bash
/Applications/Codex.app/Contents/Resources/codex plugin marketplace upgrade
codex plugin add flutter-mvvm-devkit@team-internal
```

安装或更新后请新开一个 Codex 线程，让新的 skill 配置生效。

发布新版本前，维护者先同步团队安装目录：

```bash
python3 scripts/sync_marketplace_plugin.py
```

## 直接使用生成器

```bash
python3 skills/flutter-mvvm-template/scripts/flutter_mvvm.py create --app-name "My App" --package-name com.example.myapp
```

生成项目包含首页 `Product Preview` 悬浮入口和 `lib/product_preview/` 隔离目录。产品经理新增 UI 原型时使用 `$flutter-mvvm-pm-ui`，开发审核和正式迁移时再使用 `$flutter-mvvm-feature-dev`。

定位运行中界面源码时使用 `$flutter-mvvm-inspector`。它会启动或接入 Flutter debug app，读取真实 VM Service URI，然后开启 widget 选择模式并读取选中 widget 对应源码位置。
