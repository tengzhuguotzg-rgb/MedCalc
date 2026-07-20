# MedCalc UI 优化清单

> 生成时间：2026-07-19
> 来源：截图审查（screenshots/ + test_screenshots/ 共 22 张）+ 代码只读审查（entry/src/main/ets/）
> 所有改动在 `ui-overhaul` 分支，逐项一个 commit，可单独 revert；未推送 GitHub。

## 总体结论

功能骨架完整，视觉底子（米底 `#F4F1EA` + 深绿 `#1F3D2F` + 白卡）不错。但：
- 视觉体系零资源化：全 App 3300+ 处硬编码色值、0 个设计 token
- 计算器层 ~90% 样式为复制粘贴（卡片样式在 38 个文件重复 108 次）
- 床旁可用性（字号、热区、数字键盘）有系统性短板
- 暗黑模式资源准备度≈0

---

## 🔴 高优先级（正确性 / 像 bug）

- [x] **1. 计算器"出厂即出分"，展示未录入的假结果** — `8495916`
  - 证据：`Apache2Calculator.ets:5-29` 默认值初始化+立即计算；`GcsCalculator.ets:5-7` 默认 15 分；`engine/MapCalculator.ets:4-11` 为判空范式
  - 已做：41 个计算器统一空态（9 个本对未动，20 数值型 + 12 选项型修复）；必填未录完显示"请填写必填项"；"无/有"按钮改三态；可选字段不参与必填判断；未改任何公式

- [x] **2. 底部 Tab 选中态从系统蓝改回品牌绿** — `0a9af8c`
  - 已做：自定义 TabBarBuilder，选中 `#1F3D2F` + 指示条，未选中保持灰色

- [x] **3. 内部实现细节泄露到临床界面** — `43fd7f7`
  - 已做：规则 DSL "pao2 lt 60" → "PaO2 < 60 mmHg"（复用 dataFieldSpecs 中文名/单位，含 calcResult 条件渲染）；派生 0/1 字段全部展示路径过滤；原始 key 大小写不敏感中文化（albunit→白蛋白单位）；检索统计从默认界面移除

- [x] **4. 约 1/3 数值输入框未声明数字键盘** — `f5b85c9`
  - 已做：47 处补齐 `.type(InputType.NUMBER_DECIMAL)`（15 个文件，含血气 16 处）；143/143 全覆盖

- [x] **5. 全 App 零安全区/沉浸适配** — `11c3c3d`
  - 已做：根 Tabs 加 `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])`，Tab 栏背景延伸、内容避让手势条；悬浮 AI 按钮参考系在 Tab 栏之上无需改。注：未真机验证，依据官方文档行为

## 🟡 中优先级（可用性）

- [x] **6. 知识库视觉体系与主 App 脱节** — `56fa191`
  - 已做：分类图标收敛为 4 色大地色系（深绿/墨绿/灰绿/暖棕）+ 米白字，hash 分配；首字重名自动取两字，index 条目用父目录名；标题去重；引用块内表格正确渲染（根因：`> |---|` 被当纯文本），斑马纹；标签墙改可点 chip（点击触发搜索）

- [x] **7. 患者详情页三套视觉语言混用** — `9c4c999`
  - 已做：统一为竖条（tier/urgency 色）+ 文字标签；移除 emoji 圆点与红黄数字 badge，各卡保留一个汇总角标；诊断竖条从来源色改严重度色，来源由背景底色区分

- [x] **8. 热区/字号不达床旁标准** — `1b6c67f`
  - 已做：选项按钮 36→44、输入框 40→48、顶栏按钮 36→44；"删除"加 padding 独立热区（≈52×45）+ 改危险红 `#B1452A`；小字 9/10/11pt → 12pt（97 处）；辅助灰 `#7A8074`→`#5F6654` 全局 292 处（米底对比度 3.6→5.3:1，白卡 4.06→5.97:1）

- [x] **9. 41 个计算器无"重置/清空"** — `03e2c2a`
  - 已做：43 个 struct 统一加分节标题行右侧"重置"按钮（12pt 灰字），reset() 恢复初始空态；因 TextInput 非受控，用 resetKey 强制重建输入子树清空已显示文字

- [x] **10. 残留样式问题** — `a3f8ca8`
  - 已做：删除 PEEP 死状态 `peepText`；确认 "T" 方块为系统输入法浮层（非应用组件）；全 calculators/ 234 处切换选中态已是品牌绿，无需改

## ⚪ 低优先级（工程欠债，待议）

- [x] **11. 色彩零 token 化**：3323 处硬编码色值遍布 53 个文件；`color.json` 仅 1 条。新发现：BloodGas 结果区用 `#DC3545/#28A745`、Apache2/Nrs2002 用 `#3D6B4F` 作分级色，与 CalcEngine tier 色系不统一（一并纳入）。建议：先建 `AppColors`/`Dimens` 常量类，再迁移 color.json
  - 已做：新建 `utils/AppColors.ets`/`utils/AppDimens.ets` token 层（`10047c5`）；CalcEngine tier 色改为引用 AppColors，全 App 分级色单一定义；12 个色板色值全局迁移 1990 处（52 文件，`a5fcfe0`/`57e7042`/`a298f08`）；BloodGas/Apache2/Nrs2002 分级色统一走 CalcEngine.getTierColor（`514e5dd`）；高频尺寸 .height(44/48)/.borderRadius(12)/.padding(16) 迁移 556 处（`9ad3ed5`）；中性色/功能色/域色补 26 个 token 并迁移 1285 处（`75c73d0`/`9891c31`），系统蓝残留与知识要点卡收编（`19336d6`），DOMAIN_COLORS 收编 AppColors（`341bf17`）。现 ets/ 下除 AppColors 定义与白名单（画布/阴影色 11 行）外无硬编码色值
- [x] **12. 样式全量复制粘贴**：卡片样式 108 处重复。建议抽公共组件：`CalcCard`/`InputRow`/`ResultCard`/`OptionChip`
  - 已做：新建 `calculators/widgets/CalcWidgets.ets` 四组件（`8d3ce43`）；38/40 个计算器分 11 批迁移（`65894ba`…`aaf6e5a`），每批构建验证；未迁移 2 个：Vasopressor（双栏换算特殊交互）、BloodGas（6 步法特殊区），保留 inline。reset/空态机制原样保留
- [x] **13. `PatientDetailPage.ets` 单文件 4166 行**、8 个独立 Scroll。建议拆分子组件文件
  - 已做：4166→1367行(67%↓); 提取7个组件文件到patient/目录; 21个@Builder全拆为独立@Component; 13个实例方法迁为纯函数(PatientDetailUtils 544→630+行)
- [x] **14. 暗黑模式准备度≈0**：resources/dark/ 仅 1 条。前置依赖第 11 条
  - 已做：color.json base 44 token + dark 44 token；AppColors→ResourceStr+$r()；CalcEngine/BloodGas/Patient/KbMarkdownParser 色返回值→ResourceStr；SettingsPage 外观Radio(跟随系统/浅色/深色)；PreferencesService saveThemeMode/getThemeMode；EntryAbility 启动读theme→setColorMode（`05d3a9f`）
- [x] **15. 返回逻辑碎片化**：`Index.ets:82-94` AppStorage flag 模拟返回栈；详情页 5 层布尔分发
  - 已做：Patient tab→Navigation(patientStack)+NavDestination.onBackPressed→patientBackFlag计数器；KB tab→Navigation(kbStack)+onNavDepthChanged/backAction回调；Index.onBackPress仅委托KB tab；所有旧AppStorage flag已清除grep零引用（`2aff4cb`）；修复ResourceStr+'20'徽章底色回归→getUrgencyBgColor/getLlmConfirmBgColor（`9912c8f`）；清除死代码KbRouteMap/空onDetailNavChanged/kbStack传递（`aa05b95`）
- [x] **16. 字符串未资源化**：string.json 仅 3 条（只做中文可接受，需知情决策）
  - 已做：string.json 3→~250条资源(通用/Tab/设置/患者/知识库/计算器)；SettingsPage/PatientListPage/Index 硬编码中文→$r()；仅提取用户可见UI文本，不触动数据域key/解析关键词
- [x] **17. 代码风格**：整行 UI 压成单行（`SofaCalculator.ets:29` 400+ 字符）
  - 已做：87处300+字符长行折行，13个计算器+3个组件文件方法链换行、属性分组缩进

## 修复过程中新发现的问题（未改）

- [x] **18.** 删除确认弹窗的"删除"按钮背景仍是预警橙 `#E76F2C`，应统一危险红 `#B1452A`（`PatientListPage.ets` 弹窗）— 已改 `AppColors.danger`（`deaacdf`）
- [x] **19.** 知识库面包屑父级链接与"相关章节"wikilink 仍用系统蓝 `#2B6CB0`/`#EBF2FA`，与品牌色脱节 — 链接改 `AppColors.primary`、底色改 `AppColors.background`（`deaacdf`）
- [x] **20.** `KbMarkdownParser` 的 callout/annotation 配色仍是 Material 色系（`#E65100`/`#1565C0` 等）— 信息类改深绿系、警告改橙、危险改红、提示/成功改 tier 绿（`deaacdf`）
- [x] **21.** 年龄/肌酐等已有 `.type(InputType.Number)` 的输入框是整数键盘，肌酐等实际需小数，评估换 NUMBER_DECIMAL — 22 处改小数键盘（肌酐/体重/身高/体温/WBC/尿量等，`33caadf`），年龄/心率/血压/评分项等保持整数
- [x] **22.** Apache2Calculator 的 FiO₂ 输入无"小数/百分比"切换但 placeholder 是 '21'（百分比），与其它计算器 FiO₂ 交互不一致 — 改 OptionChip 小数/百分比切换，placeholder 动态化，引擎行为不变（`82630ba`）
- [x] **23.** 死代码：`getDangerCount`/`getWarnCount`/`getSourceColor`/`getTierIcon` 已无调用方（第 7 项后遗留）— 确证零引用后删除（含配套的 `getSourceLabel`，`9cbe37e`）

## 做得对、要保持的

- tier 分级色集中在 `engine/CalcEngine.ets`（`getTierColor`）
- MAP 引擎空值保护模式（已推广到全部计算器）
- 患者列表空态与删除确认弹窗
- 助手页 loading/error 态

## 执行进度

| 批次 | 内容 | 状态 |
|---|---|---|
| 1 | #1 空态不出分 `8495916` | ✅ 构建通过 |
| 2 | #2 `0a9af8c` / #3 `43fd7f7` / #4 `f5b85c9` / #5 `11c3c3d` / #9 `03e2c2a` / #10 `a3f8ca8` | ✅ 构建通过 |
| 3 | #6 `56fa191` / #7 `9c4c999` / #8 `1b6c67f` | ✅ 构建通过 |
| 4 | #11 色彩 token 化 `10047c5`/`a5fcfe0`/`57e7042`/`a298f08`/`514e5dd`/`9ad3ed5` + 中性色收尾 `75c73d0`/`9891c31`/`19336d6`/`341bf17` + #18/#19/#20 `deaacdf` | ✅ 构建通过 |
| 5 | #12 共享组件+迁移 `8d3ce43`…`aaf6e5a`（16 commits）+ #21 `33caadf` + #22 `82630ba` + #23 `9cbe37e` | ✅ 构建通过 |
| 6 | #14 暗黑模式 `05d3a9f` / #15 返回栈 `2aff4cb`+`9912c8f`+`aa05b95` / #13 拆分 `c819b64`/`6dd8230`→`7b0f7ad`/`d60b9d0`/`3be216d` | ✅ 全部构建通过 |
