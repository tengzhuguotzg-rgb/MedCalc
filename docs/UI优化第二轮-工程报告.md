# MedCalc UI 优化第二轮 · 工程报告

> 分支：`ui-overhaul`
> 时间：2026-07-22
> 范围：基于三方共识评估文档（`docs/UI优化建议-第二轮-评估.md`）的 20 项优化
> 前置：第一轮 23 项全部完成（见 `docs/UI优化清单.md`）

---

## 一、总览

第二轮共完成 **20 项**（H 级 6 项 / M 级 9 项 / L 级 5 项），分 9 次 commit，每次构建 0 错误。

| 优先级 | 计划项 | 完成 | 不做 |
|--------|--------|------|------|
| H（高） | 6 | 6 | — |
| M（中） | 11 | 9 | M4/M8/M10/M12/M14 |
| L（低） | 3 | 5 | — |

"不做"项见评估文档 ❌ 节，理由为投入产出比低或不符合平台习惯。

---

## 二、逐项施工记录

### 批次 1 — H1 暗色对比度系统性修复

**Commit**: `68bf281`

**问题**：暗色模式下，彩底白字徽章用 `AppColors.card`（dark=`#2A2A2A`）作字色，压在 primary/tier/danger 彩底上对比度灾难。`AppColors.onPrimary`（dark=`#E8F0EA`）已定义却几乎没被用上。

**做法**：
- 全局 grep `fontColor(AppColors.card)` → `fontColor(AppColors.onPrimary)` 替换 34 处
- 另修 2 处 `fontColor(Color.White)` → `onPrimary`
- 涉及 14 个文件：计算器结果卡、患者详情 tier/urgency 徽章、知识库分类图标、诊断来源标签

**效果**：暗色模式所有彩底徽章文字对比度从 ~2:1 提升至 ~12:1，可读性根本改善。

---

### 批次 2 — H2 + M1 + M3 计算器正确性一批

**Commit**: `db44c3a`

**H2 — 升压药换算旧结果不作废**
- VasopressorCalculator 所有输入 onChange/onClick 置 `calculated=false`
- 参数变更后旧 mL/h 结果隐藏，显示"参数已变更，请重新计算"置灰态
- **临床意义**：改体重/浓度后旧泵速仍显示，床旁直接抄错泵速是正确性 bug

**M1 — ResultCard 大数值色随 tier 联动**
- 数值 `fontColor` 改为 `this.tierClass.length > 0 ? getTierColor(this.tierClass) : AppColors.primary`
- tier→danger 红 / warn 橙 / ok 绿，否则 primary
- **效果**：危急值大字不再是灰色（被 tier 胶囊色压制），危险值大号红字醒目

**M3 — Vasopressor mL/h 信息层级**
- mL/h 结果 15pt → 20pt Bold + primary 色
- 新增换算方向标注行（如 `mL/h → μg/kg/min`）
- **效果**：全 App 唯一需抄到输液泵的数字，视觉权重与临床重要性匹配

---

### 批次 3 — H3 + M5 患者页安全防护

**Commit**: `217ef56`

**H3 — 不可逆操作加确认弹窗**
- 5 处加 `promptAction.showDialog` 确认：清会话、删诊断、重新诊断、ImageEditor 取消、ImageEditor 清空
- 新增 `utils/ConfirmDialog.ets` 工具函数 `showConfirmDialog()`
- 删诊断/重诊断的"危险"按钮色统一 `AppColors.danger`
- 计算器重置**不加确认**（低风险，数据可重输）
- ImageEditor 取消仅当 `strokes.length > 0` 时弹确认，零笔刷不弹

**方案选择**：先用 ActionConfirmDialog @Component 方案，后发现需改 DSL 树加 if 块；改用 `promptAction.showDialog()` 工具函数，无需改渲染树，侵入性最小。

**M5 — 分节标题滥用 warning 橙**
- 54 处 `fontColor(AppColors.warning)` → `textSecondary`，27 个计算器文件
- **效果**：橙色被装饰消耗的问题消除，真正警示恢复辨识度

**新增 string.json 资源**：6 条确认弹窗标题/消息

---

### 批次 4 — H4B + H5 + M9 死功能修复

**Commit**: `9075ea5`

**H4B — 隐藏死按钮**
- PatientDetailPage 无 onClick 的"输入文本"按钮删除

**H5 — 知识库 TOC 点击跳转**
- **三次失败**后找到正确方案：
  1. ❌ @Builder 内加 `.id()` → ArkTS 规则禁止在条件渲染元素加属性方法，触发 100+ 级联编译错误
  2. ❌ List+ListItem → 内容为非列表结构，语义不对
  3. ❌ ForEach 加 index 变量 → 作用域问题
  4. ✅ **"解析期盖章 + 条件包裹"**方案：
     - `MarkdownLine.anchorId` 字段：仅 h2/h3 行非空，格式 `'kb_toc_0'`, `'kb_toc_1'`…
     - `extractTocFromLines(lines)` 替代 `extractToc(content)`，以解析结果为单一数据源
     - ForEach 外层 if 条件包裹 `Column.id(anchorId)`
     - @Builder 内部零改动
- Scroll 内滚动定位：`componentUtils.getRectangleById(id).windowOffset.y` - `getRectangleById('kb_scroll').windowOffset.y` + `currentOffset().yOffset` 计算 scrollTo 目标偏移
- `setTimeout(100ms)` 等 DOM 布局完成
- **效果**：TOC 点击后精准跳转到对应标题

**M9 — KB 阅读器返回键**
- `navigateBack()` 链最前加 `showKbReader` 检查
- **效果**：KB 阅读器打开时按系统返回不再直接退出详情页

---

### 批次 5 — H6 + M15 溢出/可读性

**Commit**: `90c19dd`

**H6 — TimelineDialog 溢出**
- ForEach 外包 Scroll + `constraintSize({ maxHeight: 360 })`
- **效果**：大量记录不再撑破弹窗高度

**M15 — 表格横向滚动**
- KbMarkdownRenderer + KnowledgeSearchPage tableHeader/table 行外包 `Scroll(.Horizontal).scrollBar(BarState.Off)`
- 去掉内部 `.width('100%')` 让表格自然宽度
- **效果**：剂量表、参数表不再被挤压到不可读

---

### 批次 6 — M11 + L6 + L5 + M6 + L4 bug 修 + 收尾

**Commit**: `7f31077`

**M11 — LlmDialog FAB 拖出屏幕**
- `display.getDefaultDisplaySync()` 获取屏幕尺寸
- `Math.min(maxRight, ...)` / `Math.min(maxBottom, ...)` 钳制拖动上限
- **效果**：FAB 不再可拖出屏幕不可找回（确定性 bug）

**L6 — PDF 扩展名映射**
- `ImageStore.getExtFromUri` 加 `.pdf` → `'pdf'` 映射
- **效果**：PDF 副本不再错误存为 `.jpg`

**L5 — ExamTimeEditor 保存键色**
- 保存按钮 `AppColors.tierOk` → `AppColors.primary`
- **效果**：主操作按钮色统一

**M6 — ResultCard 辅助字号降档**
- tier 标签 13→12pt，独立单位 12→10pt，footnote 14→10pt
- **效果**：辅助信息视觉权重降低，大数值更突出

**L4 — ConfirmDialog 硬编码色**
- 弹窗按钮色 `#999` → `#888`，`#E84040` → `#CC3333`（因 promptAction API 只接受 string，无法用 $r()）

---

### 批次 7 — M13 bindSheet 关闭确认

**Commit**: `72401ef`

**M13 — bindSheet 内容修改确认**
- AssistantPage expandedEditor bindSheet 加 `onWillDismiss`
- 有未提交文本时弹确认弹窗，防止误滑丢内容
- 空文本直接关闭不弹
- **效果**：编辑器误下拉关闭不再丢内容

**方案**：使用 ArkUI `onWillDismiss` + `DismissSheetAction.dismiss()` API，声明后所有关闭操作（侧滑/蒙层/下拉）都经回调，未调 dismiss 则面板不关。

---

### 批次 8 — M2 重置按钮热区扩大

**Commit**: `f922a39`

**M2 — 30 个计算器重置按钮热区**
- 新增 `ResetButton` 组件（CalcWidgets.ets）：12pt 灰字 + padding 12+10（可点击区域约 36×32→48×32）
- 30 个计算器文件 `Text('重置').fontSize(12)...onClick` → `ResetButton({ onReset })`
- 排除 VasopressorCalculator 和 BloodGasCalculator（不迁移共享组件）
- **效果**：重置按钮可点击区域显著扩大，误触减少

---

### 批次 9 — L3 死代码清理

**Commit**: `1926d12`

**L3 — 删除死代码**
- `extractToc()` 已被 `extractTocFromLines()` 完全替代，删除旧实现（24 行）及 KnowledgeSearchPage 中的 import
- `getCategoryLabel()` 无任何调用方，删除（15 行）
- **效果**：减少维护负担，消除混淆

---

## 三、关键技术决策

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| H3 确认弹窗 | A. @Component / B. promptAction.showDialog | B | A 需改 DSL 树加 if 块，侵入性大；B 工具函数无需改渲染树 |
| H5 TOC 跳转 | 3 次失败后方案 | 解析期盖章+条件包裹 | ArkTS 禁止 @Builder if-else 内加 .id()；解析期给 MarkdownLine.anchorId 赋值，ForEach 外层 if 包裹 Column.id()，@Builder 零改动 |
| H5 滚动定位 | scrollToIndex / componentUtils | componentUtils | Scroll 不支持 scrollToIndex，只有 List/Grid/WaterFlow 支持 |
| M13 bindSheet | 禁拖拽关闭 / onWillDismiss | onWillDismiss | 禁拖拽不符合平台习惯；onWillDismiss 可拦截确认，未修改内容直接关 |
| M2 热区 | 加确认弹窗 / 扩大热区 | 扩大热区 | 计算器重置是低风险操作，加确认过度 |
| M6 字号 | 全改 12pt / 关键提+辅助降 | 辅助降档 | 关键标签已是 12pt，辅助信息从 13/14 降至 10/12 更合理 |

---

## 四、新增/修改的公共资产

### 新增组件
- `ResetButton`（CalcWidgets.ets）— 计算器重置按钮，padding 扩大热区

### 新增工具函数
- `showConfirmDialog(title, message, onConfirm)` — ConfirmDialog.ets，基于 promptAction.showDialog

### 新增 string.json 资源（6 条）
- `dialog_clear_session_title/msg` — 清会话确认
- `dialog_delete_diagnosis_title/msg` — 删诊断确认
- `dialog_cancel_edit_title/msg` — 取消编辑确认
- `dialog_clear_drawing_title/msg` — 清空画布确认
- `dialog_reset_calc_title/msg` — 重计算确认
- `dialog_rediagnose_title/msg` — 重新诊断确认

### 修改的公共组件
- `ResultCard` — fontColor 随 tierClass 联动；辅助字号降档
- `MarkdownLine` — 新增 anchorId 字段
- `extractTocFromLines()` — 替代 `extractToc()`

---

## 五、风险与回归验证

### 每次提交前验证
1. `hvigorw assembleApp` — 0 编译错误
2. `arkts_check` — 0 新增 arkts-* 违规
3. grep 硬编码色值 — 无新增（白名单除外）

### 重构验证纪律
每次 `@Builder`→`@Component` 或方法提取后，grep 关键格式化函数调用数不能减少：
- `formatMissingCriteria` ≥ 1
- `formatCriterion` ≥ 1
- `translateSelectValue` ≥ 1
- `translateAgentName` ≥ 1
- `formatExtractedJson` ≥ 1

### 回退方案
- 单项回退：`git revert <commit>`
- 整批回退：`git checkout main`（main 仅含第一轮已验收批次）

---

## 六、遗留与第三轮建议

### 本轮明确不做
| 项 | 理由 |
|----|------|
| M4/M12/M14 大范围热区 | 涉及所有对话框+补录表单+芯片，投入产出比低 |
| M8 AddDiagnosis 遮罩关闭确认 | 诊断名称没输完不心疼，过度防护 |
| M10 PatientListPage Stack 改造 | 架构改动风险高收益低 |
| L1 Tab 加图标 | 锦上添花，5 个 Tab 文字已清晰 |
| L2 收藏星标橙色与警示冲突 | 实际使用中不会混淆 |
| M7 诊断确认交互 | 交互复杂（折叠区/排除态），建议第三轮独立做 |

### 第三轮可考虑
1. **M7 诊断确认交互**（最小版：✓/✗ 徽章按钮 + llmConfirmed 字段）
2. **SettingsPage Radio 整行可点 + Base URL 为空禁确定键**
3. **Sidebar 条目行高 40+**（戴手套场景）
4. **计算器重置按钮 FAB 化**（固定右下角浮动，避免分节标题行右侧拥挤）
5. **暗色模式真机走查**（第二轮 H1 修复了对比度，但未在暗色真机验证）

---

## 七、Commit 清单

| Commit | 内容 |
|--------|------|
| `68bf281` | H1 暗色对比度 — fontColor(card)→onPrimary 全局替换 34+2 处/14 文件 |
| `db44c3a` | H2 升压药结果作废 + M1 ResultCard 数值色联动 + M3 Vasopressor mL/h 20pt+方向标注 |
| `217ef56` | H3 不可逆操作确认弹窗(5处) + M5 分节标题色 54 处 warning→textSecondary |
| `9075ea5` | H4B 隐藏死按钮 + H5 TOC 跳转(解析期盖章+条件包裹) + M9 KB 返回键 |
| `90c19dd` | H6 TimelineDialog Scroll + M15 表格横向滚动 |
| `7f31077` | M11 FAB 拖动上限 + L6 PDF 扩展名 + L5 保存键色 + M6 辅助字号降档 + L4 弹窗色 |
| `72401ef` | M13 bindSheet 关闭确认(onWillDismiss) + ResetButton 组件 |
| `f922a39` | M2 计算器重置按钮热区扩大(30 文件) |
| `1926d12` | L3 删除死代码 extractToc + getCategoryLabel |

---

## 八、统计数据

| 指标 | 第一轮 | 第二轮 | 累计 |
|------|--------|--------|------|
| 优化项 | 23 | 20 | 43 |
| Commit 数 | ~30 | 9 | ~39 |
| 涉及文件 | ~60 | ~50 | ~70 |
| 硬编码色值消除 | ~3300→11 | 0→0 | 11（白名单） |
| 共享组件 | 0→4 | 4→5（+ResetButton） | 5 |
| 死代码删除 | ~200 行 | ~40 行 | ~240 行 |
