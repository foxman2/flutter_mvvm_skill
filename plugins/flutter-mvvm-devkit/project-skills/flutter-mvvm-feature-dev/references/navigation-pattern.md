# Sealed AppPage 导航模式

## 核心结构

先读取 `lib/navigation/app_page.dart` 和最接近的页面 case。每个可导航页面使用具体 `AppPage` 子类，而不是 `enum + dynamic param`，并按需要提供：

- 稳定的 `routeName`
- `defaultTransition`
- 强类型构造参数
- `queryParameters`，仅用于路由字符串、深链或恢复
- `generateWidgetBuilder()`

## ViewModel 组装

- 普通页面无论是否包含运行参数，都在 `generateWidgetBuilder()` 返回的 provider 中延迟创建 ViewModel。
- ViewModel 通过构造函数接收依赖；AppPage provider 从 `AppContainer.shared` 取得具体 Service 或 Repository。
- 不在 `generateWidgetBuilder()` 外预先创建普通页面 ViewModel。
- Alert、ActionSheet 或 child ViewModel 需要先配置动作、回调或父子关系时，可以保留已创建实例；先确认生命周期，不能把例外推广到普通页面。

## Transition

- 普通页面通常使用 `push`。
- Alert 使用 `alert`，操作面板使用 `actionSheet`。
- BottomSheet 使用 `bottomSheet` 或 `bottomSheetWithNavigator`，高度和拖拽配置跟随现有 `BottomSheetConfigProvider`。
- 清空导航栈调用 `replaceRoot(...)`，不要把它建成 transition。

## Route parser

只有页面需要深链、浏览器地址或路由恢复时才更新 parser。解析失败返回项目约定的失败结果，不为形式统一给所有页面添加 parser 分支。

保持既有 routeName 稳定；页面改名时不要无必要改变外部路由。业务页面从 ViewModel 使用项目的 `show()`、replacement、root replacement 和 `pop()` 封装，不直接绕到 `Navigator`。
