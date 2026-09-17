---
name: flutter-mvvm-mock-api-dev
description: >-
  后端协议未确认时，为正式页面和 Product Preview 提供 Mock API 演示数据。用于新增、迁移或审查模拟接口、临时模型和依赖组装；不开发真实 Dio API，不处理纯 UI 状态或静态资源。
---

# Mock API 开发

## 开始前

- 确认项目有 `lib/app_container.dart` 和 `lib/services/api/api_service.dart`。
- 读[文件职责](../shared-references/architecture-responsibilities.md)和 [Mock API 模式](references/mock-api-pattern.md)，再读相关接口、真实与 Mock 实现、调用方和测试。
- 分清模拟服务端数据、客户端共享数据、编辑草稿和页面状态。Mock 只模拟服务端。

## 数据放哪里

- 账号、列表、详情、价格、额度、消息、结果和记录等演示业务数据，都从业务接口的 Mock 实现返回。正式页面、预览和测试入口遵守同一规则。
- Widget、Page、ViewModel 和 `lib/product_preview/` 不直接编造业务数据。
- ViewModel 可以保存请求结果、编辑草稿、输入、选中、筛选和 loading。共享业务数据按需由 Repository 管理。
- l10n 文案、主题、图标、静态资源路径和纯展示枚举留在展示层。

## 怎么做

1. 按业务复用或新增接口，不按页面各建一套 API。迁移旧数据时，搜索 Page、ViewModel、Screen、预览、model 和测试里的 fixture、demo、seed 和硬编码业务对象。
2. 在 `lib/services/api/<domain>_api_service.dart` 定义调用方使用的接口。协议未确认部分标记为临时、待审核。
3. 提供 `Unimplemented<Domain>ApiService`：非 mock 环境调用时明确报未实现，不持有 Dio。
4. 在 `lib/services/mock_api/mock_<domain>_api_service.dart` 实现 Mock。已确认的 model 直接复用；未确认的结构放在 `lib/services/mock_api/models/`。
5. 按当前需求模拟延迟、空数据、错误或状态变化。
6. 只在 ApiService 组装时按已有环境开关选择 Mock、Unimplemented 或已有 Dio 实现。
7. AppPage provider 向 ViewModel 注入业务接口，或注入管理相关数据的 Repository。依赖由 AppContainer 和 ApiService 组装；没有数据管理需求就不新建 Repository。
8. 删除调用方原来的演示数据副本。将新增接口、组装代码、Mock 和临时 model 标记为待开发审核。

## 不要这样做

- 不猜真实 URL、字段、响应外层格式或错误码，测试也不能把猜测固定成正式协议。
- 不创建假装已经实现的 `Dio<Domain>ApiService`。
- 正式调用方不直接 import `services/mock_api/`。Widget 和 ViewModel 不判断 mock/real。
- 不为预览修改默认环境。预览里的业务数据也必须来自 Mock API。
- ApiService、Mock 和 Repository 不加 `shared`。
- Mock 可以用内存记录模拟服务端创建和更新，不处理客户端 loading、toast、导航、缓存或持久化。

## 完成检查

- Mock 环境能完成目标演示，非 mock 环境对未实现接口明确报错。
- 调用方不再生成演示业务数据，状态和数据各有明确负责人。
- 格式化改动文件，运行 `flutter analyze`。
- 检查已有测试是否直接验证了受影响的接口、Mock 结果、未实现分支、依赖组装和调用方行为。只是执行到代码不算覆盖。
- 已覆盖就复跑并说明依据；没覆盖才补最小测试。测试只验证临时接口行为、Mock 场景和组装结果。

## 协议确认后

停止扩展临时结构，列出接口对齐、model 迁移和非 mock 实现的工作，改用正式 API 开发 skill。不要在这里新增真实 Dio 实现，也不要把未审核 model 直接搬进正式目录。
