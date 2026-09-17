# AppPage 导航

## 路由怎么定义

先读 `lib/navigation/app_page.dart` 和相似页面的 AppPage 子类。每个可导航页面使用具体子类，不用 `enum + dynamic param`。

按需要提供：

- 稳定的 `routeName`
- `defaultTransition`
- 强类型构造参数
- `generateWidgetBuilder()`
- `queryParameters`，仅在路由字符串、深链或恢复需要时提供

## ViewModel 怎么创建

- 普通页面在 `generateWidgetBuilder()` 返回的 provider 中延迟创建 VM。有运行参数也一样，不提前创建实例。
- AppPage provider 从 `AppContainer.shared` 取得 Service 或 Repository，通过构造函数传给 VM。
- Alert、ActionSheet 和子 VM 需要预先配置动作或父子关系时，可以传已有实例。先确认由谁初始化和释放，不把这个例外用于普通页面。

## 转场怎么选

- 普通页面通常用 `push`。
- 提示框用 `alert`，操作面板用 `actionSheet`。
- 底部弹层用 `bottomSheet`，内部需要导航时用 `bottomSheetWithNavigator`。
- 弹层高度和拖拽沿用 `BottomSheetConfigProvider`。
- 清空导航栈用 `replaceRoot(...)`，不要新增一种 transition。

## 路由解析和调用

- 页面需要深链、浏览器地址或路由恢复时，才改 parser。解析失败使用项目已有的失败结果，不给所有页面强加 parser 分支。
- 页面改名不必顺带改外部 routeName；没有需求就保持路由稳定。
- 业务导航由 VM 调用已有 `show()`、replacement、root replacement 和 `pop()` 封装，不直接调用 Navigator。
