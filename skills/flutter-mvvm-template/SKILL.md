---
name: flutter-mvvm-template
description: >-
  Create new Flutter apps from the bundled MVVM template and CLI. 用于从零创建新的 Flutter MVVM 项目，生成可复用 View/ViewModel 基类、sealed AppPage 导航、alert/action sheet/bottom sheet 示例、Dio ApiService 以及 real/mock API 基础层。Do not use for modifying an existing app after generation: use flutter-mvvm-feature-dev for page/UI/navigation/ViewModel work, flutter-mvvm-api-dev for confirmed backend API/model work, and flutter-mvvm-mock-api-dev for backend-unconfirmed mock API work.
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
- 可复用 MVVM 基础设施不要依赖业务资源、Firebase、推送、生成式本地化或真实业务 API。
- 生成项目默认包含 `rxdart`、`flutter_easyloading` 和 `dio`。
- 生成项目预设 `ApiService.shared` 作为网络请求服务单例，只保留 `user` 模块作为示例占位。
- 生成项目在 `api_service.dart` 内预设 `ApiEnvironment`、baseUrl、timeout、headers 和 mock 开关，生成后直接改这个文件切换 production/test/mock。
- mock service 直接放在 `lib/services/mock_api/` 下，后台未确认的 mock-only model 放在 `lib/services/mock_api/models/`。

## 资源

- `scripts/flutter_mvvm.py`：项目生成 CLI。
- `scripts/install_cli.sh`：安装 `flutter-mvvm` 命令软链接。
- `assets/flutter_mvvm_overlay/`：复制到新 Flutter 应用中的模板文件。
- `references/architecture.md`：模板边界和生成项目结构。
- `references/sealed-page.md`：sealed page 路由模式和示例。
