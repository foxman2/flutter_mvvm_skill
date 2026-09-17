# PM 改动记录

## 保存在哪里

用 `docs/pm-changes/<change-id>.md`。优先用用户给的需求编号，没有就用简短稳定的功能名。

同一需求更新同一文件。历史由 Git 保存，正文只保留最终结果。不写旧方案、版本流水、完整协议、验收矩阵、全部文件清单或“明确不包含”清单。未决产品问题先确认，不留给开发决定。

## 格式

下面的接口名和字段只是格式示例，只有正式协议已经确认时才能这样写。

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

## 每部分写什么

- `PM 改动`：最终产品变化。不写布局实现、重构、格式化或已废弃方案。
- `接口对接`：只写接口增量。协议已确认就用正式 method、path 和字段；没确认就只写需要什么业务数据、用来做什么。临时 Mock model 不能作为正式协议依据。
- `调用顺序`：接口确实有先后依赖时才写。
- 不需要后台改动时，在 `接口对接` 下写 `- 无。`。
- `查看改动`：实际能打开的 Preview、Mock API 和必要代码入口，用相对路径，不列所有文件。
- 错误处理、分页或上传限制确实影响对接时才补充，不预建空章节。
