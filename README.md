# 医学计算器鸿蒙版

ICU/重症医学常用计算器套件，基于ArkUI开发，支持鸿蒙手机直接安装使用。

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
12. **TIMI STEMI** — STEMI 30天死亡风险, 8项, 0-14分 (InTIME-II 2000)
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

- 侧边栏抽屉导航（适配移动端，默认折叠）
- 收藏功能（快速访问常用计算器）
- 实时计算（输入即算，无多余操作）
- 结果分级（正常/轻度/中度/重度，颜色区分）
- 临床说明（每个结果附带临床意义解释）
- 数据持久化（收藏、上次使用计算器自动保存）
- PEEP 可选影响 ARDS 诊断（P/F 计算器）
- 血气分析 6 步判断法 + H-H 一致性校验 + 危急值提示
- RASS/Hunt-Hess/WFNS/Fisher 完整参考表
- AI 推荐计算器（LLM 驱动，0-4 个推荐）

## 安装方法

### 前提条件

1. 鸿蒙手机（HarmonyOS 5.0+）
2. 开启开发者模式
3. 安装 DevEco Studio 或 hdc 工具

### 安装步骤

1. 构建项目（DevEco Studio → Build → Build Hap(s))
2. 连接设备
3. 安装并运行

## 项目结构

```
entry/src/main/ets/
├── pages/
│   └── Index.ets                    # 主页面（Stack布局+抽屉侧边栏）
├── components/
│   ├── Sidebar.ets                  # 抽屉侧边栏
│   ├── LlmDialog.ets                # AI推荐计算器对话框
│   └── calculators/                 # 41个计算器UI组件
│       ├── BloodGasCalculator.ets   # 血气分析（最复杂，~980行）
│       ├── Apache2Calculator.ets    # APACHE II（~800行）
│       ├── HuntHessCalculator.ets   # Hunt-Hess + WFNS + Fisher
│       ├── TimiCalculator.ets       # TIMI STEMI + NSTEMI
│       └── ...（其余）
├── engine/                          # 计算引擎
│   ├── CalcEngine.ets               # CalcResult 接口 + 工具函数
│   ├── BloodGasCalculator.ets       # 血气引擎（~630行）
│   ├── CommonCalculators.ets        # P/F, Na, CURB-65, SIRS
│   ├── SofaCalculator.ets           # SOFA
│   ├── Apache2Calculator.ets        # APACHE II
│   └── ...（其余引擎文件）
├── model/
│   └── CalculatorRegistry.ets       # 计算器注册表（8个分组）
└── services/
    ├── PreferencesService.ets       # 数据持久化
    └── LlmService.ets               # LLM API 调用
```

## 技术栈

- **开发语言**：ArkTS
- **UI框架**：ArkUI 声明式开发
- **最低API**：API 12（HarmonyOS 5.0）
- **IDE**：DevEco Studio 5.0+

## 已移植对照

原项目（E:\ai\med-calculators）共 **40 个注册计算器 + 1 个升压药换算**，鸿蒙版已全部移植。

## 待完善功能

- [ ] 主题切换（暗色模式）
- [ ] PDF导出
- [ ] 历史记录
- [ ] LLM 推荐结果带原因

**当前进度：100%（41/41 计算器）**

## 许可

仅供医疗专业学习参考，不替代临床判断。

## 原项目

Windows版本：`E:\ai\med-calculators`
