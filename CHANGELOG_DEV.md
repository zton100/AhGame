# CHANGELOG_DEV

开发日志用于记录每个系统的新增文件、修改文件、完成内容、测试结果、存档影响和待处理问题。

## S01 项目架构与目录规范系统 - 2026-06-23

### 新增文件

- `lib/core/bootstrap/game_bootstrap.dart`
- `lib/core/routing/app_route.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/quality_theme.dart`
- `lib/features/debug/debug_page.dart`
- `lib/features/placeholder/feature_placeholder_page.dart`
- `lib/features/shell/main_shell.dart`
- `lib/models/app_config.dart`
- `lib/models/dev_log_entry.dart`
- `lib/systems/config/config_loader.dart`
- `lib/systems/debug/debug_service.dart`
- `lib/systems/navigation/navigation_service.dart`
- `assets/data/app_config.json`
- `CHANGELOG_DEV.md`
- `.gitignore`
- `.metadata`
- `README.md`
- `analysis_options.yaml`
- `android/`
- `pubspec.yaml`
- `pubspec.lock`
- `test/config_loader_test.dart`
- `test/widget_test.dart`

### 修改文件

- `lib/main.dart`

### 完成内容

- 创建 Flutter 正式工程底座。
- 接入 Riverpod 根节点。
- 建立暗黑主题、品质色 token、路由枚举和导航服务。
- 建立战斗、装备、BD、深渊、角色 5 个主页面占位。
- 建立 debug-only 调试入口和 Debug 页面。
- 注册 `assets/data/` 并加入首个 app 配置文件。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 暂无存档结构变更。S03 会正式引入 `SaveData` 和 migration。

### 待处理问题

- S02 需要实现完整 JSON 配置加载、校验和 `GameDatabase`。
- S03 需要接入 Hive 本地存档。
