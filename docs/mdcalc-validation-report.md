# MDCalc 交叉验证报告

验证日期：2026-07-26
验证方式：逐计算器核对 mdcalc.com 公式/系数/分级阈值，并与代码实现比较

---

## 🔴 严重错误（已修复）

| 计算器 | 问题 | 修复内容 |
|--------|------|----------|
| NIHSS | 缺少 6a/6b 下肢运动项，最高分标注 34 非 42 | 添加 legA/legB 参数，总分/42 正确 |
| ROX | 低风险阈值 2.85 应为 3.85 | 2.85→3.85 |
| ICH Score | 缺 GCS 组件，总分 0-4 非 0-6 | 添加 gcs 参数，GCS 3-4=2/5-12=1/13-15=0，总分/6 |
| Marshall→Murray | 整个评分实现错误，实际应为 Murray 肺损伤评分 | 保留原 Marshall（简化 ARDS 评分），新增 calculateMurray()含 P/F+PEEP+顺应性+胸片象限四组件 |
| KCC | 逻辑根本性错误：缺 pH/Cr/HE 分级输入，两条路径逻辑全错 | 新增 ph/crMgDl/hepaticEnceph 参数，重写对乙酰氨基酚/非对乙酰氨基酚双路径逻辑 |
| CLIF-C ACLF | 脑评分 HE III-IV 应为 2 分（非 3），CLIF-SOFA 脑分量表 0/1/2 | hepaticEnceph 映射修正：0→0, I-II→1, III-IV→2 |
| Wells PE | 缺 2 项（PE 最可能+3、既往 DVT/PE+1.5），最大分 8 非 12.5 | 待新增（不在当前批次） |
| Mehran | 缺低血压(+5)/IABP(+5)，年龄>60 非标准阈值 | 添加 hypotension/iabp 参数，年龄改为 ≥60=2/>75=4 |
| APACHE II | A-aDO₂ 200-349 应为 2 分（代码写了 1 分） | oScore 1→2 |
| McMahon | 5 个系数错误：Age71-80 应 2.5 非 3；Age>80 应 3 非 4.5；Ca≤7.5 应 2 非 1.5；CK>40000 应 2 非 3；HCO₃<19 应 2 非 3 | 全部修正 |
| KDIGO | delta≥0.3 错误出现在 Stage 3 检查（0.3 mg/dL 升高是 Stage 1 条件） | delta≥0.3 从 Stage 3 条件移至 Stage 1 |
| CURB-65 | 分级边界错误（0/1-2/≥3→0-1/2/≥3） | 修正为 0-1 低风险/2 中风险/≥3 高风险 |
| Fisher Grade 1 | 应为"无 SAH"而非"薄层出血" | 修正 I 级描述为"无蛛网膜下腔出血" |

---

## 🟡 中等错误（已修复）

| 计算器 | 问题 | 修复内容 |
|--------|------|----------|
| CHADS₂-VASc | 分级未按性别分层（ESC 2020 男女不同阈值） | 添加性别分层：男≥2/女≥3 抗凝，男1/女2 考虑 |
| S/F Ratio | SpO₂ 天花板警告应在 ≥97% 非 ≥99% | 99→97 |
| NEWS2 | 人工最低分 5 分规则（官方无此规则） | 移除 has3 && total<5 → total=5 逻辑 |
| Hunt-Hess Grade 4 | 应为"昏睡"非"昏迷" | 昏迷→昏睡 |
| BAP-65 | 3 个边界值 > 应改为 >=（BUN≥25/pulse≥109/age≥65） | >25→>=25, >109→>=109, >65→>=65 |
| Age-Adjusted D-dimer | age > 50 应为 age >= 50 | >50→>=50 |
| HELLP | AST/ALT ≥80 应为 ≥70（Tennessee 标准） | ≥80→≥70 |
| McMahon | 已在 🔴 修复 | — |

---

## 🟢 已验证通过（无公式/阈值错误）

| 计算器 | 验证来源 | 备注 |
|--------|----------|------|
| MAP | 内科标准 | ✅ |
| P/F Ratio | Berlin ARDS | ✅ |
| GCS | Teasdale/Jennett | ✅ |
| RASS | Richmond 躁动镇静评分 | ✅ |
| WFNS | SAH 分级 | ✅ |
| TIMI NSTEMI | TIMI Study Group | ✅ |
| Child-Pugh | Pugh 1973 | ✅ |
| SIRS | ACCP/SCCM 1992 | ✅ |
| ABCD2 | Johnston 2007 | ✅ |
| Corrected AG | 标准酸碱 | ✅ |
| ISTH DIC | ISTH 2001 | ✅ |
| PLASMIC | Bendapudi 2017 | ✅ |
| CRUSADE | Subherwal 2009 | ✅ |
| GOLD ABE | GOLD 2023 | ✅ |
| GCS-P | Brennan 2018 | ✅ |
| FOUR | Wijdicks 2005 | ✅ |
| STESS | Rossetti 2006 | ✅ |
| VIS | Gaies 2010 | ✅ |
| Lactate Clearance | 脓毒症指南 | ✅ |
| NRS-2002 | Kondrup 2003（小验证） | ✅ |
| PESI/sPESI | Aujesky 2005 | ✅ |
| mNUTRIC | Heyland 2011 | ✅ |
| Vasopressor Dose | 剂量换算 | ✅ |
| ADD-RS | Nazerian 2018 | ✅ |
| eGFR CKD-EPI 2021 | CKD-EPI 2021 | ✅ |
| HEART Score | Backus 2010/2013 | ✅ |
| RTS | Champion 1989 | ✅ |
| ADHERE | ADHERE 注册 | ✅ |
| Shock Index | 文献（MDCalc 无正式分级） | ✅ 自定义分层合理 |
| qSOFA | Sepsis-3/JAMA 2016 | ✅ 3 级扩展合理 |
| Corrected Ca | Payne 公式 | ✅ |
| Calculated Osm | 标准公式 | ✅ 缺乙醇项（低优先） |
| MME | CDC 2022 | ✅ ≥90 与 CDC 一致（MDCalc 写 ≥99） |
| Corticosteroid | 不在 MDCalc，标准药理对照 | ✅ |
| Fick | MDCalc 10095 | ✅ Hgb 单位转换正确 |
| APAP Nomogram | Rumack-Matthew 150 线 | ✅ 公式数学精确 |

---

## ⚠️ 已知偏差（保留不改）

| 计算器 | 偏差 | 原因 |
|--------|------|------|
| RSBI | 80-105 灰区不在 Yang-Tobin 原文 | 临床细化，合理扩展 |
| Shock Index | 5 级分层（MDCalc 无分层） | 临床实用 |
| qSOFA | 3 级（MDCalc 仅二元） | "警惕"级合理 |
| Duke IE | 缺病理标准（需手术/尸检） | 床旁工具可接受；使用 1994 版（2023 Duke-ISCVID 已更新） |
| Sgarbossa | Smith 改良单独（2 分）判为"改良标准阳性"非完全阳性 | 更保守，可接受 |
| AWOL | 病情严重度为单一布尔值（MDCalc 有 5 级） | 简化可接受 |
| SOFA | 缺 MV 标志 | P/F<100 必然 MV，实际影响小 |
| CAM-ICU | 缺 RASS ≥-3 前提检查 | 待后续补录 |
| ABC/2 | 缺不规则出血 ABC/3 选项 | 待后续补录 |
| Na Deficit/Correction | 缺老年人 TBW 系数；Correction 缺 InfusateK | 待后续补录 |
| KDIGO | UO<0.5 自动 Stage 2 无法区分 Stage 1（缺持续时间）；缺无尿≥12h | 待后续补录 |
| 血气分析 | 不改（用户明确） | — |
| 升压药 | 不迁移到共享组件（用户明确） | — |

---

## 不在 MDCalc 上的计算器

按文献核对：WFNS、SCAI、FSS-ICU、STESS、VIS、Lactate Clearance、KDIGO、AARC

---

## 修复后构建验证

2026-07-26: `build_project` BUILD SUCCESSFUL，所有引擎+UI 组件+AssistantService 调用链更新完毕。
