# CHANGELOG_DEV

## S34 Character Growth Overview - 2026-06-27

### Added files

- None.

### Modified files

- `lib/features/character/character_page.dart`
- `test/character_page_widget_test.dart`

### Completed

- Added a top-level growth overview for output, survivability, equipped item count, and next-step advice.
- Kept the detailed base/final stats and breakdown sections for deeper inspection.

### Tests

- Added CharacterPage widget coverage for growth overview and next-step advice.

### Save impact

- No SaveData schema change.

### Remaining

- Growth advice is still a lightweight UI heuristic, not a full deterministic progression planner.

## S33 Equipment Page Readability Polish - 2026-06-27

### Added files

- None.

### Modified files

- `lib/features/equipment/equipment_page.dart`
- `test/equipment_page_widget_test.dart`

### Completed

- Added player-facing recommendation reasons to equipment cards and detail dialogs.
- Added enhancement preview showing the next-level primary base stat change.
- Kept equipment scoring and enhancement logic in existing services.

### Tests

- Added EquipmentPage widget coverage for recommendation reasons and enhancement preview.

### Save impact

- No SaveData schema change.

### Remaining

- Recommendation copy is still rule-based and can later be connected to deeper build guidance.

## S32 Battle First-Screen Experience Polish - 2026-06-27

### Added files

- None.

### Modified files

- `lib/features/battle/battle_page.dart`
- `test/battle_page_widget_test.dart`

### Completed

- Added a top current-goal panel for progression stage, actual stage, monster, status, next-step advice, and recent battle feedback.
- Moved manual battle controls higher so core actions are visible immediately.
- Kept auto battle simulation, settlement, and fallback logic unchanged.

### Tests

- Updated BattlePage widget coverage for the new first-screen layout.

### Save impact

- No SaveData schema change.

### Remaining

- This is still functional polish, not a full visual redesign or animation pass.

## UI Chinese Text Completion - 2026-06-27

### Added files

- `lib/features/common/game_text_labels.dart`

### Modified files

- `assets/data/enhancement_config.json`
- `assets/data/formula_config.json`
- `assets/data/level_curves.json`
- `lib/core/routing/app_route.dart`
- `lib/features/character/character_page.dart`
- `lib/features/equipment/equipment_card_view_model.dart`
- `lib/features/equipment/equipment_page.dart`
- `lib/features/equipment/equipment_page_view_model.dart`
- `lib/features/placeholder/feature_placeholder_page.dart`
- `test/character_page_widget_test.dart`
- `test/equipment_card_view_model_test.dart`
- `test/equipment_page_widget_test.dart`
- `test/widget_test.dart`

### Completed

- Localized remaining player-facing route labels, placeholder text, config display names, equipment recommendations, stat labels, slot labels, and tag labels.
- Replaced visible `BD` usage with `构筑` and `Lv.` usage with Chinese level text.
- Kept technical IDs and save/config keys in English to preserve data compatibility.

### Tests

- Updated widget and view model expectations for Chinese labels.
- Ran formatter, analyzer, and Flutter tests.

### Save impact

- No SaveData schema change.
- Existing saveVersion remains unchanged.

### Remaining

- Code identifiers, enum values, JSON keys, material IDs, and stable resource IDs remain English because they are internal contracts.
- Some test fixture names and developer-only test descriptions remain English.

## S31 Auto Battle Explanation and Guidance - 2026-06-27

### Added files

- None.

### Modified files

- `lib/models/auto_battle_run_state.dart`
- `lib/systems/battle/battle_readiness_service.dart`
- `lib/systems/auto_battle/auto_battle_service.dart`
- `lib/features/battle/battle_page.dart`
- `lib/features/equipment/equipment_page.dart`
- `test/auto_battle_service_test.dart`
- `test/battle_readiness_service_test.dart`
- `test/battle_page_widget_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added runtime-only auto battle explanation fields for progression stage, actual stage, fallback reason, readiness reason, combat estimates, and recommended next action.
- Added fallback reason tracking for level too low, battle failed, low damage, and low survivability.
- Added readiness-to-guidance mapping: safe continues progression, low damage recommends weapon upgrades, and low survivability recommends armor or HP upgrades.
- AutoBattleService now records whether the run progressed normally or farmed a fallback stage, without changing battle simulation or settlement rules.
- BattlePage now shows an Auto Battle Explanation section with stage choice, estimates, readable reason labels, and next-step guidance.
- EquipmentPage now explains that recommended enhancement prioritizes equipped gear, usually the main weapon.

### Tests

- Added AutoBattleRunState explanation field coverage through copyWith and settlement paths.
- Added BattleReadinessService recommended action mapping tests.
- Added AutoBattleService coverage for normal progression, level fallback, low damage fallback, low survivability fallback, battle-failed fallback, and non-progression during fallback farming.
- Added BattlePage widget coverage for explanation UI, recommended next action, low damage advice, low survivability advice, progression stage, and actual stage.

### Save impact

- No SaveData schema change.
- Runtime explanation fields live only in `AutoBattleRunState`.
- Current `SaveData.saveVersion` is unchanged; no migration required.

### Remaining

- Readiness remains an estimate rather than a full deterministic forecast.
- No offline rewards, abyss, new content, art, animation, auto equip, or BattleSimulator/BattleSettlementService refactor was added.

## UI Chinese Localization Polish - 2026-06-25

### Added files

- `web/` Flutter web runner files generated for local browser runs.

### Modified files

- `.metadata`
- `assets/data/chapters.json`
- `assets/data/monsters.json`
- `assets/data/quality_config.json`
- `assets/data/skills.json`
- `lib/core/routing/app_route.dart`
- `lib/features/battle/battle_controller.dart`
- `lib/features/battle/battle_page.dart`
- `lib/features/character/character_page.dart`
- `lib/features/equipment/equipment_page.dart`
- `lib/features/equipment/equipment_page_view_model.dart`
- `lib/features/shell/main_shell.dart`
- `lib/systems/battle/battle_simulator.dart`
- `lib/systems/stats/character_final_stats_service.dart`
- `test/auto_battle_service_test.dart`
- `test/battle_page_widget_test.dart`
- `test/character_page_widget_test.dart`
- `test/equipment_page_widget_test.dart`
- `test/equipment_card_view_model_test.dart`
- `test/equipment_generation_service_test.dart`
- `test/equipment_loot_materialization_service_test.dart`
- `test/battle_settlement_service_test.dart`

### Completed

- Localized player-facing BattlePage, EquipmentPage, CharacterPage, route labels, warnings, buttons, summaries, and battle settlement labels to Chinese.
- Localized chapter, stage, monster, and skill display names in seed JSON while preserving stable ids and references.
- Localized equipment quality display names from `Normal/Magic/Rare/...` to `普通/魔法/稀有/...`.
- Localized battle logs for skill casts, damage, monster HP, player defeat, and victory.
- Localized material display names for gold, salvage dust, and chapter reward materials.
- Updated widget tests and battle log assertions to match Chinese UI text.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat analyze`
- Passed: `I:\dev\flutter\bin\flutter.bat test`

### Save impact

- No SaveData schema change.
- Display names changed only in config/UI; stable ids remain unchanged.

### Remaining

- Some internal developer-facing exceptions and test fixture names remain English where they are not shown to players.
- Debug-only tooling and developer-facing exception text may still contain English.

## S31-S33 Equipment Recommendation, Skill Upgrade, Chapter 2 Content - 2026-06-25

### Added files

- `lib/systems/equipment/equipment_recommendation_service.dart`
- `lib/systems/skills/skill_upgrade_service.dart`
- `test/equipment_recommendation_service_test.dart`
- `test/skill_upgrade_service_test.dart`

### Modified files

- `assets/data/chapters.json`
- `assets/data/monsters.json`
- `lib/core/save/player_save_provider.dart`
- `lib/features/battle/battle_controller.dart`
- `lib/features/character/character_page.dart`
- `lib/features/equipment/equipment_page.dart`
- `lib/models/battle_state.dart`
- `lib/models/save_data.dart`
- `lib/systems/auto_battle/auto_battle_service.dart`
- `lib/systems/battle/battle_simulator.dart`
- `lib/systems/save/save_migration_service.dart`
- `lib/systems/skills/skill_effect_preview_service.dart`
- `test/battle_simulator_test.dart`
- `test/character_page_widget_test.dart`
- `test/equipment_page_widget_test.dart`
- `test/save_service_test.dart`
- `test/seed_data_integration_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- S31: Added equipment recommendation service for current-class, same-slot upgrades.
- S31: Equipment recommendations consider BD match delta and attack upgrades, while ignoring unusable class or level candidates.
- S31: Added PlayerSaveController action and EquipmentPage button for one-click recommended upgrade equip.
- S32: Added persistent `PlayerProgress.skillLevels`.
- S32: Added SkillUpgradeService with gold cost, max level, class validation, and SaveData update result.
- S32: SkillEffectPreviewService and BattleSimulator now apply skill level damage scaling.
- S32: CharacterPage displays active skills, level, preview damage, next gold cost, and an Upgrade Skill action.
- S33: Added `chapter_2` Plague Chapel content with five stages.
- S33: Added chapter 2 monster configs: `plague_acolyte`, `blood_incense_priest`, `rotting_reliquary_guard`, `fallen_sanctifier`, and `plague_bell_keeper`.

### Tests

- Added equipment recommendation service tests for valid upgrades and unusable candidates.
- Added skill upgrade service tests for v5 migration, gold consumption, max level, insufficient gold, and preview scaling.
- Added BattleSimulator coverage for skill-level damage and BattleState JSON skill-level round trip.
- Added CharacterPage widget coverage for upgrading an active skill and persisting level.
- Added EquipmentPage smoke coverage for recommended equip action.
- Added seed data coverage for chapter 2 boss stage and monster reference.
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`
- Passed: `I:\dev\flutter\bin\flutter.bat test`

### Save impact

- `SaveData.saveVersion` is now `6`.
- v5 saves migrate by adding `playerProgress.skillLevels = {}`.
- New saves start with empty skill levels; missing skill levels still read as level 1.

### Remaining

- Recommended equip is manual one-click only; no automatic equip after drops yet.
- Skill upgrade cost is code-defined gold-only first slice; no skill tree, respec, unlock levels, or skill configuration page was added.
- Chapter 2 content is available in seed data, but cross-chapter automatic progression remains a later system.

## S26-S30 Auto Battle Progression Polish - 2026-06-24

### Added files

- `lib/systems/battle/battle_readiness_service.dart`
- `lib/systems/equipment/auto_enhancement_service.dart`
- `test/battle_readiness_service_test.dart`
- `test/auto_enhancement_service_test.dart`

### Modified files

- `assets/data/chapters.json`
- `assets/data/monsters.json`
- `lib/core/save/player_save_provider.dart`
- `lib/features/battle/battle_page.dart`
- `lib/features/equipment/equipment_page.dart`
- `lib/models/auto_battle_run_state.dart`
- `lib/systems/auto_battle/auto_battle_service.dart`
- `lib/systems/inventory/auto_salvage_service.dart`
- `test/auto_battle_service_test.dart`
- `test/auto_salvage_service_test.dart`
- `test/battle_page_widget_test.dart`
- `test/chapter_service_test.dart`
- `test/equipment_page_widget_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- S26: Added battle readiness estimates for progression stages, including low damage and low survivability detection.
- S26: Auto battle can farm the highest cleared farmable stage when the current progression stage looks unsafe.
- S26: BattlePage now displays progress mode, unsafe farming state, and last settlement summary fields.
- S27: Added recommended equipment enhancement flow for equipped gear, prioritizing the main weapon when possible.
- S27: PlayerSaveController can enhance recommended equipped gear and EquipmentPage exposes the action.
- S28: Auto salvage now preserves the best current-class candidate per slot as a future replacement.
- S29: Expanded chapter 1 from 5 stages to 10 stages and added supporting monster configs.
- S30: Added BattlePage and EquipmentPage smoke coverage for the new summary and recommended enhancement UI.

### Tests

- Added BattleReadinessService coverage for safe encounters, low damage, low survivability, and armor mitigation.
- Added AutoEnhancementService coverage for recommendation, successful enhancement, insufficient resources, and empty loadouts.
- Added AutoBattleService coverage for unsafe progression fallback and repeated fallback farming.
- Added AutoSalvageService coverage for best-slot protection.
- Updated ChapterService tests for the 10-stage chapter 1 structure.
- Targeted tests passed: `I:\dev\flutter\bin\flutter.bat test test\battle_page_widget_test.dart test\equipment_page_widget_test.dart test\chapter_service_test.dart test\seed_data_integration_test.dart test\monster_system_test.dart`

### Save impact

- `SaveData.saveVersion` remains `5`.
- `farmingBecauseUnsafe` is runtime auto battle state only.
- Recommended enhancement uses existing equipment enhancement persistence.
- Chapter and monster seed data changed, but no SaveData schema migration was required.

### Remaining

- Readiness is still an estimate, not a full combat forecast.
- No offline rewards, abyss system, automatic skill tuning, auto equip, art pass, or complex monster AI were added.

## S25 Failed Progression Fallback Farming - 2026-06-24

### Added files

- No new production files; this slice extends existing auto battle run state, auto battle orchestration, and BattlePage summary display.

### Modified files

- `lib/models/auto_battle_run_state.dart`
- `lib/systems/auto_battle/auto_battle_service.dart`
- `lib/features/battle/battle_page.dart`
- `test/auto_battle_service_test.dart`
- `test/battle_page_widget_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added `farmingBecauseBattleFailed` to `AutoBattleRunState`.
- Updated `AutoBattleService` so a failed current progression battle can fall back to the highest cleared farmable stage.
- Fallback farming settles rewards and saves SaveData, but does not advance `currentStageId`.
- `runManyBattles` can now continue farming after progression defeat instead of stopping immediately, as long as a survivable cleared stage exists.
- Existing `battleFailed` stop behavior is preserved when no cleared farmable stage exists or fallback farming also fails.
- BattlePage auto battle summary now displays battle-failure farming state and guidance text.

### Tests

- Added AutoBattleService coverage for progression defeat fallback farming.
- Added AutoBattleService coverage for repeated fallback farming until `maxBattlesReached`.
- Added BattlePage widget coverage for battle-failed farming status and warning text.
- Targeted tests passed: `I:\dev\flutter\bin\flutter.bat test test/auto_battle_service_test.dart test/battle_page_widget_test.dart`

### Save impact

- `SaveData.saveVersion` remains `5`.
- `farmingBecauseBattleFailed` is runtime auto battle state only.
- No new persisted SaveData fields or migrations were added.

### Remaining

- The system does not yet estimate whether a stage is survivable before trying it.
- No automatic gear optimization, skill loadout changes, offline rewards, abyss systems, or combat AI were added.

## S24 Combat Survival First Slice - 2026-06-24

### Added files

- No new production files; this slice extends the existing battle, auto battle, and BattlePage layers.

### Modified files

- `lib/models/battle_state.dart`
- `lib/systems/skills/skill_runtime.dart`
- `lib/systems/battle/battle_simulator.dart`
- `lib/features/battle/battle_page.dart`
- `test/battle_simulator_test.dart`
- `test/battle_settlement_service_test.dart`
- `test/auto_battle_service_test.dart`
- `test/battle_page_widget_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added player survival fields to `BattleState`: `playerMaxHp`, `playerCurrentHp`, `playerArmor`, monster attack cooldown, and monster attack interval.
- Added `BattleState` / `BattleLogEntry` JSON round-trip support and `SkillRuntime` JSON helpers for battle runtime persistence/debugging.
- Added monster counterattack damage to `BattleSimulator` with simple armor mitigation and minimum damage.
- Added defeat result handling: player HP cannot drop below `0`, defeat finishes the battle, and finished battles no longer tick.
- Added combat logs for `monsterAttack`, `playerHp`, `playerDeath`, and `defeat`.
- Confirmed non-victory settlement remains blocked; defeat battles do not grant rewards or drops.
- Updated `AutoBattleService` coverage for `battleFailed` stop behavior after defeat.
- Added BattlePage Player HP display and defeat warning for manual and auto battle flows.

### Tests

- Added BattleSimulator tests for player HP initialization, JSON round trip, monster attacks, HP floor, armor mitigation, defeat logs, and victory preservation.
- Added BattleSettlementService defeat test to prove no experience, gold, materials, or equipment drops are granted.
- Added AutoBattleService tests for stopping on battle failure without saving rewards or progressing stages.
- Added BattlePage widget tests for Player HP, defeat status, defeat warning, and auto battle `battleFailed` display.
- Targeted tests passed: `I:\dev\flutter\bin\flutter.bat test test/battle_simulator_test.dart test/battle_settlement_service_test.dart test/auto_battle_service_test.dart test/battle_page_widget_test.dart`

### Save impact

- `SaveData.saveVersion` remains `5`.
- `BattleState` is runtime state, not a persisted SaveData field.
- No new SaveData fields or migrations were added.

### Remaining

- No dodge, block, shield, lifesteal, status effects, monster skills, offline rewards, abyss systems, art, animation, or commercial systems were added.
- Monster behavior remains a fixed-interval basic attack only.

## S23 Equipment Enhancement First Slice - 2026-06-24

### Added files

- `assets/data/enhancement_config.json`
- `lib/models/enhancement_config.dart`
- `lib/systems/equipment/equipment_enhancement_service.dart`
- `lib/systems/equipment/quality_rank.dart`
- `test/equipment_enhancement_service_test.dart`
- `test/quality_rank_test.dart`

### Modified files

- `assets/data/quality_config.json`
- `lib/core/save/player_save_provider.dart`
- `lib/core/theme/quality_theme.dart`
- `lib/features/equipment/equipment_page.dart`
- `lib/features/equipment/equipment_page_view_model.dart`
- `lib/models/equipment_instance.dart`
- `lib/systems/equipment/quality_service.dart`
- `lib/systems/inventory/auto_salvage_service.dart`
- `lib/systems/stats/equipment_stat_modifier_service.dart`
- `test/auto_salvage_service_test.dart`
- `test/equipment_page_widget_test.dart`
- `test/equipment_template_service_test.dart`
- `test/seed_data_integration_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added `EnhancementConfig` and `assets/data/enhancement_config.json`.
- Added `EquipmentEnhancementService` with cost lookup, max level handling, material checks, and deterministic +0 to +10 enhancement.
- Added `enhanceLevel` to `EquipmentInstance` with JSON round trip, legacy default `0`, and `copyWith`.
- Enhancement consumes `gold` and `salvage_dust` from inventory materials.
- Enhanced equipment increases base stat contribution through `EquipmentStatModifierService`; affixes remain unchanged.
- EquipmentPage detail dialog now shows Enhance Level, next cost, and an `Enhance` action.
- PlayerSaveController can enhance equipment and persist updated `equipmentInstances`.
- Enhanced equipment is protected from auto salvage.
- S22.1: implemented `maxInventoryUsageBeforeSalvage`.
- S22.1: added `AutoSalvageReport.keptCount`; `rejectedCount` remains as deprecated compatibility for the old kept-count meaning.
- S22.1: EquipmentPage now explains that auto salvage scans all matching backpack equipment, not only new drops.
- S22.1: canonical quality order is now `normal / magic / rare / epic / legendary / ancient / mythic / abyss`; legacy `forbidden` ranks as `ancient` for compatibility.

### Tests

- Added tests for `EquipmentInstance.enhanceLevel` JSON round trip and legacy compatibility.
- Added tests for enhancement config parsing, costs, max level, and seed data loading.
- Added tests for enhancement success, material consumption, insufficient materials, max level, missing equipment, and final stat increases.
- Added tests for auto salvage threshold behavior and enhanced-equipment protection.
- Added tests for canonical quality rank ordering and legacy `forbidden` compatibility.
- Added EquipmentPage widget coverage for enhancement UI and +1 persistence.
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`
- 通过：`I:\dev\flutter\bin\flutter.bat test`

### Save impact

- `SaveData.saveVersion` remains `5`.
- `EquipmentInstance.enhanceLevel` is an internal equipment-instance field with default `0`; old equipment instances load safely without migration.
- No new top-level SaveData fields were added.

### Remaining

- No enhancement failure chance, downgrade, protection stone, reroll, socketing, or deep abyss systems were added.
- Enhancement UI is intentionally minimal and can be polished later.

## S22 Auto Salvage and Equipment Filtering First Slice - 2026-06-24

### Added files

- `lib/models/auto_salvage_config.dart`
- `lib/systems/inventory/auto_salvage_service.dart`
- `test/auto_salvage_service_test.dart`

### Modified files

- `lib/models/save_data.dart`
- `lib/models/auto_battle_run_state.dart`
- `lib/systems/save/save_migration_service.dart`
- `lib/systems/battle/battle_settlement_service.dart`
- `lib/systems/auto_battle/auto_battle_service.dart`
- `lib/core/save/player_save_provider.dart`
- `lib/features/battle/battle_page.dart`
- `lib/features/equipment/equipment_page_view_model.dart`
- `lib/features/equipment/equipment_page.dart`
- `test/auto_battle_service_test.dart`
- `test/equipment_page_widget_test.dart`
- `test/save_service_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added `AutoSalvageConfig` with persistent defaults for disabled auto salvage, minimum quality, legendary protection, locked/equipped protection, and build-score protection.
- Added `AutoSalvageService` and `AutoSalvageReport` for keep/salvage decisions, batch processing, gained materials, and reason tracking.
- Integrated optional auto salvage into `AutoBattleService` after each accepted settlement and before saving the final SaveData.
- Added auto battle summary counters for auto salvaged equipment and auto salvage materials.
- Added EquipmentPage filtering and sorting first slice: All, Equipped, Locked, Rare+, Legendary+, Current Class Usable; Newest first, Quality high to low, Build match score high to low.
- Added manual batch salvage first slice through `Salvage filtered low-value`.
- Preserved `autoSalvageConfig` when settlement, equipment generation, manual salvage, and batch salvage write inventory state back to SaveData.

### Tests

- Added tests for `AutoSalvageConfig` JSON round trip and legacy default config compatibility.
- Added tests for normal/magic auto salvage, rare quality retention, locked/equipped protection, legendary retention, high build-match retention, equipment removal, and salvage dust gain.
- Added AutoBattleService test coverage for accumulated auto salvaged equipment and materials.
- Added EquipmentPage widget coverage for auto salvage settings and manual batch salvage.
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`
- 通过：`I:\dev\flutter\bin\flutter.bat test`

### Save impact

- `saveVersion` upgraded from 4 to 5.
- `InventorySave` now persists `autoSalvageConfig`.
- v1-v4 saves migrate to v5 and receive default disabled auto salvage settings.

### Remaining

- Auto salvage settings UI is intentionally minimal: switch, minimum quality, and minimum BD score.
- No offline rewards, auto timers, equipment enhancement, deep abyss systems, server sync, or commercial systems were added.

## S21 Repeat Farm Previous Cleared Stage - 2026-06-24

### Added files

- None.

### Modified files

- `lib/models/auto_battle_run_state.dart`
- `lib/systems/chapters/chapter_service.dart`
- `lib/systems/auto_battle/auto_battle_service.dart`
- `lib/features/battle/battle_page.dart`
- `test/chapter_service_test.dart`
- `test/auto_battle_service_test.dart`
- `test/battle_page_widget_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added fallback farming when current progression stage level is too high.
- Added highest farmable stage selection through `ChapterService.highestFarmableStage`.
- Added `highestClearedStage`, `currentProgressionStage`, `shouldFarmPreviousStage`, `stageById`, and `maybeNextProgressionStage` helpers.
- Added auto battle farming state fields: `farmingStageId`, `farmingBecauseLevelTooLow`, and `progressionStageId`.
- Updated `AutoBattleService.runOneBattle` so a single completed battle returns `isRunning = false` and `stopReason = maxBattlesReached` when no error stop reason exists.
- Kept `runManyBattles` continuous behavior intact while allowing each new battle to re-check whether the progression stage is now enterable after level-up.
- Farming a previous stage grants normal settlement rewards but does not advance `currentStageId`.
- Added BattlePage farming status display and a warning when auto battle is farming because the current progression stage level is too high.

### Tests

- Added tests for highest farmable stage selection and progression-stage farming checks.
- Added tests for single-battle return semantics.
- Added tests for farming previous cleared stages, farming rewards, stable `currentStageId`, level-up returning to progression, no farmable stage fallback, and final-stage chapter completion.
- Added widget coverage for BattlePage farming status display.
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`
- 通过：`I:\dev\flutter\bin\flutter.bat test`

### Save impact

- No persistent SaveData fields were added.
- `saveVersion` remains unchanged.
- New auto battle farming fields are runtime UI/service state only.

### Remaining

- Stop Auto Battle still only updates state after synchronous execution returns.
- Offline rewards, background timers, auto salvage, equipment enhancement, and abyss systems remain out of scope.

## S19.5 World Bible and Naming Guide / 世界观与命名规范 - 2026-06-24

### 新增文件

- `docs/world_bible_v0.1.md`

### 修改文件

- `CHANGELOG_DEV.md`

### 完成内容

- 新增轻量世界观文档，明确拾遗者、深渊、遗装、魂核与五个职业的来源。
- 定义亡骨系、瘟疫系、血月系、灰烬系、寒霜系、圣裁腐化系、深渊系七类怪物阵营。
- 补充章节推进逻辑、暗黑刷宝风格章节名示例与装备品质世界观解释。
- 定义装备、技能、怪物、深渊领域命名规则和禁用命名风格。
- 文档中建议未来可为 `classes.json`、`chapters.json`、`monsters.json`、`equipment_templates.json`、`skills.json`、`soul_cores.json` 增加 `description` / `lore` 字段；本次不修改 schema。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 无存档结构变更，`saveVersion` 不变。

### 待处理问题

- 后续新增章节、怪物、装备、技能和魂核内容时，应优先参考本文档命名规则。

## S20 Auto Battle Run First Slice / 在线连续战斗第一版 - 2026-06-24

### 新增文件

- `lib/models/auto_battle_run_state.dart`
- `lib/systems/auto_battle/auto_battle_service.dart`
- `test/auto_battle_service_test.dart`

### 修改文件

- `lib/features/battle/battle_page.dart`
- `test/battle_page_widget_test.dart`
- `CHANGELOG_DEV.md`

### 完成内容

- 新增 `AutoBattleRunState` 和 `AutoBattleStopReason`，记录连续战斗运行状态、累计收益、最近战斗日志和停止原因。
- 新增 `AutoBattleService`，提供 `startRun`、`stopRun`、`runOneBattle`、`runManyBattles(maxBattles)`。
- `runOneBattle` 走真实链路：读取章节关卡、校验等级、创建怪物运行时、计算角色最终属性、创建 BattleState、最多 tick 100 次、胜利后调用 `BattleSettlementService` 并用 `ChapterService` 推进关卡。
- `runManyBattles` 连续执行多场战斗，累计经验、金币、材料、装备掉落数和拒绝装备数；遇到等级不足、章节完成、战斗未结束或失败会停止。
- 每场成功结算后都会调用保存回调，确保经验、金币、材料、装备实例和章节进度进入真实 SaveData。
- BattlePage 新增 `Run 1 Battle`、`Run 10 Battles`、`Stop Auto Battle`，并展示 Completed Battles、Total EXP、Total Gold、Materials gained、Dropped Equipment、Rejected Equipment、Stop Reason 和最近一场战斗日志。
- 等级不足时显示停止提示；章节完成时显示完成提示。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 无新增持久化字段，`saveVersion` 不变。
- 连续战斗运行态不持久化，只把每场结算后的现有 SaveData 奖励和章节进度保存。

### 待处理问题

- Stop 按钮第一版只更新状态，不中断同步执行中的循环。
- 暂不支持真实 timer、后台运行或离线收益；重复刷上一关已在 S21 补齐第一版。

## S19 Chapter Progression / 章节推进与怪物池第一版 - 2026-06-24

## S19 章节推进与怪物池第一版 - 2026-06-24

### 新增文件

- `assets/data/chapters.json`
- `lib/models/chapter_config.dart`
- `lib/systems/chapters/chapter_service.dart`
- `test/chapter_service_test.dart`

### 修改文件

- `lib/features/battle/battle_controller.dart`
- `lib/features/battle/battle_page.dart`
- `lib/models/save_data.dart`
- `lib/systems/config/reference_resolver.dart`
- `lib/systems/save/save_migration_service.dart`
- `test/battle_page_widget_test.dart`
- `test/save_service_test.dart`
- `test/seed_data_integration_test.dart`
- `CHANGELOG_DEV.md`

### 完成内容

- 新增 `chapters.json`，配置 `chapter_1` 和 5 个 stage。
- 新增 `ChapterConfig` / `StageConfig`，支持 stage 怪物池、等级要求、首通奖励预留与 Boss 关标记。
- 新增 `ChapterService`，支持读取当前关卡、下一关、进入等级校验和通关推进。
- BattleController 不再固定 `skeleton_grunt`，改为根据 `SaveData.playerProgress.currentChapterId/currentStageId` 选取当前 stage 的第一个怪物。
- 战斗胜利结算后，先结算 S17 奖励，再调用 `ChapterService.markStageCleared` 推进到下一关并保存。
- BattlePage 展示当前章节、关卡、怪物、Boss 状态，并在胜利后显示已推进提示。
- 配置引用校验新增章节 stage monsterIds -> monsters 表校验。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- `saveVersion` 从 3 升级到 4。
- `PlayerProgress` 新增 `currentChapterId`、`currentStageId`、`highestClearedStageId`。
- 旧存档缺失章节字段时默认兼容为 `chapter_1 / 1-1`，`highestClearedStageId` 默认为 `null`。
- v1/v2/v3 存档迁移到 v4 时会自动补齐章节进度字段。

### 待处理问题

- `firstClearRewards` 已在配置模型预留，但第一版尚未发放首通奖励。
- 多怪物 stage 第一版只取第一个怪物，后续可扩展为随机怪物池或战斗波次。
- 最后一关通关后当前关卡保持在末关，后续章节系统需要接入下一章节解锁。

## S18 Battle Page First Slice / 战斗页第一版 - 2026-06-24

## S18 战斗页第一版 - 2026-06-24

### 新增文件

- `lib/features/battle/battle_controller.dart`
- `lib/features/battle/battle_page.dart`
- `test/battle_page_widget_test.dart`

### 修改文件

- `lib/features/shell/main_shell.dart`
- `CHANGELOG_DEV.md`

### 完成内容

- 将 MainShell 的 battle tab 从占位页替换为真实 `BattlePage`。
- 新增 `BattleController`，负责创建战斗、tick 推进、自动推进到结束、胜利结算与保存。
- `BattlePage` 接入真实 `playerSaveProvider` 与 `gameDatabaseLoadProvider`。
- 第一版固定挑战 `skeleton_grunt`，完整串联角色存档、最终属性、技能配置、怪物运行时、战斗模拟与 S17 结算。
- 页面展示怪物名、怪物 HP、战斗状态、最近 20 条日志与胜利结算报告。
- 胜利后自动调用 `BattleSettlementService`，并通过 `PlayerSaveController.save` 保存奖励结果。
- 同一场战斗只允许结算一次，避免重复获得经验、金币、材料和装备。

### 测试结果

- 通过：`I:\dev\flutter\bin\flutter.bat test`
- 通过：`I:\dev\flutter\bin\flutter.bat analyze`

### 存档影响

- 无新增存档字段，`saveVersion` 不需要升级。
- 战斗页只读取现有 `SaveData`，结算后保存 S17 已支持的经验、材料与装备实例数据。

### 待处理问题

- 后续章节系统需要替换固定怪物选择。
- 后续战斗页可以加入更完整的行动队列、怪物反击展示和掉落详情。

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

## S07 Equipment Equip Rules - 2026-06-23

### Added files

- `lib/models/equipment_loadout.dart`
- `lib/systems/equipment/equipment_service.dart`
- `test/equipment_service_test.dart`

### Modified files

- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `EquipmentLoadout` with JSON round trip support.
- Added `EquipmentService.equip` and `EquipmentService.unequip`.
- Validates template/instance match, class restrictions, and minimum level before equipping.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_service_test.dart`

### Save impact

- No save schema change yet. `EquipmentLoadout` is serializable and ready for future inventory save expansion.

### Remaining

- Persist equipped loadout in save data when inventory/storage expands.
- Add ring slot selection behavior and equipment compare output.
- Connect equipment stats into `StatAggregationService`.

## S08 Affix Roll Foundation - 2026-06-23

### Added files

- `lib/models/affix_config.dart`
- `lib/systems/equipment/affix_roll_service.dart`
- `test/affix_roll_service_test.dart`

### Modified files

- `assets/data/affixes.json`
- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `AffixConfig`, roll ranges, stat modifier configs, effect configs, and rolled affix results.
- Added deterministic weighted `AffixRollService` with level filtering, allowed-tag filtering, duplicate prevention, and optional exclusive groups.
- Added stepped value rolls for numeric affixes.
- Added exclusive-group metadata to seed affixes and verified seed affixes can parse and roll.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\affix_roll_service_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat test test\seed_data_integration_test.dart`

### Save impact

- No save schema change. `EquipmentInstance.rolledAffixes` still stores ids as a placeholder until affix instance persistence is expanded.

### Remaining

- Add `AffixEffectResolver` for Issue 022.
- Translate stat affixes into `StatAggregationService` modifiers once resolver contracts are in place.

## S07/S08 Equipment Affix Generation - 2026-06-23

### Modified files

- `lib/models/affix_config.dart`
- `lib/models/equipment_instance.dart`
- `lib/systems/equipment/equipment_generation_service.dart`
- `test/equipment_generation_service_test.dart`
- `test/seed_data_integration_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added JSON support for structured rolled affixes with affix id, roll value, and exclusive group.
- Kept legacy `rolledAffixes: ["affix_id"]` save/config compatibility.
- Allowed `EquipmentGenerationService` to optionally receive `AffixRollService`.
- Generated equipment affixes from template allowed tags and quality affix ranges.
- Verified seed `rusted_blade` rolls the configured poison affix when affix rolling is enabled.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_generation_service_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- Forward save shape for equipment affixes changes from strings to objects.
- Legacy string affix ids remain readable and are normalized to structured rolled affixes on save.

### Remaining

- Translate stat affixes into `StatAggregationService` modifiers once resolver contracts are in place.
- Add equipment compare and inventory integration.

## S08 Affix Effect Resolver - 2026-06-23

### Added files

- `lib/systems/equipment/affix_effect_resolver.dart`
- `test/affix_effect_resolver_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `AffixEffectResolver` as the first Issue 022 parsing entry point.
- Resolved rolled stat modifiers into generic stat outputs.
- Resolved `apply_status` effects into status outputs.
- Resolved registered mechanic effects into event trigger outputs.
- Reported clear warnings for unknown effect ids, invalid params, and missing roll values.
- Verified seed `aff_poison_can_crit` resolves to the `poison_can_crit` event trigger.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\affix_effect_resolver_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change.

### Remaining

- Wire resolved stat outputs into a broader stat model when combat stats expand beyond hp/attack/armor.
- Connect event triggers to the future combat event system.
- Add equipment scoring on top of resolved affix and build data.

## S08 Build Tag Aggregation - 2026-06-23

### Added files

- `lib/systems/build/build_service.dart`
- `test/build_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `BuildConfig` and `BuildAssessment`.
- Added `BuildService` tag aggregation from class tags, selected skill tags, equipment template allowed tags, and rolled affix tags.
- Added first-pass built-in build archetypes for poison-shadow, summon-undead, fire-burn, frost-crit, and holy-block.
- Added mixed-build fallback when no archetype has enough signal or the top score is too close to another archetype.
- Verified seed Exile + toxic_slash + rusted_blade poison affix identifies `poison_shadow`.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\build_service_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change.

### Remaining

- Move build archetypes to JSON config if designers need live tuning.
- Surface current build label and tag weights in the future BD UI.

## S08 Build Equipment Scoring - 2026-06-23

### Added files

- `lib/systems/build/build_score_service.dart`
- `lib/systems/build/equipment_compare_service.dart`
- `test/build_score_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `BuildScoreService` to score equipment against a current `BuildAssessment`.
- Kept BD match score separate from raw attack score.
- Matched equipment template tags and rolled affix tags against current build tag weights.
- Penalized rejected tags such as fire/burn on a poison-shadow build.
- Added mixed-build conservative behavior so unclear builds do not force a recommendation.
- Added `EquipmentCompareService` for candidate vs equipped match-score and attack deltas.
- Verified seed Exile poison equipment receives a positive BD match score.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\build_score_service_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change.

### Remaining

- Connect scoring to future inventory/filter systems.
- Move rejected-tag relationships to config if designers need live tuning.

## Equipment Card ViewModel Foundation - 2026-06-23

### Added files

- `lib/features/equipment/equipment_card_view_model.dart`
- `test/equipment_card_view_model_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `EquipmentCardViewModelFactory` for Issue 058's first non-UI slice.
- Exposed quality id, quality label, quality color value, base stats, affix rows, mechanic-affix highlight flags, BD match score, replacement deltas, matched/rejected tags, and recommendation labels.
- Kept equipment card widgets free of business logic by reusing `EquipmentCompareService`.
- Verified seed `rusted_blade` can produce a card view model with rare quality, poison affix, and positive BD match score.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_card_view_model_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change.

### Remaining

- Build the actual equipment page/card UI from this ViewModel.
- Add equipment detail modal once inventory data exists.
- Connect scoring to future inventory/filter systems.

## S07 Inventory Foundation - 2026-06-23

### Added files

- `lib/models/inventory_state.dart`
- `lib/systems/inventory/inventory_service.dart`
- `test/inventory_service_test.dart`

### Modified files

- `lib/models/save_data.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `InventoryState` with equipment ids, equipment capacity, and material stacks.
- Added `MaterialStack` JSON support.
- Added `InventoryService.addEquipment` with capacity-safe failure results instead of exceptions.
- Added `InventoryService.addMaterial` with material id stacking.
- Extended `InventorySave` with equipment capacity and material stacks while keeping legacy saves readable.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\inventory_service_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat test test\save_service_test.dart test\inventory_service_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- `InventorySave` now writes `equipmentCapacity` and `materials`.
- Legacy saves without those fields still load with default capacity and empty materials.

### Remaining

- Store full generated equipment instances once inventory ownership is expanded beyond ids.
- Build equipment page/card UI from inventory contents.

## S07 Loot To Inventory - 2026-06-23

### Added files

- `lib/models/loot_drop.dart`
- `lib/systems/inventory/loot_inventory_service.dart`
- `test/loot_inventory_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `LootDrop` for equipment, material, and unsupported/other drop results.
- Added `LootInventoryService` to apply loot drops through `InventoryService`.
- Equipment loot now enters inventory by instance id.
- Material loot stacks by material id.
- Full equipment inventory rejects equipment drops without crashing while still accepting material drops.
- Unsupported types such as future soul core drops are safely reported as unsupported.
- Verified seed generated `rusted_blade` can enter inventory as loot.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\loot_inventory_service_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No additional save schema change beyond the inventory fields added in the previous slice.

### Remaining

- Store full generated equipment instances once inventory ownership expands beyond ids.
- Build equipment page/card UI from inventory contents.

## S07 Drop Pool Rolling - 2026-06-23

### Added files

- `lib/systems/drop/drop_pool_service.dart`
- `test/drop_pool_service_test.dart`

### Modified files

- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Added `DropPoolService` to roll weighted entries from `drop_pools`.
- Added deterministic seed behavior.
- Added quantity range rolling.
- Mapped equipment entries to equipment loot drops and material entries to material loot drops.
- Kept unsupported entries, such as future soul cores, as safe `other` loot drops.
- Verified seed `drop_chapter_1` can roll a loot drop.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\drop_pool_service_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change.

### Remaining

- Add material seed data when material economy starts.
- Build equipment page/card UI from inventory contents.

## S10 Equipment Page UI - 2026-06-24

### Added files

- `lib/features/equipment/equipment_page.dart`
- `lib/features/equipment/equipment_page_view_model.dart`
- `test/equipment_page_widget_test.dart`

### Modified files

- `lib/features/shell/main_shell.dart`
- `lib/features/debug/debug_page.dart`
- `CHANGELOG_DEV.md`

### Completed

- Replaced the equipment placeholder tab with a real `EquipmentPage`.
- Added `equipmentInventoryProvider` as the current UI inventory source.
- Equipment page reads `InventoryState.equipmentInstanceIds` and resolves full `EquipmentInstance` values from `equipmentInstances`.
- Added a page view-model factory so Widgets call existing ViewModel/services instead of recalculating equipment stats or BD score.
- Equipment cards show name, quality, slot, base stats, affixes, BD score, recommended tags, and warning tags.
- Added a detail dialog with full base stats, affix roll values, matched/rejected tags, and replacement deltas.
- Added an empty inventory state.
- Stabilized the debug page loading state so the config section title remains visible while data is loading.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_page_widget_test.dart test\widget_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change.

### Remaining

- Wire `equipmentInventoryProvider` to the real loaded save once app-level save state is introduced.
- Add equip/lock/salvage actions on top of the read-only equipment page.
- Add material seed data when material economy starts.

## S09 Character Final Stats - 2026-06-24

### Added files

- `lib/systems/stats/equipment_stat_modifier_service.dart`
- `lib/systems/stats/character_final_stats_service.dart`
- `test/character_final_stats_service_test.dart`

### Modified files

- `lib/models/stat_block.dart`
- `lib/systems/stats/stat_aggregation_service.dart`
- `test/stat_aggregation_service_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Extended `StatBlock` and `StatKey` beyond legacy `hp`, `attack`, and `armor`.
- Added support for `crit_chance`, `crit_damage`, `attack_speed`, elemental damage stats, `summon_damage`, `block_chance`, and `shield`.
- Kept legacy `StatBlock(hp:, attack:, armor:)` construction and old tests compatible.
- Added `EquipmentStatModifierService` to convert equipment base stats and resolved affix stat modifiers into `StatModifier` values.
- Added `CharacterFinalStatsService` to aggregate character level stats, equipped equipment base stats, and equipment affixes.
- Missing equipped equipment instances now return warnings instead of throwing.
- All supported stats now receive a `StatBreakdown` for future character and equipment detail views.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\stat_aggregation_service_test.dart test\character_final_stats_service_test.dart test\level_service_test.dart test\character_service_test.dart test\affix_effect_resolver_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change.

### Remaining

- Wire final stats into character/equipment UI.
- Add material seed data when material economy starts.
- Build equipment page/card UI from inventory contents.

## S07 Equipment Loot Materialization - 2026-06-23

### Added files

- `lib/systems/drop/equipment_loot_materialization_service.dart`
- `test/equipment_loot_materialization_service_test.dart`

### Modified files

- `lib/models/loot_drop.dart`
- `test/seed_data_integration_test.dart`
- `docs/开发需求拆解.md`
- `CHANGELOG_DEV.md`

### Completed

- Extended `LootDrop.equipment` to preserve quantity while keeping the default quantity at 1.
- Added `EquipmentLootMaterializationService`.
- Equipment template loot now generates full `EquipmentInstance` values through `EquipmentGenerationService`.
- Generated equipment is converted into inventory-ready equipment instance drops.
- Non-equipment loot passes through unchanged.
- Verified seed `drop_chapter_1` can roll `rusted_blade`, materialize it, and add it to inventory.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_loot_materialization_service_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- No save schema change in this slice.
- Inventory still stores equipment instance ids; full equipment instance ownership/persistence remains to be added.

### Remaining

- Add material seed data when material economy starts.
- Build equipment page/card UI from inventory contents.

## S08 Equipment Instance Persistence - 2026-06-24

### Added files

- `lib/systems/inventory/equipment_instance_store.dart`
- `lib/systems/inventory/equipment_loot_commit_service.dart`
- `test/equipment_loot_commit_service_test.dart`

### Modified files

- `lib/models/inventory_state.dart`
- `lib/models/save_data.dart`
- `lib/systems/equipment/equipment_service.dart`
- `test/inventory_service_test.dart`
- `test/equipment_service_test.dart`
- `test/save_service_test.dart`
- `test/seed_data_integration_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Extended `InventoryState` and `InventorySave` with `equipmentInstances` and `lockedEquipmentInstanceIds`.
- Added `EquipmentInstanceStore` for add, remove, find, require, ordered listing, and containment checks.
- Added `EquipmentLootCommitService` to commit generated equipment instances and passthrough loot without orphan records.
- Full generated equipment instances now persist alongside `equipmentInstanceIds`.
- Duplicate equipment instance commits are idempotent.
- Full equipment bags reject new generated instances when full without saving orphan `EquipmentInstance` values.
- `EquipmentService` can equip by inventory instance id and rejects missing ids before class and level validation.
- Verified save/load preserves `templateId`, `qualityId`, `rolledBaseStats`, and `rolledAffixes`.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\inventory_service_test.dart test\equipment_loot_commit_service_test.dart test\equipment_service_test.dart test\save_service_test.dart test\seed_data_integration_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`

### Save impact

- Save schema now includes optional `equipmentInstances` and `lockedEquipmentInstanceIds`.
- `saveVersion` remains `3` because old saves read these fields as an empty map/list.
- Existing id-only inventory saves remain valid.

### Remaining

- Add material seed data when material economy starts.
- Build equipment page/card UI from inventory contents.

## S11 Equipment Page SaveData Integration - 2026-06-24

### Added files

- `lib/core/save/player_save_provider.dart`

### Modified files

- `lib/main.dart`
- `lib/features/equipment/equipment_page.dart`
- `test/equipment_page_widget_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added `saveServiceProvider` and `playerSaveProvider` as the app-level SaveData access point.
- Wired production startup to Hive-backed `SaveService` with backup storage.
- Removed the temporary equipment inventory provider from `EquipmentPage`.
- Equipment page now renders from the current `SaveData.inventory` through `InventoryState`.
- Added loading, creating, and save-error states for missing or pending saves.
- Added a debug-only "generate test equipment" action.
- Test equipment generation now uses the formal chain: `DropPoolService` -> `EquipmentLootMaterializationService` -> `EquipmentLootCommitService` -> `SaveService.save`.
- Added conversion helpers between `InventorySave` and `InventoryState`.
- Verified generated equipment remains visible after SaveService reload.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\equipment_page_widget_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat test test\widget_test.dart test\save_service_test.dart`

### Save impact

- No save schema change.
- Existing `InventorySave` full equipment instance fields are now consumed by the real equipment page.
- App startup now persists saves through Hive instead of the previous UI-only temporary inventory.

### Remaining

- Add equip, lock, and salvage actions on top of the real equipment inventory page.
- Surface save/debug status in the Debug page after broader save management UI is introduced.
- Add material seed data when material economy starts.

## S12 Equipment Page Basic Actions - 2026-06-24

### Added files

- `lib/systems/inventory/equipment_inventory_action_service.dart`

### Modified files

- `lib/core/save/player_save_provider.dart`
- `lib/features/equipment/equipment_page.dart`
- `lib/features/equipment/equipment_page_view_model.dart`
- `lib/models/inventory_state.dart`
- `lib/models/save_data.dart`
- `test/equipment_page_widget_test.dart`
- `test/inventory_service_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- `EquipmentPageViewModelFactory.create` now requires an explicit `classId`.
- Equipment page passes `saveData.playerProgress.currentClassId` into the ViewModel factory.
- Added persisted `equipmentLoadout` to `InventoryState` and `InventorySave`.
- Old saves without `equipmentLoadout` still read as an empty loadout.
- Added `lockEquipment`, `unlockEquipment`, and `isLocked` helpers.
- Added `EquipmentInventoryActionService` for salvage rules.
- Locked equipment and equipped equipment cannot be salvaged.
- Salvage removes both equipment id and full `EquipmentInstance`.
- Salvage currently grants `salvage_dust x1`.
- Equipment detail dialog now exposes equip, lock/unlock, and salvage actions.
- Equip uses `EquipmentService.equipFromInventory` with current save class and level validation.
- Equipment actions save through `SaveService.save` via `PlayerSaveController`.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\inventory_service_test.dart test\equipment_page_widget_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`
- Passed: `I:\dev\flutter\bin\flutter.bat test`

### Save impact

- `InventorySave` now writes optional `equipmentLoadout`.
- `saveVersion` remains `3` because old saves read this field as an empty loadout.

### Remaining

- Tune salvage rewards by quality and level once material economy is specified.
- Add bulk salvage and locked-item filters after the equipment page grows list controls.
- Surface equipped-slot state in future character/final-stats UI.

## S13 Character Page First Slice - 2026-06-24

### Added files

- `lib/features/character/character_page.dart`
- `test/character_page_widget_test.dart`

### Modified files

- `lib/features/shell/main_shell.dart`
- `CHANGELOG_DEV.md`

### Completed

- Replaced the character tab placeholder with a real `CharacterPage`.
- Character page reads `playerSaveProvider` and `gameDatabaseLoadProvider`.
- Restores `CharacterState` from the current `SaveData`.
- Converts `InventorySave` into `InventoryState`.
- Uses `CharacterFinalStatsService` to compute final stats from character growth and equipped gear.
- Displays current class, level, experience, base stats, final stats, equipped slots, and stat breakdowns.
- Missing equipped equipment instances now surface warning banners and missing slot text instead of crashing.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\character_page_widget_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat test test\widget_test.dart`
- Passed: `I:\dev\flutter\bin\flutter.bat analyze`
- Passed: `I:\dev\flutter\bin\flutter.bat test`

### Save impact

- No save schema change.
- Character page consumes existing `SaveData.playerProgress` and `InventorySave.equipmentLoadout`.

### Remaining

- Add richer slot labels and equipment comparison summaries.
- Add collapsible breakdown sections after the page needs denser presentation.
- Wire character page into future class switching and unlock systems.

## S14 Skill Runtime System - 2026-06-24

### Added files

- `lib/models/skill_config.dart`
- `lib/models/skill_loadout.dart`
- `lib/systems/skills/skill_service.dart`
- `lib/systems/skills/skill_runtime.dart`
- `lib/systems/skills/skill_effect_preview_service.dart`
- `test/skill_runtime_system_test.dart`

### Modified files

- `lib/models/save_data.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added strong `SkillConfig` and `SkillEffectConfig` models for records loaded from `assets/data/skills.json`.
- Added `SkillService` for requiring skills, listing skills by class, filtering by tag, and validating class ownership.
- Added `SkillRuntime` for cooldown state, ticking, cast readiness, and entering cooldown after cast.
- Added `SkillLoadout` with active, passive, and ultimate slots plus JSON round-trip support.
- Enforced loadout JSON validation for up to 3 active skills and up to 3 passive skills.
- Extended `PlayerProgress` with persisted `skillLoadout`.
- Old saves without `skillLoadout` now default to the current class base skill.
- Added `SkillEffectPreviewService` to preview direct skill damage from `ComputedStats.attack`.
- Existing `deal_damage` skill effects are treated as the current direct-damage preview source.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\skill_runtime_system_test.dart`

### Save impact

- `PlayerProgress` now writes optional `skillLoadout`.
- `saveVersion` remains `3` because old saves missing `skillLoadout` are filled during `PlayerProgress.fromJson`.

### Remaining

- Add skill equip/change actions after the skill page or character skill panel is specified.
- Expand preview formulas when non-direct effects, status effects, summons, and resource costs enter combat runtime.
- Add UI only after S14 runtime contracts settle.

## S15 Monster System - 2026-06-24

### Added files

- `assets/data/monsters.json`
- `lib/models/monster_config.dart`
- `lib/models/monster_runtime.dart`
- `lib/systems/monsters/monster_service.dart`
- `lib/systems/monsters/monster_factory.dart`
- `test/monster_system_test.dart`

### Modified files

- `lib/systems/config/reference_resolver.dart`
- `test/seed_data_integration_test.dart`
- `CHANGELOG_DEV.md`

### Completed

- Added seed monster data for `skeleton_grunt`, `plague_rat`, `blood_cultist`, `abyss_imp`, and `training_dummy`.
- Added `MonsterConfig` with level, tags, base stats, rewards, drop pool binding, optional skills, and optional resistances.
- Added `MonsterService` for requiring monsters, filtering by tag, filtering by level range, and validating drop pool references.
- Added global `ReferenceResolver` validation for monster `dropPoolId`.
- Added `MonsterRuntime` with hp, attack, armor, tags, alive checks, damage, optional healing, and JSON round-trip support.
- Added `MonsterFactory` for creating runtime monsters from config with simple level scaling.
- Verified real seed monster data can create a runtime monster and bind to `drop_chapter_1`.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\monster_system_test.dart test\seed_data_integration_test.dart`

### Save impact

- No save schema change.
- Monster runtime state is not persisted yet; future combat/encounter systems can decide when to store encounter snapshots.

### Remaining

- Add combat encounter orchestration after automatic battle requirements are specified.
- Expand monster skills and resistance formulas when the combat resolver starts consuming them.
- Add monster-specific drop pools once progression chapters and enemy families are defined.

## S16 Battle Simulator First Slice - 2026-06-24

### Added files

- `lib/models/battle_state.dart`
- `lib/systems/battle/battle_simulator.dart`
- `test/battle_simulator_test.dart`

### Modified files

- `CHANGELOG_DEV.md`

### Completed

- Added immutable `BattleState` as the first battle-page data source.
- Added `BattleLogEntry`, `BattleResult`, and `BattleLogType`.
- Added `BattleSimulator.createBattle` to create a battle from `CharacterState`, `ComputedStats`, `SkillLoadout`, `MonsterRuntime`, and `SkillService`.
- Battle creation initializes active `SkillRuntime` values and snapshots active `SkillConfig` values into the state.
- Added `BattleSimulator.tick` to advance elapsed time and skill cooldowns.
- The simulator casts the first ready active skill by loadout order.
- If no active skill is ready, the simulator performs a basic attack.
- Skill and basic attack damage use `ComputedStats.finalStats.attack`.
- Damage now applies the first simple armor formula: `rawDamage * (100 / (100 + armor))`, with minimum damage of 1.
- Monster death marks the battle as `victory`.
- Battle logs now cover battle start, skill cast, basic attack, damage, monster remaining hp, monster death, and victory.
- Monster counterattack is intentionally limited to a simple log placeholder when the monster has attack.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\battle_simulator_test.dart`

### Save impact

- No save schema change.
- `BattleState` is not persisted yet; future battle/idle systems can decide whether to store current encounters or only resolved reports.

### Remaining

- Add battle reward and drop settlement after the reward contract is specified.
- Add monster action resolution once enemy skill behavior is defined.
- Add battle page UI after the simulation state is stable enough to render.

## S17 Battle Settlement System - 2026-06-24

### Added files

- `lib/models/battle_settlement_report.dart`
- `lib/systems/battle/battle_drop_resolution_service.dart`
- `lib/systems/battle/battle_settlement_service.dart`
- `test/battle_settlement_service_test.dart`

### Modified files

- `CHANGELOG_DEV.md`

### Completed

- Added `BattleSettlementService` as a separate service from `BattleSimulator`.
- Added `BattleSettlementReport` with acceptance state, reason, gained experience, gained gold, gained materials, generated equipment, rejected equipment, level-up state, new level, and settled `SaveData`.
- Victory is required before rewards can be settled.
- Non-victory battles return `accepted = false` and leave `SaveData` unchanged.
- Monster experience rewards now flow through `LevelService.addExperience`.
- Level-up state and new level are reported for future battle result UI.
- Monster gold is stored as material `gold`.
- Monster material rewards are merged into `InventorySave.materials`.
- Added `BattleDropResolutionService` to keep drop compatibility filtering outside the simulator and settlement core.
- Drop pools are rolled through `DropPoolService`.
- Equipment drops are materialized through `EquipmentLootMaterializationService`.
- Generated equipment is committed through `EquipmentLootCommitService`.
- Full equipment bags reject generated equipment without saving orphan instances.
- Real seed `skeleton_grunt` settlement now grants experience, gold, and compatible equipment drops through the actual data chain.

### Tests

- Passed: `I:\dev\flutter\bin\flutter.bat test test\battle_settlement_service_test.dart`

### Save impact

- No save schema change.
- `saveVersion` remains `3`.
- Gold and monster materials reuse the existing `InventorySave.materials` list, so old saves remain compatible without migration.

### Remaining

- Add battle result UI after settlement report presentation is specified.
- Add explicit resource/currency save structure later if gold needs to leave the generic materials list.
- Expand settlement to support soul cores and non-equipment reward types when those inventory systems are specified.
