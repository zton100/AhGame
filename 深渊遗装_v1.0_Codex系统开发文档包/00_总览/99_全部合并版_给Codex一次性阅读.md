# 《深渊遗装》v1.0 全部合并版

> 如果 Codex 一次只能读取少量文件，请优先上传本文件；如果可以读取文件夹，请按 README 的拆分文档逐个执行。



---

# 《深渊遗装》v1.0 Codex 系统开发文档包

本包用于直接交给 Codex 分阶段开发。它不是概念 PDR，而是面向实现的系统开发说明。

## 先读顺序

1. `00_总览/00_项目范围与开发原则.md`
2. `00_总览/01_开发顺序总览.md`
3. `00_总览/02_数据驱动原则.md`
4. `03_Codex任务书/Codex_总启动提示词.md`
5. 然后按 `01_系统开发文档/S01` 到 `S28` 顺序实现。

## 当前锁定规格

- 职业：5 个
- 核心 BD：25 套
- 变种 BD：50+ 套
- 装备部位：12 个
- 装备品质：8 档
- 词缀：300 个
- 传奇装备：180 件
- 神话装备：50 件
- 深渊装备：80 件
- 套装：30 套
- 魂核：60 个
- 符文：120 个
- 普通章节：12 章
- 深渊领域：10 个
- 每领域层数：100 层
- 难度：6 档
- 等效深渊层数：6000 层

## 强制开发原则

1. **所有内容数据化**：职业、技能、装备、词缀、怪物、Boss、深渊、掉落、套装、魂核、符文都必须来自 JSON 配置。
2. **代码只做系统逻辑**：不要把装备名、技能名、词缀效果硬编码在 UI 或业务代码里。
3. **先实现引擎，再填内容**：先保证 1 个职业、1 套 BD、1 个章节、1 个深渊领域跑通，再批量扩内容。
4. **每个系统必须可测试**：所有核心计算都要能用单元测试验证。
5. **Flutter UI 与战斗逻辑分离**：页面只展示状态，战斗、掉落、数值、收益全部放在 service/system 层。
6. **保留扩展能力**：后续可加云存档、赛季、排行榜，但 v1.0 先做单机稳定版。

## 不允许 Codex 做的事

- 不允许把数值写死在 widget 里。
- 不允许每个装备写一个单独 class。
- 不允许战斗系统直接依赖页面生命周期。
- 不允许装备生成逻辑散落在多个页面。
- 不允许先做临时 Demo 再重构。要从第一版就用正式目录结构。


---

# 00_项目范围与开发原则

## 1. 项目定位

《深渊遗装》是一款竖屏暗黑风格挂机刷宝手游。核心体验不是手动操作，而是通过装备、词缀、魂核、套装、技能、天赋和符文组合形成 BD，让角色自动战斗、离线刷宝、持续推深渊。

## 2. 完整 v1.0 内容边界

```json
{
  "project_name": "深渊遗装",
  "version": "v1.0 完整项目规格",
  "platform": [
    "Android",
    "iOS 后续适配"
  ],
  "tech_stack": [
    "Flutter",
    "Dart",
    "Riverpod 或 Provider",
    "Hive 或 SQLite",
    "本地 JSON 配置",
    "本地存档优先"
  ],
  "classes": 5,
  "core_builds": 25,
  "variant_builds": "50+",
  "equipment_slots": 12,
  "qualities": 8,
  "affixes": 300,
  "legendary_items": 180,
  "mythic_items": 50,
  "abyss_items": 80,
  "sets": 30,
  "soul_cores": 60,
  "runes": 120,
  "chapters": 12,
  "abyss_domains": 10,
  "abyss_layers_per_domain": 100,
  "difficulties": 6,
  "equivalent_abyss_layers": 6000,
  "boss_or_strong_enemies": "40-60+",
  "monster_units": "120-200+"
}
```

## 3. 项目不是原型

本项目从第一天开始按正式项目架构开发。允许内容分批填充，但不允许做一次性 Demo 代码。任何模块都要满足：

- 数据可配置
- 逻辑可测试
- UI 可替换
- 存档可迁移
- 未来可扩展

## 4. 核心体验优先级

1. 装备随机掉落与价值判断
2. BD 构筑与装备机制联动
3. 自动战斗与低频决策
4. 深渊多难度挑战
5. 离线收益与收菜反馈
6. 强化、洗练、镶嵌、腐化等装备养成
7. 图鉴、成就、任务、商店等长期系统

## 5. 关键体验目标

玩家每次打开游戏都应该做这几件事：

1. 领取离线收益。
2. 查看爆出的装备。
3. 锁定有潜力装备。
4. 分解垃圾装备。
5. 调整技能、装备、魂核、天赋或符文。
6. 挑战更高难度或更高层深渊。
7. 设置下一轮挂机目标。

## 6. Codex 开发约束

Codex 必须按系统顺序开发，不要一次性生成全项目。每次只实现一个明确模块，并在完成后补充测试。每个系统完成后，需要在 `CHANGELOG_DEV.md` 记录：新增文件、修改文件、完成内容、待处理问题。


---

# 01_开发顺序总览

## 1. 总原则

开发顺序必须遵循：底层模型 -> 数据配置 -> 核心计算 -> 系统服务 -> 状态管理 -> UI 展示 -> 测试与调优。

不要先做漂亮页面。对于这类装备驱动游戏，最重要的是数据结构和计算逻辑稳定。

## 2. 推荐开发阶段

### 阶段 1：项目底座

- Flutter 项目初始化
- 目录结构
- Theme 暗黑主题
- 路由
- 全局状态管理
- JSON 加载器
- 本地存档服务
- Debug 面板

### 阶段 2：核心模型

- CharacterModel
- ClassModel
- SkillModel
- EquipmentModel
- AffixModel
- MonsterModel
- BattleState
- LootResult
- SaveData

### 阶段 3：战斗与掉落

- 自动战斗循环
- 伤害公式
- 异常状态
- 怪物死亡
- 掉落池
- 装备随机生成
- 战斗日志

### 阶段 4：装备与 BD

- 装备穿戴
- 装备对比
- 词缀解析
- 魂核系统
- 套装系统
- BD 评分
- 推荐词缀

### 阶段 5：深渊与难度

- 章节推进
- 深渊领域
- 难度系数
- 层数词缀
- Boss 变体
- 首通奖励

### 阶段 6：长期系统

- 离线收益
- 自动分解/保留
- 强化/洗练/镶嵌/腐化
- 任务
- 图鉴
- 成就
- 商店

### 阶段 7：完整 UI 与体验

- 战斗页
- 装备页
- BD 页
- 深渊页
- 角色页
- 离线收益弹窗
- 装备详情弹窗
- 新手引导

## 3. 每个阶段验收方式

每个阶段至少要满足：

- App 能正常启动。
- 无红屏异常。
- 核心数据可以加载。
- 存档不会丢失。
- 相关单元测试通过。
- Debug 面板可检查关键数据。


---

# 02_数据驱动原则

## 1. 为什么必须数据驱动

本项目内容量大，包括 5 个职业、25 套核心 BD、300 个词缀、180 件传奇装备、60 个魂核、30 套套装、10 个深渊领域和 6 个难度。如果把内容写死在代码里，后期一定维护崩溃。

## 2. 数据和代码的边界

### 放在 JSON 中

- 职业基础数据
- 技能名称、类型、冷却、倍率、标签
- 装备模板、装备池、品质权重
- 词缀 id、词缀类型、数值区间、权重
- 传奇效果 id 和参数
- 魂核效果 id 和参数
- 套装件数效果
- 怪物、Boss、章节、深渊、难度、掉落池

### 放在代码中

- JSON 解析和校验
- 随机算法
- 战斗公式
- 效果解析器
- 状态机
- 存档序列化
- UI 展示
- 单元测试

## 3. 配置文件建议

```text
assets/data/classes.json
assets/data/builds.json
assets/data/skills.json
assets/data/affixes.json
assets/data/equipment_templates.json
assets/data/legendary_items.json
assets/data/soul_cores.json
assets/data/sets.json
assets/data/runes.json
assets/data/monsters.json
assets/data/bosses.json
assets/data/chapters.json
assets/data/abyss_domains.json
assets/data/difficulties.json
assets/data/drop_pools.json
assets/data/quests.json
assets/data/achievements.json
assets/data/shop_items.json
```

## 4. 配置版本

每个 JSON 文件都必须带 `schemaVersion`。存档也必须带 `saveVersion`。当字段变化时，通过 migration 兼容旧存档。

## 5. 效果系统原则

复杂效果不要写成自然语言解析，而是使用 `effectId + params`。

示例：

```json
{
  "effectId": "poison_explode_on_death",
  "params": {
    "remainingDamageRatio": 0.35,
    "radius": 4
  }
}
```

代码根据 effectId 调用对应处理器。


---

# 系统文档目录

- `S01_项目架构与目录规范系统.md`：建立正式 Flutter 项目结构，保证后续 20+ 系统可以稳定扩展。
- `S02_数据配置加载与校验系统.md`：负责加载所有 JSON 配置，做 schema 校验、id 去重、引用检查和版本检查。
- `S03_本地存档与版本迁移系统.md`：保存玩家角色、背包、装备、深渊进度、任务、图鉴、设置和离线时间，支持版本迁移。
- `S04_角色职业系统.md`：实现 5 个职业的基础属性、成长、职业标签、职业解锁和职业切换。
- `S05_BD构筑与评分系统.md`：根据职业、技能、装备、词缀、魂核、套装、天赋、符文计算当前构筑标签和匹配评分。
- `S06_属性数值与战斗公式系统.md`：统一计算角色属性、装备加成、词缀加成、技能倍率、异常状态和难度系数，防止数值散落。
- `S07_装备生成与品质系统.md`：根据部位、职业、等级、品质、掉落池随机生成装备实例，并支持装备对比和穿戴。
- `S08_词缀系统.md`：实现 300 个词缀的配置、随机、权重、标签、数值区间、效果触发和展示。
- `S09_魂核系统.md`：实现独立装备位“魂核”，作为 BD 引擎，提供改变玩法规则的核心机制。
- `S10_套装系统.md`：实现 30 套套装的收集、穿戴件数检测、2/3/4 件效果和 BD 引导。
- `S11_技能与自动释放系统.md`：实现主动技能、被动技能、终结技能的配置、冷却、资源消耗、释放条件和自动释放优先级。
- `S12_天赋系统.md`：实现每职业天赋树，提供长期成长和 BD 强化。
- `S13_符文系统.md`：实现符文获取、镶嵌、升级、组合和对技能/装备的增强。
- `S14_自动战斗系统.md`：实现挂机战斗核心循环，包括目标选择、普通攻击、技能释放、异常状态、死亡、日志和失败。
- `S15_怪物、精英词缀与 Boss 系统.md`：实现普通怪、精英怪、特殊怪、Boss 和高难度变体 Boss 的配置与战斗机制。
- `S16_掉落池与随机权重系统.md`：实现金币、材料、装备、符文、魂核、套装、深渊装备等掉落逻辑，支持难度和层数修正。
- `S17_深渊领域、难度与层数系统.md`：实现 10 个深渊领域、6 个难度、每领域 100 层，总计 6000 等效层数。
- `S18_挂机与离线收益系统.md`：实现在线挂机效率、离线收益计算、收益上限、防作弊和离线收益弹窗。
- `S19_背包、仓库、锁定、分解与自动筛选系统.md`：管理玩家所有装备和材料，支持容量、锁定、一键分解、自动保留和 BD 筛选模板。
- `S20_装备养成：强化、洗练、镶嵌、腐化系统.md`：实现装备长期养成，但不让养成系统压过刷宝本身。
- `S21_章节、地图推进与普通 Boss 系统.md`：实现 12 章主线推进，用于新手引导、系统解锁和基础装备产出。
- `S22_任务、成就与图鉴系统.md`：提供长期目标、每日回访理由和装备收集反馈。
- `S23_商店、商业化与付费边界系统.md`：实现轻商业化框架，避免破坏刷宝核心。
- `S24_UI 页面与交互系统.md`：定义全游戏 UI 架构、页面、弹窗、装备卡片、品质表现和暗黑视觉规范。
- `S25_新手引导与系统解锁系统.md`：控制玩家前 30 分钟体验，让玩家逐步理解自动战斗、装备、词缀、BD 和深渊。
- `S26_音效、震动与反馈系统.md`：统一处理掉落、强化、Boss、通关、失败、按钮等反馈，增强刷宝爽感。
- `S27_数据平衡、Debug 与调试后台系统.md`：为大体量数值调试提供内部工具，包括掉落模拟、战斗模拟、装备生成模拟和存档编辑。
- `S28_测试、验收与质量门槛系统.md`：定义项目级测试策略和每个版本合入前必须满足的验收标准。


---

# S01_项目架构与目录规范系统

## 1. 系统目的

建立正式 Flutter 项目结构，保证后续 20+ 系统可以稳定扩展。

## 2. 系统范围

- Flutter 目录结构
- 分层架构
- 依赖管理
- 路由规范
- 主题规范
- Debug 入口
- CHANGELOG_DEV 规范

## 3. 核心数据模型

- `AppConfig`
- `AppRoute`
- `AppTheme`
- `GameBootstrap`
- `DevLogEntry`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `ConfigLoader`
- `SaveService`
- `GameStateController`
- `NavigationService`
- `DebugService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 采用 feature + system 混合目录；models/services/data/pages/widgets 分层；所有 assets/data 在 pubspec 注册；所有系统 service 不依赖 Widget。
2. 所有 id 使用 snake_case 英文，展示名称可中文。
3. 任何跨系统调用必须通过明确的 service 接口。

## 6. UI / 交互接入

- 底部导航：战斗、装备、BD、深渊、角色。
- 全局暗黑主题：背景、卡片、品质色、按钮、弹窗。
- Debug 入口只在 debug mode 显示。

## 7. Codex 实现步骤

1. 创建 lib/core、lib/models、lib/systems、lib/features、lib/data、lib/ui。
2. 配置 pubspec assets/data。
3. 创建 AppTheme、AppRouter、GameBootstrap。
4. 创建 CHANGELOG_DEV.md 模板。
5. 创建第一个 smoke test，验证 app 可以启动。

## 8. 验收测试

- App 启动不报错。
- assets/data 路径可读取。
- 切换 5 个主页面不崩溃。
- Debug mode 可打开调试页。

## 8.1 边界情况

- 后续更换状态管理库时，业务 service 不应大改。

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S02_数据配置加载与校验系统

## 1. 系统目的

负责加载所有 JSON 配置，做 schema 校验、id 去重、引用检查和版本检查。

## 2. 系统范围

- JSON 加载
- schemaVersion 检查
- id 唯一性检查
- 引用完整性检查
- 配置热重载 debug
- 错误展示

## 3. 核心数据模型

- `DataFileMeta`
- `ConfigValidationError`
- `GameDatabase`
- `ReferenceCheckResult`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `DataLoader`
- `ConfigValidator`
- `GameDatabaseService`
- `ReferenceResolver`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 启动时必须先加载配置再进入主界面。
2. 任何配置错误必须在 debug 面板明确显示，不允许静默失败。
3. 正式环境遇到严重配置错误，显示安全错误页。
4. 所有配置表通过 GameDatabase 统一访问。

## 6. UI / 交互接入

- Debug 页显示配置文件数量、记录数量、错误数量。
- 配置错误列表支持按文件筛选。

## 7. Codex 实现步骤

1. 实现 DataLoader 读取 assets/data/*.json。
2. 创建 GameDatabase 聚合类。
3. 对每个表检查 schemaVersion。
4. 检查所有 id 唯一。
5. 实现引用检查：装备引用词缀、技能引用效果、掉落池引用装备。
6. 写单元测试覆盖缺字段、重复 id、无效引用。

## 8. 验收测试

- 缺失 JSON 文件时提示明确错误。
- 重复 id 能被检测。
- 无效引用能被检测。
- 正常配置可构建 GameDatabase。

## 8.1 边界情况

- 后续支持远程配置时，仍保持同一 GameDatabase 接口。

## 8.2 关联配置文件

- `assets/data/classes.json`
- `assets/data/skills.json`
- `assets/data/affixes.json`
- `assets/data/equipment_templates.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S03_本地存档与版本迁移系统

## 1. 系统目的

保存玩家角色、背包、装备、深渊进度、任务、图鉴、设置和离线时间，支持版本迁移。

## 2. 系统范围

- 本地存档
- 自动保存
- 手动备份
- 版本迁移
- 存档校验
- 异常恢复
- 多存档位预留

## 3. 核心数据模型

- `SaveData`
- `PlayerProgress`
- `InventorySave`
- `EquipmentInstanceSave`
- `SettingsSave`
- `MigrationResult`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `SaveService`
- `AutoSaveService`
- `SaveMigrationService`
- `BackupService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 存档必须使用稳定 instanceId 保存装备实例。
2. 保存装备实例时保存 rolledAffixes，不保存可被配置重新推导的冗余字段。
3. 每次退出、进入后台、关键操作后自动保存。
4. 存档损坏时优先读取最近备份。

## 6. UI / 交互接入

- 设置页提供手动保存、导出存档、导入存档预留。
- Debug 页显示 saveVersion、最后保存时间、装备实例数量。

## 7. Codex 实现步骤

1. 选择 Hive 或 SQLite。
2. 定义 SaveData 根结构。
3. 实现 load/save/delete/backup。
4. 实现 saveVersion。
5. 实现 migration v1 -> v2 示例。
6. 关键系统接入自动保存。

## 8. 验收测试

- 首次启动创建新存档。
- 穿戴装备后重启仍保留。
- 离线时间正确记录。
- 旧版本存档可迁移。
- 损坏存档不会导致白屏。

## 8.1 边界情况

- 系统时间被玩家修改时，离线收益必须有防作弊限制。

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S04_角色职业系统

## 1. 系统目的

实现 5 个职业的基础属性、成长、职业标签、职业解锁和职业切换。

## 2. 系统范围

- 5 职业
- 等级成长
- 基础属性
- 职业标签
- 职业资源
- 职业解锁
- 职业专属装备限制

## 3. 核心数据模型

- `ClassConfig`
- `CharacterState`
- `LevelCurve`
- `ClassTag`
- `ClassUnlockState`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `CharacterService`
- `ClassService`
- `LevelService`
- `StatAggregationService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 5 职业：流放者、亡语者、灰烬术士、冰痕猎手、圣裁者。
2. 职业只决定基础成长和可用技能/装备/天赋，不直接决定最终强度。
3. 等级提供基础属性和系统解锁，不应压过装备价值。

## 6. UI / 交互接入

- 角色页展示等级、职业、基础属性、当前 BD 标签。
- 职业选择页显示定位、推荐流派、解锁条件。

## 7. Codex 实现步骤

1. 定义 classes.json。
2. 创建 ClassConfig model。
3. 创建 CharacterState。
4. 实现经验和等级成长。
5. 实现职业切换或多角色选择预留。
6. 将职业标签接入装备和技能过滤。

## 8. 验收测试

- 每个职业可正常创建。
- 等级提升后属性变化正确。
- 职业限制装备不可穿戴。
- 职业标签可用于筛选技能和装备。

## 8.1 边界情况

- 未来增加职业时，不应改 UI 主逻辑，只新增配置。

## 8.2 关联配置文件

- `assets/data/classes.json`
- `assets/data/level_curves.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S05_BD构筑与评分系统

## 1. 系统目的

根据职业、技能、装备、词缀、魂核、套装、天赋、符文计算当前构筑标签和匹配评分。

## 2. 系统范围

- 核心 BD 定义
- 变种 BD 识别
- BD 标签
- BD 匹配度
- 推荐词缀
- 装备评分
- 一键预设
- BD 保存

## 3. 核心数据模型

- `BuildConfig`
- `BuildTag`
- `BuildScore`
- `BuildPreset`
- `BuildRecommendation`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `BuildService`
- `BuildScoreService`
- `PresetService`
- `RecommendationService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 核心 BD 25 套配置化。
2. 变种 BD 不写死，按标签权重自然识别。
3. BD 评分不是战力评分，而是词缀/技能/装备机制匹配度。
4. 每个 BD 需要核心标签、次级标签、排斥标签。

## 6. UI / 交互接入

- BD 页展示当前流派、核心伤害、核心生存、关键装备缺口、推荐词缀。
- 装备详情页显示对当前 BD 的匹配度。

## 7. Codex 实现步骤

1. 创建 builds.json。
2. 实现标签聚合：技能标签 + 装备标签 + 词缀标签 + 魂核标签。
3. 实现核心 BD 匹配算法。
4. 实现装备对当前 BD 的评分。
5. 实现 BD 预设保存/切换。

## 8. 验收测试

- 穿戴毒伤装备后识别暗影毒爆流倾向。
- 穿戴召唤装备后识别亡灵相关流派。
- 无明确标签时显示混合构筑。
- 装备评分不会只按战力排序。

## 8.1 边界情况

- 混合 BD 允许存在，不强行归类。

## 8.2 关联配置文件

- `assets/data/builds.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S06_属性数值与战斗公式系统

## 1. 系统目的

统一计算角色属性、装备加成、词缀加成、技能倍率、异常状态和难度系数，防止数值散落。

## 2. 系统范围

- 属性聚合
- 伤害公式
- 防御公式
- 暴击公式
- 异常公式
- 召唤物公式
- 护盾公式
- 难度修正
- 数值上限

## 3. 核心数据模型

- `StatBlock`
- `ComputedStats`
- `DamageContext`
- `DamageResult`
- `StatusEffectInstance`
- `FormulaConfig`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `StatAggregationService`
- `DamageFormulaService`
- `StatusFormulaService`
- `SummonFormulaService`
- `DifficultyModifierService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 所有最终属性由 StatAggregationService 计算。
2. 禁止页面自己计算攻击、生命、伤害。
3. 公式参数放 formula_config.json。
4. 所有百分比统一使用小数，例如 0.15 表示 15%。
5. 需要设置软上限，避免暴击率、冷却、减伤无限堆叠。

## 6. UI / 交互接入

- 属性详情页显示基础值、装备加成、天赋加成、最终值。
- Debug 面板显示完整属性拆解。

## 7. Codex 实现步骤

1. 实现 StatBlock。
2. 实现属性叠加：flat、percent、more、less。
3. 实现普通伤害、暴击、中毒、流血、燃烧、冻结、召唤。
4. 实现减伤和抗性。
5. 实现公式单元测试。

## 8. 验收测试

- 攻击 + 100 和攻击 +10% 叠加顺序正确。
- 暴击率封顶生效。
- 负面词缀可以降低属性但不产生 NaN。
- 怪物抗性正确降低伤害。

## 8.1 边界情况

- 数值溢出时使用 double 并格式化显示，避免 UI 超长。

## 8.2 关联配置文件

- `assets/data/formula_config.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S07_装备生成与品质系统

## 1. 系统目的

根据部位、职业、等级、品质、掉落池随机生成装备实例，并支持装备对比和穿戴。

## 2. 系统范围

- 12 装备位
- 8 品质
- 装备实例
- 随机基础属性
- 随机词缀
- 职业限制
- 等级限制
- 装备对比
- 穿戴卸下

## 3. 核心数据模型

- `EquipmentTemplate`
- `EquipmentInstance`
- `EquipmentSlot`
- `EquipmentQuality`
- `RolledAffix`
- `EquipmentCompareResult`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `EquipmentGenerationService`
- `EquipmentService`
- `EquipmentCompareService`
- `QualityService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 装备模板和装备实例分离。
2. 模板来自 JSON，实例是玩家实际掉落的装备。
3. 品质决定词缀数量、数值范围、特效概率。
4. 魂核是特殊装备位，但仍可复用装备实例结构。

## 6. UI / 交互接入

- 装备页按部位筛选。
- 装备详情展示基础属性、随机词缀、特殊效果、BD 匹配度、替换变化。

## 7. Codex 实现步骤

1. 定义 equipment_templates.json。
2. 实现 12 装备位枚举。
3. 实现品质枚举和颜色。
4. 实现生成装备实例。
5. 实现穿戴/卸下。
6. 实现装备对比。

## 8. 验收测试

- 生成装备拥有唯一 instanceId。
- 同模板多次掉落词缀不同。
- 职业不符不能穿戴。
- 戒指 1/2 逻辑正确。

## 8.1 边界情况

- 掉落大量装备时性能不应明显下降。

## 8.2 关联配置文件

- `assets/data/equipment_templates.json`
- `assets/data/quality_config.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S08_词缀系统

## 1. 系统目的

实现 300 个词缀的配置、随机、权重、标签、数值区间、效果触发和展示。

## 2. 系统范围

- 词缀分类
- 权重随机
- 数值 roll
- 词缀标签
- 互斥规则
- 等级门槛
- 机制词缀
- 深渊禁忌词缀

## 3. 核心数据模型

- `AffixConfig`
- `AffixTier`
- `AffixRollRange`
- `RolledAffix`
- `AffixTag`
- `AffixGroupRule`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `AffixService`
- `AffixRollService`
- `AffixEffectResolver`
- `AffixDisplayService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 词缀必须有 id、name、type、tags、minLevel、weight、rollRange。
2. 机制词缀使用 effectId + params。
3. 互斥词缀不能同时出现在同一装备上。
4. 深渊禁忌词缀必须带负面效果或代价。

## 6. UI / 交互接入

- 装备详情中机制词缀高亮。
- 筛选页可按词缀标签选择。
- BD 推荐页展示关键词缀。

## 7. Codex 实现步骤

1. 定义 affixes.json。
2. 实现词缀权重随机。
3. 实现词缀数值 roll。
4. 实现词缀互斥检查。
5. 实现词缀效果解析器。
6. 接入装备生成。

## 8. 验收测试

- 同一 group 互斥生效。
- 词缀数值在范围内。
- 低等级不会 roll 出高阶词缀。
- 筛选关键词能命中标签。

## 8.1 边界情况

- 自然语言描述只用于展示，不用于逻辑判断。

## 8.2 关联配置文件

- `assets/data/affixes.json`
- `assets/data/affix_groups.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S09_魂核系统

## 1. 系统目的

实现独立装备位“魂核”，作为 BD 引擎，提供改变玩法规则的核心机制。

## 2. 系统范围

- 魂核装备位
- 魂核品质
- 魂核效果
- 魂核升级
- 魂核标签
- 魂核与 BD 评分
- 魂核限制

## 3. 核心数据模型

- `SoulCoreConfig`
- `SoulCoreInstance`
- `SoulCoreEffect`
- `SoulCoreLevelConfig`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `SoulCoreService`
- `SoulCoreEffectService`
- `SoulCoreUpgradeService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 魂核必须是玩法引擎，不只是加数值。
2. 魂核效果必须通过 effectId 触发。
3. 每个职业至少 12 个魂核，总计 60 个。
4. 魂核允许通用，但职业专属魂核优先。

## 6. UI / 交互接入

- BD 页展示当前魂核如何影响构筑。
- 装备页中魂核单独分组。
- 战斗日志应显示关键魂核触发。

## 7. Codex 实现步骤

1. 定义 soul_cores.json。
2. 实现魂核穿戴。
3. 实现魂核效果处理器。
4. 将魂核标签接入 BD 评分。
5. 实现魂核升级预留。

## 8. 验收测试

- 瘟疫魂核能触发毒爆。
- 血月魂核能让流血暴击。
- 魂核卸下后效果消失。
- 魂核标签影响 BD 判断。

## 8.1 边界情况

- 多个核心机制冲突时，必须通过 priority 解决。

## 8.2 关联配置文件

- `assets/data/soul_cores.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S10_套装系统

## 1. 系统目的

实现 30 套套装的收集、穿戴件数检测、2/3/4 件效果和 BD 引导。

## 2. 系统范围

- 套装配置
- 套装件数效果
- 职业套装
- 通用套装
- 套装图鉴
- 套装效果激活
- 套装与词缀联动

## 3. 核心数据模型

- `SetConfig`
- `SetBonus`
- `ActiveSetBonus`
- `SetCollectionState`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `SetService`
- `SetBonusService`
- `SetCollectionService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 每套建议 4 件，激活 2/3/4 件效果。
2. 套装效果用 effectId + params。
3. 套装用于引导 BD，但不应该让散件完全失去价值。

## 6. UI / 交互接入

- 装备详情显示所属套装。
- 角色页显示已激活套装效果。
- 图鉴页显示套装收集进度。

## 7. Codex 实现步骤

1. 定义 sets.json。
2. 实现穿戴装备统计套装件数。
3. 实现套装效果激活/取消。
4. 接入属性聚合和战斗效果。

## 8. 验收测试

- 穿 2 件激活 2 件效果。
- 卸下一件后效果取消。
- 同时穿多套时都能统计。
- 套装图鉴记录曾经获得。

## 8.1 边界情况

- 同名套装不同品质变体要明确是否计入同一套。

## 8.2 关联配置文件

- `assets/data/sets.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S11_技能与自动释放系统

## 1. 系统目的

实现主动技能、被动技能、终结技能的配置、冷却、资源消耗、释放条件和自动释放优先级。

## 2. 系统范围

- 主动技能
- 被动技能
- 终结技能
- 冷却
- 资源
- 释放条件
- 技能标签
- 技能升级
- 自动释放优先级

## 3. 核心数据模型

- `SkillConfig`
- `SkillInstance`
- `SkillSlot`
- `SkillCooldownState`
- `SkillCastCondition`
- `SkillEffect`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `SkillService`
- `SkillCastService`
- `CooldownService`
- `SkillPriorityService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 技能不由玩家高频点击，而是配置后自动释放。
2. 每个角色可配置 3 主动、3 被动、1 终结，后期可扩。
3. 技能效果必须可被装备/魂核/词缀修改。

## 6. UI / 交互接入

- 技能配置页支持拖拽排序或优先级数字。
- 战斗页显示技能冷却和释放日志。

## 7. Codex 实现步骤

1. 定义 skills.json。
2. 实现技能槽。
3. 实现冷却和资源消耗。
4. 实现释放条件。
5. 实现自动优先级。
6. 接入战斗循环。

## 8. 验收测试

- 冷却未完成不能释放。
- 资源不足不能释放。
- 满足低血条件时才释放治疗/护盾技能。
- 被动技能不主动释放但能影响属性或触发事件。

## 8.1 边界情况

- 技能效果修改链要防止无限递归。

## 8.2 关联配置文件

- `assets/data/skills.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S12_天赋系统

## 1. 系统目的

实现每职业天赋树，提供长期成长和 BD 强化。

## 2. 系统范围

- 职业天赋树
- 节点解锁
- 天赋点
- 前置节点
- 重置
- 分支方向
- 天赋效果

## 3. 核心数据模型

- `TalentTreeConfig`
- `TalentNode`
- `TalentState`
- `TalentEffect`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `TalentService`
- `TalentUnlockService`
- `TalentEffectService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 每职业 3-5 条路线，总计 120+ 节点。
2. 天赋增强 BD，不替代装备。
3. 节点效果用 effectId + params。
4. 重置需要消耗资源或免费调试。

## 6. UI / 交互接入

- 天赋页展示节点、连线、已点亮状态。
- BD 页显示关键天赋缺口。

## 7. Codex 实现步骤

1. 定义 talents.json。
2. 实现天赋点获取。
3. 实现前置节点检查。
4. 实现点亮/重置。
5. 将天赋效果接入属性/战斗。

## 8. 验收测试

- 点亮节点消耗天赋点。
- 未满足前置不可点。
- 重置后效果移除。
- 天赋效果能影响 BD 评分。

## 8.1 边界情况

- 大型天赋树 UI 可先用列表/分组实现，后续再做可视化树。

## 8.2 关联配置文件

- `assets/data/talents.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S13_符文系统

## 1. 系统目的

实现符文获取、镶嵌、升级、组合和对技能/装备的增强。

## 2. 系统范围

- 符文配置
- 符文品质
- 符文镶嵌
- 符文升级
- 符文拆卸
- 符文标签
- 符文组合预留

## 3. 核心数据模型

- `RuneConfig`
- `RuneInstance`
- `RuneSlot`
- `RuneEffect`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `RuneService`
- `RuneSocketService`
- `RuneUpgradeService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 符文数量 120 个。
2. 符文主要提供定向增强和微型机制，不要强于魂核。
3. 只有特定装备位有符文槽。
4. 符文效果可作用于属性、技能或掉落。

## 6. UI / 交互接入

- 装备详情显示符文槽。
- 符文页支持筛选和镶嵌。

## 7. Codex 实现步骤

1. 定义 runes.json。
2. 实现符文背包。
3. 实现镶嵌/拆卸。
4. 实现符文效果聚合。
5. 接入装备和属性系统。

## 8. 验收测试

- 空槽可镶嵌。
- 已镶嵌符文效果生效。
- 拆卸后效果取消。
- 不符合槽类型的符文不可镶嵌。

## 8.1 边界情况

- 符文升级失败机制暂不做，避免负反馈过重。

## 8.2 关联配置文件

- `assets/data/runes.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S14_自动战斗系统

## 1. 系统目的

实现挂机战斗核心循环，包括目标选择、普通攻击、技能释放、异常状态、死亡、日志和失败。

## 2. 系统范围

- 战斗循环
- 目标选择
- 普通攻击
- 技能释放
- 状态效果
- 召唤物
- Boss 战
- 战斗日志
- 胜负判断
- 性能优化

## 3. 核心数据模型

- `BattleState`
- `Combatant`
- `EnemyWave`
- `BattleEvent`
- `BattleLogEntry`
- `StatusEffectInstance`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `BattleService`
- `BattleLoopService`
- `TargetingService`
- `CombatEventBus`
- `BattleLogService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 战斗是自动模拟，不依赖手动操作。
2. 战斗 tick 建议使用固定步长，例如 0.5 秒或 1 秒。
3. 所有触发效果走 CombatEventBus。
4. 战斗日志只保留最近 N 条，避免内存增长。

## 6. UI / 交互接入

- 战斗页展示敌人、角色血量、技能冷却、日志、掉落提示。
- Debug 页可加速战斗。

## 7. Codex 实现步骤

1. 实现 BattleState。
2. 实现固定 tick 循环。
3. 实现攻击、技能、状态、召唤物。
4. 实现怪物死亡事件。
5. 接入掉落系统。
6. 接入失败/胜利判定。

## 8. 验收测试

- 角色能自动打死低级怪。
- 怪物能打死角色。
- 技能按优先级释放。
- 状态持续时间正确减少。
- 日志不会无限增长。

## 8.1 边界情况

- 离线收益不需要逐 tick 模拟，应使用效率公式。

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S15_怪物、精英词缀与 Boss 系统

## 1. 系统目的

实现普通怪、精英怪、特殊怪、Boss 和高难度变体 Boss 的配置与战斗机制。

## 2. 系统范围

- 怪物配置
- 精英词缀
- Boss 技能
- Boss 阶段
- 抗性
- 掉落池
- 难度变体
- 特殊怪

## 3. 核心数据模型

- `MonsterConfig`
- `EliteAffixConfig`
- `BossConfig`
- `BossPhase`
- `EnemyInstance`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `MonsterService`
- `EliteAffixService`
- `BossService`
- `EnemyGenerationService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 普通怪主要通过数据区分，Boss 才需要复杂机制。
2. 精英词缀可叠加，但需要数量上限。
3. Boss 高难度变体通过 difficultyModifier + extraMechanics 实现。

## 6. UI / 交互接入

- 深渊页显示本层可能出现的精英词缀。
- Boss 挑战页显示 Boss 主要机制和推荐抗性。

## 7. Codex 实现步骤

1. 定义 monsters.json、elite_affixes.json、bosses.json。
2. 实现怪物实例生成。
3. 实现精英词缀附加。
4. 实现 Boss 阶段切换。
5. 接入掉落池。

## 8. 验收测试

- 普通怪属性受章节/层数影响。
- 精英词缀能改变属性或触发效果。
- Boss 低血进入二阶段。
- 不同难度 Boss 机制增强。

## 8.1 边界情况

- 多个死亡爆炸类效果同时存在时要限制触发频率。

## 8.2 关联配置文件

- `assets/data/monsters.json`
- `assets/data/elite_affixes.json`
- `assets/data/bosses.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S16_掉落池与随机权重系统

## 1. 系统目的

实现金币、材料、装备、符文、魂核、套装、深渊装备等掉落逻辑，支持难度和层数修正。

## 2. 系统范围

- 掉落池
- 品质权重
- 职业权重
- 保底预留
- Magic Find
- 首通奖励
- Boss 专属掉落
- 深渊掉落修正

## 3. 核心数据模型

- `DropPoolConfig`
- `DropEntry`
- `LootResult`
- `QualityWeight`
- `DropContext`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `DropService`
- `LootRollService`
- `QualityRollService`
- `RewardService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 掉落通过 DropContext 计算，包含章节、深渊领域、难度、层数、怪物类型、玩家掉落加成。
2. 品质先 roll，后 roll 具体装备池。
3. 职业装备权重应高于其他职业，但允许少量通用掉落。

## 6. UI / 交互接入

- 战斗页掉落提示。
- 离线收益页汇总掉落。
- 装备页可查看来源。

## 7. Codex 实现步骤

1. 定义 drop_pools.json。
2. 实现品质权重。
3. 实现装备掉落。
4. 实现材料掉落。
5. 实现 Boss 专属掉落。
6. 接入战斗和离线收益。

## 8. 验收测试

- 普通怪掉落低品质较多。
- Boss 掉落稀有以上概率更高。
- 高难度提高神话/深渊权重。
- 首通奖励只领取一次。

## 8.1 边界情况

- 掉落大量装备时必须先经过自动筛选，避免背包爆满。

## 8.2 关联配置文件

- `assets/data/drop_pools.json`
- `assets/data/quality_config.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S17_深渊领域、难度与层数系统

## 1. 系统目的

实现 10 个深渊领域、6 个难度、每领域 100 层，总计 6000 等效层数。

## 2. 系统范围

- 深渊领域
- 难度等级
- 层数进度
- 层数词缀
- 首通奖励
- 领域掉落
- Boss 层
- 挑战失败建议

## 3. 核心数据模型

- `AbyssDomainConfig`
- `DifficultyConfig`
- `AbyssLayerConfig`
- `AbyssProgress`
- `AbyssModifier`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `AbyssService`
- `DifficultyService`
- `AbyssModifierService`
- `AbyssRewardService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 深渊结构 = 领域 × 难度 × 层数。
2. 每 10 层一个小 Boss，每 50/100 层领域 Boss。
3. 难度影响怪物倍率、词缀数量、掉落品质。
4. 层数越高，词缀越多，奖励越高。

## 6. UI / 交互接入

- 深渊页显示领域、难度、当前层、词缀、可能掉落、推荐属性。
- 失败页给出具体建议。

## 7. Codex 实现步骤

1. 定义 abyss_domains.json、difficulties.json、abyss_modifiers.json。
2. 实现解锁难度。
3. 实现层数挑战。
4. 实现词缀随机。
5. 实现首通奖励。

## 8. 验收测试

- 普通难度第 1 层可进入。
- 未通关前置层不能挑战下一层。
- 不同难度倍率生效。
- Boss 层生成 Boss。

## 8.1 边界情况

- 无尽难度可以后续扩展为无限层，v1.0 先按 100 层实现。

## 8.2 关联配置文件

- `assets/data/abyss_domains.json`
- `assets/data/difficulties.json`
- `assets/data/abyss_modifiers.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S18_挂机与离线收益系统

## 1. 系统目的

实现在线挂机效率、离线收益计算、收益上限、防作弊和离线收益弹窗。

## 2. 系统范围

- 在线挂机
- 离线挂机
- 收益效率
- 离线时长
- 收益上限
- 自动筛选
- 防时间作弊
- 收益展示

## 3. 核心数据模型

- `IdleSession`
- `OfflineReward`
- `IdleEfficiency`
- `OfflineRewardConfig`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `IdleService`
- `OfflineRewardService`
- `EfficiencyService`
- `AntiCheatTimeService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 离线收益不逐 tick 模拟，按最近挂机效率计算。
2. 收益包含经验、金币、装备、材料、符文、深渊碎片。
3. 普通离线收益上限可配置。
4. 时间异常回拨时不给异常收益。

## 6. UI / 交互接入

- 登录后弹出离线收益页，显示击杀、金币、装备、稀有掉落、自动分解结果。

## 7. Codex 实现步骤

1. 记录 lastExitTime 和当前挂机目标。
2. 计算在线每分钟击杀效率。
3. 实现离线收益公式。
4. 接入掉落系统和自动筛选。
5. 实现防作弊限制。

## 8. 验收测试

- 关闭 10 分钟后返回有收益。
- 超过上限只按上限计算。
- 时间回拨不产生负收益。
- 离线掉落装备进入背包或被自动分解。

## 8.1 边界情况

- 离线时切换系统时间需要记录异常标记。

## 8.2 关联配置文件

- `assets/data/offline_reward_config.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S19_背包、仓库、锁定、分解与自动筛选系统

## 1. 系统目的

管理玩家所有装备和材料，支持容量、锁定、一键分解、自动保留和 BD 筛选模板。

## 2. 系统范围

- 背包
- 仓库
- 装备锁定
- 材料堆叠
- 一键分解
- 自动分解
- 自动保留
- 筛选模板
- 容量扩展

## 3. 核心数据模型

- `InventoryState`
- `StorageState`
- `FilterRule`
- `AutoSalvageResult`
- `MaterialStack`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `InventoryService`
- `StorageService`
- `FilterService`
- `SalvageService`
- `AutoLootService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 锁定装备不可分解。
2. 自动筛选优先级：锁定 > 保留规则 > 分解规则。
3. 材料必须堆叠，不占装备格。
4. 背包满时优先执行自动分解。

## 6. UI / 交互接入

- 背包页支持品质、部位、BD 匹配度、词缀标签筛选。
- 离线收益页展示自动分解结果。

## 7. Codex 实现步骤

1. 实现背包状态。
2. 实现装备添加/移除。
3. 实现锁定。
4. 实现一键分解。
5. 实现自动筛选规则。
6. 实现仓库移动。

## 8. 验收测试

- 锁定装备不会被一键分解。
- 自动保留传奇。
- 毒伤模板能保留毒相关词缀。
- 背包满时不会崩溃。

## 8.1 边界情况

- 筛选规则需要可保存到存档。

## 8.2 关联配置文件

- `assets/data/filter_templates.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S20_装备养成：强化、洗练、镶嵌、腐化系统

## 1. 系统目的

实现装备长期养成，但不让养成系统压过刷宝本身。

## 2. 系统范围

- 强化
- 洗练
- 镶嵌
- 腐化
- 材料消耗
- 成功率
- 词缀锁定预留
- 负面词缀
- 装备损坏预留

## 3. 核心数据模型

- `EnhanceConfig`
- `RerollConfig`
- `CorruptionConfig`
- `UpgradeResult`
- `RerollResult`
- `CorruptionResult`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `EnhanceService`
- `RerollService`
- `SocketService`
- `CorruptionService`
- `MaterialCostService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 强化主要提升基础属性。
2. 洗练每次只洗一条可洗词缀。
3. 传奇核心效果不可洗。
4. 腐化提供强机制但可能附加负面代价。
5. 所有消耗来自配置。

## 6. UI / 交互接入

- 装备详情页提供强化、洗练、镶嵌、腐化入口。
- 操作前展示消耗和可能结果。

## 7. Codex 实现步骤

1. 定义 upgrade_config.json。
2. 实现强化。
3. 实现洗练选择词缀。
4. 实现符文镶嵌。
5. 实现腐化结果池。
6. 消耗材料接入背包。

## 8. 验收测试

- 材料不足不能操作。
- 强化后属性提升。
- 洗练不改变不可洗词缀。
- 腐化能添加正面或负面效果。

## 8.1 边界情况

- 腐化失败不能直接让玩家核心装备永久消失，除非后续明确做硬核模式。

## 8.2 关联配置文件

- `assets/data/upgrade_config.json`
- `assets/data/corruption_pools.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S21_章节、地图推进与普通 Boss 系统

## 1. 系统目的

实现 12 章主线推进，用于新手引导、系统解锁和基础装备产出。

## 2. 系统范围

- 12 章节
- 地图节点
- 小 Boss
- 章节 Boss
- 系统解锁
- 章节掉落
- 推荐战力
- 失败建议

## 3. 核心数据模型

- `ChapterConfig`
- `StageConfig`
- `ChapterProgress`
- `UnlockCondition`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `ChapterService`
- `StageService`
- `UnlockService`
- `ChapterRewardService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 章节是前中期引导，不是终局核心。
2. 每章提供特定装备/词缀主题。
3. 系统逐步解锁，避免新手一次看到所有功能。

## 6. UI / 交互接入

- 战斗页显示当前章节。
- 章节页显示进度、Boss、掉落、解锁内容。

## 7. Codex 实现步骤

1. 定义 chapters.json。
2. 实现章节进度。
3. 实现通关奖励。
4. 实现系统解锁。
5. 接入战斗生成怪物。

## 8. 验收测试

- 通关第 1 章解锁装备强化。
- 通关指定章节解锁深渊。
- 重复刷章节可获得掉落。
- Boss 首通奖励只给一次。

## 8.1 边界情况

- 玩家卡关时需要提示推荐强化/BD。

## 8.2 关联配置文件

- `assets/data/chapters.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S22_任务、成就与图鉴系统

## 1. 系统目的

提供长期目标、每日回访理由和装备收集反馈。

## 2. 系统范围

- 每日任务
- 周常任务
- 成就
- 装备图鉴
- 套装图鉴
- 魂核图鉴
- 奖励领取
- 进度追踪

## 3. 核心数据模型

- `QuestConfig`
- `QuestProgress`
- `AchievementConfig`
- `AchievementProgress`
- `CollectionEntry`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `QuestService`
- `AchievementService`
- `CollectionService`
- `ProgressTrackerService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 任务应鼓励核心玩法：刷怪、分解、推层、强化、换 BD。
2. 图鉴记录曾经获得过，不要求当前持有。
3. 成就奖励可以提供小幅永久加成，但不能破坏平衡。

## 6. UI / 交互接入

- 任务页显示日常/周常。
- 图鉴页按装备、套装、魂核分组。
- 成就页显示长期目标。

## 7. Codex 实现步骤

1. 定义 quests.json、achievements.json、collections.json。
2. 实现事件监听进度。
3. 实现奖励领取。
4. 接入装备获得和深渊通关事件。

## 8. 验收测试

- 获得装备时图鉴点亮。
- 任务进度可累计。
- 奖励只能领取一次。
- 每日任务可刷新。

## 8.1 边界情况

- 每日刷新时间按本地时间，防作弊简单处理。

## 8.2 关联配置文件

- `assets/data/quests.json`
- `assets/data/achievements.json`
- `assets/data/collections.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S23_商店、商业化与付费边界系统

## 1. 系统目的

实现轻商业化框架，避免破坏刷宝核心。

## 2. 系统范围

- 商店
- 月卡
- 战令预留
- 仓库扩容
- BD预设栏
- 外观
- 广告预留
- 购买记录

## 3. 核心数据模型

- `ShopItemConfig`
- `PurchaseState`
- `Entitlement`
- `MonetizationConfig`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `ShopService`
- `EntitlementService`
- `PurchaseMockService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 不卖毕业装备。
2. 不卖核心词缀。
3. 不卖直接通关。
4. 可以卖便利性、外观、仓库、预设栏、离线上限。
5. v1.0 可以先做本地模拟购买，后续接平台支付。

## 6. UI / 交互接入

- 商店页分为便利、外观、礼包、月卡。
- 付费内容必须清楚显示不影响核心掉落公平性。

## 7. Codex 实现步骤

1. 定义 shop_items.json。
2. 实现商品展示。
3. 实现权益状态。
4. 实现本地模拟购买。
5. 接入仓库容量/离线上限/预设栏。

## 8. 验收测试

- 购买仓库扩容后容量增加。
- 月卡提升离线收益上限。
- 未购买权益不可使用。
- 重启后权益保留。

## 8.1 边界情况

- 正式上架前需替换为真实 IAP。

## 8.2 关联配置文件

- `assets/data/shop_items.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S24_UI 页面与交互系统

## 1. 系统目的

定义全游戏 UI 架构、页面、弹窗、装备卡片、品质表现和暗黑视觉规范。

## 2. 系统范围

- 启动页
- 主界面
- 战斗页
- 装备页
- BD页
- 深渊页
- 角色页
- 背包页
- 弹窗
- 装备详情
- 离线收益
- 设置

## 3. 核心数据模型

- `PageState`
- `EquipmentCardViewModel`
- `LootPopupViewModel`
- `NavigationTab`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `UIStateService`
- `ViewModelMapper`
- `ToastService`
- `ModalService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. UI 不直接计算业务逻辑，只消费 ViewModel。
2. 装备品质颜色统一来自 QualityTheme。
3. 页面必须适配常见手机尺寸。
4. 所有长列表使用 ListView.builder。

## 6. UI / 交互接入

- 底部 5 Tab：战斗、装备、BD、深渊、角色。
- 装备详情弹窗必须重点展示机制词缀和 BD 匹配度。
- 离线收益弹窗必须有收菜爽感。

## 7. Codex 实现步骤

1. 创建 UI 主题。
2. 实现底部导航。
3. 实现装备卡片组件。
4. 实现装备详情弹窗。
5. 实现战斗日志组件。
6. 实现离线收益弹窗。
7. 实现各主页面骨架。

## 8. 验收测试

- 页面切换无崩溃。
- 装备卡片显示品质色。
- 长装备列表不卡顿。
- 小屏手机不溢出。

## 8.1 边界情况

- 先用高质量 UI 组件和暗黑色彩，不必一开始做复杂动效。

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S25_新手引导与系统解锁系统

## 1. 系统目的

控制玩家前 30 分钟体验，让玩家逐步理解自动战斗、装备、词缀、BD 和深渊。

## 2. 系统范围

- 引导步骤
- 强制引导
- 弱提示
- 系统解锁
- 首件传奇
- 首次失败
- BD推荐
- 离线收益引导

## 3. 核心数据模型

- `TutorialStep`
- `UnlockState`
- `GuidePointer`
- `FirstDropRule`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `TutorialService`
- `UnlockFlowService`
- `GuideService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 新手不要一次开放所有系统。
2. 前 5 分钟必须让玩家获得一件能改变体验的传奇或魂核。
3. 首次失败要给清晰建议，不要只提示战力不足。

## 6. UI / 交互接入

- 引导遮罩、箭头、提示框。
- 系统解锁弹窗。
- 首次传奇掉落强提示。

## 7. Codex 实现步骤

1. 定义 tutorial_steps.json。
2. 实现引导状态保存。
3. 实现系统解锁条件。
4. 实现首件传奇掉落规则。
5. 接入章节推进。

## 8. 验收测试

- 完成一步后不会重复弹出。
- 跳过引导后状态保存。
- 系统未解锁时入口置灰。
- 首件传奇只保底一次。

## 8.1 边界情况

- 引导文本要后续可配置，避免写死。

## 8.2 关联配置文件

- `assets/data/tutorial_steps.json`
- `assets/data/unlock_rules.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S26_音效、震动与反馈系统

## 1. 系统目的

统一处理掉落、强化、Boss、通关、失败、按钮等反馈，增强刷宝爽感。

## 2. 系统范围

- 音效管理
- 震动反馈
- 掉落反馈
- 强化反馈
- Boss反馈
- 设置开关
- 音量

## 3. 核心数据模型

- `FeedbackEvent`
- `SoundConfig`
- `HapticConfig`
- `FeedbackSettings`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `FeedbackService`
- `SoundService`
- `HapticService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 传奇、神话、深渊装备必须有不同反馈层级。
2. 震动可关闭。
3. 音效资源缺失不能导致崩溃。
4. 反馈事件由系统发送，不由页面重复判断。

## 6. UI / 交互接入

- 设置页提供音效、震动开关。
- 掉落弹窗根据品质播放反馈。

## 7. Codex 实现步骤

1. 定义 feedback_config.json。
2. 实现 FeedbackService。
3. 接入掉落、强化、Boss、通关。
4. 实现设置开关。

## 8. 验收测试

- 关闭音效后不播放。
- 传奇掉落触发高等级反馈。
- 资源缺失时静默跳过。

## 8.1 边界情况

- 正式素材可后续替换，先用占位音效 id。

## 8.2 关联配置文件

- `assets/data/feedback_config.json`

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S27_数据平衡、Debug 与调试后台系统

## 1. 系统目的

为大体量数值调试提供内部工具，包括掉落模拟、战斗模拟、装备生成模拟和存档编辑。

## 2. 系统范围

- Debug面板
- 掉落模拟
- 战斗模拟
- 装备生成模拟
- 属性查看
- 存档编辑
- 资源添加
- 层数跳转

## 3. 核心数据模型

- `DebugCommand`
- `SimulationResult`
- `DropSimulationReport`
- `CombatSimulationReport`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `DebugService`
- `SimulationService`
- `BalanceReportService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. Debug 功能只在 debug mode 显示。
2. 模拟器必须不污染正式存档，除非明确点击写入。
3. 掉落模拟需要支持 1000/10000 次测试。

## 6. UI / 交互接入

- Debug 页展示按钮：加资源、生成装备、模拟掉落、模拟战斗、跳层。

## 7. Codex 实现步骤

1. 实现 DebugService。
2. 实现生成指定品质装备。
3. 实现掉落池模拟。
4. 实现战斗模拟。
5. 实现导出平衡报告为 JSON/文本。

## 8. 验收测试

- 模拟掉落不改变背包。
- 加资源只在 debug 生效。
- 能快速生成某个职业装备。
- 能查看属性拆解。

## 8.1 边界情况

- 正式包需要通过开关完全关闭 Debug。

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# S28_测试、验收与质量门槛系统

## 1. 系统目的

定义项目级测试策略和每个版本合入前必须满足的验收标准。

## 2. 系统范围

- 单元测试
- Widget测试
- 配置校验测试
- 存档测试
- 战斗公式测试
- 掉落模拟测试
- 性能检查
- 回归清单

## 3. 核心数据模型

- `TestCaseSpec`
- `AcceptanceChecklist`
- `RegressionReport`

建议所有模型都支持：

- `fromJson`
- `toJson`
- 基础字段校验
- 稳定 id
- debug 输出

## 4. 核心 Service / System

- `TestRunnerHelper`
- `ConfigTestService`
- `RegressionService`

Service 必须放在 `lib/systems/` 或对应 feature 的 service 层中，不允许写在页面文件里。

## 5. 业务规则

1. 每个核心 service 必须有单元测试。
2. 每次新增配置必须跑引用检查。
3. 存档结构变化必须有 migration 测试。
4. 关键公式必须有确定性测试。

## 6. UI / 交互接入

- Debug 页显示测试入口预留。
- 开发文档中每个系统都有验收标准。

## 7. Codex 实现步骤

1. 建立 test/ 目录。
2. 为配置加载写测试。
3. 为装备生成写测试。
4. 为战斗公式写测试。
5. 为存档迁移写测试。
6. 创建回归清单。

## 8. 验收测试

- flutter test 通过。
- 配置错误能被发现。
- 装备生成无 null。
- 战斗 1000 tick 不崩。
- 存档读写稳定。

## 8.1 边界情况

- 性能测试可先手动，但至少要确保背包 1000 件不卡死。

## 9. Codex 输出要求

Codex 完成本系统时必须输出：

1. 新增/修改文件列表。
2. 核心实现说明。
3. 关键数据结构说明。
4. 已完成测试列表。
5. 尚未实现但预留的扩展点。
6. 是否影响存档结构；如果影响，必须说明 migration 方案。

## 10. 禁止事项

- 不允许将配置内容硬编码在 Widget 中。
- 不允许让 UI 直接修改底层模型，必须通过 service/notifier。
- 不允许用中文名称作为逻辑主键，必须使用稳定 id。
- 不允许出现未处理的 null 崩溃。
- 不允许把调试用临时代码留在正式逻辑中。


---

# Codex_分系统开发任务清单
按顺序复制给 Codex。每次只执行一个任务。

## S01 项目架构与目录规范系统
请阅读 `01_系统开发文档/S01_项目架构与目录规范系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S02 数据配置加载与校验系统
请阅读 `01_系统开发文档/S02_数据配置加载与校验系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S03 本地存档与版本迁移系统
请阅读 `01_系统开发文档/S03_本地存档与版本迁移系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S04 角色职业系统
请阅读 `01_系统开发文档/S04_角色职业系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S05 BD构筑与评分系统
请阅读 `01_系统开发文档/S05_BD构筑与评分系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S06 属性数值与战斗公式系统
请阅读 `01_系统开发文档/S06_属性数值与战斗公式系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S07 装备生成与品质系统
请阅读 `01_系统开发文档/S07_装备生成与品质系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S08 词缀系统
请阅读 `01_系统开发文档/S08_词缀系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S09 魂核系统
请阅读 `01_系统开发文档/S09_魂核系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S10 套装系统
请阅读 `01_系统开发文档/S10_套装系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S11 技能与自动释放系统
请阅读 `01_系统开发文档/S11_技能与自动释放系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S12 天赋系统
请阅读 `01_系统开发文档/S12_天赋系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S13 符文系统
请阅读 `01_系统开发文档/S13_符文系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S14 自动战斗系统
请阅读 `01_系统开发文档/S14_自动战斗系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S15 怪物、精英词缀与 Boss 系统
请阅读 `01_系统开发文档/S15_怪物、精英词缀与 Boss 系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S16 掉落池与随机权重系统
请阅读 `01_系统开发文档/S16_掉落池与随机权重系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S17 深渊领域、难度与层数系统
请阅读 `01_系统开发文档/S17_深渊领域、难度与层数系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S18 挂机与离线收益系统
请阅读 `01_系统开发文档/S18_挂机与离线收益系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S19 背包、仓库、锁定、分解与自动筛选系统
请阅读 `01_系统开发文档/S19_背包、仓库、锁定、分解与自动筛选系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S20 装备养成：强化、洗练、镶嵌、腐化系统
请阅读 `01_系统开发文档/S20_装备养成：强化、洗练、镶嵌、腐化系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S21 章节、地图推进与普通 Boss 系统
请阅读 `01_系统开发文档/S21_章节、地图推进与普通 Boss 系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S22 任务、成就与图鉴系统
请阅读 `01_系统开发文档/S22_任务、成就与图鉴系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S23 商店、商业化与付费边界系统
请阅读 `01_系统开发文档/S23_商店、商业化与付费边界系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S24 UI 页面与交互系统
请阅读 `01_系统开发文档/S24_UI 页面与交互系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S25 新手引导与系统解锁系统
请阅读 `01_系统开发文档/S25_新手引导与系统解锁系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S26 音效、震动与反馈系统
请阅读 `01_系统开发文档/S26_音效、震动与反馈系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S27 数据平衡、Debug 与调试后台系统
请阅读 `01_系统开发文档/S27_数据平衡、Debug 与调试后台系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。

## S28 测试、验收与质量门槛系统
请阅读 `01_系统开发文档/S28_测试、验收与质量门槛系统.md`，实现该系统的第一版。要求：
- 保持数据驱动。
- 新增必要 model/service/test。
- 不写临时代码。
- 完成后更新 CHANGELOG_DEV.md。
- 输出新增/修改文件列表和测试结果。


---

# Codex_总启动提示词

你正在开发一款 Flutter 竖屏暗黑挂机刷宝手游《深渊遗装》。请严格按照本项目文档实现，不要做临时 Demo，不要硬编码内容数据。

## 项目目标

实现一款完整可上线的单机暗黑挂机刷宝手游。核心玩法是：玩家配置 BD，角色自动战斗，掉落随机装备，通过装备、词缀、魂核、套装、技能、天赋、符文组合，不断挑战多难度深渊。

## 当前规格

- 5 个职业
- 25 套核心 BD，50+ 变种 BD
- 12 个装备位
- 8 档装备品质
- 300 个词缀
- 180 件传奇装备
- 50 件神话装备
- 80 件深渊装备
- 30 套套装
- 60 个魂核
- 120 个符文
- 12 章普通章节
- 10 个深渊领域
- 6 个难度
- 每领域 100 层，合计 6000 等效深渊层

## 技术要求

- 使用 Flutter + Dart。
- 使用本地 JSON 配置所有内容。
- 本地存档优先，后续预留云存档。
- UI 和业务逻辑分离。
- 战斗、掉落、装备、属性、离线收益必须在 service/system 层实现。
- 所有核心计算必须可测试。

## 开发方式

每次只实现一个系统。实现前先阅读对应 `Sxx_系统开发文档.md`。完成后：

1. 列出新增/修改文件。
2. 简述实现逻辑。
3. 说明如何运行和测试。
4. 更新 `CHANGELOG_DEV.md`。
5. 不要删除已有功能。

## 禁止事项

- 不要把装备、技能、词缀写死在代码里。
- 不要让 Widget 直接改模型。
- 不要忽略配置校验。
- 不要牺牲存档兼容性。
- 不要一次性生成大量无测试代码。

## 第一个任务

先实现 `S01_项目架构与目录规范系统`，只做正式项目底座，不要实现复杂玩法。完成后等待下一步。


---

# 项目验收总清单

## 1. 启动与稳定性

- App 首次启动不崩溃。
- JSON 配置加载成功。
- 配置错误可以在 debug 面板看到。
- 存档创建、读取、保存、迁移正常。

## 2. 核心循环

- 玩家可以进入章节或深渊。
- 角色可以自动战斗。
- 怪物可以死亡并掉落奖励。
- 玩家可以查看装备。
- 玩家可以穿戴、分解、锁定装备。
- 玩家可以通过装备变化提高战斗效率。

## 3. 装备与 BD

- 12 个装备位正常工作。
- 8 档品质显示正确。
- 随机词缀可生成。
- 传奇/神话/深渊效果可触发。
- 魂核可以改变 BD 机制。
- 套装件数效果可激活。
- BD 评分不只看战力。

## 4. 深渊

- 10 个领域可配置。
- 6 个难度可解锁。
- 每领域 100 层可推进。
- 层数词缀生效。
- Boss 层正常生成。
- 首通奖励只发一次。

## 5. 挂机与离线

- 在线挂机有持续收益。
- 离线回来展示收益弹窗。
- 离线收益受上限限制。
- 自动分解/保留规则生效。
- 时间异常不会刷出无限收益。

## 6. UI

- 5 个主页面完整。
- 装备详情弹窗清晰。
- 离线收益弹窗有反馈。
- 小屏幕不溢出。
- 长列表不卡顿。

## 7. 测试

- 配置校验测试通过。
- 装备生成测试通过。
- 伤害公式测试通过。
- 掉落模拟测试通过。
- 存档读写测试通过。
- 战斗 1000 tick 不崩溃。
