---
name: flutter-mvvm-pm-ui
description: >-
  用户明确要求 PM 评审、UI 原型或产品预览时使用。调整展示、创建隔离预览，并记录产品改动和接口需求。不修改正式业务行为，不开发真实 API，也不把预览迁成正式页面。
---

# 产品界面与预览

## 开始前

- 读相关页面、组件、预览示例和 registry，查找当前需求已有的 `docs/pm-changes/` 记录。
- 新增预览、改交互或接数据前，读[文件职责](../shared-references/architecture-responsibilities.md)。纯样式和固定文案不用重复读。
- 找出已有硬编码演示数据和本次需要新增的数据。分清展示状态、请求结果和数据来源。

## 可以做什么

- 调整正式页面、共用 Widget 和 theme 的纯展示部分，不改变正式 ViewModel 行为。
- 新页面或流程原型放在 `lib/product_preview/pages/<feature>/`，按正式 MVVM 方式命名和组织。
- 为预览增加对应 AppPage，并注册到 Product Preview。
- 预览 ViewModel 可以保存步骤、tab、选中、筛选、输入、草稿和请求结果。
- 演示列表、详情、价格、额度等数据从注入的业务接口或已有 Repository 获取。预览层不编造业务数据，不管理共享缓存。

## 怎么做

1. 现有 UI 微调只改展示。新原型使用同目录 ViewModel 管理临时交互。
2. 需要新增、修改或迁移演示数据时，先按适用的 API 或 Mock API skill 完成接口、实现和依赖组装，再接入预览。
3. 复用现有组件、主题、间距、按钮和弹层风格。
4. 检查状态由谁管理、数据从哪里来，修正本次相关问题。
5. 格式化，运行 `flutter analyze`，通过实际 Product Preview 查看效果。
6. 更新 `docs/pm-changes/<change-id>.md`，写最终产品改动、接口差异、必要调用顺序和查看入口。没有接口影响就写“无”。
7. 交付时给出记录文件、预览验收和检查结果，不在回复里重复整份记录。

## 测试

- 纯展示和静态文案改动不新增或修改测试。
- 改预览 VM 状态、callback、临时交互或 Mock 数据时，先检查现有测试。
- 测试必须直接检查受影响的输入、动作、状态、输出或接口约定。只是执行到代码不算覆盖。
- 已覆盖就复跑并说明依据；没覆盖才补最小测试。混合改动只测试行为部分。

## 不在这里做什么

- 不修改正式 ViewModel 的状态、异步、业务动作、导航或持久化。
- 不改与预览无关的 AppPage、route parser 和正式依赖。
- API 接口、ApiService 组装、Mock、正式 model 和真实 Dio 请求由对应数据层 skill 处理。
- 不修改认证、埋点、推送和持久化逻辑。
- 不修改 Dart define、环境解析、默认环境、启动配置、构建脚本或 CI 参数。

## 记录要求

- 同一需求始终更新同一份记录，不为每轮调整新增文件或版本历史。
- 产品行为先确认，再写记录，不把未决产品问题留给开发。
- 协议没确认时，只写需要什么业务数据、用来做什么。不要猜 method、path、字段名、类型或响应结构。

## 按需阅读

- 判断修改范围：读 [UI 范围](references/ui-scope.md)。
- 新增或注册预览：读 [预览模式](references/product-preview-pattern.md)。
- 更新交接记录：读 [改动记录](references/change-handoff-pattern.md)。
