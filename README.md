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
- 向量嵌入混合检索（EmbeddingService）
- Markdown 渲染器（表格横滑/callout/标注/TOC 跳转）
- 收录《实用重症医学》+ 多份国际指南/专家共识

## 项目结构

```
entry/src/main/ets/
├── pages/
│   └── Index.ets                        # 5-Tab 主框架
├── components/
│   ├── Sidebar.ets                      # 抽屉侧边栏（分类色导航）
│   ├── LlmDialog.ets                    # AI推荐计算器（多轮问诊+LLM切换+FAB）
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
│   ├── CalculatorRegistry.ets           # 88个计算器注册表 + 8分类
│   ├── Patient.ets                      # 患者数据模型
│   └── DiagnosisRules.ets               # 诊断规则库
├── utils/
│   ├── AppColors.ets                    # 语义色彩 token（$r 双主题）
│   ├── AppDimens.ets                    # 尺寸 token
│   ├── ConfirmDialog.ets                # 确认弹窗
│   └── KbMarkdownParser.ets            # Markdown 解析+TOC提取
└── services/
    ├── PreferencesService.ets           # 偏好持久化（收藏/LLM配置/主题）
    ├── LlmService.ets                   # LLM API（多轮问诊+视觉+extractJsonPayload）
    ├── AssistantService.ets             # 助手逻辑（提取+解析+引擎路由）
    ├── PatientRepository.ets            # RDB 层
    ├── PatientService.ets               # 业务逻辑（预警+诊断）
    ├── DiagnosisEngine.ets              # 诊断匹配引擎
    ├── KnowledgeService.ets             # 知识库全文检索
    ├── EmbeddingService.ets             # 向量嵌入
    └── ImageStore.ets                   # 图片存取
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
- 零 `any` 类型滥用

## 许可

仅供医疗专业学习参考，不替代临床判断。
