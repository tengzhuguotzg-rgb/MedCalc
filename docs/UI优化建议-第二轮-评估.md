# MedCalc UI 优化建议 · 第二轮 — 评估

> 评估时间：2026-07-22
> 基于：`docs/UI优化建议-第二轮.md`
> 评估人：施工 AI（完成第一轮 23 项 + 泄露修复 + 暗色微调）

---

## ✅ 同意（值得做）

### H1. 暗色下彩底白字徽章 — 完全同意
`AppColors.card` 在 dark = `#2A2A2A`，压在 primary/tier/danger 彩底上对比度灾难。`AppColors.onPrimary`（dark=`#E8F0EA`）已定义却几乎没被用上，是系统性遗漏。改完暗色走查全部徽章类元素。

### H2. 升压药换算旧结果不作废 — 完全同意
改体重/浓度后旧 mL/h 仍显示，床旁直接抄错泵速，是正确性 bug 级。建议：任一输入 onChange 置 `calculated=false`，结果卡显示"参数已变更，请重新计算"置灰态。

### H3. 无确认不可逆操作 — 同意（含 ImageEditor 取消）
清会话、删诊断、重诊断无确认是真实误操作风险。ImageEditor 取消同样是不可逆操作（`showEditor=false` 销毁组件，strokes 随之消失，undo 只在编辑器开着时有效）。
- **加确认**：清空会话、删除用户诊断、重诊断（触发全量 LLM 调用）、ImageEditor 清空、ImageEditor 取消（仅当 `strokes.length > 0` 时弹确认，零笔刷不弹）
- **不加确认**：计算器重置（低风险，数据可重输）
- 额外：重诊断在 loading 期间应禁用；危险色统一 `AppColors.danger`（目前 records 删除和确认弹窗用 warning 橙，不一致）

### H4. 输入文本死按钮 — 同意方案B
方案B（先隐藏死按钮）1 行代码。方案A（LLM 提取文本）是好功能但工作量大，建议单独做。底部 4 按钮 2×2 布局建议也合理。

### H5. 知识库 TOC 点击不跳转 — 同意
假功能比没有更差，用户点了没反应。用 Scroller.scrollToIndex 实现。

### H6. TimelineDialog 溢出 — 同意加 Scroll
趋势图单独做（Canvas 折线图工作量大），本轮只加 Scroll + maxHeight。

### M1. ResultCard 大数值色不随 tier 联动 — 同意
危急值大字绿色削弱警示。数值色随 tierClass 联动。

### M5. 分节标题滥用 warning 橙 — 同意
橙色被装饰消耗，真正警示失去辨识度。改 `textSecondary` 或 `primary`。

### M9. KbReaderOverlay 返回键不处理 — 同意
KB 阅读器打开时按系统返回直接退出详情页，是导航 bug。navigateBack 链最前加 `if (showKbReader) 关闭浮层`。

### M15. 表格无横向滚动 — 同意
剂量表被挤压不可读是实际痛点。外层包横向 Scroll，参考 CodeBlockView 已有模式。

### L3. Sidebar CollapsedView 死代码 — 同意删除
条目行高 40+ 也同意，戴手套场景。

### L4. 小瑕疵 — 同意
BloodGas 重复 margin、硬编码 rgba 修掉。

---

## 🔶 部分同意（需调整）

### M2. 重置防误触 — 只加热区，不加确认
重置按钮加 44 热区同意，但二次确认过度——计算器重置是低风险操作，不像删除不可恢复。只加热区 + padding 即可。

### M6. 小字号残留 — 关键标签提，辅助信息保留
方向对但全改 12pt 会让信息区域过于拥挤。建议：
- 关键标签（urgency、缺项、计数）→ 12pt
- Agent 步骤辅助信息 → 保持 10pt（本来就是次要信息）

### M7. 诊断确认交互 — 先做最小版
方向好但交互复杂（折叠区、排除态等）。建议先做最小版：诊断卡加 ✓/✗ ≥32pt 徽章按钮，点击写 `llmConfirmed` 字段，标签变色即可。

### M13. SettingsPage — Radio 整行可点同意，但不禁拖拽关闭
- Radio 整行可点 ✅
- Base URL 为空禁用确定键 ✅
- **禁拖拽关闭 bindSheet** ❌ — HarmonyOS 标准交互就是下拉关闭 sheet，改了不符合平台习惯。改为：内容有修改时弹确认。

### M3. Vasopressor 信息层级 — 折中同意
Vasopressor 结果卡是自定义卡片（`:241-242`），不走 ResultCard，M1 修不到它。现状 mL/h 是 15pt `textBody` 灰字——作为全 App 唯一需要抄到输液泵上的数字，确实不够醒目。折中：mL/h 提至 20pt Bold + primary 色；结果卡显式标注换算方向（如 `mL/h → μg/kg/min`）。不加 28pt，不改交互模式。与 H2 同文件，顺手做。

### M11. LlmDialog FAB 拖出屏幕 — 同意（漏评，实为 bug）
`LlmDialog.ets:130-131` 只钳下限 `Math.max(0, ...)`，无上限约束，FAB 可拖出屏幕无法找回。确定性 bug，加屏幕边界上限钳制。

### L6. PDF 扩展名映射 — 同意
`ImageStore.ets:90-98` `getExtFromUri` 不认 `.pdf`，副本存成 `.jpg`。一行映射的事，顺手修。

### L5. ExamTimeEditor 保存键色 — 同意
`PatientDetailDialogs.ets:174` 保存按钮用 `tierOk` 绿 + `card` 字色，主操作应统一 `primary` + `onPrimary`。一行改动，且 fontColor 的 `card` 正好是 H1 要修的范围。

---

## ❌ 不同意（不做）

### M4/M12/M14. 大范围热区提升（对话框按钮/补录表单/芯片 32→44）
范围太广（涉及所有对话框+补录表单+各种芯片），投入产出比低。当前 36-40 尚可接受，非系统性痛点。

### M8. AddDiagnosis 遮罩关闭弹确认
诊断名称没输完就丢了不心疼，过度防护。

### M10. PatientListPage 根改 Stack
架构改动风险高收益低。搜索无结果文案区分同意（1 行代码改文案），其余不做。

### L1. Tab 加图标
锦上添花，5 个 Tab 文字已够清晰，优先级极低。

### L2. 收藏星标橙色与警示冲突
理论成立，但实际使用中用户不会混淆，优先级极低。

---

## 建议施工顺序

| 批次 | 内容 | 理由 |
|---|---|---|
| 1 | **H1** onPrimary 全局替换 | 系统性，影响暗色模式可用性 |
| 2 | **H2** 升压药结果作废 + **M1** ResultCard 数值色联动 + **M3** Vasopressor mL/h 提升至 20pt+方向标注 | 计算器正确性一批，M3 同文件顺手 |
| 3 | **H3**(含 ImageEditor 取消确认) 清会话/删诊断/重诊断/ImageEditor 加确认 + **M5** 分节标题色 | 患者页安全防护 |
| 4 | **H4B** 隐藏死按钮 + **H5** TOC 跳转 + **M9** KB返回键 | 死功能修复 |
| 5 | **H6** TimelineDialog Scroll + **M15** 表格横向滚动 | 溢出/可读性 |
| 6 | **M11** FAB 拖动上限 + **L6** PDF扩展名 + **L5** ExamTimeEditor保存键色 + L3死代码 + L4小瑕疵 + M2热区 + M6字号精选 | bug修+收尾 |

## 施工纪律

- 沿用第一轮：一个逻辑改动一个 commit，每个 commit 构建必须 0 错误
- 重构后 grep 关键格式化函数调用数防回归（见 `UI优化清单.md` 验证纪律）
- 新增色值只加 token，禁止硬编码 `#RRGGBB`
- 计算器输入区保住 resetKey 机制
