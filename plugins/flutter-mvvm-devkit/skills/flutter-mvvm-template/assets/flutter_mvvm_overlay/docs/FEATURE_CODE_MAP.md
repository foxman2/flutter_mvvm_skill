# 功能代码地图

## 全局入口

- 应用启动：`lib/main.dart`
- 应用配置：`lib/app.dart`
- 依赖装配：`lib/app_container.dart`
- 页面路由：`lib/navigation/app_page.dart`
- 路由解析：`lib/navigation/app_route_parser.dart`
- 导航执行：`lib/navigation/app_navigator.dart`
- 本地化文案：`lib/l10n/app_en.arb`

## 功能索引

| 功能/别名 | 代码入口 | 检索锚点 |
|---|---|---|
| 首页 / 示例入口 | `lib/pages/home/home_page.dart`、`lib/pages/home/home_view_model.dart` | `HomePage`、`HomeViewModel` |
| 短消息 / Toast | `lib/widgets/app_toast.dart`、`lib/mvvm/base_view_model.dart` | `AppToastController`、`showNormalMessage`、`showSuccessMessage` |
| 提示弹窗 / Alert | `lib/pages/alert/alert_page.dart`、`lib/pages/alert/alert_view_model.dart` | `AlertPage`、`AlertViewModel`、`AlertAppPage` |
| 输入弹窗 / Input Alert | `lib/pages/input_alert/input_alert_page.dart`、`lib/pages/input_alert/input_alert_view_model.dart` | `InputAlertPage`、`InputAlertViewModel`、`InputAlertAppPage` |
| 操作菜单 / Action Sheet | `lib/pages/action_sheet/action_sheet_page.dart`、`lib/pages/action_sheet/action_sheet_view_model.dart` | `ActionSheetPage`、`ActionSheetViewModel`、`ActionSheetAppPage` |
| 底部弹层 / Bottom Sheet | `lib/pages/home/home_page.dart`、`lib/widgets/common_bottom_sheet_container.dart`、`lib/navigation/app_page.dart` | `BottomSheetDemoPage`、`BottomSheetDemoAppPage`、`BottomSheetConfig` |
| 产品预览列表 / Product Preview | `lib/product_preview/product_preview_page.dart`、`lib/product_preview/product_preview_registry.dart` | `ProductPreviewPage`、`productPreviewItems` |
| 产品预览示例 / Sample UI | `lib/product_preview/pages/sample_product/sample_product_page.dart`、`lib/product_preview/pages/sample_product/sample_product_view_model.dart` | `SampleProductPage`、`SampleProductViewModel` |
| 用户资料 / 模拟用户接口 | `lib/services/api/user_api_service.dart`、`lib/services/mock_api/mock_user_api_service.dart`、`lib/models/user/user_profile.dart` | `UserApiService`、`MockUserApiService`、`UserProfile` |
