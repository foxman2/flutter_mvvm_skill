---
name: flutter-mvvm-template
description: >-
  用于从零创建新的 Flutter MVVM 项目，并套用 flutter-mvvm-template 模板，生成 View/ViewModel 基类、sealed AppPage 导航、弹窗、ActionSheet、BottomSheet 示例、Dio ApiService、real/mock API 基础层和隔离预览入口。不用于修改已生成或已有应用；隔离预览 UI 原型使用 flutter-mvvm-pm-ui，正式页面/UI/导航/ViewModel 开发使用 flutter-mvvm-feature-dev，已确认后端 API/model 使用 flutter-mvvm-api-dev，后端未确认或 mock API 使用 flutter-mvvm-mock-api-dev。
---

# Flutter MVVM Template

使用这个 skill 创建新的 Flutter MVVM 项目。

## 快速开始

创建新项目时，优先使用 CLI：

```bash
python3 <skill-dir>/scripts/flutter_mvvm.py create --app-name "My App" --package-name com.example.myapp
```

如果已经安装了 CLI，也可以使用：

```bash
flutter-mvvm create --app-name "My App" --package-name com.example.myapp
```

该命令默认在当前目录下创建项目目录，目录名默认从包名最后一段推导。命令会先运行 `flutter create`，再把 `assets/flutter_mvvm_overlay/` 中的 MVVM 模板覆盖到新项目中。

## 工作流程

1. 创建新项目前，如果用户没有明确给出 app 显示名和原生包名，先询问这两个值。包名指 Android `applicationId` / iOS `PRODUCT_BUNDLE_IDENTIFIER`，例如 `com.example.myapp`。
2. 生成目录默认使用当前工作目录；除非用户明确指定其它输出路径，不传 `--output`。
3. 除非用户明确要求手动复制，否则运行 `scripts/flutter_mvvm.py create --app-name "<App Name>" --package-name <package.name>`；需要指定目录名时才补 `<project_name>`。
4. 只生成新项目或模板文件，不修改已有 Flutter 应用。
5. 用户要求改造已有 app 时，说明这个 skill 只覆盖新模板项目生成，并建议先生成一个参考项目。
6. 需要理解生成项目边界时，阅读 `references/architecture.md`。
7. 需要说明生成项目的 sealed page 路由模式时，阅读 `references/sealed-page.md`。

## 默认约定

- 创建项目时先调用官方 `flutter create`，然后只覆盖 Dart/template 文件。
- app 显示名会同步到 Flutter UI 标题、Android label、iOS display name 和 Web manifest/title。
- 原生包名会同步到 Android namespace/applicationId/MainActivity package，以及 iOS bundle identifier。
- 使用 `sealed class AppPage` 表达带参数的页面枚举。
- 页面参数放在具体的 `AppPage` 子类中，不使用全局 `dynamic param`。
- 页面 ViewModel 使用严格 input/output/type 契约：Page 依赖 `<Feature>ViewModelType`，用户事件走 input 方法，展示状态走 output getter 或 stream。
- input 方法命名只描述用户在 View 上做了什么：点击用简短 `onClickXxx`，输入用 `onInputXxx`；不要用裸的 `show/open/load/save/delete/submit/close/select/fetch` 这类目的性方法名。
- output 默认使用 getter + `makeRebuild()`；只有输入联动、进度、倒计时、刷新状态和一次性 UI 事件等高频或局部刷新场景使用 `ValueStream<T>`/`Stream<T>`。
- 不把 `ValueNotifier` 作为页面 ViewModel output；需要局部刷新时使用模板提供的 `ValueStreamBuilder<T>`。
- 可复用 MVVM 基础设施不要依赖业务资源、Firebase、推送、产品专属本地化策略或真实业务 API。
- 生成项目默认包含 `rxdart`、`flutter_easyloading` 和 `dio`。
- 生成项目默认启用 Flutter 官方 l10n：`flutter_localizations`、`intl:any`、`flutter.generate: true`、`l10n.yaml` 和 `lib/l10n/app_en.arb`。
- 模板当前只提供英语 `en`；新增语言时复制 ARB 文件并按 Flutter gen-l10n 规则扩展，不在模板里加入运行时切换语言 UI。
- 用户可见文案放进 ARB。Page 或纯 Widget 用 `AppLocalizations.of(context)!`，ViewModel 用基类 `localStrings` 现用现取当前字符串。
- ViewModel 不在构造函数或 `initState()` 中读取 `localStrings`，因为页面 callback 绑定发生在 ViewModel 创建之后。
- 生成项目预设 `ApiService.shared` 作为网络请求服务单例，只保留 `user` 模块作为示例占位。
- 生成项目在 `api_service.dart` 内预设 `ApiEnvironment`、baseUrl、timeout、headers 和 mock 开关；本地预览 mock 数据时优先使用 `--dart-define=USE_MOCK_API=true`。
- mock service 直接放在 `lib/services/mock_api/` 下，后台未确认的 mock-only model 放在 `lib/services/mock_api/models/`。
- 生成项目包含 `lib/product_preview/` 和首页悬浮 Product Preview 入口，供隔离新增 UI 原型，正式迁移前需要开发审核。

## 资源

- `scripts/flutter_mvvm.py`：项目生成 CLI。
- `scripts/install_cli.sh`：安装 `flutter-mvvm` 命令软链接。
- `assets/flutter_mvvm_overlay/`：复制到新 Flutter 应用中的模板文件。
- `references/architecture.md`：模板边界和生成项目结构。
- `references/sealed-page.md`：sealed page 路由模式和示例。
