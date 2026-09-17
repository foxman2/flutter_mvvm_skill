# 页面和 ViewModel

## 先读什么

读 1～2 个相似页面、VM、AppPage、相关 Widget、l10n key 和测试。按[文件职责](../../shared-references/architecture-responsibilities.md)检查后，再复用基类、命名、import 和状态管理写法。

没有相似页面时，先查 MVVM 基类、AppPage 和依赖入口的真实接口。不要猜方法，不补不需要的层。

## 命名和基类

- 目录和文件用 snake_case，例如 `lib/pages/profile/profile_page.dart`。
- 类型用 `<Feature>Page`、`<Feature>ViewModelInput`、`Output`、`Type` 和 `<Feature>ViewModel`。
- 有 VM 的 Page 用项目的 `AppBaseStatefulPage<T>` 和对应 State，即使没有本地 controller 或动画。

## Input 和 Output

- Input 接收用户或生命周期事件，沿用 `onClickXxx`、`onInputXxx` 等命名。
- Input 默认返回 `void`，异步流程放在 VM 私有方法里。只有框架明确要求异步返回时才例外，并说明原因。
- Input 声明、实现和调用方一起检查。不要接口写 `void`，实现却继续向调用方暴露 Future 或业务结果。
- Output 提供与业务状态、异步结果、页面参数或操作有关的展示值。默认用 getter 配合 `makeRebuild()`。
- 输入联动、进度、倒计时、刷新或一次性 UI 事件等确有需要的局部状态，才用 `ValueStream<T>` 或 `Stream<T>`。
- 内部状态保持私有。导航、弹窗和页面操作由 VM 发起，Widget 只绑定事件。
- VM 可以保存本页结果和草稿；共享数据更新经过 Repository，独立规则交给 Model 或业务 Service。

## Loading 和错误

实现位于 `lib/mvvm/base_view_model.dart`、`loading_tracker.dart` 和 `error_tracker.dart`。

| 需要什么 | 使用什么 |
|---|---|
| loading 和错误提示 | `trackLoadingAndConsumeError(this)`，不再手动维护同一操作的 loading |
| 只提示错误 | `consumeError(errorTracker)`，不用再写 try/catch |
| 提示错误后继续抛出 | `trackError(errorTracker)`，外层不要重复提示 |
| 按错误类型处理、重试或回滚 | 自己写 try/catch |

`consumeError` 和 `trackLoadingAndConsumeError` 捕获错误后返回 `null`：

- 成功结果保证非空时，可以用 `null` 判断失败。
- 返回 `void`，或成功也可能返回 `null` 时，不能这样判断。
- 失败后仍要执行的步骤，可以写在这次 `await` 后。
- 如果包装整个流程，流程内部因异常跳过的步骤不会补执行。

## 页面如何接收结果

- 页面不要等待 Input 返回值来决定下一步。需要的反馈改走 Output 或已有输出通道。
- 例如发送成功后清空输入框：View 接收发送成功事件；失败保留输入，错误走 tracker。
- 测试通过 Output、事件、导航或错误通道判断结果。要控制异步时序，就控制测试替身的完成时机，不为测试公开内部异步方法。

## 固定展示值

只依赖 l10n、Theme 或 Context 的固定值，由 Page/Widget 直接读取。不要为了转发固定文案增加 VM Output，也不要照搬相邻页面的多余 getter。

固定标题直接写：

```dart
title: Text(strings.dragDropEditTitle),
```

不要为它增加：

```dart
DisplayText get title => .localized((strings) => strings.dragDropEditTitle);
```

## Page 与依赖

- Page 依赖 `<Feature>ViewModelType`，接收返回非空 VM 的 `viewModelProvider`。
- 普通路由页面由 AppPage provider 延迟创建 VM。Page 不自行创建，也不直接接收预先创建的 VM 实例。
- AppPage provider 从 `AppContainer.shared` 取得依赖，经构造函数传给 VM。
- Alert 和 ActionSheet 可能需要预先配置实例。先确认谁创建、绑定和释放，不套用普通路由页面的规则。

## 父页面组合子 Page

- 子 Page 仍优先使用普通 `AppBaseStatefulPage<T>` 和对应 State，不因嵌套另建基类或绑定组件。
- 父级可以创建并保存子 VM，通过 provider 交给子 Page。
- 创建和保存实例的人，可以与负责生命周期的人不同；但初始化和释放只能由一方负责。
- 子 Page 负责生命周期时，父级不能再调用 VM 的 `initState()` 或 `dispose()`。
- 同一次子 Page 生命周期内，provider 返回稳定有效的实例。重新挂载时不能返回已释放的实例。
- 父子通过明确的状态、回调或接口协作，不为嵌套修改通用 MVVM Base。

父级保存实例、子 Page 管理生命周期的例子：

```dart
late final ChildViewModelType _childViewModel;

@override
void initState() {
  super.initState();
  _childViewModel = ChildViewModel();
}

@override
Widget build(BuildContext context) {
  return ChildPage(
    viewModelProvider: () => _childViewModel,
  );
}
```

是否保留 State、是否条件挂载、重新挂载时如何换实例，由具体需求决定。这里不规定 Widget 结构或状态保留方式。

## 本地化

- 用户文案写入现有 ARB，沿用 key 命名。
- Page/Widget 用 `AppLocalizations.of(context)!` 读取文案。
- VM 不持有 Context，也不直接读取 AppLocalizations。
- VM 向 toast、Alert、InputAlert 或 ActionSheet 传递 `DisplayText` 时，用 `.localized((strings) => strings.xxx)`，展示时按当前语言解析。依赖业务状态或参数的文案也这样处理。
- API 和服务端原文用 `.raw(value)`，不走本地化。

```dart
final alert = AlertViewModel(
  title: .localized((strings) => strings.deleteTitle),
  content: .raw(serverMessage),
);
```
