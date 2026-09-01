# PM 改动与接口对接记录

## 文件

在 `docs/pm-changes/<change-id>.md` 保存当前 PM 需求的记录。优先使用用户提供的需求编号；没有编号时使用简短、稳定的功能名。同一需求反复调整时更新同一文件，以 Git 保存历史，不在正文维护版本流水。

记录只保留最终有效内容，不添加待开发确认的产品问题、明确不包含、版本历史、完整接口协议、验收矩阵或完整文件列表。

## 格式

以下接口写法只适用于 method、path 和字段已有正式协议依据的情况。

```markdown
# <需求编号或标题>

## PM 改动

- <用户可感知的最终改动>
- <用户可感知的最终改动>

## 接口对接

- 修改 `PATCH /users/me`
  - 新增请求字段：`nickname`、`avatarFileId`
  - 响应增加：`avatarUrl`
- 新增 `POST /files/avatar`
  - 返回：`fileId`
- 调用顺序：上传头像成功后更新用户资料。

## 查看改动

- Preview：`/product-preview/profile/edit`
- Mock API：`lib/services/mock_api/mock_profile_api_service.dart`
- 关键代码：`lib/product_preview/pages/profile/edit_profile_page.dart`
```

## 记录规则

- `PM 改动` 只写本次需求产生的最终产品变化，不记录布局实现、重构、格式化或已经被替换的方案。
- `接口对接` 只写新增或修改的接口差异；已确认协议使用正式 method、path 和字段名，未确认协议只写需要提供的业务数据及用途，不把 mock-only model 当成正式字段依据。
- 多个接口有先后依赖时，用一条 `调用顺序` 说明；没有顺序依赖时不增加该项。
- 页面不需要后台改动时，在 `接口对接` 下写 `- 无。`。
- `查看改动` 只列实际可打开的 Preview、Mock API 和理解改动所需的关键相对路径，不穷举分支文件。
- 只有错误处理、分页、上传约束或其他规则确实改变接口对接时才补充，不预设空章节。
