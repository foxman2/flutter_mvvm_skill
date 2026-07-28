# 页面和 ViewModel 模式

## 先读相邻实现

新增或修改页面前，读取 1～2 个相似页面及其：

- `<feature>_page.dart` 与 `<feature>_view_model.dart`
- 对应 AppPage case
- 相关 Widget、l10n key 和测试

项目代码优先于本参考。保持相邻页面的基类、命名、import 和状态管理方式。

## 文件与类型

- 页面目录和文件使用 snake_case，例如 `lib/pages/profile/profile_page.dart`。
- 类型命名为 `<Feature>Page`、`<Feature>ViewModelInput`、`Output`、`Type` 和 `<Feature>ViewModel`。
- ViewModel Page 使用项目的 `AppBaseStatefulPage<T>` 与对应 State，即使页面没有本地 controller 或 animation。

## ViewModel 职责

- input 表达用户或生命周期事件，并跟随项目已有 `onClickXxx`、`onInputXxx` 等命名。
- output 暴露展示状态；默认使用 getter 配合 `makeRebuild()`。
- 仅为输入联动、进度、倒计时、刷新或一次性 UI 事件等局部高频状态使用 `ValueStream<T>`/`Stream<T>`。
- 内部状态保持私有；异步 loading/error 使用项目现有 tracker。
- 导航、弹窗和业务动作由 ViewModel 发起，Widget 只绑定事件。

## Page 与依赖

- Page 只依赖 `<Feature>ViewModelType>`，并显式接收返回非空 ViewModel 的 `viewModelProvider`。
- 普通页面由对应 AppPage provider 延迟创建 ViewModel；Page 不自行创建，也不接收预先创建的普通页面实例。
- ViewModel 通过构造函数接收 Service 或 Repository；AppPage provider 从 `AppContainer.shared` 取得依赖。
- Alert、ActionSheet 和 child ViewModel 可能需要预配置实例；修改前确认创建、绑定和释放责任，不套用普通页面所有权。

## 本地化

- 用户可见文案写入项目现有 ARB，并遵循当前 key 命名。
- Page 或纯 Widget 用 `AppLocalizations.of(context)!` 读取展示文案。
- ViewModel 用 `localStrings` 读取状态、toast、弹窗和导航结果文案，但不能在构造函数或 `initState()` 中读取，因为 callback 尚未绑定。

## 测试

先运行受影响的已有测试。只为非平凡状态转换、异步竞争、错误恢复、关键交互或回归新增测试；纯布局、文案和可由编译器或 analyzer 约束的结构默认不单独测试。
