# Flutter MVVM DevKit

`flutter-mvvm-devkit` 是团队内部 Codex 插件，用于快速创建 Flutter MVVM 项目。
插件全局只暴露 `flutter-mvvm-template`，项目内能力在生成后由 `.codex/skills/` 管理。

## 快速安装

```bash
/Applications/Codex.app/Contents/Resources/codex plugin marketplace add https://github.com/foxman2/flutter_mvvm_skill.git --ref main
/Applications/Codex.app/Contents/Resources/codex plugin add flutter-mvvm-devkit@team-internal
```

如果 `codex` 已在 PATH，可用短命令：

```bash
codex plugin marketplace add https://github.com/foxman2/flutter_mvvm_skill.git --ref main
codex plugin add flutter-mvvm-devkit@team-internal
```

旧名用户先切：

```bash
codex plugin remove flutter-mvvm-template
codex plugin add flutter-mvvm-devkit@team-internal
```

安装后新开一个 Codex 线程。

## 3 分钟上手

```text
Use $flutter-mvvm-template to create a Flutter MVVM app.
```

或直接运行：

```bash
python3 skills/flutter-mvvm-template/scripts/flutter_mvvm.py create --app-name "My App" --package-name com.example.myapp
```

生成项目里会有：

- `.codex/skills/`（项目内技能）
- `.codex/flutter-mvvm-skills.json`（受管清单）
- `scripts/update-codex-skills.py`（升级脚本）

常用项目内技能：`$flutter-mvvm-pm-ui`、`$flutter-mvvm-feature-dev`、`$flutter-mvvm-api-dev`、`$flutter-mvvm-mock-api-dev`、`$flutter-mvvm-inspector`。

## 升级

### 插件本体

```bash
/Applications/Codex.app/Contents/Resources/codex plugin marketplace upgrade
/Applications/Codex.app/Contents/Resources/codex plugin add flutter-mvvm-devkit@team-internal
```

### 已生成项目技能

```bash
./scripts/update-codex-skills.py
./scripts/update-codex-skills.py --version v0.1.3
./scripts/update-codex-skills.py --archive /path/to/flutter-mvvm-skills.tar.gz
```

更新脚本需要本机有 `python3`。私有仓库用户请先设置 `GITHUB_TOKEN`。

## 维护者

```bash
python3 scripts/sync_marketplace_plugin.py
python3 scripts/package_project_skills.py --version v0.1.3
git tag v0.1.3 && git push origin v0.1.3
```
