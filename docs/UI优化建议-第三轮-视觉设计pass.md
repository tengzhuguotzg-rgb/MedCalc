# MedCalc UI 优化第三轮 · 视觉设计 Pass 施工单

> 生成时间：2026-07-22（v2 修订：2026-07-25，合入施工 AI 技术验证反馈，见文末"修订记录"）
> 定位：以**美观为目标、实用为约束**的视觉品质提升。约束红线：不降低热区（≥44）、字号（辅助≥11/关键≥12）、对比度（≥4.5:1）、层级效率；不改配色体系（米底+深绿）；不改页面结构
> 前置：第一、二轮 43 项已完成并验收（见 `docs/UI优化清单.md`、`docs/UI优化第二轮-审核意见.md`）
> 施工纪律沿用：一个逻辑改动一个 commit；每次 commit 前构建 0 错误；新色值只加 token；动计算器输入区必须保住 resetKey 机制

---

## 总体思路

美观的核心杠杆是**图标、字阶、留白、层级、动效**——都不需要动代码结构。38 个计算器走共享组件，主要改动集中在 `CalcWidgets.ets` + `Index.ets` + 资源文件，**禁止逐文件美化**。

| 项 | 内容 | 主战场 | 感知度 | 工作量 |
|---|---|---|---|---|
| V1 | 图标体系（零矢量图标的现状终结） | resources + Index + 各页 | ★★★★★ | 中 |
| V2 | ResultCard Hero 化 | CalcWidgets 一个组件 | ★★★★★ | 小 |
| V3 | 字阶与中文排印修正 | CalcWidgets + 全局小改 | ★★★ | 小 |
| V4 | 间距节奏 + 分节标题规范化 | AppDimens + CalcWidgets + 计算器一处 | ★★★ | 中 |
| V5 | 卡片层次（描边/浅阴影） | CalcWidgets 一处 | ★★★★ | 小 |
| V6 | 微动效 | Index + CalcWidgets | ★★★ | 中 |
| V7 | 暗色模式精调（非映射，是设计） | color.json dark + 走查 | ★★★★ | 中 |

---

## V1. 图标体系（最大杠杆）

**现状证据**：全 App 零矢量图标——`resources/base/media/` 只有应用图标 4 个文件；Tab 纯文字（`Index.ets:154-169`）；菜单图标是三条手绘 Row（`Index.ets:336-340`）；收藏是文本字符 ★/☆（`Index.ets:318`）；知识库分类是色块+首字。

**做法**：
1. 选一套 **fill 绘制**的开源图标（fillColor 只对 fill 生效，stroke 系图标如 Lucide/Feather 全部无法上色，禁用）：**首选 Remix Icon**（fill、2400+、Apache 2.0），备选 Phosphor fill 变体 / Material Symbols Filled。导出 SVG 放 `resources/base/media/`，命名 `ic_*.svg`
2. SVG 入库规范（验证反馈已证实为硬约束）：
   - 必须 fill 绘制，禁止 stroke；禁止 `currentColor`（导入时用脚本批量替换为 `fill="#000000"`）；禁止 `<style>` 内联、opacity、filter
   - 入库后跑批量检查：`grep -l 'stroke=\|currentColor' resources/base/media/ic_*.svg` 必须为空
3. 封装 `IconButton` 组件（Row + Image + fillColor + `backgroundColor(Color.Transparent)`，尺寸走 AppDimens.touchTarget），Tab/顶栏/Sidebar 统一调用，不直接裸写 Image（Button 等容器有默认灰底会渗出）
4. 首批清单（约 18 个）：
   - Tab×5：计算器、助手、病历、知识库、设置
   - 顶栏：菜单、收藏星（空心/实心）、返回
   - 计算器分类（Sidebar 分组标题）：呼吸、心血管、肾、肝、神经、代谢、感染、综合
   - 结果 tier：正常/轻度/中度/重度
   - 空态：文档
5. Tab 改为 图标+文字（图标 20-22px，文字 11-12pt），指示条保留
6. `Image($r('app.media.xxx')).fillColor(...)` 上色，深浅色模式用同一 SVG 不同色值，**不为暗色单独出图**
7. ★/☆ 文本字符替换为 star SVG（同时顺手解决 L2 遗留的橙色语义问题：改用品牌绿实心星）

**验收**：5 个 Tab + 顶栏 + Sidebar 分组 + ResultCard tier 均有图标；暗色下图标颜色正确（fillColor 走 token）；无拉伸变形；SVG 批量检查 0 违规。

## V2. ResultCard Hero 化

**现状证据**：`CalcWidgets.ets:152-199`——结果卡与输入卡同为普通白卡；数值 32pt 比例字体；footnote 被挤在右栏 50%（`:183-190`）；空态仅一个"—"。

**做法**（只改 ResultCard 一个组件，38 个计算器自动继承）：
1. 数值升 40pt Bold，加 `.fontFeature('tnum')` 等宽数字（已验证 ArkUI 原生支持，无需 fallback）
2. 整卡 tier 氛围：左侧 4px tier 色竖条 + 卡底用 `getTierBgColor(tierClass)`（token 已有，**禁止 alpha 拼接**，见 PITFALLS 07-20）；空态（tierClass 为空）保持白卡
3. footnote 从右栏 50% 改为数值区下方通栏（上下结构），数值与说明不再互相挤压；`lineHeight` 保持 18
4. 空态设计：标题 + "—"（40pt 浅灰）+ "请填写必填项"胶囊维持，但整体视觉降噪（数值区灰化）
5. tier 胶囊加 V1 的 tier 图标（图标+文字）

**验收**：抽查 SOFA/APACHE II/GCS/PF 四个计算器——空态→录入→正常/预警/危急三档 tier 各看一次，竖条+底色随 tier 变化；footnote 长文本（BloodGas 解释）不再挤压；重置后回空态。

## V3. 字阶与中文排印

**现状证据**：辅助 12 / 正文 14 两档过近（`AppDimens.fontCaption=12/fontBody=14`）；75 处 `letterSpacing` 含大量中文场景（`CalcWidgets.ets:159`、各计算器分节标题等）——letterSpacing 是西文小标题手法，中文加字距反而松散。

**做法**：
1. 工序先行：`grep -rn "letterSpacing" entry/src/main/ets/` 出完整清单，逐处标注 纯中文/纯西文/混排 分类，**先标完再动手，不边改边找**
2. 字阶重排：caption 12 / body 14 / 页面描述 15 / 分节标题 13 Bold / 结果 Hero 40（V2）——AppDimens 补 `fontSectionTitle=13`、`fontHero=40`
3. 中文文本去掉 letterSpacing（纯中文删；'SOFA Total' 等纯西文保留 1.5；混排删）
4. 统一 lineHeight：正文 14pt→20-22，caption 12pt→17-18

**验收**：中文标题无明显字距；西文小标题保留字距；无文字溢出（重点查 BloodGas/Apache2 长文案）。

## V4. 间距节奏 + 分节标题规范化

**现状证据**：间距只有 12/16 两档；分节标题是手工破折号 `'— 输入参数'`（约 38 个计算器文件各一处，如 `PfCalculator.ets:42`）。

**做法**：
1. AppDimens 补 `spacing1=8 / spacing2=16 / spacing3=24`，页面级段落间用 24，卡内用 16，行内用 8（仅新改/已动文件顺手应用，**不做全局机械替换**）
2. CalcWidgets 新增 `SectionTitle` 组件：13pt Bold textSecondary + 右侧可选 ResetButton 槽位，无手工破折号
3. 38 个计算器的 `'— xxx'` 行替换为 SectionTitle（这是唯一动全部计算器文件的项目）：**必须写替换脚本（sed/正则）+ diff 逐文件确认 + 批量构建验证，禁止手动逐文件改**；一批一 commit，可分两批
4. 计算器页描述块样式化：主描述 15pt primary Medium + 副说明 12pt + 下方 8px 间距 + 细分隔线（`Index` 不动，各计算器描述块随 SectionTitle 批次顺手做）

**验收**：无残留 "— " 手工前缀；SectionTitle 右侧重置按钮功能不变（resetKey 机制完好，抽查 3 个计算器重置流程）。

## V5. 卡片层次

**现状证据**：`CalcCard`（`CalcWidgets.ets:32-41`）无描边无阴影，白卡贴米底无纵深；暗色下 `#2A2A2A` 贴 `#1A1A1A` 边界消失（与病历页同病，病历页已修）。

**做法**：
1. CalcCard 加 `.border({ width: 1, color: AppColors.border })`——亮色 `#E0E0E0` 几乎不可见（不改变现有观感），暗色 `#404040` 恢复边界
2. ResultCard 因 V2 已有 tier 氛围，不加描边避免叠床架屋；输入卡/内容卡统一加
3. 不加阴影（米底+细描边已够，阴影在暗色下不可见且增噪）——若施工方认为需要，仅限 ResultCard 极浅阴影并真机对比后决定

**验收**：亮色下无感知变化；暗色下计算器页/助手页卡片边界清晰（对照病历页已修效果）。

## V6. 微动效

**做法**（全部 ≤200ms，可关闭项不做）：
1. **结果出现**：ResultCard 在 ① 空态→出分、② tier 档位变化 两个时刻淡入+上移 4px；**纯数值跳动不播动画**（结果随每次击键变化，逢变必播比鬼畜更糟）。实现用 `animation()` 属性动画（opacity/translate），不用 animateTo——属性动画天然支持中断，新值到来自动从当前态跳到新终态，无鬼畜
2. **OptionChip 选中**：背景色/文字色 `animation({ duration: 150 })` 属性过渡
3. **Tab 切换**：指示条滑动/淡入 150ms
4. 不做：页面转场、弹簧、加载骨架屏（超范围）

**验收**：动效流畅无卡顿；低端机上不掉帧（真机验证）；快速连续输入时结果动画不鬼畜（动画被打断应直接到终态）。

## V7. 暗色模式精调

**现状**：dark token 是亮色的机械映射，第二轮修了对比度（H1）但没按暗色重新设计。

**做法**：
1. 暗色 tier 色逐个人眼校准（暗底上橙/红/绿的饱和度和明度，必要时为 dark 单独提亮一档，改 `dark/element/color.json`）
2. 暗色卡片层次：背景 `#1A1A1A` / 卡 `#2A2A2A` / 描边 `#404040` 三级拉开不够时，卡升 `#2E2E2E` 或描边升 `#4A4A4A`（真机定）
3. 全页面暗色走查清单：5 Tab + 3 计算器 + 患者详情四卡 + KB 阅读器 + 助手 + 弹窗，逐项确认无白底刺眼、无黑字黑底、徽章文字可读

**验收**：走查清单全过；tier 色暗色对比度 ≥4.5:1。

---

## 施工顺序

| 批次 | 内容 | 理由 |
|---|---|---|
| 1 | V5 卡片描边 + V3 字阶/letterSpacing | 低成本高感知，先见效 |
| 2 | V2 ResultCard Hero 化 | 单组件改动，感知最强 |
| 3 | V1 图标体系 | 工作量最大，单独成批（Tab/顶栏先行，分类/tier 随后） |
| 4 | V4 间距 + SectionTitle（38 文件机械替换，可分两批） | 唯一动全部计算器的项，放共享组件稳定后 |
| 5 | V6 微动效 | 锦上添花，放最后 |
| 6 | V7 暗色精调 + 全量走查 | 所有改动落地后统一校准 |

## 红线与纪律（第三轮专用）

1. **不改配色体系**（米底+深绿是资产）；不加渐变/玻璃拟态/大圆角潮流元素
2. `ResourceStr` 禁止拼接 alpha 字符串（PITFALLS 07-20），浅底色一律用已有 tierXxxBg token 或新增 token
3. **SVG 资源规范**（技术验证已证实为硬约束）：
   - V1-SVG-01：所有 SVG 必须 fill 绘制，无 stroke、无 currentColor、无 `<style>` 内联、无 opacity/filter
   - V1-SVG-02：入库后批量检查 `grep -l 'stroke=\|currentColor' resources/base/media/ic_*.svg` 必须为空
   - V1-SVG-03：图标一律经 IconButton 组件渲染（fillColor + Transparent 背景），不裸写 Image
4. **动画纪律**：
   - V6-ANIM-01：结果/选中过渡用 `animation()` 属性动画，不用 animateTo
   - V6-ANIM-02：结果动画只在 空态→出分 / tier 变化 触发，纯数值跳动不播
   - V6-ANIM-03：禁止 animateTo 包裹命令式方法（scrollTo 等），命令式方法用自带 animation 参数
5. 计算器输入区 resetKey 分支切换必须保住（交接文档 §3.2）
6. 图标只用 SVG + fillColor 上色，不引入位图 PNG（适配深浅色）；图标集必须 fill 系（Remix Icon 首选），stroke 系（Lucide/Feather）禁用
7. V4 的 38 文件替换必须脚本化 + diff 确认，禁止手动逐文件改
8. 每批次构建 0 错误；批次 3/4 完成后出真机截图基线对照（现有 screenshots/ 已过期）

## 验收总清单

- [ ] 亮色：5 Tab + 5 个抽查计算器 + 患者页 + KB 阅读器，视觉走查无回归
- [ ] 暗色：同上全量走查（V7 清单）
- [ ] 功能：3 个计算器 空态→录入→出分→重置 流程完好；tier 三档展示正确
- [ ] 真机截图（亮/暗各一套）更新到 screenshots/，替换过期基线

---

## 修订记录

**v2（2026-07-25）**：合入施工 AI 技术验证反馈（`UI优化第三轮-视觉设计pass-验证反馈.md`）：

1. V1 图标集选型修正：fillColor 只对 fill 生效 → stroke 系（Lucide/Feather）禁用，首选 Remix Icon（fill）；新增 SVG 入库三条硬规范 + IconButton 封装
2. V2 删除 fontFeature fallback，`fontFeature('tnum')` 已验证原生支持
3. V6 动画方案定为 `animation()` 属性动画（天然抗中断）；触发条件收窄为 空态→出分 / tier 变化，纯数值跳动不播（建议方补充）
4. V3 增加"先 grep 出完整清单分类再动手"工序；V4 增加"脚本替换 + diff 确认，禁止手动逐文件改"纪律
5. 红线扩为 8 条（V1-SVG-01/02/03、V6-ANIM-01/02/03 入列）

施工顺序不变，可按批次 1 开工。
