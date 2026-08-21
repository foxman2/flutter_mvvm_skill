# Product Preview 模式

## 先读现有预览

项目代码是事实来源。新增页面前读取：

- `lib/product_preview/pages/` 中最接近的页面；模板示例存在时参考 `sample_product/`
- `lib/product_preview/product_preview_registry.dart`
- `lib/navigation/app_page.dart` 中现有预览 page case
- 相关 l10n key 和预览局部样例数据

## 目录与命名

- 新页面只放在 `lib/product_preview/pages/<feature>/`。
- 文件和类型按正式页面命名：`<feature>_page.dart`、`<feature>_view_model.dart`、`<Feature>Page` 和 `<Feature>ViewModel...`。
- 隔离边界由目录表达，不给文件或类型追加 `preview` 后缀。
- ViewModel 使用 Input、Output、Type 和实现类；Page 接收非空 provider。

## 展示状态与数据

- 同目录 ViewModel 管理展示状态和临时交互。
- 纯布局占位、tab、选中态和筛选项等小型 UI 状态可以本地保存。
- 列表、卡片、详情或业务状态使用预览目录内的局部 fixture，由同目录 ViewModel 暴露。
- 不为预览数据新增 domain contract、ApiService wiring、mock service 或正式 model。
- 用户可见文案走项目 l10n。

## AppPage 与注册

- 为预览页面新增普通 AppPage，routeName 使用 `/product-preview/...` 语义。
- AppPage 的 provider 创建 ViewModel；registry 只保存标题、描述和 appPage，不创建 ViewModel 或处理权限、环境和 API。
- 通过 Product Preview 入口和 AppNavigator 打开页面，不把预览注册成正式业务入口。

## 审核迁移

在 `docs/pm-changes/<change-id>.md` 的 `查看改动` 中标记 Preview、局部 fixture 和理解改动所需的关键代码入口。审核通过后保留预览作为正式开发参考，但不在本工作流中迁移到 `lib/pages/<feature>/`、接入正式状态或发布 demo 逻辑。
