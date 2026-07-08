# MedCalc 鸿蒙版

ICU/重症医学智能计算器套件，基于ArkUI开发，支持鸿蒙手机直接安装使用。

## 已实现计算器（41个）

### 呼吸
1. **血气分析** — 动脉+静脉血气, 酸碱失衡/氧合/缺氧分型/呼吸商/危急值
2. **S/F 氧合指数** — SpO₂/FiO₂, ARDS 床旁筛查
3. **P/F 氧合指数** — PaO₂/FiO₂, ARDS 诊断金标准 (Berlin 2012)
4. **ROX 指数** — 预测 HFNC 失败风险
5. **CURB-65** — 社区获得性肺炎严重度
6. **Marshall 评分** — ARDS严重程度评分
7. **PESI / sPESI** — 肺栓塞30天死亡风险, 总分0-300+ 五级

### 心血管
8. **MAP（平均动脉压）** — SSC 2021 复苏目标 ≥ 65 mmHg
9. **CHADS₂-VASc** — 房颤卒中风险, 总分 0-9 (ESC 2020)
10. **HAS-BLED** — 房颤抗凝出血风险, 总分 0-9 (ESC 2020)
11. **Mehran 评分** — 造影剂肾病风险预测
12. **TIMI STEMI** — STEMI 30天死亡风险, 8项, 0-14分
13. **TIMI NSTEMI** — NSTEMI 14天复合终点, 总分 0-7
14. **WELLS PE** — 肺栓塞临床概率, 总分 0-12.5
15. **SCAI 休克分级** — 心源性休克 A-E 五级 (SCAI 2019/2024)
16. **升压药剂量换算** — mL/h ↔ μg/kg/min, 垂体后叶素支持 U/min

### 肾
17. **CrCl（肌酐清除率）** — Cockcroft-Gault 公式
18. **eGFR（CKD-EPI 2021）** — Race-free 公式, CKD 分期依据
19. **KDIGO AKI 分期** — 急性肾损伤 1-3 期 (KDIGO 2012)

### 肝
20. **Child-Pugh 分级** — 肝硬化肝功能储备评估
21. **KCC 标准** — 急性肝衰竭紧急肝移植决策
22. **CLIF-C ACLF** — 慢加急性肝衰竭死亡率 (Jalan 2014)
23. **AARC 评分** — 慢加急性肝衰竭严重度 (APASL 2017)

### 神经
24. **GCS 评分** — 3 维度 (E/V/M), 总分 3-15
25. **NIHSS 卒中** — 11 项, 总分 0-42
26. **ABCD² 评分** — TIA 后短期卒中风险, 0-7 分
27. **RASS 镇静** — Richmond Agitation-Sedation Scale
28. **ICH 评分** — 脑出血预后评分, 总分 0-6
29. **Hunt-Hess 分级** — SAH 手术风险分层
30. **WFNS 分级** — SAH 临床分级
31. **Fisher 分级** — SAH 蛛血 CT 分级
32. **CAM-ICU** — ICU 谵妄筛查 (Ely 2001)

### 代谢
33. **白蛋白校准 AG** — 低白蛋白时 AG 假性正常, 必须校正
34. **校正血钠** — 高血糖时假性低钠校正

### 感染
35. **SOFA 评分** — 6 系统器官功能评估, Sepsis-3 诊断标准
36. **NEWS2 评分** — 英国国家早期预警评分 2 (RCP 2017)
37. **SIRS 评分** — 4 项, ≥2 = 阳性 (1991 ACCP/SCCM)

### 综合
38. **APACHE II** — 急性生理与慢性健康评分, 总分 0-71 (Knaus 1985)
39. **NRS-2002** — 住院患者营养风险, 总分 0-7, ≥ 3 有营养风险
40. **mNUTRIC** — ICU 营养风险评分, 0-9, ≥5 高营养风险 (Heyland 2011)
41. **FSS-ICU** — ICU 功能状态评分, 5项各0-7, 总分 0-35 (Thrush 2012)

## 核心功能

### 计算器
- 侧边栏抽屉导航（适配移动端，默认折叠）
- 收藏功能（快速访问常用计算器）
- 实时计算（输入即算，无多余操作）
- 结果分级（正常/轻度/中度/重度，颜色区分）
- 临床说明（每个结果附带临床意义解释）
- 数据持久化（收藏、上次使用计算器自动保存）
- PEEP 可选影响 ARDS 诊断（P/F 计算器）
- 血气分析 6 步判断法 + H-H 一致性校验 + 危急值提示
- RASS/Hunt-Hess/WFNS/Fisher 完整参考表
- 单位换算（SOFA FiO₂模式、Child-Pugh 胆红素/白蛋白单位、KCC 单位等）

### AI 助手
- LLM 驱动计算器推荐（0-4 个推荐）
- 上传检查报告图片 → AI 自动提取结构化数据
- 上传 PDF 多页报告 → 逐页识别提取
- 文本输入 → AI 提取医疗参数
- 缺失字段补充表单（选择型字段按钮组 + 数值型输入框）
- 图片编辑器（马赛克脱敏笔刷 + 放大镜 + 撤销 + base64 导出）

### 患者病历系统
- 患者列表（搜索 + 新建 + 删除确认）
- 每位患者独立数据空间（RDB 5表持久化）
- 结构化数据管理（按领域分组：血气/电解质/肝肾功能/凝血/感染指标/血流动力学/呼吸参数/神经/代谢/营养）
- 数据时间线（点击数据卡片查看历史变化趋势）
- 手动录入（搜索字段 + 数值输入）
- 全量预警引擎（41 个计算器自动实时计算，仅显示异常项）
- ICU 诊断引擎（58 条规则 / 9 分类：感染/呼吸/肾脏/心血管/神经/血液/肝/代谢/营养）
- LLM 诊断确认（新匹配诊断自动发 LLM 确认/排除/待定，降低误报）
- 预览卡 UI（预警/诊断/结构化数据/上传记录 四卡概览，点击展开全屏详情）
- 侧滑返回拦截（详情页 → 患者页 → 列表页，不误退出应用）

## 项目结构

```
entry/src/main/ets/
├── pages/
│   └── Index.ets                        # 4-Tab 主框架 + onBackPress
├── components/
│   ├── Sidebar.ets                      # 抽屉侧边栏
│   ├── LlmDialog.ets                    # AI推荐计算器对话框
│   ├── AssistantPage.ets                # AI助手（上传/提取/补充）
│   ├── ImageEditor.ets                  # 图片脱敏编辑器
│   ├── PatientListPage.ets              # 患者列表
│   ├── PatientDetailPage.ets            # 患者详情（4预览卡+4详情页）
│   ├── SettingsPage.ets                 # 设置页（LLM配置管理）
│   └── calculators/                     # 41个计算器UI组件
├── engine/                              # 计算引擎
│   ├── CalcEngine.ets                   # CalcResult + tier分级 + 工具函数
│   └── ...（各计算器引擎）
├── model/
│   ├── CalculatorRegistry.ets           # 计算器注册表
│   ├── Patient.ets                      # 患者数据模型（6类 + DATA_DOMAINS）
│   └── DiagnosisRules.ets               # 诊断规则库（58条 + 工厂函数）
└── services/
    ├── PreferencesService.ets           # 偏好持久化
    ├── LlmService.ets                   # LLM API（文本+视觉）
    ├── AssistantService.ets             # 助手逻辑（DATA_FIELDS+提取prompt+解析）
    ├── PatientRepository.ets            # RDB层（5表+CRUD）
    ├── PatientService.ets               # 业务逻辑（预警+诊断+数据合并）
    ├── DiagnosisEngine.ets              # 诊断匹配引擎
    └── ImageStore.ets                   # 图片存取（沙箱filesDir）
```

## 技术栈

- **开发语言**：ArkTS
- **UI框架**：ArkUI 声明式开发
- **最低API**：API 12（HarmonyOS 5.0）
- **数据存储**：RDB（relationalStore）+ 应用沙箱文件
- **IDE**：DevEco Studio 5.0+

## 待完善功能

- [ ] 检查时间（examTime）提取与显示，替代上传时间
- [ ] 主题切换（暗色模式）
- [ ] PDF导出
- [ ] 诊断编辑/覆盖/治疗建议
- [ ] LLM 推荐结果带原因

**当前进度：41/41 计算器 + 患者病历系统 + ICU诊断引擎**

## 许可

仅供医疗专业学习参考，不替代临床判断。
