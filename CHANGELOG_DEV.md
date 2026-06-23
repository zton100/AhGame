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

## S02 数据配置加载与校验系统 / ConfigValidator - 2026-06-23

### 新增文件

- `lib/models/config_issue.dart`
- `lib/models/config_validation_error.dart`
- `lib/systems/config/config_validator.dart`
- `test/config_validator_test.dart`

### 修改文件

- `lib/systems/config/game_database_load_result.dart`
- `lib/systems/config/game_database_service.dart`
- `test/game_database_service_test.dart`
- `CHANGELOG_DEV.md`

### 完成内容

- 新增 `ConfigValidator` 基础配置校验器。
- 校验配置根对象必须具备整数 `schemaVersion`。
- 校验配置文件必须包含根记录或记录列表。
- 校验表记录必须包含稳定 `id` 和展示 `name`。
- 校验根配置记录使用 `id` 和 `displayName`。
- 校验同一表内重复 id。
- 新增统一 `ConfigIssue`，将加载错误和校验错误汇总到 `GameDatabaseLoadResult`。
- `GameDatabaseService` 会在构建数据库时同步返回校验错误，并纳入 Debug 统计。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 暂无存档结构变更。

### 待处理问题

- S02 后续需要实现跨表引用完整性检查。
- Debug 页后续需要展示可筛选的配置错误列表。

## S02 数据配置加载与校验系统 / 引用检查与首批配置 - 2026-06-23

### 新增文件

- `lib/systems/config/effect_registry.dart`
- `lib/systems/config/reference_resolver.dart`
- `assets/data/classes.json`
- `assets/data/skills.json`
- `assets/data/affixes.json`
- `assets/data/equipment_templates.json`
- `assets/data/soul_cores.json`
- `assets/data/difficulties.json`
- `assets/data/drop_pools.json`
- `test/reference_resolver_test.dart`
- `test/seed_data_integration_test.dart`

### 修改文件

- `lib/models/config_validation_error.dart`
- `lib/features/debug/debug_page.dart`
- `lib/systems/config/game_database_service.dart`
- `CHANGELOG_DEV.md`

### 完成内容

- 新增 `ReferenceResolver`，实现跨表引用检查。
- 检查技能 `classId` 是否引用存在的职业。
- 检查装备模板和魂核 `allowedClasses` 是否引用存在的职业或 `all`。
- 检查掉落池装备/魂核引用是否存在。
- 检查技能、词缀、魂核、套装中的 `effectId` 是否进入 `EffectRegistry`。
- 将引用检查接入 `GameDatabaseService`，统一纳入 `ConfigIssue` 和 Debug 错误统计。
- 新增首批 5 职业轻量配置：流放者、亡语者、灰烬术士、冰痕猎手、圣裁者。
- 新增每职业 1 个示例技能和 1 个示例武器模板。
- 新增基础词缀、魂核、难度和第 1 章基础掉落池示例配置。
- Debug 页增加前 5 条配置问题展示。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 暂无存档结构变更。

### 待处理问题

- S02 后续可继续细化 schema 级字段类型校验。
- Debug 页后续可增加按文件筛选和完整错误列表。
## S03 Local Save and Migration System - 2026-06-23

### Added files

- `lib/models/save_data.dart`
- `lib/models/settings_save.dart`
- `lib/models/migration_result.dart`
- `lib/systems/save/save_store.dart`
- `lib/systems/save/in_memory_save_store.dart`
- `lib/systems/save/hive_save_store.dart`
- `lib/systems/save/backup_service.dart`
- `lib/systems/save/save_migration_service.dart`
- `lib/systems/save/save_service.dart`
- `test/save_service_test.dart`

### Modified files

- `pubspec.yaml`
- `pubspec.lock`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Chose Hive as the first local save backend, while keeping `SaveStore` as the persistence boundary.
- Added `SaveData.currentVersion = 2`, default new-game data, player progress, inventory, and settings save structures.
- Added `SaveService` for load/create/save/delete.
- Added `SaveMigrationService` with a `v1 -> v2` migration example.
- Added `BackupService` and recovery behavior: if the primary save cannot be read or migrated, the service attempts the latest backup before falling back to a new save.
- Added `HiveSaveStore` with recursive JSON normalization so Hive dynamic maps can safely round-trip through typed save models.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\save_service_test.dart`

### Save impact

- Introduces save schema version 2.
- Migration path: legacy saves without `saveVersion` or with `saveVersion: 1` are migrated by adding version 2 and default settings.

### Remaining

- Add lifecycle-based `AutoSaveService`.
- Surface save summary in Debug and Settings pages.
- Add export/import placeholders after the UI settings shell exists.

## S03 Auto Save Lifecycle Hook - 2026-06-23

### Added files

- `lib/systems/save/auto_save_service.dart`
- `lib/systems/save/app_lifecycle_auto_save_observer.dart`

### Modified files

- `lib/models/save_data.dart`
- `lib/models/migration_result.dart`
- `lib/systems/save/save_migration_service.dart`
- `test/save_service_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `lastExitAt` to `SaveData` and bumped the save schema to version 3.
- Added migration support from v1 and v2 saves into version 3.
- Added `AutoSaveService` for key-operation saves, forced app-exit saves, throttling, and last error capture.
- Added `AppLifecycleAutoSaveObserver` so paused, hidden, and detached lifecycle states can trigger exit saves from the service layer.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\save_service_test.dart`

### Save impact

- Introduces save schema version 3.
- Migration path: v1 saves gain default settings, then v2 saves gain nullable `lastExitAt`; both migrate to v3.

### Remaining

- Wire the lifecycle observer into real app startup after save bootstrapping is introduced.
- Surface live save and auto-save status in the Debug page.
- Add Settings page manual save/export/import placeholders after the settings UI exists.

## S04 Character Class System / Service Layer - 2026-06-23

### Added files

- `lib/models/stat_block.dart`
- `lib/models/class_config.dart`
- `lib/models/character_state.dart`
- `lib/systems/character/class_service.dart`
- `lib/systems/character/character_service.dart`
- `test/character_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `ClassConfig` parsing from `classes.json`, including stable id, display name, tags, base stats, and growth stats.
- Added `CharacterState` as a service-layer view of current class, level, experience, and base stats.
- Added `ClassService` for listing, finding, and requiring class configs from `GameDatabase`.
- Added `CharacterService` for creating a character, restoring from `SaveData`, and switching current class while preserving level and experience.
- Verified all 5 configured classes parse through the real seed data path.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\character_service_test.dart test\seed_data_integration_test.dart`

### Save impact

- No save schema change. Character state uses existing `SaveData.playerProgress.currentClassId`, `level`, and `experience`.

### Remaining

- Add character page UI integration.
- Add `LevelService` and `level_curves.json` for Issue 015.
- Add stat aggregation in S06/Issue 016 before equipment and combat consume final stats.

## S04 Character Class System / Level Growth - 2026-06-23

### Added files

- `assets/data/level_curves.json`
- `lib/models/level_curve.dart`
- `lib/systems/character/level_service.dart`
- `test/level_service_test.dart`

### Modified files

- `lib/models/character_state.dart`
- `lib/models/stat_block.dart`
- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added the first data-driven level curve config with levels 1-20.
- Added `LevelCurve` parsing and cumulative total-experience level lookup.
- Added `LevelService.addExperience` to update saved level and total experience.
- Added max-level capping and negative experience gain rejection.
- Added class stat growth calculation using base stats plus per-level growth.
- Verified the real seed level curve loads through `GameDatabase`.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\level_service_test.dart test\seed_data_integration_test.dart`

### Save impact

- No save schema change. Existing `PlayerProgress.level` and `experience` now have service-backed update rules.

### Remaining

- Add character page UI integration.
- Connect level-up events to future combat/idle reward services.
- Add richer unlock outputs after the unlock system exists.

## S06 Attribute Aggregation / Issue 016 First Slice - 2026-06-23

### Added files

- `lib/systems/stats/stat_aggregation_service.dart`
- `test/stat_aggregation_service_test.dart`

### Modified files

- `lib/models/stat_block.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `StatAggregationService` for final stat calculation.
- Added `ComputedStats` and `StatBreakdown` so Debug/UI can later show base, flat, percent, more, less, and final values.
- Added `StatModifier` with `flat`, `percent`, `more`, and `less` modifier types.
- Implemented stacking order: `(base + flat) * (1 + percent) * more multipliers * less multipliers`.
- Guarded invalid final numeric output so negative modifiers do not create `NaN`.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\stat_aggregation_service_test.dart`

### Save impact

- No save schema change.

### Remaining

- Add formula config and soft caps for crit/cooldown/resistance.
- Add damage, defense, status, and difficulty formulas in later S06 slices.
- Connect equipment, affixes, talents, and skills as modifier sources after their systems exist.

## S06 Damage Formula / Issue 017 First Slice - 2026-06-23

### Added files

- `assets/data/formula_config.json`
- `lib/models/formula_config.dart`
- `lib/systems/stats/damage_formula_service.dart`
- `test/damage_formula_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added data-driven formula config for critical chance cap, default critical multiplier, resistance cap, and armor constant.
- Added `DamageContext`, `DamageResult`, and `DamageBreakdown`.
- Added `DamageFormulaService` with base damage, skill multiplier, critical hit, resistance mitigation, and armor mitigation.
- Damage results expose whether the hit crit, final damage, and formula breakdown values.
- Guarded final damage from invalid numeric output.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\damage_formula_service_test.dart test\seed_data_integration_test.dart`

### Save impact

- No save schema change.

### Remaining

- Add status effect formulas for poison, bleed, burn, freeze, and summons.
- Add soft-cap config for future crit/cooldown/resistance expansion.
- Connect combat simulation once monster and skill runtime systems exist.

## S07 Equipment Template and Quality Foundation - 2026-06-23

### Added files

- `assets/data/quality_config.json`
- `lib/models/equipment_template.dart`
- `lib/models/quality_config.dart`
- `lib/systems/equipment/equipment_template_service.dart`
- `lib/systems/equipment/quality_service.dart`
- `test/equipment_template_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added 12 equipment slots with stable ids, including dual ring slots and soul core.
- Added data-driven quality config for all 8 qualities.
- Added `EquipmentTemplate` parsing for slot, class restrictions, minimum level, quality pool, base stat ranges, and affix rules.
- Added `QualityService` and `EquipmentTemplateService`.
- Verified real seed equipment templates and quality config parse through `GameDatabase`.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_template_service_test.dart test\seed_data_integration_test.dart`

### Save impact

- No save schema change.

### Remaining

- Add `EquipmentInstance` and deterministic generation in Issue 019.
- Add class/level equip restrictions in Issue 020.
- Add equipment compare and UI card view models in later S07/S24 slices.

## S07 Equipment Instance Generation - 2026-06-23

### Added files

- `lib/models/equipment_instance.dart`
- `lib/systems/equipment/equipment_generation_service.dart`
- `test/equipment_generation_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `EquipmentInstance` and `RolledBaseStat` with JSON round trip support.
- Added deterministic `EquipmentGenerationService` using template id, quality id, class id, level, and seed.
- Generated stable instance ids and rolled base stat values inside template ranges scaled by quality multiplier.
- Added validation for template quality pool, class restrictions, and minimum level.
- Verified real seed equipment templates can generate an equipment instance.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_generation_service_test.dart test\seed_data_integration_test.dart`

### Save impact

- No save schema change. Existing inventory stores equipment instance ids; full instance persistence will be added when inventory/storage expands.

### Remaining

- Add affix rolling after S08 affix runtime exists.
- Add equipment equip/unequip rules in Issue 020.
- Add equipment comparison and inventory integration.
