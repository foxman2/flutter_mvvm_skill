# Product Preview

## 先读什么

- `lib/product_preview/pages/` 中最接近的页面，模板 `sample_product/` 还在时可以参考
- `lib/product_preview/product_preview_registry.dart`
- `lib/navigation/app_page.dart` 中的预览 AppPage
- 相关 l10n、业务接口、Mock 和待迁移的局部演示数据

先按[文件职责](../../shared-references/architecture-responsibilities.md)检查示例，再复用。没有相似预览时，查 MVVM 基类、AppPage 和依赖入口，不照搬静态示例处理复杂业务。

## 目录和命名

- 新页面只放在 `lib/product_preview/pages/<feature>/`。
- 用正式页面命名：`<feature>_page.dart`、`<feature>_view_model.dart`、`<Feature>Page` 和 `<Feature>ViewModel...`。
- 目录已经说明它是预览，文件和类型不用再加 `preview` 后缀。
- VM 使用 Input、Output、Type 和实现类；Page 接收返回非空 VM 的 provider。

## 状态和数据

- 同目录 VM 管理展示状态、请求结果和临时交互，不管理共享业务缓存。
- 布局占位、tab、选中和筛选等 UI 状态可以本地保存。
- 列表、卡片、详情、价格、额度和业务状态来自业务接口的 Mock 实现，预览目录不另存局部演示数据。
- 需要改接口、ApiService 组装、Mock 或临时 model 时，先由适用的数据层 skill 完成。
- 用户可见文案走项目 l10n。

## 路由和注册

- 新建普通 AppPage，routeName 使用 `/product-preview/...`。
- AppPage provider 创建 VM，从 AppContainer 注入业务接口或已有 Repository。
- registry 只存标题、描述和 appPage，不创建 VM 或 service，不处理权限或环境。
- 通过 Product Preview 入口和 AppNavigator 打开，不注册成正式业务入口。

## 交接和迁移

在 `docs/pm-changes/<change-id>.md` 的 `查看改动` 中列 Preview、Mock API 和必要代码入口。

审核后保留预览供正式开发参考。本工作流不把预览搬到 `lib/pages/<feature>/`，不接入正式状态，不发布 demo 逻辑。
