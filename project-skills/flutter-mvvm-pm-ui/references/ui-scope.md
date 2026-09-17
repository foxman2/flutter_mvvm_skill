# PM UI 可以改哪里

## 可以改

- 布局、文案、颜色、字体、间距、图标，以及 loading/empty/error 的显示方式。
- 正式 `_page.dart` 对已有 VM Input/Output 的展示和绑定。
- `lib/widgets/`、theme 和页面局部展示组件。
- `lib/product_preview/` 的入口、页面、同目录 VM 和 registry。
- 新预览对应的 AppPage。
- 预览中的步骤、tab、选中、展开、筛选和输入等 UI 状态。

## 不可以改

- 正式 VM 的状态、异步、业务动作、弹窗和导航决策。
- 与新预览无关的 navigator、transition 或 route parser。
- API 接口、ApiService 组装、Mock、正式 model、真实 Dio 请求和正式业务依赖。
- Dart define、环境解析、默认环境、启动配置、构建脚本或 CI 参数。
- 不在 Widget 中新增 API 调用、JSON 解析、缓存、登录态判断或业务路由。

Widget 只绑定已有 VM 事件。预览的临时交互放在同目录 VM。

预览需要演示业务数据时，先由适用的数据层 skill 提供 Mock API。正式 UI 需要新业务动作时，在 `docs/pm-changes/<change-id>.md` 中记录已确认的产品行为和数据需求，不在本工作流里实现。
