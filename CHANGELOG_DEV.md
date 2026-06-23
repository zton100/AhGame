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

## S02 数据配置加载与校验系统 - 2026-06-23

### 新增文件

- `lib/models/config_load_error.dart`
- `lib/models/data_file_meta.dart`
- `lib/models/loaded_data_file.dart`
- `lib/systems/config/config_load_result.dart`
- `lib/systems/config/data_loader.dart`

### 修改文件

- `lib/features/shell/main_shell.dart`
- `test/config_loader_test.dart`

### 完成内容

- 保留 S01 的 `ConfigLoader` 原始 asset 读取能力。
- 新增 `DataLoader`，支持读取单个 JSON 配置文件。
- 新增结构化加载结果：成功返回 `LoadedDataFile` 和 `DataFileMeta`，失败返回 `ConfigLoadError`。
- 支持识别缺失文件、非法 JSON、根节点非对象、缺少整数 `schemaVersion`。
- 支持从 `AssetManifest` 按目录加载 `assets/data/*.json` 的入口。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 暂无存档结构变更。

### 待处理问题

- S02 后续需要实现 `GameDatabase` 聚合访问层。
- S02 后续需要实现 id 唯一性校验、引用校验和 Debug 错误展示。

## S02 数据配置加载与校验系统 / GameDatabase - 2026-06-23

### 新增文件

- `lib/models/game_database_summary.dart`
- `lib/systems/config/game_database.dart`
- `lib/systems/config/game_database_load_result.dart`
- `lib/systems/config/game_database_service.dart`
- `test/game_database_service_test.dart`

### 修改文件

- `lib/features/debug/debug_page.dart`
- `test/widget_test.dart`
- `CHANGELOG_DEV.md`

### 完成内容

- 新增 `GameDatabase` 聚合访问层。
- 支持从多个 `LoadedDataFile` 构建配置数据库。
- 支持按配置文件路径查询文件元数据。
- 支持按表名和稳定 id 查询记录，缺失 id 返回 `null`，不抛未处理异常。
- 新增 `GameDatabaseService`，汇总成功加载文件、加载错误和数据库摘要。
- Debug 页显示配置文件数量、记录数量、错误数量和已构建表名。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 暂无存档结构变更。

### 待处理问题

- S02 后续需要实现配置必填字段校验、id 唯一性校验和引用完整性检查。
- Debug 页后续需要支持配置错误列表按文件筛选。
