---
name: flutter-mvvm-template
description: >-
  从 bundled assets 创建新的 Flutter MVVM 项目并安装项目局部开发 skills。用于生成、初始化或脚手架化全新 Flutter app，执行前必须取得 app 显示名和原生包名；不用于修改已有应用或开发现有项目功能。
---

# Flutter MVVM Template

## 创建项目

优先运行 bundled CLI：

```bash
python3 <skill-dir>/scripts/flutter_mvvm.py create --app-name "My App" --package-name com.example.myapp
```

已安装命令时也可使用 `flutter-mvvm create` 和相同参数。

## 工作流程

1. 用户未提供 app 显示名或原生包名时先询问；包名对应 Android `applicationId` 和 iOS `PRODUCT_BUNDLE_IDENTIFIER`。
2. 默认在当前目录生成项目，目录名从包名最后一段推导；仅在用户指定输出位置时传 `--output`，需要自定义目录名时传 `<project_name>`。
3. 运行 CLI；它先执行官方 `flutter create`，再覆盖 MVVM 模板并安装项目局部 skills。
4. 不修改已有 Flutter 应用；已有项目的页面、API、mock、代码地图或 Inspector 工作使用该项目内的局部 skills。
5. 完成后报告项目路径和 CLI 关键结果；本地工具链或网络导致最终检查失败时，区分已生成文件和未完成检查。

## 可选参数

- `--platforms`：默认 `ios,android,web`。
- `--skip-final-checks`：仅在用户明确要求跳过 format、analyze 和 smoke test 时使用。

## 生成结果

- app 显示名与原生包名同步到 Flutter 和原生平台配置。
- 项目包含 MVVM、sealed AppPage、AppContainer、l10n、real/mock API 示例、Product Preview、smoke test 和 `.codex/skills/`。
- `scripts/update-codex-skills.py` 用于更新项目局部 skills；无参数跟随 `main`，`--version vX.Y.Z` 固定版本。

需要解释生成项目的结构或边界时，读取 `references/architecture.md`。
