# Flutter MVVM Template

这个仓库是 `flutter-mvvm-template` Codex skill 和插件的源码。

## 目录结构

- `.codex-plugin/plugin.json`：Codex 插件 manifest。
- `skills/flutter-mvvm-template/`：创建新 Flutter MVVM 项目的 skill 源码。
- `skills/flutter-mvvm-feature-dev/`：在已有 Flutter MVVM 项目中创建页面、修改 UI、接导航的 skill 源码。
- `skills/flutter-mvvm-api-dev/`：在已有 Flutter MVVM 项目中新增 API service、model 解析和接口调用的 skill 源码。
- `skills/flutter-mvvm-mock-api-dev/`：在已有 Flutter MVVM 项目中新增临时 mock API、mock service 和 mock-only model 的 skill 源码。
- `skills/flutter-mvvm-template/scripts/flutter_mvvm.py`：项目生成 CLI。
- `skills/flutter-mvvm-template/assets/flutter_mvvm_overlay/`：覆盖到新 Flutter 项目中的模板文件。
- `examples/mvvm_skill_test/`：用于手动验证的生成示例项目。
- `scripts/package_plugin.py`：在 `dist/` 下生成可分发的插件 zip。

## 开发

主要修改 `skills/flutter-mvvm-template/`、`skills/flutter-mvvm-feature-dev/`、`skills/flutter-mvvm-api-dev/` 和 `skills/flutter-mvvm-mock-api-dev/`。模板改动后，可以用 `examples/mvvm_skill_test/` 这个本地测试项目检查生成后的 Flutter 代码。

常用检查：

```bash
python3 /Users/xiaominliu/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .
for skill in skills/flutter-mvvm-*; do
  python3 /Users/xiaominliu/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$skill"
done
flutter analyze examples/mvvm_skill_test
flutter test examples/mvvm_skill_test
```

## 打包

生成插件压缩包：

```bash
python3 scripts/package_plugin.py
```

压缩包包含 `.codex-plugin/`、`skills/` 和 `README.md`，并排除 git 元数据、示例项目、Flutter 生成缓存和历史打包产物。

## 直接使用生成器

```bash
python3 skills/flutter-mvvm-template/scripts/flutter_mvvm.py create --app-name "My App" --package-name com.example.myapp
```
