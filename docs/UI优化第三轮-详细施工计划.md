# MedCalc UI 第三轮 · 详细施工计划

> 生成时间：2026-07-25
> 基于：`UI优化建议-第三轮-视觉设计pass.md` v2 + `验证反馈.md`

---

## 现状盘点

| 维度 | 数据 |
|------|------|
| 计算器文件 | 39 个 `*Calculator.ets` |
| 含 `— ` 分节标题的文件 | 30 个计算器 + CalcWidgets (共约 56 处) |
| 含 `letterSpacing` 的文件 | 19 个，75 处（全部 1 或 1.5，均为中文/混排场景，需删） |
| 图标资源 | 0 个矢量图标（仅 4 个 PNG 应用图标） |
| Tab | 纯文字，无图标 |
| Sidebar | emoji icon 字段 + 首字母缩略 |
| 收藏 | ★/☆ 文本字符 |
| 菜单 | 3 条 Row 手绘 |
| ResultCard | 左右双栏 50%/50%，数值 32pt，footnote 被挤压 |
| CalcCard | 无描边无阴影 |
| AppDimens | fontCaption=12, fontBody=14（缺 spacing1/2/3, fontSectionTitle, fontHero） |
| dark color.json | 机械映射，tier 色未人眼校准 |

---

## 批次 1：V5 卡片描边 + V3 字阶/letterSpacing

### 1A. V5 CalcCard 加描边

**改动**：`CalcWidgets.ets` CalcCard build() 加 `.border({ width: 1, color: AppColors.border })`

**文件**：1 个
- `CalcWidgets.ets:32-41`

**验证**：arkts_check + build

### 1B. V3 字阶 token 补充

**改动**：`AppDimens.ets` 新增 3 个 token

**文件**：1 个
- `AppDimens.ets`：+ `fontSectionTitle=13`、`fontHero=40`、`spacing1=8`、`spacing2=16`、`spacing3=24`

**验证**：arkts_check + build

### 1C. V3 letterSpacing 清理

**分类清单**（已 grep 确认）：

| 类型 | 文件数 | 处理 |
|------|--------|------|
| CalcWidgets ResultCard title (`.letterSpacing(1.5)`) | 1 | 删（中文标题） |
| Sidebar GroupHeader/FavoritesSection (`.letterSpacing(1.5)`) | 1 文件 2 处 | 删（中文） |
| AssistantPage/LlmDialog (`.letterSpacing(1)`) | 2 文件 3 处 | 删（中文） |
| 30 个计算器 `— xxx` 行 (`.letterSpacing(1.5)`) | 30 文件 ~50 处 | 删（中文/混排） |
| BloodGas (`.letterSpacing(1.5)`) | 1 文件 1 处 | 删（中文） |
| Apache2 7 处分节 (`.letterSpacing(1.5)`) | 1 文件 7 处 | 删（中文） |
| Nrs2002 (`.letterSpacing(1.5)`) | 1 文件 1 处 | 删（中文） |
| HuntHess 6 处 (`.letterSpacing(1.5)`) | 1 文件 6 处 | 删（中文/混排） |
| Rass 2 处 (`.letterSpacing(1.5)`) | 1 文件 2 处 | 删（中文） |

**策略**：全部删除，因为全部是中文或中英混排场景，无纯西文标题。

**文件**：~19 个
**验证**：arkts_check 批量 + build

### 1D. V3 lineHeight 统一

**改动**：
- CalcWidgets InputRow label (14pt)：无 lineHeight → 不动
- CalcWidgets ResultCard footnote (12pt)：已有 lineHeight(18) → 不动
- CalcCard 无 lineHeight 需求

**结论**：当前 lineHeight 已合理，本轮不改。

**commit**：`style: V5 CalcCard border + V3 font tokens + letterSpacing cleanup`

---

## 批次 2：V2 ResultCard Hero 化

**改动**：`CalcWidgets.ets` ResultCard 组件重构

**具体**：
1. 数值 `.fontSize(40)` + `.fontFeature('tnum')`，删除 `valueFontSize`/`valueMarginTop` 参数（统一 Hero 尺寸）
2. 布局从左右双栏改为上下结构：标题+数值+tier 胶囊在上，footnote 通栏在下
3. 左侧 4px tier 色竖条：`Row` 外层加 `Clip` + 左侧 `Row().width(4).backgroundColor(getTierColor(tierClass))`
4. 卡底 tier 氛围色：`backgroundColor(tierClass.length > 0 ? getTierBgColor(tierClass) : AppColors.card)`
5. 空态：数值区灰化（`fontColor(AppColors.textFaint)`），保持 "—" + "请填写必填项" 胶囊
6. tier 胶囊预留图标位（V1 完成后补入，暂放文字）

**文件**：1 个
- `CalcWidgets.ets` ResultCard (行 100-200)

**风险**：38 个计算器自动继承，需验证多计算器布局无回归
**验证**：arkts_check + build + 抽查 SOFA/APACHE2/GCS/PF/BloodGas

**commit**：`feat: V2 ResultCard Hero layout with tier accent`

---

## 批次 3：V1 图标体系

### 3A. SVG 资源入库（Remix Icon）

**清单**（18 个）：
- Tab×5：`ic_calculator`, `ic_assistant`, `ic_patient`, `ic_knowledge`, `ic_settings`
- 顶栏×3：`ic_menu`, `ic_star`, `ic_star_filled`, `ic_chevron_left`
- Sidebar 分类×8：`ic_lungs`, `ic_heart_pulse`, `ic_kidney`, `ic_liver`, `ic_brain`, `ic_metabolism`, `ic_infection`, `ic_general`
- Tier×4：`ic_check_circle`, `ic_info`, `ic_alert_triangle`, `ic_alert_octagon`
- 空态×1：`ic_inbox`

**做法**：
1. 从 Remix Icon SVG 库选取对应图标
2. 批量转换：stroke→fill（Remix Icon 本身是 fill 系，无需转换），currentColor→#000000
3. 跑批量检查脚本
4. 放入 `resources/base/media/ic_*.svg`

### 3B. IconButton 组件封装

**改动**：`CalcWidgets.ets` 新增 `IconButton` struct

### 3C. Tab 加图标

**改动**：`Index.ets` TabBarBuilder — Column 内加 Image + 文字调 11pt

### 3D. 顶栏改造

**改动**：`Index.ets`
- MenuIcon() → IconButton({ iconResource: $r('app.media.ic_menu') })
- ★/☆ → IconButton({ iconResource: $r('app.media.ic_star')/ic_star_filled })

### 3E. Sidebar 改造

**改动**：`Sidebar.ets`
- GroupHeader 加图标
- CalculatorItem 的 emoji icon → SVG 图标

**验证**：arkts_check + build + 真机暗色模式验证 fillColor

**commit**：分 2-3 个（资源入库 / 组件封装+Tab / 顶栏+Sidebar）

---

## 批次 4：V4 间距 + SectionTitle 38 文件替换

### 4A. SectionTitle 组件

**改动**：`CalcWidgets.ets` 新增 `SectionTitle` struct
- 13pt Bold textSecondary
- 右侧可选 ResetButton 槽位（`resetAction?: () => void`）
- 无手工破折号前缀

### 4B. 38 计算器文件替换

**脚本策略**：
- Pattern: `Text('— xxx').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5)` → `SectionTitle({ title: 'xxx', resetAction: ... })`
- 分两批：
  - 批 4B-1：简单 `— 输入参数` 行（约 20 个文件，Row 包裹 + ResetButton 模式一致）
  - 批 4B-2：复杂多分节文件（SOFA/APACHE2/CLIF-C/Vasopressor/TIMI/HuntHess/KDIGO 等）

**验证**：脚本替换 → diff 确认 → 批量 arkts_check → build → 抽查重置流程

**commit**：`refactor: V4 SectionTitle component + batch replace` (分 2 个)

---

## 批次 5：V6 微动效

### 5A. ResultCard 结果出现动画

**改动**：`CalcWidgets.ets` ResultCard
- 新增 `@State resultOpacity: number` + `@State resultTranslateY: number`
- 空态→出分 / tier 变化时触发 `animation({ duration: 200, curve: Curve.EaseOut })`
- 纯数值跳动不触发

### 5B. OptionChip 选中过渡

**改动**：`CalcWidgets.ets` OptionChip
- 加 `.animation({ duration: 150 })` 在背景色/文字色属性后

### 5C. Tab 指示条动画

**改动**：`Index.ets` TabBarBuilder
- 指示条 Row 加 `.animation({ duration: 150 })`

**验证**：build + 真机验证快速输入不鬼畜

**commit**：`feat: V6 micro-animations (result/chip/tab)`

---

## 批次 6：V7 暗色模式精调

### 6A. tier 色校准

**改动**：`dark/element/color.json`
- tier_ok: `#5A9A78` → 提亮至 `#6AAA88`（对比度需 ≥4.5:1 on #2A2A2A）
- tier_warn: `#E0B050` → 保持或微调
- tier_danger: `#E07060` → 保持或微调
- tier_ok_bg: `#1E3A28` → 确认可读
- tier_warn_bg: `#3A3018` → 确认可读
- tier_danger_bg: `#3A1A1A` → 确认可读

### 6B. 卡片层次精调

**改动**：`dark/element/color.json`
- card: `#2A2A2A` → `#2E2E2E`（拉开与 #1A1A1A 背景差距）
- border: `#404040` → `#4A4A4A`（加强可读性）

### 6C. 全量暗色走查

**清单**：5 Tab + SOFA/APACHE2/GCS + 患者详情四卡 + KB 阅读器 + 助手 + 弹窗

**验证**：真机暗色模式逐项走查

**commit**：`style: V7 dark mode tier/color refinement`

---

## 总工期估算

| 批次 | 预估改动量 | commit 数 |
|------|-----------|----------|
| 1 | 1A(1 行) + 1B(5 行) + 1C(~75 处删 letterSpacing) | 1 |
| 2 | 1 文件重构 ResultCard | 1 |
| 3 | 18 SVG + IconButton + Tab + 顶栏 + Sidebar | 2-3 |
| 4 | SectionTitle 组件 + 38 文件脚本替换 | 2 |
| 5 | 3 处 animation | 1 |
| 6 | color.json 微调 + 走查 | 1 |

**总计**：约 8-9 个 commit
