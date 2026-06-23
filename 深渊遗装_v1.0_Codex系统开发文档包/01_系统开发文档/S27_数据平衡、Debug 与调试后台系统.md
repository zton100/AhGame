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
