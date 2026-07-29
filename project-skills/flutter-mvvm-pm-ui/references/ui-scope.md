# PM UI 改动范围

## 可以修改

- 页面布局、文案、颜色、字体、间距、图标和 loading/empty/error 的呈现
- 正式 `_page.dart` 对已有 ViewModel input/output 的展示与绑定
- `lib/widgets/`、theme 和页面局部纯展示组件
- `lib/product_preview/` 下的入口、隔离页面、同目录 ViewModel 与 registry
- 与新增预览页面对应的 AppPage case
- `lib/product_preview/` 范围内的局部 fixture 和样例展示状态

## 不可以修改

- 正式 ViewModel 的状态、异步、业务动作、弹窗和导航决策
- 与新增预览 AppPage 无关的 navigator、transition 或 route parser
- domain API contract、ApiService wiring、mock service、正式 model、真实 Dio 请求和正式业务依赖逻辑
- Dart define、环境解析、默认环境、启动配置、构建脚本或 CI 参数
- Widget 中的 API 调用、JSON 解析、缓存、登录态判断或业务路由

Widget 可以绑定已有 ViewModel 事件；隔离页面可以通过同目录 ViewModel 表达展示状态、局部样例数据和临时交互。正式 UI 需要新业务动作时，在 PM 交付说明中描述需求，但不在本工作流中实现。
