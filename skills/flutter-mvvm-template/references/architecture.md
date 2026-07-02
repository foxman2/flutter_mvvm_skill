# Flutter MVVM Template 架构边界

## 模板边界

- 模板代码要独立于产品专属服务：Firebase、推送处理、生成式本地化、资源、认证/session manager 和领域 manager 都留在应用层。
- 网络层只预设基础 `ApiService` 规则：Dio setup、通用请求、错误转换、代码级 API 环境切换和 `user` real/mock 示例模块，不预设真实业务接口或后端响应协议。
- 跨项目可复用的生命周期代码放到 `mvvm/`：view model 绑定、dispose 管理、loading/error 跟踪和基础 page widget。
- 导航基础能力放到 `navigation/`：page model、navigator、route parser、transition enum 和 observer。
- 通用 UI 保持小而可替换：alert、input alert、action sheet、bottom sheet 是示例，不是完整设计系统。
- 优先使用回调或 view model 方法，不要从通用模板里直接导入业务模块。
- 这个模板只负责生成新项目，不包含已有项目改造步骤。

## 生成项目结构

```text
lib/
├── app.dart
├── main.dart
├── models/
├── mvvm/
├── navigation/
├── pages/
├── product_preview/
│   └── pages/
├── services/
│   ├── api/
│   └── mock_api/
│       └── models/
└── widgets/
```

`main.dart` 负责初始化 `AppServices` 并启动应用。`app.dart` 负责 `MaterialApp`、navigator observers、主题和 EasyLoading builder。

`product_preview/` 是产品经理 UI 预览隔离区。首页通过悬浮按钮进入 `ProductPreviewAppPage`，新增 PM 页面放在 `product_preview/pages/` 并通过 `product_preview_registry.dart` 注册；审核通过后再由开发迁移到正式 `pages/`、ViewModel 和 AppPage 导航。

## 生成后检查清单

1. 运行 `flutter pub get`。
2. 运行 `dart format lib test`。
3. 运行 `flutter analyze`。
4. 运行 `flutter test`。
5. 打开生成项目，确认 `lib/mvvm/`、`lib/navigation/`、`lib/pages/`、`lib/services/`、`lib/models/` 和 `test/` 都已覆盖到位。

## 不要放入模板的内容

- 业务页面和领域 view model。
- 真实业务 API、认证/session manager 和领域 manager。
- 后台未确认的 mock-only model；新增时先放在 `lib/services/mock_api/models/`，确认后再合并到正式 model。
- 未经开发审核的 PM 预览页面；这类页面先留在 `lib/product_preview/`。
- Retrofit、Chopper、freezed、json_serializable 或其他代码生成依赖。
- Firebase、推送通知、app link 和 analytics 配置。
- 产品资源、生成式本地化、应用专属主题。
- 平台目录，除非用户明确想复制完整项目。
