# Flutter MVVM DevKit

这个仓库是 `flutter-mvvm-devkit` Codex 插件的源码。全局插件只暴露 `flutter-mvvm-template`，负责创建新的 Flutter MVVM 模板项目；正式功能开发、PM UI 预览、运行中界面源码定位、正式 API 开发和 mock API 开发等 skills 会内置到生成项目的 `.codex/skills/` 中，避免在非 MVVM 项目里误触发。

## 目录结构

- `.codex-plugin/plugin.json`：Codex 插件 manifest。
- `.agents/plugins/marketplace.json`：团队内部 GitHub 插件市场入口。
- `plugins/flutter-mvvm-devkit/`：发布给团队安装的插件目录，由同步脚本生成。
- `skills/flutter-mvvm-template/`：全局插件唯一暴露的 skill，用于创建新 Flutter MVVM 项目。
- `project-skills/`：生成项目内置的局部 skills 源码，包括正式功能开发、PM UI 预览、运行中界面源码定位、正式 API 开发和 mock API 开发。
- `skills/flutter-mvvm-template/scripts/flutter_mvvm.py`：项目生成 CLI。
- `skills/flutter-mvvm-template/assets/flutter_mvvm_overlay/`：覆盖到新 Flutter 项目中的模板文件。
- `scripts/update-codex-skills.sh`：复制到生成项目中的局部 skills 更新脚本。
- `scripts/package_project_skills.py`：生成 GitHub Release asset `flutter-mvvm-skills.tar.gz`。
- `examples/`：用于手动验证的生成示例项目目录，内容不纳入插件包。
- `scripts/package_plugin.py`：在 `dist/` 下生成可分发的插件 zip。
- `scripts/sync_marketplace_plugin.py`：把当前插件源码同步到 `plugins/flutter-mvvm-devkit/`，用于 GitHub 团队安装。

## 开发

主要修改 `skills/flutter-mvvm-template/` 和 `project-skills/`。模板改动后，可以用本地生成项目检查生成后的 Flutter 代码。

常用检查：

```bash
python3 scripts/sync_marketplace_plugin.py
python3 /Users/xiaominliu/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py plugins/flutter-mvvm-devkit
for skill in skills/flutter-mvvm-* project-skills/flutter-mvvm-*; do
  python3 /Users/xiaominliu/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$skill"
done
```

## 打包

生成插件压缩包：

```bash
python3 scripts/package_plugin.py
```

压缩包包含 `.codex-plugin/`、全局 `skills/`、`project-skills/`、项目 updater 和 `README.md`，但 Codex 只会从 manifest 的 `skills` 路径发现 `flutter-mvvm-template`。

## Project Skills Release

局部 skills 通过 GitHub Release asset 分发，asset 名固定为：

```bash
flutter-mvvm-skills.tar.gz
```

维护者发布新版本：

```bash
python3 scripts/package_project_skills.py --version v0.1.3
```

然后在 GitHub 创建 tag/release `v0.1.3`，上传 `dist/flutter-mvvm-skills.tar.gz`。

生成项目内更新局部 skills：

```bash
./scripts/update-codex-skills.sh
./scripts/update-codex-skills.sh --version v0.1.3
./scripts/update-codex-skills.sh --archive /path/to/flutter-mvvm-skills.tar.gz
```

公开仓库默认走 GitHub release 下载；如果 release asset 在私有仓库中，先设置 `GITHUB_TOKEN`。updater 只替换 `.codex/flutter-mvvm-skills.json` 中记录的 managed skills，不删除项目自定义的其它 `.codex/skills/*`。

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

生成项目还包含 `.codex/skills/`、`.codex/flutter-mvvm-skills.json` 和 `scripts/update-codex-skills.sh`。产品经理新增 UI 原型时在项目线程里使用 `$flutter-mvvm-pm-ui`，开发审核和正式迁移时再使用 `$flutter-mvvm-feature-dev`。定位运行中界面源码时使用 `$flutter-mvvm-inspector`。
