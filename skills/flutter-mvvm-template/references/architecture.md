# Flutter MVVM Template 架构边界

## 模板职责

- 生成可直接开发的 Flutter MVVM 项目，不改造已有应用。
- 保持模板独立于 Firebase、认证/session、推送、埋点、产品资源和运行时语言切换等产品能力。
- 提供 MVVM 生命周期、sealed AppPage、AppContainer、l10n、Dio ApiService、real/mock 示例、Product Preview 和 smoke test。
- 网络层只提供基础 client、错误转换、环境切换和示例 domain，不预设真实业务接口或统一后端 envelope。
- 生成项目的局部 skills 负责后续页面、API、mock、PM 预览、代码地图和 Inspector 工作。

## 核心结构

```text
.codex/
├── flutter-mvvm-skills.json
└── skills/
lib/
├── app.dart
├── app_container.dart
├── l10n/
├── main.dart
├── models/
├── mvvm/
├── navigation/
├── pages/
├── product_preview/
├── services/
│   ├── api/
│   └── mock_api/
└── widgets/
scripts/
└── update-codex-skills.py
test/
└── app_smoke_test.dart
```

## 架构不变量

- `AppContainer` 是唯一全局依赖容器；其持有的 Service 和 Repository 不提供独立 `shared`。
- 普通页面的 AppPage provider 延迟创建 ViewModel，并从 AppContainer 取得构造依赖。
- 页面 ViewModel 使用 Input、Output、Type 与实现类，Page 只依赖 Type。
- 用户可见文案走 Flutter l10n；固定 Widget 文案直接读取 `AppLocalizations`，跨页面、弹层和 toast 的 `DisplayText` 参数用 `.localized` 延迟到展示时解析，服务端原文用 `.raw`。
- `.raw` 不读取 `AppLocalizations`；ViewModel 不持有 `BuildContext`，也不直接访问 `AppLocalizations`。
- 导航使用具体 sealed AppPage 子类和强类型参数。
- `product_preview/` 是隔离预览区；审核通过后再迁移到正式页面与业务实现。

## 测试与更新

- 生成项目只保留应用初始化和渲染 smoke test；完整模板契约测试保留在 DevKit 的 `tests/template_contract/`。
- CLI 默认执行依赖获取、代码生成、format、analyze 和 smoke test；失败时以 CLI 输出区分已生成文件和未完成检查。
- `scripts/update-codex-skills.py` 更新项目局部 skills；运行环境需要 `python3` 和 `git`。
