# MedCalc UI 优化第四轮 · 手术青（方向 B 定稿）施工单

> 生成时间：2026-07-26（v2 同日修订：合入施工 AI 审核疑问，补全 45+4 条全量色表 + 3 项设计裁决，见 §10）
> 定稿依据：用户选定方向 B（手术青·单色调克制风），效果图 `docs/design-mockups/direction-b-final.png`
> 附加要求：Tab 栏沿用现有 22 个 SVG 图标，仅改配色（选中青/未选中灰），不要花哨
> 本轮实质：**全色系迁移**（米底深绿 → 手术青）。色值全部集中在 `color.json`（base+dark）+ AppColors 别名层，迁移是"换 token 值"而非全库改代码
> **硬性门槛：本轮以真机截图（亮/暗双模式）为验收依据，不见图不宣布完成**

---

## 1. 色彩 token 全量迁移表（45 现有 + 4 新增，逐条对照 color.json 现值）

### 1.1 base（亮色）

| token | 现值 | 新值 | 说明 |
|---|---|---|---|
| start_window_background | #FFFFFF | #EDF3F4 | 启动窗与 background 一致 |
| primary | #1F3D2F | **#0F766E** | 品牌青 teal-700 |
| onPrimary | #FFFFFF | #FFFFFF | 不变 |
| background | #F4F1EA | **#EDF3F4** | 冷调浅青灰 |
| card | #FFFFFF | #FFFFFF | 不变 |
| textPrimary | #1F2421 | **#1E2A2A** | 冷调近黑 |
| textBody | #4A5247 | **#3A4A46** | |
| textSecondary | #5F6654 | **#5B7272** | |
| textFaint | #B0B0A8 | **#A3B8B5** | |
| textOption | #2D5440 | **#5B7272** | **=textSecondary（B2 裁决，见 §10）** |
| placeholder | #999999 | **#9AAFAE** | |
| border | #E0E0E0 | **#D8E3E3** | |
| divider | #E0DCC8 | **#D8E3E3** | 与 border 统一 |
| fillNeutral | #F5F5F5 | **#E4EEEE** | |
| fillBeige | #E8E5D8 | **#E4EEEE** | **与 fillNeutral 同值合并（B3 裁决）：token 名保留、21 处引用不动** |
| surfaceMuted | #F5F4EF | **#EFF4F4** | 冷调化 |
| surfaceSubtle | #F9F8F3 | **#F6FAFA** | 冷调化 |
| danger | #B1452A | **#C03A2B** | |
| warning | #E76F2C | **#C77700** | 橙→琥珀，与青互补 |
| warningText | #9A6B1E | **#8A5A2B** | |
| tierOk | #3D6B4F | **#178A50** | 保持绿语义，与品牌青拉开 |
| tierWarn | #C8881A | **#C77700** | |
| tierDanger | #B1452A | **#C03A2B** | |
| tierInfo | #5F6654 | **#5B7272** | |
| tierOkBg | #E8F5E9 | **#E3F2E9** | |
| tierWarnBg | #FFF8E1 | **#FAF0DC** | |
| tierDangerBg | #FFEBEE | **#F9E7E4** | |
| tierInfoBg | #F5F5F5 | **#EDF1F1** | |
| kbAccent | #4A7C6F | **#14A08F** | |
| kbDeepGreen | #3A5F4F | **#0F766E** | 同 primary |
| kbWarmBrown | #8B6B4A | **#8A6D3B** | 暖锚点保留（大地系唯一暖色） |
| aiAccent | #7A6B9D | **#5B6BB8** | 紫→靛蓝，AI 语义独立色相 |
| aiAccentBg | #F0EBF5 | **#EBEEF8** | |
| infoAccent | #2B5C8A | **#1F6FA8** | |
| infoAccentBg | #DBEAFE | **#E3F0F8** | |
| domain_electrolyte | #6B8E23 | **#0E8FA8** | 青蓝 |
| domain_kidney | #D4760A | **#5B7FB8** | 蓝 |
| domain_liver | #8B6914 | **#8A6D3B** | 暖棕锚点 |
| domain_inflammation | #C0392B | **#C77700** | 琥珀（炎症=警示语义） |
| domain_cardiac_marker | #E74C3C | **#C03A2B** | 红（心脏语义保留） |
| domain_neuro | #6B4FA0 | **#6B5CA5** | 紫（微调） |
| domain_endocrine | #9B59B6 | **#7A9A2E** | 橄榄绿（避开与 tierOk 撞色，v3 修正） |
| domain_muscle | #E67E22 | **#5B7272** | 灰青 |
| dialog_cancel | #5F6654 | **#5B7272** | |
| dialog_confirm | #B1452A | **#C03A2B** | |
| **headerBg（新增）** | — | **#0F766E** | §2 深青顶栏 |
| **headerText（新增）** | — | **#FFFFFF** | |
| **tabInactive（新增）** | — | **#9AAFAE** | §3 Tab 未选中 |
| **groupLine（新增）** | — | **#B8D8D5** | §4 分组隔线（primary 35% on bg，施工 AI 估算值，真机微调） |

### 1.2 dark（暗色全套，非亮色反推）

| token | 现值 | 新值 |
|---|---|---|
| start_window_background | #121212 | #101E1D |
| primary | #5A9A78 | **#3FAF9F** |
| onPrimary | #E8F0EA | **#0A1F1C**（注意：暗色徽章/按钮文字由浅转深——亮青/亮琥珀/亮红底上深字对比度更高，全页面走查确认，见 §10-D1） |
| background | #1A1A1A | **#101E1D** |
| card | #2E2E2E | **#1B2C2A** |
| textPrimary | #E8E8E0 | **#C7D4D0**（v4 调暗：原 #E2EBE9 在 #101E1D 上 14.1:1 夜间晃眼，现 11.2:1 仍达 AAA） |
| textBody | #C0C8B8 | **#B0C0BB**（v4 调暗：原 #B9C8C4，现 9.1:1） |
| textSecondary | #9CA89A | **#8FA5A3** |
| textFaint | #6A7068 | **#5F726F** |
| textOption | #7ABA8A | **#8FA5A3**（=textSecondary） |
| placeholder | #666666 | **#5F726F** |
| border | #4A4A4A | **#2E4542** |
| divider | #3A3A30 | **#243836** |
| fillNeutral | #333333 | **#243836** |
| fillBeige | #3A3830 | **#243836**（同值合并） |
| surfaceMuted | #2A2A26 | **#182726** |
| surfaceSubtle | #242420 | **#142221** |
| danger | #E07060 | #E07060 不变 |
| warning | #F09050 | **#E0A040** |
| warningText | #D0A050 | #D0A050 不变 |
| tierOk | #6AAA88 | **#45B08C** |
| tierWarn | #E0B050 | #E0B050 不变 |
| tierDanger | #E07060 | #E07060 不变 |
| tierInfo | #9CA89A | **#8FA5A3** |
| tierOkBg | #1E3A28 | **#14332A** |
| tierWarnBg | #3A3018 | #3A3018 不变 |
| tierDangerBg | #3A1A1A | **#3A1C1A** |
| tierInfoBg | #333333 | **#243836** |
| kbAccent | #6BA08A | **#3FAF9F** |
| kbDeepGreen | #5A8A6A | **#2E8C80** |
| kbWarmBrown | #A08A6A | **#A8895C** |
| aiAccent | #9A8ABF | **#8B97D8** |
| aiAccentBg | #2A2638 | **#23283A** |
| infoAccent | #5A8ABA | **#5A9AC8** |
| infoAccentBg | #1A2A3A | **#16283A** |
| domain_electrolyte | #8AB040 | **#3BB7CC** |
| domain_kidney | #E09030 | **#7C9FD1** |
| domain_liver | #B09030 | **#B0925A** |
| domain_inflammation | #E06050 | **#E0A040** |
| domain_cardiac_marker | #F06060 | **#E07060** |
| domain_neuro | #8A6AC0 | **#9488C7** |
| domain_endocrine | #B07ACA | **#9AB84E** |
| domain_muscle | #F09040 | **#8FA5A3** |
| dialog_cancel | #8A8E84 | **#8FA5A3** |
| dialog_confirm | #D45A3A | #D45A3A 不变 |
| **headerBg（新增）** | — | **#0C2422** |
| **headerText（新增）** | — | **#FFFFFF** |
| **tabInactive（新增）** | — | **#5F726F** |
| **groupLine（新增）** | — | **#1A3B38**（施工 AI 估算值，真机微调） |

## 2. 深青顶栏（品牌识别的主动作）

- token：`headerBg`（base #0F766E / dark #0C2422）、`headerText`（均 #FFFFFF）
- 应用范围：计算器 Topbar（`Index.ets`）、Sidebar 顶栏、患者详情页头、KB 阅读器页头、设置页头——**全部统一**深青底 + 白标题 + 白图标
- 顶栏上的返回箭头、菜单、收藏星、操作图标 fillColor 全部改 `headerText`
- 收藏星选中态：顶栏上为白色实心星（不做金色）；Sidebar 收藏列表内的星用 primary

## 3. Tab 栏克制化（用户指定）

- 图标：沿用现有 `ic_calculator/ic_assistant/ic_patient/ic_knowledge/ic_settings`，**不换图标**
- 配色：选中 `primary`，未选中 `tabInactive`；文字 11pt，选中 Medium、未选中 Normal
- **不加指示条、不加底色胶囊、不加任何额外装饰**
- 底部 AI 悬浮球（LlmDialog FAB）：背景 primary，图标白色

## 4. Sidebar 分组头升级（解决"系统名不起眼"）

现状：`Sidebar.ets:94-103`（12pt 灰字 + 14px 灰图标）。改为（效果图方向 B 样式）：
- 24×24 圆角 7 图标块：底 primary、内嵌白色分类图标（现有 ic_lungs 等 8 个）
- 系统名 14pt ExtraBold，色 primary
- 右侧数量徽标（该分类计算器数，12pt textSecondary + 卡底描边小胶囊）
- 其后 2px 细分隔线，色 `groupLine`（独立 token，禁止 alpha 拼接）
- 计算器条目：行高 40+（第二轮 L3 遗留，顺手做）；当前选中条目左侧 3px primary 竖条 + 卡底色

## 5. 结果区自适应空态（B1 裁决：紧凑条替代灰化 Hero 卡）

现状：第三轮做的空态灰化 Hero 卡（`CalcWidgets.ets:182-197`，inbox 图标 + '—' + 0.4 opacity）仍占完整 Hero 高度——用户实测"内容少的空白太多"。
**裁决：紧凑条替代灰化 Hero 卡**，删除 inbox/opacity 空态逻辑：
- 空态判定与现有代码对齐：以 `isEmpty()`（`value === null && valueText === ''`）为准，**不引入 tierClass 判断**。空态渲染**紧凑空态条**：单行 40px 高，ic_info 图标 + 12pt textSecondary 文案（取 tier 文本，引擎空态返回"请填写必填项"；tier 为空时回退"填写参数后自动出分"），白卡描边
- 有值 → 现有 Hero 卡（竖条+氛围底+40pt 等宽数字），内容自适应高度，**禁止任何 minHeight/固定高度**
- 空态→出分过渡沿用 V6 的 200ms 属性动画

## 6. 波及面清单（换色系必须全走查）

1. `CalcEngine.getTierColor/getTierBgColor`——只引用 AppColors，token 换值即生效，无需改代码
2. `KbMarkdownParser` 的 callout/annotation 色——走 token，换值生效；暗色下 callout 底色需走查
3. `DOMAIN_COLORS`、kb* 分类色——按 §1 表整体换值（v2 已给出全部具体色值）
4. `ImageEditor` 画布色（白名单硬编码）——深色画布 `#2A2A2A` 等 4 处可保留（功能色不参与品牌色系）
5. `ConfirmDialog` 按钮色——dialog_confirm 跟随新 danger
6. 知识库阅读器引用块斑马纹、表格描边——走 token，走查即可
7. 暗色 onPrimary 由浅转深（§1.2），所有徽章/实底按钮文字随之变深——**必须全页面走查**

## 7. 施工顺序

| 批次 | 内容 |
|---|---|
| 1 | color.json base+dark 全 token 换值（§1 表）+ 构建 + 亮色走查 |
| 2 | 深青顶栏（headerBg/headerText token + 5 处页头统一） |
| 3 | Tab 克制化 + FAB + Sidebar 分组头升级 |
| 4 | ResultCard 空态紧凑条（CalcWidgets 单点，删除第三轮灰化 Hero 空态逻辑） |
| 5 | 暗色全页面走查修正（重点：onPrimary 转深后的徽章可读性）+ 真机截图（亮/暗各一套） |

## 8. 验收（硬性）

- [ ] 每批次 `assembleApp` 0 错误
- [ ] **真机截图亮/暗各一套**（计算器页含空态+出分、Sidebar、病历、知识库、助手），与 `direction-b-final.png` 对照确认色系还原
- [ ] 截图更新至 `screenshots/`（替换 07-12 过期基线）
- [ ] 对比度抽查：headerBg 白字、tabInactive 灰字、textSecondary 在 background 上、暗色 onPrimary 深字在各 tier 实底上 ≥4.5:1
- [ ] 功能回归：3 个计算器 空态→录入→出分→重置；空态应为紧凑条而非 Hero 卡

## 9. 不做

- 不改 22 个 SVG 图标本身；不加分类多色相（方向 A 方案，用户已否决）
- 不动页面结构/布局；不动 38 个计算器文件（ResultCard 单点继承）
- 不加渐变、阴影体系、圆角调整（方向 B 的克制感靠平色+细描边）

---

## 10. 施工 AI 审核疑问的裁决（v2 新增）

**A 类（色表完整性）**：全部采纳——§1 已补全 45 现有 + 4 新增 token 的 base+dark 具体色值，无占位符、无空白。groupLine 采用施工 AI 估算值（#B8D8D5 / #1A3B38），真机微调。

**B1（空态冲突）**：紧凑条**替代**第三轮灰化 Hero 卡，删除 inbox/opacity 逻辑（§5 已改写）。理由：灰化 Hero 仍占完整高度，正是用户抱怨的"空白太多"。

**B2（textOption=primary 区分度）**：采纳施工 AI 替代方案——`textOption = textSecondary`。未选中灰字+浅底、选中白字+深青底，色相+明度双重区分；未选中态本就该后退，品牌色只给选中态。

**B3（fillBeige 合并）**：合并——fillBeige 与 fillNeutral 同值（#E4EEEE/#243836），**token 名保留**（21 处引用零改动）。KB callout 有独立色系不受影响；若走查发现设置页等场景需要层次，用 surfaceMuted/surfaceSubtle 区分，不再新增米色。

**C2（kb* 色）**：已给全（§1 表）：kbAccent #14A08F、kbDeepGreen #0F766E、kbWarmBrown #8A6D3B（暖锚点保留，大地系唯一暖色）。

**C3（DOMAIN_COLORS）**：已给全 8 色 base+dark。衍生规则：主色转青蓝系，但保留 3 个临床语义锚点——心脏=红、炎症=琥珀、肝=暖棕，避免 8 色全是青导致域间无法区分。

**D1（我方主动标注的新风险）**：暗色 `onPrimary` 由浅（#E8F0EA）转深（#0A1F1C）——因为新 dark primary #3FAF9F 是亮青，浅字压不住。副作用是所有徽章/实底按钮文字在暗色变深色，属预期内变化，但必须在批次 5 全页面走查确认（尤其 tierDanger #E07060、tierWarn #E0B050 实底上的深字）。

---

## 11. 第三轮疑问的裁决（v3 新增）

**Q1（§5 空态条件与 isEmpty 不一致）**：采纳。空态判定以 `isEmpty()`（`value === null && valueText === ''`）为准，不引入 tierClass 判断（§5 已改写）。

**Q2（dark onPrimary 对比度）**：**经脚本验算，深字方案全部达标，该疑问不成立**——但其计算恰好证明了"若保留浅字"会全面不达标，D1 的转深决策因此从"风险"升级为"已验证正确"：

| 实底 | 深字 #0A1F1C | 浅字 #E8F0EA（旧方案，对照） |
|---|---|---|
| primary #3FAF9F | **6.40:1** ✅ | 2.31:1 ❌ |
| tierWarn #E0B050 | **8.56:1** ✅ | 1.72:1 ❌ |
| tierDanger #E07060 | **5.43:1** ✅ | 2.72:1 ❌ |
| tierOk #45B08C | **6.40:1** ✅ | — |
| tierInfo #8FA5A3 | **6.59:1** ✅ | — |

（其 2.8/3.2 的数字与浅字场景吻合，推测是对照了旧 onPrimary。）批次 5 的走查项保留，但性质从"验证风险"改为"确认观感"。

**Q3（domain_endocrine 与 tierOk 撞色 #178A50）**：采纳，属实。endocrine 改橄榄绿 **#7A9A2E**（base）/ **#9AB84E**（dark）——同时修复了 dark 下 endocrine 与 tierOk 同为 #45B08C 的同款撞色（§1 两表均已更新）。
