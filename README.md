# 深渊遗装

Flutter/Dart 单机暗黑挂机刷宝手游。核心循环是配置 BD、自动战斗、随机掉落装备、筛选和养成装备，并逐步推进章节与深渊。

## Repository

GitHub remote: [zton100/AhGame](https://github.com/zton100/AhGame)

## Quick Start

本机 Flutter SDK 位于 `I:\dev\flutter`。如果 `flutter` 不在 PATH 中，可直接使用完整路径：

```powershell
I:\dev\flutter\bin\flutter.bat pub get
I:\dev\flutter\bin\flutter.bat test
I:\dev\flutter\bin\flutter.bat analyze
```

## Architecture

- `lib/core`: bootstrap、路由、主题等跨系统基础设施。
- `lib/models`: 可序列化数据模型。
- `lib/systems`: 不依赖 Widget 的业务 service/system。
- `lib/features`: 页面和 feature 级 UI。
- `assets/data`: 本地 JSON 配置。
- `test`: 单元测试和 Widget smoke test。

## Development Rules

- 所有玩法内容走 `assets/data/*.json`。
- Widget 不直接计算战斗、掉落、属性或收益。
- 每完成一个系统，更新 `CHANGELOG_DEV.md`。
- 核心 service 必须有测试。
