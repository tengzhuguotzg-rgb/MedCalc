# 技术债：ArkTS 构建 warning 清理（暂缓）

> 记录时间：2026-07-26。结论：先不修，记录在案，后续按本文档分阶段处理。

## 现状

- 构建绿色（BUILD SUCCESSFUL），warning 不阻塞编译。
- 总量：**369 条**（2026-07-26 构建统计，Batch 1a 之前即存在，与新增计算器无关）。

## 构成

| 类别 | 数量 | 说明 |
| --- | --- | --- |
| `addTryCatch`（Function may throw exceptions. Special handling is required.） | 361 | ArkTS 严格异常检查：RDB / ResultSet / 文件 / JSON 等可抛异常 API 要求显式处理 |
| deprecated API | 8 | `showDialog`、`getContext`、`packing`、`onChange`、`getRectangleById` 等 |

按文件分布：

- `entry/src/main/ets/services/PatientRepository.ets`：**301**
- `entry/src/main/ets/services/KnowledgeService.ets`：**58**
- 其余组件/工具（PatientDetailPage、KnowledgeSearchPage、ImageEditor、ConfirmDialog、PatientDetailDialogs、SettingsPage、AssistantPage 等）：约 **10**

## 根因与已验证结论

- 这些方法是 `async`，异常最终表现为 Promise rejection，但 ArkTS 编译器仍要求在可抛 API 调用点做特殊处理，所以产生 `addTryCatch` warning。
- 已做最小试验：把 `db.insert()` 包进 `try/catch` 可消掉对应 warning，但 `catch (e) { throw e; }` 会触发编译错误 **`arkts-limited-throw`**（throw 不能接受任意类型值）。试验已回退。
- 因此**不能**简单全局套 `try/catch + rethrow`。安全修法是：方法级 `try/catch` + ResultSet 用 `try/finally` 保证 `rs.close()` + catch 内做类型化错误转换。

## 分阶段修复计划（待启动）

- **Stage A（小）**：修 8 条 deprecated。逐条查官方替代 API，改后真机验证对应页面。
- **Stage B（大，价值最高）**：`PatientRepository.ets` 301 条。方法级异常处理 + ResultSet finally 释放。回归清单：患者 CRUD、时间线、预警刷新、诊断规则、lab alert、DB v1→v5 迁移。
- **Stage C（中）**：`KnowledgeService.ets` 58 条。涉及 FTS 索引/检索/JSON/文件。回归清单：首次建库索引、中文复合词搜索、Markdown 阅读链路（参见 PITFALLS 记录）。

## 约束

- 不与功能批次（Batch 1b/2/3）混在同一个提交里做。
- 不追求一次性清零；每阶段独立提交、独立验证。
- 若决定接受现状，也可把本文件标记为「accepted non-blocking」并关闭。
