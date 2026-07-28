# UI 修改模式

## 修改前

读取当前页面和相邻页面，确认使用的布局、按钮、theme、间距、弹层容器，以及已有 ViewModel input/output。优先沿用项目现状。

## 职责边界

Widget 负责：

- 布局、样式和文案展示
- 绑定 ViewModel 事件
- 根据 output 状态选择 UI

ViewModel 负责：

- 点击后的业务动作和异步加载
- loading/error
- 导航、Alert、ActionSheet 和 BottomSheet

不要在 Widget callback 中直接调用 API、写缓存或决定业务导航。

## 弹层选择

- 普通错误优先使用项目现有 `errorTracker`。
- 业务确认使用现有 Alert ViewModel 与对应 AppPage。
- 多个互斥操作使用 ActionSheet。
- 复杂内容或完整布局使用独立 BottomSheet 页面；内部还需导航时使用带 Navigator 的变体。
- 高度、拖拽和顶部间距跟随现有 BottomSheet 配置接口。

## 视觉检查

- 复用已有 Widget 和 theme，不为单页发明另一套样式。
- 检查长文案、按钮文本、小屏滚动、键盘、安全区和表单错误。
- 保持原有返回行为、loading/error 呈现和交互语义。
