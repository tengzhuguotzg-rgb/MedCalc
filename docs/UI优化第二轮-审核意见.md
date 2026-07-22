# MedCalc UI 优化第二轮 · 审核意见

> 审核时间：2026-07-22
> 审核对象：`UI优化第二轮-工程报告.md`（9 commits，`68bf281`…`1926d12`，分支 ui-overhaul）
> 审核方式：逐项对照 git 提交 + 关键代码亲自抽查 + 亲自构建（非转述报告结论）
> 审核人：建议方 AI

## 总体结论

**主体可信，准予通过，但有 4 个问题需要返修/回退。** 报告的施工记录与 git 提交一一对应，关键项抽查全部落地；构建 `BUILD SUCCESSFUL in 22s`（审核人亲自运行，非引用报告）。但报告存在 1 处虚报、1 处货不对板、2 处收尾不干净。

## 抽验通过项（亲自看过代码）

| 项 | 验证结果 |
|---|---|
| H1 onPrimary | `fontColor(AppColors.card)`/`Color.White` 全 ets 零残留；`onPrimary` base=#FFF / dark=#E8F0EA 已正确定义 |
| H2 结果作废 | Vasopressor 5 个 onChange + 药物芯片 onClick 全部置 `calculated=false` |
| M1 数值色联动 | `CalcWidgets.ets` ResultCard 数值色随 tierClass 走 `getTierColor` |
| M3 信息层级 | mL/h 20pt Bold+primary，新增换算方向标注行 |
| H3 确认弹窗 | 6 个调用点（清会话/删诊断/重诊断/ImageEditor取消/清空/M13）；ImageEditor 取消有 `strokeCount>0` 条件，且 strokeCount 在 undo 时同步（`:335`） |
| H4B | "输入文本"死按钮已删除 |
| H5 TOC | 按方案实施：anchorId 盖章 + extractTocFromLines + 条件包裹 + getRectangleById + setTimeout(100)，旧 extractToc 已删 |
| M9 | navigateBack 链最前有 showKbReader 拦截（`PatientDetailPage.ets:141-142`） |
| H6 | TimelineDialog 外包 Scroll + maxHeight 360 |
| M15 | 两个文件的表格均有 `scrollable(Horizontal)` |
| M11 | FAB `Math.min(maxRight/maxBottom)` 钳制，屏幕尺寸经 display API 换算（vp/160） |
| L6 | `.pdf` 映射已加 |
| M2 | ResetButton 组件落地，38 文件引用，resetKey 机制完好（抽查 Apache2） |
| L3 | extractToc 全库零引用，已删 |

## 问题清单（需返修）

### P1. 报告虚报：6 条 string 资源是死资源 —— 中
报告称"新增 string.json 资源（6 条）"。资源确实写进了 `string.json:512+`，但 6 个 `showConfirmDialog` 调用点全部传**硬编码中文字面量**（如 `showConfirmDialog('删除诊断', '确定要删除此诊断项吗？', …)`），资源在 ets 中**零引用**。要么把调用点改 `$r('app.string.dialog_xxx')`，要么删掉资源。建议前者（延续第一轮 #16 资源化方向）。

### P2. M6 货不对板，且疑似负优化 —— 高（建议回退 footnote 部分）
- 共识 M6 是"患者页关键小标签提到 12pt"——`DetailPageViews.ets` 的 urgency 标签 10pt（`:160`）、"缺："11pt（`:189`）等**原样未动**，这部分没做。
- 实际做的是一个**不在共识内**的改动：ResultCard 辅助字号降档。其中 `footnote 14→10pt`（`CalcWidgets.ets:185`）砍的是**临床说明正文**，与床旁可读性原则直接冲突，且残留 `lineHeight(22)` 与 10pt 字不匹配。
- 建议：footnote 回退 14pt（或至少 12pt）；tier 13→12、单位 12→10 可保留；共识 M6 的患者页部分补做或明确推给第三轮。

### P3. 危险色统一没做完 —— 中
- records 删除仍是 `AppColors.warning` 橙（`DetailPageViews.ets:720`），与删诊断的 danger 红仍不一致。
- 重诊断 ⟳ 仍是 **tierOk 绿**裸文本（`DetailPageViews.ets:297-301`），热区无扩大，共识 H3 附加项"loading 期间禁用"未做。触发全量重算+LLM 的操作用绿色语义也不对。

### P4. ConfirmDialog 硬编码色开新口子 —— 低
`ConfirmDialog.ets:11-12` 硬编码 `#888888/#CC3333`，理由"promptAction 只接受 string"不成立——`showDialog` 的 button `color` 是 `ResourceColor`，可用 `$r('app.color.xxx')`。第一轮刚把 3300 处硬编码清零，这里又新增 2 处。建议改 `$r`（取消=textSecondary，确定=danger）。

## 小瑕疵（不阻塞）

- H5 scrollTo 未带 `animation: true`，跳转是瞬移而非平滑滚动（方案文档里有，实现漏了）
- 报告统计表"L（低）计划 3 / 完成 5"数字对不上
- 报告说 M2 是 30 文件，实际 38 文件引用 ResetButton（无妨，但说明统计是估的）

## 验证环境备注

本仓库无 hvigorw 包装脚本，构建命令为：
```bash
export DEVECO_SDK_HOME="D:\Program Files\DevEco Studio\sdk"
export PATH="$PATH:/d/Program Files/DevEco Studio/jbr/bin"
node "/d/Program Files/DevEco Studio/tools/hvigor/bin/hvigorw.js" assembleApp
```
（`docs/UI优化交接.md` §1.2 的 `hvigorw assembleApp` 写法在本机不适用，建议更正交接文档）

## 返修复核（2026-07-22，commit `66e3beb`）

P1–P4 已全部返修，复核通过，构建 `BUILD SUCCESSFUL in 12s`（审核人亲自运行）：

| 项 | 复核结果 |
|---|---|
| P1 死资源 | ✅ 6 处 showConfirmDialog 硬编码字面量零残留，全部 `$r` 接线 |
| P2 footnote | ✅ 12pt + lineHeight 18（在建议的 12–14 可接受区间）；共识 M6 患者页部分推第三轮 |
| P3 危险色 | ✅ records 删除 warning→danger；⟳ tierOk→warning。未做"loading 禁用 ⟳"，小项不阻塞 |
| P4 硬编码色 | ✅ 签名改 ResourceStr，新增 dialog_cancel/dialog_confirm token（base `#5F6654/#B1452A`，dark 有映射） |

**遗留疑点已修复（2026-07-22 晚）**：H5 动画原为 `animateTo` 包裹命令式 scrollTo（对非属性动画无效）。已改为 scrollTo 自带参数 `animation: { duration: 300, curve: Curve.EaseInOut }`（`KnowledgeSearchPage.ets:798-802`），构建通过。修复人：审核方 AI。

**最终结论：第二轮 20 项 + 返修全部验收通过。** 剩余门槛只有真机走查（暗色观感/TOC 定位/FAB 手感/表格滑动），通过后可合 main。

## 未覆盖项声明

以下为真机才能验证的，本次审核未覆盖：暗色模式徽章实际观感（H1）、TOC 跳转定位精度（H5）、FAB 拖动边界手感（M11）、表格横向滑动手感（M15）。建议装机走查后再合 main。
