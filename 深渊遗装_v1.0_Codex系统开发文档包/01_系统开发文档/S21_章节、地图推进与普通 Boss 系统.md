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
