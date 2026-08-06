# Flutter MVVM 测试模式

## 覆盖门禁

- 只有颜色、字体、间距、布局、圆角、阴影、图标、静态 fixture 或静态文案变化，且状态、callback、校验、交互、导航、异步、数据和 contract 全部不变时，才视为纯视觉改动，不新增或修改测试。
- 非视觉改动先检查已有测试是否直接断言受影响的输入、动作、状态、输出或 contract；覆盖充分时复跑并记录依据，覆盖不足时新增或更新最小测试。
- 混合改动只为行为部分编写断言，不测试颜色、尺寸、间距、像素位置或其他无语义视觉细节。
- 仅执行到相关代码、拥有行覆盖或间接经过调用链不算直接覆盖；断言必须能在行为回归时稳定失败。

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
- 在测试内创建 controller、subject、subscription、fake clock 或全局 override 后立即用 `addTearDown` 注册清理；`setUp` 创建的 fixture 用 `tearDown` 恢复，不把清理只放在测试末尾。
- 注入时钟和随机数，或复用项目已有 fake time；不依赖真实时间、随机顺序和任意延迟。

## AppContainer wiring

- 只有验证 composition root 时才使用 `AppContainer`，并且只调用项目已有的公开初始化或测试 API。
- 分别验证需要区分的环境或模块选择，不在普通 Service、Repository 和 ViewModel 测试中读取全局容器。
- 已有可恢复 API 时立即注册清理；只有一次性 setup 时，把初始化前后断言放进同一个测试，或隔离到不包含其他容器状态假设的测试文件。
- 不依赖测试声明顺序，也不为测试方便新增全局替换或重置入口；架构确需改变时先取得用户明确授权。
- 修改共享或全局状态相关测试后，使用 `flutter test <scope> --test-randomize-ordering-seed=<seed>` 验证顺序独立性；失败时记录并复用该 seed。

## Widget 行为

- 用最小 `MaterialApp`、本地化和必要 provider 包装受测 Widget。
- 通过可见文本、语义、控件类型和用户动作断言结果，不依赖私有 State 或脆弱的树位置。
- 对点击、输入、loading、empty、error、弹层和导航等关键交互使用 `testWidgets`。
- 使用可控 Future、stream 或 fake 完成异步阶段；优先精确 `pump()`，仅在动画和任务确定收敛时使用 `pumpAndSettle()`。
- 纯布局、颜色、间距和文案默认通过实际预览或设计验收，不机械增加 Widget 测试。

## 覆盖率

- 只有用户明确要求数值覆盖率时，才在修改前运行 `flutter test <scope> --coverage` 建立基线，并在修改后用相同命令范围复测。
- 沿用项目已有覆盖率排除、阈值和报告工具；未经明确要求不修改口径。
- 根据未覆盖行为的回归风险选测试，不为简单 getter、生成文件或不可观察实现细节追求行覆盖。
- 报告命令范围、前后数值和仍未覆盖的高风险行为，不把总百分比等同于测试质量。

## 失败测试处理

1. 单独运行失败文件和测试名称，确认能够稳定复现。
2. 检查共享状态、时区、随机数、网络、计时和测试顺序依赖；怀疑顺序问题时用明确 seed 重跑并保留复现命令。
3. 根据公开 contract 判断是断言过期、测试环境错误还是生产回归。
4. 只修改与根因对应的一侧，不以删除断言或扩大等待掩盖问题。
5. 先重新运行目标测试，再运行受影响目录或完整测试集。
