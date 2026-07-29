# Flutter MVVM 测试模式

## 选择最小测试层级

| 行为 | 优先测试层级 |
|---|---|
| model 缺失值、可空、嵌套集合和自定义转换 | Dart 单元测试 |
| API method、path、query/body、解析和错误映射 | contract 单元测试 |
| Service、Repository 和 ViewModel 状态转换 | 直接构造依赖的单元测试 |
| AppContainer 模块选择和依赖装配 | 独立 wiring 测试 |
| 用户点击、输入、loading/error 和导航结果 | Widget 测试 |
| 多页面、平台或真实设备流程 | 已有集成测试体系 |

优先覆盖最接近行为来源的层级。一个低层测试已经稳定覆盖转换或错误映射时，不在 Widget 层重复相同细节。

## Model 与 API contract

- 只为缺失值、可空兼容、嵌套集合、自定义转换、复杂序列化或已发生的解析回归新增 model 测试。
- 让代表性 API contract 测试同时覆盖 HTTP method、path、query/body、response parsing 和错误映射。
- 使用项目现有 Dio adapter、fake client 或 mock server，不发出真实网络请求。
- 协议或响应结构未确认时，不通过测试固化猜测出的字段和 envelope。

## Service、Repository 与 ViewModel

- 直接构造受测对象并传入 fake Service、Repository、时钟或其他依赖。
- 让 fake 只表达当前测试需要的结果、错误或可控完成时机，不复制生产实现。
- 覆盖非平凡状态转换、异步竞争、错误恢复、去重、分页和关键业务分支。
- 分别断言初始状态、触发动作和最终可观察状态；仅在顺序本身属于 contract 时断言中间状态。
- 关闭 controller、stream 和 subscription，避免测试结束后遗留异步工作。

## AppContainer wiring

- 只有验证 composition root 时才整体替换或初始化 `AppContainer`。
- 分别验证需要区分的环境或模块选择，不在普通 Service、Repository 和 ViewModel 测试中读取全局容器。
- 在 `tearDown` 中恢复容器和其他全局状态，保证测试可独立、乱序和重复执行。

## Widget 行为

- 用最小 `MaterialApp`、本地化和必要 provider 包装受测 Widget。
- 通过可见文本、语义、控件类型和用户动作断言结果，不依赖私有 State 或脆弱的树位置。
- 对点击、输入、loading、empty、error、弹层和导航等关键交互使用 `testWidgets`。
- 使用可控 Future、stream 或 fake 完成异步阶段；优先精确 `pump()`，仅在动画和任务确定收敛时使用 `pumpAndSettle()`。
- 纯布局、颜色、间距和文案默认通过实际预览或设计验收，不机械增加 Widget 测试。

## 失败测试处理

1. 单独运行失败文件和测试名称，确认能够稳定复现。
2. 检查共享状态、时区、随机数、网络、计时和测试顺序依赖。
3. 根据公开 contract 判断是断言过期、测试环境错误还是生产回归。
4. 只修改与根因对应的一侧，不以删除断言或扩大等待掩盖问题。
5. 先重新运行目标测试，再运行受影响目录或完整测试集。
