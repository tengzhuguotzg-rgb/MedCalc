# MedCalc UI 优化 · 交接文档

> 写给接手继续 UI 优化的 AI / 开发者。
> 读这份文档前，先读 `docs/UI优化清单.md`（逐项状态与 commit 对照）和 `PITFALLS.md`（ArkTS 踩坑日志，含返回键、手势、@Builder 等硬性约束）。
> 本文最后更新：2026-07-20，基于分支 `ui-overhaul` 顶端 `59224ae`。

---

## 0. TL;DR

UI 优化清单 23 项已完成 17 项（#1–#12、#18–#23），剩 5 项工程项（#13 大文件拆分、#14 暗黑模式、#15 返回栈、#16 字符串资源、#17 代码风格）。
**建议施工顺序：#14 暗黑模式 → #15 返回栈 → #13 大文件拆分（与 #15 耦合）→ #16 / #17（可选）。**

## 1. 仓库与构建环境

### 1.1 Git 状态（动手前先核对）

- 远程：`origin https://github.com/tengzhuguotzg-rgb/MedCalc.git`，用户明确要求：**未经确认禁止 push**
- `main`：顶端 `efdca0d`（merge 提交，含批次 1–3，即清单 #1–#10）
- `ui-overhaul`：领先 main **28 个 commit**（批次 C 色彩 token 化 + 批次 D 共享组件 + 文档），**尚未合并回 main**。开工前建议先合并：
  ```bash
  git checkout main && git merge --no-ff ui-overhaul -m "merge: 色彩token化+共享组件+剩余小项"
  git checkout -b ui-phase2   # 或继续用 ui-overhaul
  ```
- commit 纪律（沿用至今，不要破坏）：一个逻辑改动一个 commit；中文消息带 `fix:`/`feat:`/`refactor:`/`chore:`/`docs:` 前缀；**每个 commit 前必须构建通过**

### 1.2 构建（Windows，已验证可用）

```bash
export DEVECO_SDK_HOME="D:\Program Files\DevEco Studio\sdk"
export PATH="$PATH:/d/Program Files/DevEco Studio/jbr/bin"
cd /e/ai/MedCalc && hvigorw assembleApp
```

- 不加这两个环境变量会报 SDK 路径无效 / `spawn java ENOENT`
- 成功标准：`BUILD SUCCESSFUL`，0 编译错误；历史 WARN（deprecated API 等）可接受
- 签名 HAP 产物：`entry/build/default/outputs/default/entry-default-signed.hap`（可装机验证）
- 真机截图惯例：`screenshots/`（新）、`test_screenshots/`（旧），用于视觉对照

## 2. 已完成工作（17 项）

详见 `docs/UI优化清单.md`（每项有证据、做法、commit hash）。压缩版：

| 批次 | 内容 | commit 范围 |
|---|---|---|
| 1 | #1 空态：41 个计算器必填未录完不出分 | `8495916` |
| 2 | #2 Tab 品牌绿 / #3 DSL 泄露清理 / #4 数字键盘 / #5 安全区 / #9 重置按钮 / #10 残留 | `0a9af8c`…`a3f8ca8` |
| 3 | #6 知识库视觉 / #7 患者详情严重度统一 / #8 热区字号对比度 | `56fa191`/`9c4c999`/`1b6c67f` |
| C | #11 色彩 token 化（约 3800 处迁移）+ #18/#19/#20 杂色收编 | `10047c5`…`341bf17` |
| D | #12 共享组件 + 38 个计算器迁移 + #21 小数键盘 + #22 FiO₂ 对齐 + #23 死代码 | `8d3ce43`…`9cbe37e` |

## 3. 关键机制与铁律（改代码前必读，违反必出 bug）

### 3.1 计算器空态模式（批次 1 建立，全 App 统一）

- 引擎：必填项不完整 → 返回 `{ value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' }`；数值字段用 0 或 −1 作"未录入"哨兵（0 是有效值的用 −1，RASS 用 −99）
- 选项型："无/有"按钮是**三态 number**（−1 未选 / 0 无 / 1 有），不是 boolean
- 可选字段（PEEP、基线 Cr 等）不参与必填判断
- 范式参考：`engine/MapCalculator.ets` + `components/calculators/MapCalculator.ets`

### 3.2 resetKey 强制重建机制（批次 2 建立，极易踩雷）

所有 TextInput 是**非受控组件**（只有 onChange，没有 text 绑定）。重置按钮靠 `@State resetKey` 让 `build()` 在 `resetKey % 2` 两个分支间切换，销毁重建整个输入子树。
**任何涉及计算器输入区/共享组件 InputRow 的改动，必须保证 resetKey 分支切换仍然包住输入子树**，否则"重置"按钮会静默失效（输入框文字清不掉）。

### 3.3 共享组件（批次 D 建立）

`components/calculators/widgets/CalcWidgets.ets`：`CalcCard` / `InputRow` / `ResultCard` / `OptionChip`。
- `InputRow` 固定带 `fontColor(textPrimary)` 和 `width('100%')`：**原代码缺这两个属性的输入框一律保留 inline 不迁移**（避免主题默认色偏差）
- 无 `.height()` 的 Button 保留 inline（OptionChip 的 `horizontalPadding=-1` 约定：-1 时走 if/else 不调 `.padding()`，保留 Button 默认内边距）
- **未迁移的 2 个**：`VasopressorCalculator`（双栏换算特殊交互）、`BloodGasCalculator`（6 步法特殊区 + 三套自定义结果）。如要迁移，需先扩展组件 API，不要硬套
- 局部组件（Abcd2 的 OptRow、Timi 的 YesNoBtn 等）有意保留

### 3.4 色彩/尺寸 token（批次 C 建立）

- `utils/AppColors.ets`（40+ 语义 token）、`utils/AppDimens.ets`；tier 色唯一定义在 AppColors，`CalcEngine.getTierColor` 引用之（AppColors 不反向依赖 CalcEngine，无循环）
- **新代码禁止硬编码 `#RRGGBB`**。白名单仅：`ImageEditor.ets` 画布功能色 7 处、`#AARRGGBB` 透明度阴影 4 处
- 同义近色已归并（见 AppColors 注释），新增 token 前先查是否已有同义

### 3.5 视觉规范（批次 2/3 建立，保持一致）

- 色板：深绿 `#1F3D2F` / 米底 `#F4F1EA` / 白卡 / 辅助灰绿 `#5F6654` / 危险红 `#B1452A` / 预警橙 `#E76F2C`
- 热区：选项 44、输入框 48；字号：辅助 12、正文 14；严重度表达：竖条(tier 色) + 文字标签（不要再用 emoji 圆点/数字 badge）
- 知识库分类图标：4 色大地色系 hash 分配（AppColors.kb*），不要再加新色

## 4. 未完成项施工方案

### #14 暗黑模式（建议先做；README 待办项；前置已就绪）

**现状**：token 层已集中全部色值，但 `AppColors` 是硬编码亮色的常量类，直接改它无法跟随系统主题。

**推荐方案（资源化）**：
1. 把 AppColors 的色值迁移到 `entry/src/main/resources/base/element/color.json`（`app.color.xxx`），新建 `resources/dark/element/color.json` 放暗色映射
2. UI 层字面量引用改 `$r('app.color.xxx')`；`AppColors` 保留为 `$r` 的语义别名层（`static readonly primary: Resource = $r('app.color.primary')`），调用方改动最小
3. **难点——引擎层色值**：`CalcEngine.getTierColor(): string` 被 engine/model 非 UI 代码调用，`$r` 只能在 UI 属性绑定用。两个解法：
   - A（推荐）：`getTierColor` 改为返回 tier 枚举，UI 渲染处用映射表查 `$r`。顺带让引擎与表现解耦，但调用点多（全部计算器 + PatientDetailPage），需逐处改
   - B：保留 string 返回，新增 `ThemeService` 监听 `ConfigurationConstant.ColorMode` 并切换 AppColors 值（AppStorage 驱动刷新）。改动小但 token 双轨制
4. 设置页加主题选项（跟随系统/浅色/深色），`PreferencesService` 持久化；ImageEditor 白名单深色画布在暗色下是否调整需单独看
5. 验收：5 个 Tab 页 + 计算器 + 患者详情 + 知识库阅读器在暗色下无白底刺眼、无黑字黑底；tier 色在暗色下对比度 ≥4.5:1（暗色 tier 色建议提亮一档）

### #15 返回栈（建议先于 #13 做，或一起做）

**现状**：`pages/Index.ets:82-94` 用 AppStorage flag（`patientBackFlag`/`kbBackFlag`）模拟返回；`PatientDetailPage.ets:746-756` 另有 5 层 `showXxxDetail` 布尔分发。PITFALLS.md 2026-07-09 条目记录过"物理返回键直接退出 app"的坑。

**方案**：
1. 首选 ArkUI `Navigation` + `NavDestination`（API 12+ 支持），把 Tab 内的患者/知识库两条深层路径迁过去，物理返回键由系统栈处理
2. 保守替代：写一个集中式 `BackStackService`（压栈/弹栈/当前栈顶查询），替换散落的 flag 和布尔
3. 回归测试路径：诊断详情→患者页→列表页→（再按返回）退出 app；知识库阅读器→搜索页→Tab；每一步都不能直接退出 app，也不能死循环

### #13 PatientDetailPage 拆分（4166 行 → 多文件）

**现状**：单文件承载 dashboard + 预警/诊断/数据/记录 4 详情页（build() 746-756 if-else 分发），8 个独立 `Scroll`，固定高度与 constraintSize 混用。

**方案**：
1. 拆到 `components/patient/`：`PatientDashboard`（4 预览卡）+ `AlertDetailView` / `DiagnosisDetailView` / `DataDetailView` / `RecordsDetailView`
2. 状态处理：患者数据/预警/诊断状态目前都在大文件内，优先 `@Provide`/`@Consume` 或上提一个 `PatientDetailViewModel`；避免逐 prop 透传 10 层
3. **与 #15 强耦合**：详情页分发方式会被返回栈方案改写，务必 #15 定案后再拆，否则返工
4. 注意 `formatMissingCriteria`/`findFieldSpec` 等工具函数（批次 2 新增）要随用方搬走，别留循环 import

### #16 字符串资源化（可选，先决策）

`string.json` 仅 3 条，全 App 中文硬编码。**若确认只做中文市场，可明确跳过**；若做：按页面分批迁 `$r('app.string.xxx')`，每批一个 commit，计算器词条可借共享组件迁移之机顺带做。工作量大、风险低、收益主要是未来多语言。

### #17 代码风格（顺手做）

整行 UI 压单行（如 `SofaCalculator.ets` 400+ 字符行）——批次 D 迁移过的文件已自然改善大半；剩余文件顺手格式化，不单独成批。仓库有 `code-linter.json5` 可参考规则。

## 5. 每次改完必做的验证

1. `hvigorw assembleApp` 0 错误（环境变量见 §1.2）
2. `grep -rn "#[0-9A-Fa-f]\{6\}" entry/src/main/ets/` —— 除 AppColors.ets 与白名单外应无新增
3. 抽查 3 个计算器：空开显示"请填写必填项"→ 录入 → 出分 → 重置 → 回到空态（验证 §3.1/§3.2 未被破坏）
4. 真机走查：5 个 Tab、患者详情四卡、知识库阅读器（表格/标签/callout）、AI 助手上传流程

## 6. 回退

- 单项不要：`git revert <commit>`（清单里有每项的 hash）
- 整批不要：`git checkout main`（main 只含已验收的批次 1–3）
- 任何提交都没推送过远程；推送与否由用户决定

## 7. 关键文件地图

| 文件 | 作用 |
|---|---|
| `docs/UI优化清单.md` | 23 项状态总表（继续勾选） |
| `PITFALLS.md` | ArkTS 踩坑日志（新坑请追加） |
| `entry/src/main/ets/utils/AppColors.ets` / `AppDimens.ets` | 设计 token |
| `entry/src/main/ets/components/calculators/widgets/CalcWidgets.ets` | 计算器共享组件 |
| `entry/src/main/ets/engine/CalcEngine.ets` | CalcResult + tier 分级（引用 AppColors） |
| `entry/src/main/ets/pages/Index.ets` | 4-Tab 主框架 + onBackPress（#15 战场） |
| `entry/src/main/ets/components/PatientDetailPage.ets` | 4166 行（#13 战场） |
| `entry/src/main/ets/components/KnowledgeSearchPage.ets` + `utils/KbMarkdownParser.ets` | 知识库 UI + Markdown 渲染管线 |
| `entry/src/main/ets/services/PreferencesService.ets` | 偏好持久化（#14 主题存这里） |
