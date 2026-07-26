# MedCalc UI 第四轮·手术青 — 施工单审核疑问

> 审核对象：`docs/UI优化建议-第四轮-手术青.md`
> 审核时间：2026-07-26

---

## A. 色表完整性

### A1. §1.1 缺 4 个新增 token 行

以下 token 在 §2/§3/§4 中提到但 §1.1 色表未列，需补入：

| token | base | dark | 来源 |
|---|---|---|---|
| headerBg | #0F766E | #0C2422 | §2 |
| headerText | #FFFFFF | #FFFFFF | §2 |
| tabInactive | #9AAFAE | #5F726F | §3 |
| groupLine | #B8D8D5（primary 35% on bg，需实测） | ~#1A3B38（需实测） | §4 |

### A2. §1.2 dark 表严重不完整

当前仅 12 条，color.json 有 44 条。以下 token 缺失 dark 映射：

- textOption、placeholder、textBody
- fillBeige、surfaceMuted、surfaceSubtle
- divider、warningText
- kbAccent、kbDeepGreen、kbWarmBrown
- aiAccent、aiAccentBg
- infoAccent、infoAccentBg
- domain 8 色（electrolyte/kidney/liver/inflammation/cardiac_marker/neuro/endocrine/muscle）
- dialog_cancel、dialog_confirm
- 新增 4 token（A1 表）的 dark 值

**建议：补全全部 44+4 条 dark 映射，不留空白。**

### A3. §1.1 多处"（现值）"占位符

以下 token 写了"（现值）"而非实际色值，施工时需对照 color.json 逐条填明：

- textBody（现 #4A5247）
- placeholder（现 #999999）
- divider（现 #E0DCC8）
- fillNeutral（现 #F5F5F5）
- fillBeige（现 #E8E5D8）
- textOption（现 #2D5440）
- tierInfo（现 #5F6654）
- tierOkBg（现 #E8F5E9）
- tierWarnBg（现 #FFF8E1）
- tierDangerBg（现 #FFEBEE）

---

## B. 设计决策

### B1. §5 空态 vs 第三轮冲突

第三轮刚做完空态灰化 Hero 卡（`CalcWidgets.ets:182-197`）：
- inbox 图标 + '—' 灰化 + 0.4 opacity
- 占完整 Hero 卡高度

§5 要改成紧凑 40px 单行条（ic_info + "填写必填项后自动出分"）。

**需确认**：紧凑条替代灰化 Hero 卡？替代后删掉 inbox/opacity 逻辑，换成紧凑条？

### B2. textOption=#0F766E（=primary）区分度问题

82 处代码逻辑：`选中→白字(card) on primary底，未选中→textOption色 on fillNeutral底`

如果 textOption=primary：
- 未选中：青字(#0F766E) + 浅冷灰底(#E4EEEE)
- 选中：白字(#FFFFFF) + 深青底(#0F766E)

色相相同，仅靠底色深浅区分。OptionChip 在列表密集排列时，快速扫视能否区分？

**替代方案**：textOption=textSecondary(#5B7272)，未选中灰字+浅底，选中白字+深底，色相+明度双重区分。

### B3. fillBeige→fillNeutral 合并

fillBeige 有 21 处引用：Settings(6)、PatientDetailPage(3)、PatientDetailDialogs(2)、KbMarkdownRenderer(2)、DashboardPreviewCards(2)、AssistantPage(2)、KnowledgeSearchPage(2)、PatientListPage(1)、ImageEditor(1)、LlmDialog(1)。

合并后全部变 #E4EEEE 冷灰。米色语义废弃，但这些场景（设置页分割线、患者页选中态、KB callout 底色等）在新青系下是否都该统一？还是部分场景需保留区分？

---

## C. 技术细节

### C1. groupLine dark 值

§4 写了 `primary 35% 透明度`，dark 下 primary=#3FAF9F on background=#101E1D。
估算：`#3FAF9F` 35% on `#101E1D` ≈ `#1A3B38`（需实测确认）。
**施工时需补入色表。**

### C2. kb* 分类色衍生规则不明确

§1.1 写"kbDeepGreen→#0F766E，kbAccent→#14A08F，其余 4 色知识库图标色在青/灰青/蓝青/暖棕内取"，但未给出具体色值。需补充：

| token | base 新值 | dark 新值 |
|---|---|---|
| kbAccent | #14A08F | ? |
| kbDeepGreen | #0F766E | ? |
| kbWarmBrown | ? | ? |

### C3. DOMAIN_COLORS 15 域色衍生规则不明确

§1.1 写"青系衍生（保持域间区分度，只转色相不减少数量）"，但未给出具体色值。当前 8 个 domain 色是暖色系（绿/橙/棕/红/紫），需逐个转为青系衍生色并保持 8 色间区分度。

---

## 总结

| 类别 | 数量 | 阻塞性 |
|---|---|---|
| 色表缺失（需补值） | ~34 条 | 高 — 不补无法开工 |
| 设计决策（需确认） | 3 项 | 中 — 影响视觉效果 |
| 技术细节（需明确） | 3 项 | 中 — 影响施工精确度 |
