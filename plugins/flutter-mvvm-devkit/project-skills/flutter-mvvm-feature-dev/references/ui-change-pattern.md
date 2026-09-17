# 修改 UI

## 开始前

读当前页面和相似页面，确认布局、按钮、主题、间距、弹层容器及 VM Input/Output。只复用符合项目分工和风格的写法。涉及行为时，先按[文件职责](../../shared-references/architecture-responsibilities.md)确定状态和数据由谁管理。

## 页面分工

- Widget 负责布局、样式、文案，绑定 Input，按 Output 显示 UI。
- VM 响应操作、加载数据、调用注入的业务能力，并发起 loading/error、导航和弹层。
- Widget callback 不直接调用 API、写缓存或决定业务导航。

## 弹层怎么选

- 普通错误：已有 `errorTracker`。
- 业务确认：已有 Alert ViewModel 和 AppPage。
- 多个互斥操作：ActionSheet。
- 复杂内容或完整布局：独立 BottomSheet 页面。内部需要导航时，用带 Navigator 的版本。
- 高度、拖拽和顶部间距：沿用已有 BottomSheet 配置。

## 看实际效果

- 复用已有 Widget 和主题，不为单页另做一套样式。
- 检查长文案、按钮文字、小屏滚动、键盘、安全区和表单错误。
- 保持原有返回、loading/error 和交互行为。
