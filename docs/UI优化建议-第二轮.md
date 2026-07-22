# MedCalc UI 优化建议 · 第二轮（纯建议，未改任何代码）

> 生成时间：2026-07-21
> 来源：截图审查（screenshots/ 9 张 + test_screenshots/ 13 张，**注意：均为 07-10~12 旧版截图，反映的是大改前 UI**）+ 当前代码只读审查（entry/src/main/ets/，即 `ui-overhaul` 大改完成后的状态）。
> **本文档只提建议，不含任何代码改动。施工前必读：`docs/UI优化清单.md`（上一轮 23 项已完成）、`docs/UI优化交接.md`（铁律 §3）、`PITFALLS.md`（踩坑日志）。**

## 总体结论

第一轮大改后底子已经很好（token 化、暗色、共享组件、热区/字号、空态）。本轮发现的问题集中在四类：

1. **暗色模式对比度遗留（系统性，影响面最大）**：大量"彩色底徽章/按钮"的文字色用了 `AppColors.card`，亮色系下它是白色没问题，但 dark 下 card 是深灰 `#2A2A2A`，压在 primary/tier 色/危险红上对比度严重不足。`AppColors.onPrimary` 已定义却几乎没被用上。
2. **误操作防护不足**：多个"一键不可逆"操作（清会话、删诊断、删 LLM 配置、图片编辑取消/清空、计算器重置）没有二次确认，热区也偏小——床旁戴手套场景风险高。
3. **两个死/假功能**：患者详情"输入文本"按钮无 onClick（PITFALLS 待办仍属实）；知识库 TOC 目录点击不跳转。
4. **结果时效性**：升压药换算修改参数后旧结果不作废，床旁调泵速场景有误读旧值风险。

---

## 🔴 高优先级

### H1. 暗色下"彩底白字"徽章文字色错误（系统性，已核实）
- **证据**：`AppColors.card` 在 dark 下 = `#2A2A2A`（深灰），被大量用作彩色底上的文字色。典型位置：
  - `calculators/widgets/CalcWidgets.ets:233,246`（OptionChip 选中态文字）
  - `BloodGasCalculator.ets:841,908,949`（tier 徽章）
  - `patient/AlertSubviews.ets:49`、`patient/DetailPageViews.ets:51,588`（计数徽章）
  - `patient/DashboardPreviewCards.ets:27,141,229,311`、`patient/PatientDetailDialogs.ets:44,68,103,173,274,333`
  - `KnowledgeSearchPage.ets:439,539,619,634`（含分类卡用 `background` 当文字色，dark 下深字压深色块）
  - `AssistantPage.ets:368`（用户气泡）、`LlmDialog.ets:196,198,260`
- **建议**：全部改用已定义的 `AppColors.onPrimary`（dark=`#E8F0EA`）。改完暗色模式逐页走查一遍徽章类元素。

### H2. 升压药换算：改参数后旧结果不作废（已核实）
- **证据**：`VasopressorCalculator.ets:236` 结果卡由 `calculated` 控制，而 `calculated = false` 只出现在 `reset()`（`:140`）；体重/浓度/药物/输入框的 onChange 均不作废结果。
- **场景**：床旁调泵速——改完体重没点"计算"，屏幕上还是旧 mL/h，极易照抄旧值。
- **建议**：任一输入 onChange 时置 `calculated=false`（或结果卡显示"参数已变更，请重新计算"置灰态）。

### H3. 一组"无确认不可逆"操作（误操作风险，已核实）
| 位置 | 操作 | 现状 |
|---|---|---|
| `AssistantPage.ets:310-320` | 🗑 清空整段会话 | 一键即清，无确认 |
| `patient/DetailPageViews.ets:174-182,457` | 删除用户诊断 '×' | 14pt 无热区，无确认即删 |
| `SettingsPage.ets:350-359` | 删除 LLM 配置 | 10pt/22px 小按钮，与测试/编辑挤一行，无确认 |
| `ImageEditor.ets:424-430` | 取消（放弃全部马赛克） | 无确认 |
| `ImageEditor.ets:534-556` | 清空（紧邻撤销，均 32 高） | 想撤销误点清空即全灭，无确认 |
| `patient/DetailPageViews.ets:291-300` | '⟳' 重诊断（触发全量重算+LLM 调用） | 裸文本约 20pt 热区，无确认，loading 中仍可点 |

- **建议**：统一复用 DeleteConfirmDialog 模式做二次确认；危险按钮热区 ≥32pt、拉开与相邻按钮间距；重诊断在 loading 期间禁用。危险色统一 `AppColors.danger`（目前 records 删除用 warning 橙 `DetailPageViews.ets:720`、确认弹窗也用橙 `PatientDetailDialogs.ets:334`，三处不一致）。

### H4. 患者详情"输入文本"按钮是死按钮（已核实，PITFALLS 待办属实）
- **证据**：`PatientDetailPage.ets:569-576`，无 onClick。
- **建议**（二选一）：
  - A（完整方案）：点击弹出与 ManualInputDialog 同风格的文本录入 Sheet——大 TextArea + "识别并提取"按钮，文本送 LLM 提取后走 `mergeExtractedData` 复用现有管线；
  - B（短期）：先隐藏该按钮，避免用户点了没反应。
- 注：底部 4 个操作按钮均 40 高/12pt（`:552-585`），4 等分后每键约 80pt 宽，戴手套局促；建议 2×2 布局或缩为 3 键+更多菜单。

### H5. 知识库 TOC 目录点击不跳转（假功能）
- **证据**：`KnowledgeSearchPage.ets:788`，TOC 条目 onClick 只关面板，不滚动定位。
- **建议**：用 pageScroller.scrollToIndex 或按标题索引定位，让目录成为真导航。

### H6. TimelineDialog 内容溢出（已核实）
- **证据**：`patient/PatientDetailDialogs.ets:31-98`，ForEach 直出无 Scroll；同指标几十次采集后列表溢出，底部"关闭"被顶出屏。
- **建议**：列表包 Scroll + `constraintSize({maxHeight})`；顺便实现 PITFALLS 待办"数据趋势图"——Dialog 顶部加 120–160pt 高 Canvas 折线图（点=采集值，参考上下限画虚线），下方保留现有文字列表。

---

## 🟡 中优先级

### 计算器
- **M1. ResultCard 大数值颜色不随 tier 联动**：`CalcWidgets.ets:164` 数值固定 primary 绿，异常结果（tier-danger）也是绿大字，危急程度只靠小胶囊。建议数值色随 tierClass 联动。
- **M2. "重置"按钮防误触**：各计算器分节标题右侧的重置是 12pt 纯文本无热区（如 `Apache2Calculator.ets:132`、`GcsCalculator.ets:40`），戴手套误触一下清空 14 项已填参数。建议加 padding 至 44 热区；APACHE II 等多字段计算器考虑二次确认或"撤销重置"。
- **M3. Vasopressor 信息层级颠倒**：`:241-242` 药名 22pt Bold，关键输出 mL/h 仅 15pt——泵速才是要抄的数。建议 mL/h 28pt+。另：双向换算方向取"最后编辑的框"（`:53,58`），对用户不透明，建议显式分段选择换算方向。
- **M4. 小热区残留**：Vasopressor 药物芯片 32 高（`:179`）、BloodGas 急性/慢性 32（`:291,299`）、单位切换 28，均 < 44。
- **M5. 小节标题滥用 warning 橙**：所有计算器 `— xxx` 分节标头用 `AppColors.warning`，橙色被装饰消耗，真正警示失去辨识度。建议改 `textSecondary` 或 `primary`。

### 患者页
- **M6. 小字号残留**：patient/ 目录 38 处 `fontSize(9/10/11)`（urgency 标签 10pt `DetailPageViews.ets:159`、"缺："11pt `:187`、Agent 步骤 9–10pt `DiagnosisKbSection.ets:289-299`、时间线 10pt `PatientDetailDialogs.ets`）。弱光+快速扫读低于可读下限，建议辅助信息最低 11pt、关键标签 12pt。
- **M7. 诊断确认交互未做**（PITFALLS 待办属实）：模型已有 `llmConfirmed` 字段（`DetailPageViews.ets:165-173`）但无操作入口。建议：诊断卡加 ✓/✗ 两个 ≥32pt 徽章按钮（或长按弹菜单），确认后标签变绿"已确认"、排除后置灰移入折叠区。
- **M8. AddDiagnosisDialog 点遮罩即关**：`PatientDetailDialogs.ets:439-441`，输入一半误触外部全丢；其他对话框反而无遮罩关闭——行为不一致。建议统一：有内容时弹确认或无遮罩关闭。
- **M9. KbReaderOverlay 无返回键处理**：`PatientDetailPage.ets:140-164` 的 navigateBack 不处理 showKbReader，浮层打开时按系统返回会直接退出整个详情页。建议在 navigateBack 链最前加 `if (showKbReader) 关闭浮层`。
- **M10. PatientListPage 对话框布局**：`:163-168` 对话框是根 Column 尾部子节点而非 Stack 叠加，弹出时列表被压扁、遮罩盖不住顶栏。建议根改 Stack。另：`+新建` 32 高在右上远点（`:63`），建议 40+ 或底部 FAB；患者名无 maxLines（`:104`）；搜索无结果与空列表同文案"暂无患者"（`:83`），建议区分"未找到匹配患者"。

### 助手 / 设置
- **M11. LlmDialog**：FAB 拖动只钳制下限（`:130-131`），可拖出屏幕无法找回，建议加上限钳制；点遮罩关闭同时清空 userInput/results（`:81-83`），建议保留草稿。
- **M12. 助手补录表单控件 28–32 高**：`AssistantPage:577,602,640,657`，对话内补录是核心流程，建议 ≥36。
- **M13. SettingsPage**：Radio 仅 20×20 圆点可点（`:299-307,395-435`），建议整行可点；编辑 LLM 的 bindSheet 可下拉关闭丢表单（`:471-476`），建议禁拖拽或离开时提示；Base URL/Key 为空时点确定静默失败（`:135-136`），建议禁用态或错误提示。
- **M14. 所有对话框按钮高 36 < 44**：`PatientDetailDialogs.ets` 全部 5 个对话框 + `PatientListPage.ets:307,318` 删除确认。

### 知识库
- **M15. 表格无横向滚动**：`KbMarkdownRenderer.ets:120-127,146-153`、`KnowledgeSearchPage.ets:927-960`，多列表格被 layoutWeight 均分挤压换行，指南剂量表基本不可读。建议表格外层包横向 Scroll（CodeBlockView 已有此模式可参考）。

---

## ⚪ 低优先级

- **L1. Tab 栏仅文字无图标**（`Index.ets:154-169`）：5 个 Tab 纯 14pt 文字，床旁扫读定位慢，建议加图标。
- **L2. 收藏星标用 warning 橙**（`Index.ets:325`）：与"警示"语义冲突，建议换专属色。同理 `DashboardPreviewCards.ets:229` 数据项计数用 tierOk 绿底——计数是中性信息，建议 fillNeutral。
- **L3. Sidebar**：计算器条目行高约 32–36（`Sidebar.ets:111`），40+ 条密集列表戴手套易串行，建议 40+；`CollapsedView`（`:121-153`）是不可达死代码，建议删除；收藏区与全量列表间无分隔。
- **L4. 死代码/小瑕疵**：BloodGas `:305-306` 重复 `.margin({left:6}).margin({left:8})`；Apache2 pH/HCO₃⁻ 互斥时禁用框无视觉说明（`:190-191`）；`Index.ets:283` 遮罩 `rgba(0,0,0,0.35)` 硬编码。
- **L5. ExamTimeEditor 保存键用 tierOk 绿**（`PatientDetailDialogs.ets:174`）：主操作应统一 primary。
- **L6. PdfDocument 扩展名**（PITFALLS 待办属实）：`ImageStore.ets:90-98` `getExtFromUri` 不认 `.pdf`，副本存成 `.jpg`，目前靠内容解析未炸但属隐患。
- **L7. 助手杂项**：发送键 40 宽略小（`AssistantPage.ets:994`）；附件菜单 position 固定 y:-80 硬编码（`:953`）。
- **L8. 阅读页返回键仅 20pt 箭头**（`KnowledgeSearchPage.ets:708-712`）：建议 40pt 热区。

---

## 建议施工顺序

1. **H1**（onPrimary 全局替换，暗色对比度）→ 改完暗色走查全部徽章
2. **H2**（Vasopressor 结果作废）+ **M1**（ResultCard 数值色联动）+ **M2**（重置防误触）——计算器一批
3. **H3**（确认弹窗统一）+ **H6**（TimelineDialog Scroll + 趋势图）——患者页一批
4. **H4**（输入文本按钮）+ **H5**（TOC 跳转）+ **M9**（KbReaderOverlay 返回键）——死功能修复
5. 中/低优先级按页面顺手清

## 施工纪律提醒（沿用上一轮）

- 一个逻辑改动一个 commit，每个 commit 前 `hvigorw assembleApp` 必须 0 错误（环境变量见交接文档 §1.2）
- 新增色值只加 token，禁止硬编码 `#RRGGBB`（白名单仅 ImageEditor 画布色）
- 动计算器输入区必须保住 resetKey 分支切换包住输入子树，否则重置静默失效
- "无/有"按钮是三态 number（−1/0/1），不是 boolean
- 截图已过期：施工前建议先出一版当前真机截图作基线，施工后对照
