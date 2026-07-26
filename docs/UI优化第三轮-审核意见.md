# MedCalc UI 优化第三轮 · 审核意见

> 审核时间：2026-07-25
> 审核对象：第三轮视觉设计 Pass（施工单 v2，`docs/UI优化建议-第三轮-视觉设计pass.md`）
> 审核方式：逐项 diff 抽查 + 规范 grep + 亲自构建（`BUILD SUCCESSFUL in 21s`）
> 审核人：建议方 AI

## 总体结论

**主体合格，准予通过，6 个尾巴需处理（2 个功能缺项 + 4 个小项）。** 施工质量比第二轮更稳：SVG 规范自查通过、SectionTitle 迁移彻底（Apache2 的 7 个自定义分节也全部迁移且命名更好）、动画方案完全按 v2 纪律执行。**全部改动仍在工作区未提交（75 文件 + 22 SVG），需按批次补 commit。**

## 抽验通过项

| 项 | 验证结果 |
|---|---|
| V1 SVG 资源 | 22 个 `ic_*.svg` 入库，`stroke=/currentColor/<style` 批量检查 **0 违规**（v2 红线 V1-SVG-02 执行到位） |
| V1 Tab/顶栏 | Tab 图标+11pt 文字、fillColor 选中变色 ✓；收藏星换 SVG 且改品牌绿（顺带解决 L2 橙色语义遗留）✓；菜单手绘三杠换 SVG ✓；Sidebar 8 个分类图标 ✓ |
| V2 ResultCard Hero | 40pt + `fontFeature('tnum')` ✓；左侧 4px tier 竖条 + `getTierBgColor` 卡底氛围 ✓；空态 textFaint + opacity 0.4 灰化 ✓；footnote 改通栏不再挤压 ✓ |
| V3 字阶 token | `fontSectionTitle=13 / fontHero=40 / spacing1-3` 全部入库 ✓ |
| V4 SectionTitle | 组件落地，40 个文件迁移，`'— '` 手工前缀 **grep 零残留**；Apache2 的 7 个分节（生命体征/氧合参数/酸碱状态…）全部迁移 ✓ |
| V5 CalcCard 描边 | `border({width:1, color:border})` ✓，暗色边界问题根治 |
| V6 动效 | OptionChip `animation({duration:150})`、ResultCard `animation({duration:200})` —— 均为属性动画，触发于颜色/透明度变化（即空态→出分、tier 变化），符合 V6-ANIM-01/02；数值跳动不播动画 ✓ |
| V7 暗色精调 | card `#2A→#2E`、border `#40→#4A`、tierOk `#5A9A78→#6AAA88` 提亮 ✓（与施工单给出的备选值完全一致） |

## 问题清单

### P1. tier 胶囊图标与空态图标未实现（功能缺项，5 个 SVG 死资源）
`ic_check_circle / ic_info / ic_alert_triangle / ic_alert_octagon / ic_inbox` 在 ets 中**零引用**。施工单 V2 第 5 条（tier 胶囊加图标）和 V1 清单中的空态图标未落地。建议补做（ResultCard 胶囊内 Image+文字即可，一个组件的事），或删除未用 SVG。

### P2. letterSpacing 一刀切全删（与施工单偏差，minor）
75→0，但 v2 施工单明确"纯西文保留 1.5"——ResultCard 标题（'SOFA Total'、'MAP' 等纯西文）的 letterSpacing 也被删了。视觉差异细微，可接受；若要严格执行施工单，给 ResultCard title 加回 `.letterSpacing(1.5)`（西文标题场景）。

### P3. Tab 指示条被移除（与施工单偏差，可接受但需确认）
施工单写"指示条保留"，实际删除了 24×2 指示条，仅靠图标+文字变色表达选中态。个人认为图标+变色已足够清晰，属合理简化——但这是未声明的偏差，确认后建议在施工单补记。

### P4. IconButton 定义但零调用（死组件）
`CalcWidgets.ets:271` 的 IconButton 无任何调用方——Index/Sidebar 均为内联 Image+fillColor（效果等价，未发现灰底渗出）。按 V1-SVG-03 要么把内联处迁到 IconButton，要么删除该组件。

### P5. CalcWidgets 组件文档注释被删（维护性，minor）
ResultCard 的 props 逐条注释（valueFontSize/unitInline/titleMedium 等用法说明）在重写时丢失。这是 38 个计算器共用的核心组件，建议把关键 props 注释补回。

### P6. V4 描述块样式化未做（施工单标注"顺手做"，可推后）
各计算器描述块仍是 14pt 裸文本（如 `PfCalculator.ets:39`），未按施工单改 15pt+分隔线。不阻塞，可并入后续批次或明确放弃。

## 必须立即处理

**全部改动未提交**：75 个修改文件 + 22 个 SVG + 4 个文档都在工作区。按施工纪律应拆批 commit（建议：V5+V3 / V2 / V1 / V4 / V6+V7 五批，或至少按"共享组件 / 页面框架 / 资源"三批），每个 commit 前构建已验证通过。

## 未覆盖项声明

真机视觉效果（图标观感、tier 氛围色实际表现、动画流畅度、暗色 V7 走查）无法模拟，需装机按施工单"验收总清单"过一遍亮/暗双模式，并更新 screenshots/ 基线（现有截图已全部过期）。
