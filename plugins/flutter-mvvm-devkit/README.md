# Flutter MVVM DevKit

`flutter-mvvm-devkit` 是团队内部 Codex 插件，用于快速创建 Flutter MVVM 项目。
插件全局只暴露 `flutter-mvvm-template`，项目内能力在生成后由 `.codex/skills/` 管理。

## 快速安装

```bash
/Applications/ChatGPT.app/Contents/Resources/codex plugin marketplace add https://github.com/foxman2/flutter_mvvm_skill.git --ref main
/Applications/ChatGPT.app/Contents/Resources/codex plugin add flutter-mvvm-devkit@team-internal
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

- `AGENTS.md`（开发期重构约定，上线前删除该条约定）
- `.codex/skills/`（项目内技能）
- `.codex/flutter-mvvm-skills.json`（受管清单）
- `scripts/update-codex-skills.py`（升级脚本）

常用项目内技能：`$code-quality`、`$feature-code-map`、`$flutter-mvvm-pm-ui`、`$flutter-mvvm-feature-dev`、`$flutter-mvvm-api-dev`、`$flutter-mvvm-mock-api-dev`、`$flutter-mvvm-inspector`。

## 升级

### 插件本体

```bash
/Applications/ChatGPT.app/Contents/Resources/codex plugin marketplace upgrade
/Applications/ChatGPT.app/Contents/Resources/codex plugin add flutter-mvvm-devkit@team-internal
```

### 已生成项目技能

```bash
./scripts/update-codex-skills.py
./scripts/update-codex-skills.py --version v0.1.7
```

无参数时从仓库 `main` 更新；`--version` 只接受 `vX.Y.Z` 或对应的预发布 tag。更新器会通过浅层 sparse checkout 仅检出项目 skills、插件版本清单和最新版 updater，验证完整后再修改项目。

更新脚本需要本机同时有 `python3` 和 `git`。仓库访问由本机 Git 凭据配置负责。

旧项目首次升级到公共参考目录结构时，先用本仓库的
`skills/flutter-mvvm-template/assets/flutter_mvvm_overlay/scripts/update-codex-skills.py`
替换项目的 `scripts/update-codex-skills.py`，再执行更新。旧脚本不识别 `shared-references/`，会在写入项目前停止。

## 维护者

开发 skills 共用的文件职责与依赖规范维护在 `project-skills/shared-references/architecture-responsibilities.md`。
四个开发 skill 通过相对路径引用这一份文档；同步脚本更新插件镜像，生成器和更新器将公共目录安装到项目的 `.codex/skills/shared-references/`。
公共目录不是 skill，不计入 `managedSkills`；分发项目 skills 时需一并包含它。

```bash
python3 scripts/sync_marketplace_plugin.py
python3 -m unittest discover -s tests -v
python3 -m unittest discover -s project-skills/flutter-mvvm-inspector/tests -v
git tag v0.4.10 && git push origin main v0.4.10
```

完整模板契约验收需要本机安装 Flutter；没有 Flutter 时 Python 测试会明确跳过该集成用例。发布前必须在有 Flutter 的环境运行并通过。

发布新版本只需更新源码中的插件版本、同步插件镜像并推送 tag。
