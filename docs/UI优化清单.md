# MedCalc UI 优化清单

> 生成时间：2026-07-19
> 来源：截图审查（screenshots/ + test_screenshots/ 共 22 张）+ 代码只读审查（entry/src/main/ets/）
> 状态：仅评估，未改动任何代码。每条带证据，改完一项勾一项。

## 总体结论

功能骨架完整，视觉底子（米底 `#F4F1EA` + 深绿 `#1F3D2F` + 白卡）不错。但：
- 视觉体系零资源化：全 App 3300+ 处硬编码色值、0 个设计 token
- 计算器层 ~90% 样式为复制粘贴（卡片样式在 38 个文件重复 108 次）
- 床旁可用性（字号、热区、数字键盘）有系统性短板
- 暗黑模式资源准备度≈0

---

## 🔴 高优先级（正确性 / 像 bug）

- [ ] **1. 计算器"出厂即出分"，展示未录入的假结果**
  - 证据：`Apache2Calculator.ets:5-29` 用默认值（体温37/SBP120/GCS15）初始化并在 `aboutToAppear` 立即 `calculate()`；`GcsCalculator.ets:5-7` 默认 15 分"正常"；而 `engine/MapCalculator.ets:4-11` 会判空返回"请填写必填项"
  - 建议：统一走 MAP 判空模式，必填项未录完时结果卡只显示"待录入"占位

- [ ] **2. 底部 Tab 选中态是系统蓝，与深绿品牌色冲突**
  - 证据：screenshots/ 多张截图，选中 Tab 蓝色下划线+蓝字（HarmonyOS 默认色），全 App 主色为深绿
  - 建议：Tab 指示器与选中文字统一改品牌绿

- [ ] **3. 内部实现细节泄露到临床界面**
  - 证据：诊断详情显示"缺: pao2 lt 60"（规则 DSL）；结构化数据显示"albunit gl"、"年龄65-74 0 / 年龄≥75 1"（字段 key 与派生 0/1 标志）；"广搜:50→全文:10+片段:0"（检索统计噪音）
  - 建议：DSL 渲染为"PaO₂ < 60 mmHg"；派生字段过滤或本地化；检索统计收进调试入口

- [ ] **4. 约 1/3 数值输入框未声明数字键盘**
  - 证据：calculators/ 下 143 个 `TextInput` 仅 96 处 `.type(InputType.Number)`；`BloodGasCalculator.ets:272-419` 血气 16 个输入框全漏；`SofaCalculator.ets:30` FiO₂ 漏
  - 建议：逐一补齐，血气优先（约半天工作量）

- [ ] **5. 全 App 零安全区/沉浸适配**
  - 证据：全 ets/ 目录 `expandSafeArea|SafeArea` 0 命中；`Index.ets:133-139` Tab 栏无避让；`LlmDialog.ets:13-14,116` 悬浮按钮固定 `fabBottom=24`
  - 建议：加 `.expandSafeArea()` 策略，手势导航条设备防压线

## 🟡 中优先级（可用性）

- [ ] **6. 知识库视觉体系与主 App 脱节**
  - 证据：截图 test_screenshots/screenshot_3/4/6-12：图标绿/棕/橙/紫/蓝随机配色；首字图标辨识度低（两个"实"、三个"I"）；详情页标题"index/index"重复；Markdown 表格纯文本渲染（`------` 裸露）；整页 `#标签` 导航为不可点文本墙
  - 建议：图标统一为品牌色系或按分类定色；修标题；Markdown 表格用真表格组件渲染；标签导航改可点 chip

- [ ] **7. 患者详情页三套视觉语言混用**
  - 证据：screenshots/screenshot_3：预警卡同时用圆形数字 badge + 彩色圆点 + 竖条；诊断卡另用"警示/关注"文字标签
  - 建议：统一为一种分级表达（如 竖条颜色 + 文字标签）

- [ ] **8. 热区/字号不达床旁标准**
  - 证据：选项按钮统一 `height(36)`（122 处，如 `GcsCalculator.ets:26,37,48`）；输入框 `height(40)`；列表"删除"为 12pt 小字且紧邻整行点击区（`PatientListPage.ets:135-142`）；fontSize ≤11.5 共 199 处（`Sidebar.ets:54,88` 为 10pt）；`#7A8074` 灰 on 米底对比度约 3.6:1（低于 WCAG 4.5:1）
  - 建议：选项按钮 36→44vp、输入框 40→48vp、辅助文字最小 12pt、辅助灰调深

- [ ] **9. 41 个计算器无"重置/清空"，换患者需逐字段手删**
  - 证据：calculators/ 目录 grep "重置|清空" 0 命中；`onChange` 逐键即时计算导致分层标签输入中抖动（`MapCalculator.ets:23`）
  - 建议：每计算器加重置按钮；或评估"计算"提交式

- [ ] **10. 残留样式问题**
  - 证据：test_screenshots/screenshot_1：P/F 计算器 PEEP 输入框右侧有残留 "T" 方块；截图 1/2 间单位切换选中态颜色不一致
  - 建议：清理残留组件；选中态色纳入 token

## ⚪ 低优先级（工程欠债）

- [ ] **11. 色彩零 token 化**：3323 处硬编码色值遍布 53 个文件；`resources/base/element/color.json` 仅 1 条；`PatientDetailPage.ets` 单文件 310 处色值；"删除/预警"用橙 `#E76F2C` 与"危险=红 `#B1452A`"语义不一致（`PatientListPage.ets:128,137,313`）。建议：先建 `AppColors`/`Dimens` 常量类，再迁移 color.json
- [ ] **12. 样式全量复制粘贴**：卡片样式 108 处重复；结果卡/输入行结构逐字重复。建议抽公共组件：`CalcCard`/`InputRow`/`ResultCard`/`OptionChip`
- [ ] **13. `PatientDetailPage.ets` 单文件 4166 行**、8 个独立 Scroll、嵌套滚动、固定高度混用。建议拆分子组件文件
- [ ] **14. 暗黑模式准备度≈0**：resources/dark/ 仅 1 条启动窗色。前置依赖第 11 条
- [ ] **15. 返回逻辑碎片化**：`Index.ets:82-94` 靠 AppStorage flag 模拟返回栈；详情页内 5 层布尔分发（`PatientDetailPage.ets:746-756`）
- [ ] **16. 字符串未资源化**：string.json 仅 3 条，全 App 中文硬编码（只做中文可接受，但需知情决策）
- [ ] **17. 代码风格**：整行 UI 压成单行（`SofaCalculator.ets:29` 400+ 字符），review/diff 不友好

## 做得对、要保持的

- tier 分级色集中在 `engine/CalcEngine.ets:31-55`（`getTierColor`）
- MAP 引擎空值保护模式
- 患者列表空态与删除确认弹窗（`PatientListPage.ets:81-94, 285-337`）
- 助手页 loading/error 态（`AssistantPage.ets:65-78`）

## 执行顺序建议

1. 高 1（未录完不出分）→ 医疗安全
2. 高 2、3（Tab 蓝、DSL 泄露）→ 最显眼的打磨
3. 高 4（数字键盘）→ 半天工作量
4. 低 11、12（token + 公共组件）→ 一次消灭 108 处重复，为暗黑模式铺路
5. 中 8（热区字号）→ 床旁可用性
6. 高 5、中 9（安全区 + 重置按钮）
