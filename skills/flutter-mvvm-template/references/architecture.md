# Flutter MVVM Template 架构边界

## 模板边界

- 模板代码要独立于产品专属服务：Firebase、推送处理、生成式本地化、资源、网络客户端和领域 manager 都留在应用层。
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
├── mvvm/
├── navigation/
├── pages/
└── widgets/
```

`main.dart` 只负责启动应用。`app.dart` 负责 `MaterialApp`、navigator observers、主题和 EasyLoading builder。

## 生成后检查清单

1. 运行 `flutter pub get`。
2. 运行 `dart format lib test`。
3. 运行 `flutter analyze`。
4. 运行 `flutter test`。
5. 打开生成项目，确认 `lib/mvvm/`、`lib/navigation/`、`lib/pages/` 和 `test/` 都已覆盖到位。

## 不要放入模板的内容

- 业务页面和领域 view model。
- 后端 API client、DTO、认证/session manager。
- Firebase、推送通知、app link 和 analytics 配置。
- 产品资源、生成式本地化、应用专属主题。
- 平台目录，除非用户明确想复制完整项目。
