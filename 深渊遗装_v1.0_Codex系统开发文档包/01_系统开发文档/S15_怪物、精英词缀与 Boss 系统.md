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
