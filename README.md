# MedCalc 重症智算

ICU/重症医学智能计算器套件，基于 ArkTS + ArkUI 开发，支持鸿蒙手机直接安装使用。

## 已实现计算器（88 个）

| 分类 | 数量 | 代表计算器 |
|------|------|-----------|
| 心血管 | 21 | MAP、CHADS₂-VASc、HAS-BLED、TIMI STEMI/NSTEMI、Wells PE/DVT、SCAI 休克、Mehran、HEART、CRUSADE、Sgarbossa、QTc、Fick、VIS、ADD-RS 等 |
| 综合 | 19 | APACHE II、Marshall MODS、RTS、Glasgow-Blatchford、BISAP/Ranson、BWPS、ISTH DIC、PLASMIC、Parkland、Alvarado、RIPASA、MME、激素等效、APAP 列线图、REMS、乳酸清除率等 |
| 神经 | 15 | GCS、GCS-P、FOUR、NIHSS、ABCD²、ICH、Hunt-Hess、WFNS、Fisher、RASS、CAM-ICU、STESS、ABC/2、CSF 解读、AWOL 谵妄等 |
| 呼吸 | 11 | 血气分析、S/F、P/F、ROX、CURB-65、RSBI、哮喘分级、GOLD ABE、BAP-65、CPIS、吸入性肺炎等 |
| 感染 | 7 | SOFA、qSOFA、SIRS、NEWS2、ANC/MASCC、Duke IE 等 |
| 代谢 | 6 | 校正 AG、校正血钠、钠缺失量、钠纠正速率、校正钙/渗透间隙、Cairo-Bishop TLS 等 |
| 肝 | 5 | Child-Pugh、KCC、CLIF-C ACLF、AARC、HELLP 等 |
| 肾 | 4 | CrCl、eGFR(CKD-EPI 2021)、KDIGO AKI、McMahon 横纹肌溶解 |

全部 88 个计算器均已与 MDCalc 逐条交叉验证，详见 `docs/mdcalc-validation-report.md`。

## 核心功能

### 计算器
- 侧边栏抽屉导航（8 分类，分类色图标，适配移动端）
- 收藏功能（快速访问常用计算器）
- 实时计算（输入即算，无多余操作）
- 结果分级（正常/轻度/中度/重度，颜色区分）
- 临床说明（每个结果附带临床意义解释与文献来源）
- 数据持久化（收藏、上次使用计算器自动保存）
- 单位换算（Cr µmol↔mg/dL、Bili µmol↔mg/dL、BUN mmol↔mg/dL、FiO₂ %↔小数等）
- 每个计算器底部附医学文献来源卡片（`docs/calculator-references.md`）

### AI 推荐计算器（多轮问诊）
- **第一轮：固定问卷**（代码控制，零幻觉）— 4 个维度一次性展示：
  - 主诉（多选）：胸痛/呼吸困难/意识障碍/休克/下肢肿痛/腹痛恶心呕吐/出血/发热/电解质紊乱/药物中毒/无明显症状
  - 器官系统（多选）：心血管/呼吸/神经/肝肾/消化腹部/血液凝血/感染脓毒症/代谢电解质
  - 场景（单选）：ICU/急诊/病房/门诊
  - 急慢性（单选）：急性发作/慢性持续/不确定
- **第二轮：LLM 自由追问**（基于 R1 信息，LLM 自行设计 1-2 个追问问题进一步定位，支持多选）
- 推荐结果含 summary 说明框（为什么推荐这几个）+ 每条 reason 推荐理由
- 同类计算器（如 bg/sf/pf 氧合指数、crcl/gfr 肾功能）整体推荐不强行区分
- 弹窗内可切换 LLM 模型（显示供应商-名称，bindMenu 下拉）
- 三层 JSON 防护解析（`</think>` 截断 + 代码围栏 + 花括号兜底），兼容带思考过程的模型

### AI 助手
- LLM 驱动数据提取（上传检查报告图片/PDF/文本 -> AI 自动提取结构化数据）
- PDF 多页报告逐页识别提取
- 缺失字段补充表单（选择型字段按钮组 + 数值型输入框）
- 72 个计算器接入助手自动计算管线（callEngine 统一路由 + 单位换算）
- 图片编辑器（马赛克脱敏笔刷 + 放大镜 + 撤销 + base64 导出）

### 患者病历系统
- 患者列表（搜索 + 新建 + 删除确认）
- 每位患者独立数据空间（RDB 持久化）
- 结构化数据管理（按领域分组：血气/电解质/肝肾功能/凝血/感染指标/血流动力学/呼吸参数/神经/代谢/营养）
- 数据时间线（点击数据卡片查看历史变化趋势）
- 手动录入（搜索字段 + 数值输入）
- 全量预警引擎（88 个计算器自动实时计算，仅显示异常项）
- ICU 诊断引擎（规则匹配 + LLM 确认，降低误报）
- 预览卡 UI（预警/诊断/结构化数据/上传记录 四卡概览，点击展开全屏详情）

### 知识库
- 本地 Markdown 知识库（rawfile 打包，离线可用）
- SQLite FTS4 全文检索（icu zh_CN 分词）
- 向量检索预留未启用（EmbeddingService 底层存储层已就绪，检索方法待接入）
- Markdown 渲染器（表格横滑/callout/标注/TOC 跳转）
- 收录《实用重症医学》+ 多份国际指南/专家共识

## 项目结构

```
entry/src/main/ets/
├── pages/
│   └── Index.ets                        # 4-Tab 主框架（三模式切换）
├── components/
│   ├── CalcRouter.ets                   # 88路计算器统一路由（@Component + @Prop）
│   ├── Sidebar.ets                      # 抽屉侧边栏（分类色导航）
│   ├── LlmDialog.ets                    # AI推荐计算器（多轮问诊+LLM切换+弹出计算器）
│   ├── AssistantPage.ets                # AI助手（上传/提取/补充）
│   ├── ImageEditor.ets                  # 图片脱敏编辑器
│   ├── PatientListPage.ets              # 患者列表
│   ├── PatientDetailPage.ets            # 患者详情
│   ├── KnowledgeSearchPage.ets          # 知识库搜索+阅读器
│   ├── SettingsPage.ets                 # 设置页（LLM配置+外观切换）
│   ├── CalcKbLinks.ets                  # 计算器文献来源卡片
│   ├── calculators/                     # 88个计算器UI组件
│   │   └── widgets/CalcWidgets.ets      # 共享组件(CalcCard/InputRow/ResultCard/OptionChip)
│   └── patient/                         # 患者详情子组件
├── engine/                              # 计算引擎（纯逻辑，无UI）
│   ├── CalcEngine.ets                   # CalcResult + emptyResult + tier分级
│   └── ...（37个引擎文件，含Batch聚合）
├── model/
│   ├── CalculatorRegistry.ets           # 88个计算器注册表 + 派生查询函数
│   ├── FieldSchema.ets                  # 字段定义+别名+输入规格（从AssistantService拆出）
│   ├── Enums.ets                        # TabIndex + CalcMode 枚举
│   ├── Patient.ets                      # 患者数据模型
│   └── DiagnosisRules.ets               # 诊断规则库
├── utils/
│   ├── AppColors.ets                    # 语义色彩 token（$r 双主题 + overlay）
│   ├── AppDimens.ets                    # 尺寸 token
│   ├── ConfirmDialog.ets                # 确认弹窗
│   ├── ToastUtil.ets                    # Toast 反馈工具
│   ├── KbMarkdownParser.ets            # Markdown 解析+TOC提取
│   └── KbTextUtils.ets                 # 知识库文本处理纯函数
└── services/
    ├── PreferencesService.ets           # 偏好持久化（收藏/LLM配置/主题）
    ├── LlmService.ets                   # LLM API（多轮问诊+视觉+extractJsonPayload）
    ├── AssistantService.ets             # 助手逻辑（对话管理+LLM提取）
    ├── CalcDispatcher.ets               # 计算器引擎调度（策略表路由）
    ├── SheetResultBus.ets              # AppStorage 类型安全总线（12键封装）
    ├── PatientRepository.ets            # RDB 层
    ├── PatientService.ets               # 业务逻辑（预警+诊断）
    ├── DiagnosisEngine.ets              # 诊断匹配引擎（纯函数，无副作用）
    ├── KnowledgeService.ets             # 知识库门面（单例）
    ├── KnowledgeIndex.ets               # 知识库DB初始化+Markdown摄取
    ├── KnowledgeSearch.ets              # 知识库FTS检索+LLM增强检索
    ├── KnowledgeTypes.ets               # 知识库共享数据类型
    ├── EmbeddingService.ets             # 向量检索底座（预留未启用）
    ├── ImageStore.ets                   # 图片存取
    └── prompts/                         # LLM Prompt 集中管理（6个文件）
        ├── CalcExtractionPrompt.ets     # 计算器字段提取
        ├── ClarifyPrompt.ets            # 推荐澄清（含CLARIFY_DIMENSIONS）
        ├── DiagnosisConfirmPrompt.ets   # 诊断确认
        ├── DiagnosisSuggestPrompt.ets   # 诊断建议
        ├── KnowledgeVerifyPrompt.ets    # 知识库验证
        └── KnowledgeExpandPrompt.ets    # 知识库扩展

entry/src/ohosTest/                      # 单元测试（31个用例，hypium标准驱动）
```

## 技术栈

- **开发语言**：ArkTS
- **UI 框架**：ArkUI 声明式开发
- **目标 SDK**：HarmonyOS 6.0.2 (API 22)
- **数据存储**：RDB（relationalStore）+ Preferences + 应用沙箱文件
- **LLM 兼容**：OpenAI 兼容 / Anthropic / MiniMax（按域名自动识别）
- **IDE**：DevEco Studio

## LLM 配置

在设置页配置 LLM API：
- 支持 OpenAI 兼容接口（`/v1/chat/completions`）
- 支持 Anthropic（`/v1/messages`，x-api-key 鉴权）
- 支持 MiniMax（`/v1/text/chatcompletion_v2`，按域名自动识别）
- API Key 本地存储，不上云
- 可配置多个模型，AI 推荐弹窗内可直接切换

## 质量保障

- 88 个计算器与 MDCalc 两轮交叉验证（`docs/mdcalc-validation-report.md`）
- 每个计算器的原始文献（PMID + 期刊 + 年份）和 MDCalc 链接可溯源（`docs/calculator-references.md`）
- 全量编译验证（devecocli build BUILD SUCCESSFUL）
- 单元测试 31 个用例全绿（hypium 标准驱动，`aa test` 实测通过）
- 零 `any` 类型滥用

## 架构重构（2026-07 完成）

项目经历了一轮完整的架构重构，消除了三个上帝文件（Index.ets / AssistantService.ets / KnowledgeService.ets），详见 `docs/架构重构结果报告.md`。

**核心成果**：
- 三个上帝文件合计 4131 -> ~1355 行（-67%）
- 88 路 if-else 路由从 2 份重复 -> 1 份集中（CalcRouter）
- AppStorage 12 个裸键封装为类型安全总线（SheetResultBus）
- LLM prompt 从散落在方法体内 -> 集中到 services/prompts/（6 个文件全部接线）
- 魔法数字/字符串 -> 枚举化（TabIndex + CalcMode）
- 单元测试从 0 -> 31 个用例全绿
- UI 改进：遮罩统一 token / Toast 反馈 / Sheet 高度分档 / 顶栏颜色修正

**挂起事项**（诊断 Tab 开发时一起做）：
- 注册表物理合并（aliases/inputSpec 并入 Calculator 接口，当前逻辑门面已就绪）
- InputRow 受控化（消除 resetKey 承重 hack，需改 85 个组件）

## 许可

仅供医疗专业学习参考，不替代临床判断。
